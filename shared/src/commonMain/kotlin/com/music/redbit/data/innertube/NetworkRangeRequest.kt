package com.music.redbit.data.innertube

import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch

/** Ein Schnittstellenwechsel darf denselben Bereich erneut anfordern. */
internal suspend fun <T : Any> fetchNetworkRange(
    generation: StateFlow<Long>,
    request: suspend () -> T,
): T? {
    val started = generation.value
    return coroutineScope {
        val fetch = async { request() }
        val watcher = launch {
            generation.first { it != started }
            fetch.cancel(CancellationException("network changed"))
        }
        try {
            fetch.await()
        } catch (cancelled: CancellationException) {
            // Der Aufrufer darf weiterhin echte Download-Abbrüche durchreichen.
            currentCoroutineContext().ensureActive()
            if (generation.value != started) null
            else throw NetworkRangeInterrupted(cancelled)
        } finally {
            watcher.cancel()
        }
    }
}

/** Lokaler Request-Abbruch: zählt als Transportfehler statt unbegrenztem Netzwechsel. */
internal class NetworkRangeInterrupted(cause: CancellationException) :
    Exception("Audio range request interrupted without a network change", cause)
