package com.music.redbit.data.innertube

import kotlinx.coroutines.*
import kotlinx.coroutines.test.runTest
import com.music.redbit.data.http.RawHttpBytes
import com.metrolist.innertubex.extraction.StreamResolveException
import com.metrolist.innertubex.extraction.StreamAttemptDiagnostic
import com.metrolist.innertubex.extraction.StreamDiagnostics
import kotlin.test.*

/** The production resolver shell around upstream extraction, with synthetic media. */
class StreamResolverRecoveryTest {
    private suspend fun fixture(body: suspend () -> Unit) {
        val extract = StreamResolver.extraction
        try {
            Innertube.cookie = null
            StreamResolver.onSessionChanged()
            body()
        } finally {
            StreamResolver.extraction = extract
            Innertube.cookie = null; StreamResolver.onSessionChanged()
        }
    }
    private fun stream(id: String) = StreamResolver.ResolvedStream(
        "https://media.invalid/$id", 128, "audio/mp4", mapOf("User-Agent" to "synthetic-profile"))

    private fun botCheckFailure() = StreamResolveException(
        StreamResolveException.Reason.BOT_CHECKED,
        "YouTube asks this network to sign in to confirm it is not a bot",
    )

    @Test fun guestBotCheckBacksOffUntilSessionChanges() = runTest {
        fixture {
            var attempts = 0
            StreamResolver.extraction = { id, _ ->
                attempts++
                if (id == "blocked") throw botCheckFailure()
                stream(id)
            }
            assertFailsWith<StreamResolver.BotCheckException> { StreamResolver.resolve("blocked") }
            // A second track must not send another player request during guest backoff.
            assertFailsWith<StreamResolver.BotCheckException> { StreamResolver.resolve("other") }
            assertEquals(1, attempts)

            // Signing in is a new session: a guest's backoff cannot prevent its retry.
            Innertube.cookie = "SAPISID=synthetic-account"
            assertNotNull(StreamResolver.resolve("other"))
            assertEquals(2, attempts)
        }
    }

    @Test fun signedInBotCheckDoesNotBlockUnrelatedTracks() = runTest {
        fixture {
            Innertube.cookie = "SAPISID=synthetic-account"
            var attempts = 0
            StreamResolver.extraction = { id, _ ->
                attempts++
                if (id == "blocked") throw botCheckFailure()
                stream(id)
            }
            assertFailsWith<StreamResolver.BotCheckException> { StreamResolver.resolve("blocked") }
            assertNotNull(StreamResolver.resolve("other"))
            assertEquals(2, attempts)
        }
    }

    @Test fun unrelatedExtractionFailureIsNotMisdiagnosedAsBotCheck() = runTest {
        fixture {
            StreamResolver.extraction = { _, _ -> throw IllegalStateException("Cipher unavailable") }
            val error = assertFailsWith<IllegalStateException> { StreamResolver.resolve("broken") }
            assertEquals("Cipher unavailable", error.message)
            StreamResolver.extraction = { id, _ -> stream(id) }
            assertNotNull(StreamResolver.resolve("working"))
        }
    }

    @Test fun ordinaryUnplayableResponseDoesNotCauseGuestBackoff() = runTest {
        fixture {
            StreamResolver.extraction = { id, _ ->
                if (id == "broken") {
                    throw StreamResolveException(
                        StreamResolveException.Reason.NO_PLAYABLE_STREAM,
                        "No playable stream found for this track.",
                    )
                }
                stream(id)
            }
            val error = assertFailsWith<StreamResolveException> { StreamResolver.resolve("broken") }
            assertEquals(StreamResolveException.Reason.NO_PLAYABLE_STREAM, error.reason)
            assertNotNull(StreamResolver.resolve("working"))
        }
    }

    @Test fun openingRangeMustBePartialMediaAndCannotAcceptTruncatedFullBody() {
        val bytes = ByteArray(MIN_FIRST_RANGE_BYTES) { 7 }
        assertContentEquals(bytes, validateFirstMediaRange(RawHttpBytes(206, bytes, "audio/mp4")))
        assertFailsWith<InvalidFirstMediaRangeException> {
            validateFirstMediaRange(RawHttpBytes(403, bytes, "text/html"))
        }
        assertFailsWith<InvalidFirstMediaRangeException> {
            validateFirstMediaRange(RawHttpBytes(206, bytes, "text/html"))
        }
        assertFailsWith<InvalidFirstMediaRangeException> {
            validateFirstMediaRange(RawHttpBytes(206, bytes, "application/json"))
        }
        assertFailsWith<InvalidFirstMediaRangeException> {
            validateFirstMediaRange(RawHttpBytes(206, bytes, "video/mp4"), "audio/mp4")
        }
        assertFailsWith<InvalidFirstMediaRangeException> {
            validateFirstMediaRange(RawHttpBytes(206, null, "audio/mp4"))
        }
        assertFailsWith<InvalidFirstMediaRangeException> {
            validateFirstMediaRange(RawHttpBytes(206, ByteArray(0), "audio/mp4"))
        }
        assertFailsWith<InvalidFirstMediaRangeException> {
            validateFirstMediaRange(RawHttpBytes(206, ByteArray(1_024), "audio/mp4"))
        }
    }

    @Test fun resolutionReturnsUrlWithoutASeparateMediaProbe() = runTest {
        fixture {
            var attempts = 0
            StreamResolver.extraction = { _, _ -> attempts++; stream("direct") }
            val first = StreamResolver.resolve("track")!!
            val cached = StreamResolver.resolve("track")!!
            assertEquals("https://media.invalid/direct", first.url)
            assertEquals(first, cached)
            assertEquals(1, attempts)
        }
    }
    @Test fun distinctTracksResolveIndependently() = runTest {
        fixture {
            var attempts = 0
            StreamResolver.extraction = { id, _ -> attempts++; stream(id) }
            assertNotNull(StreamResolver.resolve("bad"))
            assertEquals(1, attempts)
            assertNotNull(StreamResolver.resolve("good"))
            assertEquals(2, attempts)
        }
    }
    @Test fun duplicateRequestsShareOneExtraction() = runTest {
        fixture {
            var requests = 0
            val entered = CompletableDeferred<Unit>(); val release = CompletableDeferred<Unit>()
            StreamResolver.extraction = { id, _ -> requests++; entered.complete(Unit); release.await(); stream(id) }
            val first = async { StreamResolver.resolve("shared") }
            entered.await()
            val second = async { StreamResolver.resolve("shared") }
            yield(); release.complete(Unit)
            assertEquals(first.await(), second.await()); assertEquals(1, requests)
        }
    }
    @Test fun cancellingOneListenerDoesNotCancelAnother() = runTest {
        fixture {
            val entered = CompletableDeferred<Unit>(); val release = CompletableDeferred<Unit>()
            StreamResolver.extraction = { id, _ -> entered.complete(Unit); release.await(); stream(id) }
            val first = async { StreamResolver.resolve("shared") }; entered.await()
            val second = async { StreamResolver.resolve("shared") }; yield()
            first.cancelAndJoin(); release.complete(Unit)
            assertNotNull(second.await())
        }
    }
    @Test fun abandonedSelectionCancelsItsExtraction() = runTest {
        fixture {
            val entered = CompletableDeferred<Unit>(); val cancelled = CompletableDeferred<Unit>()
            StreamResolver.extraction = { _, _ ->
                try { entered.complete(Unit); awaitCancellation() }
                finally { cancelled.complete(Unit) }
            }
            val selection = async { StreamResolver.resolve("abandoned") }; entered.await()
            selection.cancelAndJoin(); withContext(Dispatchers.Default) { withTimeout(3000) { cancelled.await() } }
        }
    }
    @Test fun accountSwitchRejectsObsoleteResponseAndDoesNotRetainIt() = runTest {
        fixture {
            StreamResolver.extraction = { id, _ ->
                Innertube.cookie = "SAPISID=synthetic-new-account"; stream(id)
            }
            assertFailsWith<CancellationException> { StreamResolver.resolve("switch") }
            StreamResolver.extraction = { id, _ -> stream("new-$id") }
            assertTrue(StreamResolver.resolve("switch")!!.url.endsWith("new-switch"))
        }
    }
    @Test fun tailRefusalInvalidatesOnlyIssuedTrackUrl() = runTest {
        fixture {
            var reads = 0
            StreamResolver.extraction = { id, _ -> stream("$id-${++reads}") }
            val original = StreamResolver.resolve("track")!!
            val other = StreamResolver.resolve("other")!!
            StreamResolver.onPlaybackRefused(original.url, 403)
            assertEquals(other, StreamResolver.resolve("other"))
            assertNotEquals(original.url, StreamResolver.resolve("track")!!.url)
            assertEquals(3, reads)
        }
    }
    @Test fun bitrateRequestsAreNotCoalescedAcrossDifferentCeilings() = runTest {
        fixture {
            val ceilings = mutableListOf<Int>()
            StreamResolver.extraction = { id, ceiling -> ceilings += ceiling; stream("$id-$ceiling") }
            assertNotEquals(StreamResolver.resolve("quality", 64), StreamResolver.resolve("quality", Int.MAX_VALUE))
            assertEquals(listOf(64, Int.MAX_VALUE), ceilings)
        }
    }

    @Test fun backgroundWaitersAreCancellableAndDoNotBlockForegroundPlayback() = runTest {
        fixture {
            val opened = CompletableDeferred<Unit>()
            val release = CompletableDeferred<Unit>()
            val queuedStarted = CompletableDeferred<Unit>()
            StreamResolver.extraction = { id, _ ->
                when (id) {
                    "download" -> {
                        opened.complete(Unit)
                        release.await()
                    }
                    "prefetch" -> queuedStarted.complete(Unit)
                }
                stream(id)
            }
            val generation = Innertube.sessionGeneration
            val active = async { StreamResolver.resolveBackground("download", 128, generation) }
            opened.await()
            val queued = async(start = CoroutineStart.UNDISPATCHED) {
                StreamResolver.resolveBackground("prefetch", 128, generation)
            }
            assertNotNull(StreamResolver.resolve("tapped"))
            assertFalse(queuedStarted.isCompleted)
            queued.cancelAndJoin()
            release.complete(Unit)
            assertNotNull(active.await())
            assertFalse(queuedStarted.isCompleted)
            assertNotNull(StreamResolver.resolveBackground("prefetch", 128, generation))
        }
    }

    @Test fun backgroundWorkFromPreviousAccountCannotStartAfterWaiting() = runTest {
        fixture {
            val opened = CompletableDeferred<Unit>()
            val staleStarted = CompletableDeferred<Unit>()
            StreamResolver.extraction = { id, _ ->
                if (id == "active") {
                    opened.complete(Unit)
                    awaitCancellation()
                }
                if (id == "stale") staleStarted.complete(Unit)
                stream(id)
            }
            val generation = Innertube.sessionGeneration
            val active = async { StreamResolver.resolveBackground("active", 128, generation) }
            opened.await()
            val stale = async(start = CoroutineStart.UNDISPATCHED) {
                StreamResolver.resolveBackground("stale", 128, generation)
            }
            Innertube.cookie = "SAPISID=synthetic-new-account"
            assertFailsWith<CancellationException> { active.await() }
            assertFailsWith<CancellationException> { stale.await() }
            assertFalse(staleStarted.isCompleted)
            assertNotNull(StreamResolver.resolveBackground("current", 128, Innertube.sessionGeneration))
        }
    }

    @Test fun reportSeparatesRealRequestsFromSkippedProfilesAndRedactsRawFields() {
        val failure = StreamResolveException(
            reason = StreamResolveException.Reason.NO_PLAYABLE_STREAM,
            message = "No compatible audio",
            diagnostics = StreamDiagnostics(
                attempts = listOf(
                    StreamAttemptDiagnostic("IOS", "IOS", "private-agent", "selection:private reason"),
                    StreamAttemptDiagnostic("IOS", "IOS", "private-agent", "transport:hls-only"),
                    StreamAttemptDiagnostic("VISIONOS", "invalid/private-profile", "private-agent", "playability:private status"),
                ),
                usedAuthenticatedWatchPage = false,
                playerRequests = 2,
            ),
        )
        val message = failure.playbackDiagnostic()
        assertContains(message, "player_requests=2")
        assertContains(message, "IOS/transport:hls-only")
        assertContains(message, "unknown/playability:other")
        assertFalse(message.contains("private"))
    }
}
