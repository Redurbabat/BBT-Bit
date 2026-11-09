package com.music.bitchord.data.innertube

import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.TimeoutCancellationException
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.withTimeout
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNull
import kotlin.test.assertTrue

class NetworkRangeRequestTest {
    @Test fun completedRequestReturnsItsBytes() = runTest {
        assertEquals("audio", fetchNetworkRange(MutableStateFlow(0L)) { "audio" })
    }

    @Test fun localTimeoutIsNotReportedAsANetworkChange() = runTest {
        val generation = MutableStateFlow(0L)
        // Bisher wurde jeder lokale Request-Abbruch wie ein Netzwechsel behandelt.
        // null übersprang dadurch den begrenzten Fehlerzähler des Downloaders.
        val result = runCatching {
            fetchNetworkRange(generation) { withTimeout(50) { awaitCancellation() } }
        }
        assertTrue(result.isFailure, "Lokaler Timeout darf keinen Netzwechsel vortäuschen")
        assertTrue(result.exceptionOrNull() !is CancellationException,
            "Lokaler Timeout muss das Transport-Retrybudget verwenden")
        assertEquals(0L, generation.value)
    }

    @Test fun locallyCancelledRequestUsesTransportRetryBudget() = runTest {
        val result = runCatching {
            fetchNetworkRange(MutableStateFlow(0L)) { throw CancellationException("request stopped") }
        }
        assertTrue(result.isFailure)
        assertTrue(result.exceptionOrNull() !is CancellationException)
    }

    @Test fun aLocalInterruptionDoesNotPoisonTheNextAttempt() = runTest {
        val generation = MutableStateFlow(0L)
        val first = runCatching {
            fetchNetworkRange(generation) { throw CancellationException("fixture interruption") }
        }
        assertTrue(first.exceptionOrNull() is NetworkRangeInterrupted)
        assertEquals("resumed audio", fetchNetworkRange(generation) { "resumed audio" })
    }

    @Test fun networkChangeRetriesWithoutCancellingTheDownload() = runTest {
        val generation = MutableStateFlow(0L)
        launch { delay(10); generation.value = 1L }
        assertNull(fetchNetworkRange(generation) { awaitCancellation() })
        assertEquals("next range", fetchNetworkRange(generation) { "next range" })
    }

    @Test fun cancellingTheDownloadStillPropagatesCancellation() = runTest {
        assertFailsWith<TimeoutCancellationException> {
            withTimeout(50) { fetchNetworkRange(MutableStateFlow(0L)) { awaitCancellation() } }
        }
    }

    @Test fun transportErrorsKeepTheirOriginalIdentity() = runTest {
        val expected = IllegalStateException("fixture transport failure")
        val actual = runCatching { fetchNetworkRange(MutableStateFlow(0L)) { throw expected } }
        assertTrue(actual.exceptionOrNull() === expected)
    }
}
