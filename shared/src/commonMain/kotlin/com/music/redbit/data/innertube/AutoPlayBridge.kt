package com.music.redbit.data.innertube

import com.music.redbit.data.model.Song
import com.music.redbit.data.model.SearchFilter
import com.music.redbit.data.model.SearchResult
import com.music.redbit.data.sources.TrackMatcher
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

    /** Ergebnis ist ausschließlich eine geprüfte YouTube-ID, kein Quellenwechsel. */
    fun seed(songJson: String, callback: AutoPlayCallback) {
        val generation = Innertube.sessionGeneration
        bridgeScope.launch {
            try {
                Innertube.checkSession(generation)
                val song = json.decodeFromString(Song.serializer(), songJson)
                val id = findAutoplaySeed(TrackMatcher.targetOf(song)) { query ->
                    val response = Innertube.search(query, InnertubeParser.paramsFor(SearchFilter.SONGS.name))
                    InnertubeParser.parseSearchPage(response, includeVideos = false).mapNotNull {
                        when (it) {
                            is SearchResult.Track -> it.song
                            is SearchResult.TopTrack -> it.song
                            else -> null
                        }
                    }
                }
                Innertube.checkSession(generation)
                callback.onResult(id, null)
            } catch (_: Throwable) {
                callback.onResult(null, "autoplay_seed_unavailable")
            }
        }
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
