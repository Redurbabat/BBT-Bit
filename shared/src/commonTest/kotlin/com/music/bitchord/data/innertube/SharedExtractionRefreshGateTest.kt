package com.music.bitchord.data.innertube

import kotlin.test.Test
import kotlin.test.assertFalse
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TestTimeSource

/** Offline regression coverage for the global Innertube connection reset gate. */
class SharedExtractionRefreshGateTest {
    @Test
    fun multipleFailedTracksDoNotKeepResettingOneSharedSession() {
        val clock = TestTimeSource()
        val gate = SharedExtractionRefreshGate()
        assertTrue(gate.shouldRefresh(7, clock.markNow()))
        assertFalse(gate.shouldRefresh(7, clock.markNow()))
        clock += 19.seconds
        assertFalse(gate.shouldRefresh(7, clock.markNow()))
        clock += 2.seconds
        assertTrue(gate.shouldRefresh(7, clock.markNow()))
    }

    @Test
    fun switchingToAnotherAuthenticatedSessionMayResetImmediately() {
        val clock = TestTimeSource()
        val gate = SharedExtractionRefreshGate()
        assertTrue(gate.shouldRefresh(2, clock.markNow()))
        assertFalse(gate.shouldRefresh(2, clock.markNow()))
        assertTrue(gate.shouldRefresh(3, clock.markNow()))
        assertFalse(gate.shouldRefresh(3, clock.markNow()))
    }
}
