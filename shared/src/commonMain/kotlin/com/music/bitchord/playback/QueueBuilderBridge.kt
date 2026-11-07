package com.music.bitchord.playback

import com.music.bitchord.data.model.Song
import com.music.bitchord.data.settings.AppSettings
import com.music.bitchord.data.innertube.Innertube
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.json.Json

/**
 * JSON wrapper so Swift can run upstream [QueueBuilder.extend] without
 * mapping Kotlin collection types across the FFI.
 */
object QueueBuilderBridge {
    private val json = Json { ignoreUnknownKeys = true; encodeDefaults = true }
    private val songs = ListSerializer(Song.serializer())
    private val sessionIds = mutableSetOf<String>()
    // Auch angebotene, nicht nur abgespielte Titel gelten im Original als gesehen.
    private val sessionSuggestions = mutableListOf<Song>()
    private var generation = Innertube.sessionGeneration

    private fun checkSession() {
        val current = Innertube.sessionGeneration
        if (generation != current) {
            sessionIds.clear()
            sessionSuggestions.clear()
            generation = current
        }
    }

    fun rememberPlayed(videoId: String) {
        checkSession()
        if (videoId.isNotBlank()) sessionIds += videoId
    }

    fun clearSession() {
        sessionIds.clear()
        sessionSuggestions.clear()
    }

    fun extendJson(existingJson: String, candidatesJson: String, limit: Int, preferVideos: Boolean = false): String {
        checkSession()
        val existing = runCatching { json.decodeFromString(songs, existingJson) }.getOrDefault(emptyList())
        val candidates = runCatching { json.decodeFromString(songs, candidatesJson) }.getOrDefault(emptyList())
        val skip = if (AppSettings.dontRepeatSuggestions.value) sessionIds else emptySet()
        val filtered = if (skip.isEmpty()) {
            candidates
        } else {
            candidates.filterNot { it.videoId in skip }
        }
        // Die Seed-Aufnahme muss am Ende bleiben: QueueBuilder leitet daraus
        // die höhere Künstlerobergrenze ab. Frühere Empfehlungen stehen davor.
        val history = if (AppSettings.dontRepeatSuggestions.value) sessionSuggestions else emptyList()
        val extra = QueueBuilder.extend(history + existing, filtered, limit, preferVideos)
        if (AppSettings.dontRepeatSuggestions.value) sessionSuggestions += extra
        return json.encodeToString(songs, extra)
    }
}
