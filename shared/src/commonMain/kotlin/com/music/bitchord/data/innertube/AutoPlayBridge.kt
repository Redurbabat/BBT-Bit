package com.music.bitchord.data.innertube

import com.music.bitchord.data.model.Song
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.json.Json

/**
 * Swift-facing bridge for the AutoPlay radio — the `next` endpoint that
 * returns related tracks after the current queue runs out.
 */
object AutoPlayBridge {

    private val bridgeScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    private val json = Json { ignoreUnknownKeys = true }
    private val songListSerializer = ListSerializer(Song.serializer())

    fun interface AutoPlayCallback {
        fun onResult(json: String?, message: String?)
    }

    fun related(videoId: String, preferVideo: Boolean, callback: AutoPlayCallback) {
        val generation = Innertube.sessionGeneration
        bridgeScope.launch {
            try {
                Innertube.checkSession(generation)
                val response = Innertube.next(videoId)
                // Die Auswahl von Audio-/Video-Sendern trifft der gemeinsame
                // QueueBuilder. Videos hier vorab zu löschen wäre nicht originalgetreu.
                val songs = InnertubeParser.parseWatchQueue(response, preferVideo = preferVideo)
                Innertube.checkSession(generation)
                callback.onResult(
                    json.encodeToString(songListSerializer, songs),
                    null,
                )
            } catch (e: Throwable) {
                callback.onResult(null, e.message ?: e.toString())
            }
        }
    }
}
