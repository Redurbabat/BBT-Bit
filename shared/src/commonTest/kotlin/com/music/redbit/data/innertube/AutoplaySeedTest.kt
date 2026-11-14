package com.music.redbit.data.innertube

import com.music.redbit.data.model.Song
import com.music.redbit.data.sources.TrackMatcher
import kotlinx.coroutines.delay
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class AutoplaySeedTest {
    private val target = TrackMatcher.Target("Clocks", "Coldplay", 300)
    private fun song(id: String = "abcdefghijk", artist: String = "Coldplay", duration: String = "5:00", video: Boolean = false) =
        Song(id, "Clocks", artist, durationText = duration, isVideo = video)

    @Test fun matchingAudioSeedsRadio() = runTest {
        assertEquals("abcdefghijk", findAutoplaySeed(target) { listOf(song()) })
    }
    @Test fun anotherArtistIsNotASeed() = runTest {
        assertNull(findAutoplaySeed(target) { listOf(song(artist = "Other Artist")) })
    }
    @Test fun thirtySecondPreviewIsNotASeed() = runTest {
        assertNull(findAutoplaySeed(target) { listOf(song(duration = "0:30")) })
    }
    @Test fun moduleIDsAndVideosAreNotSeeds() = runTest {
        assertNull(findAutoplaySeed(target) { listOf(song(id = "src:module:1"), song(video = true)) })
    }
    @Test fun matchingIsBounded() = runTest {
        assertNull(findAutoplaySeed(target, timeoutMillis = 50) { delay(100); listOf(song()) })
    }
    @Test fun missingMatchStaysEmpty() = runTest {
        assertNull(findAutoplaySeed(target) { emptyList() })
    }
}
