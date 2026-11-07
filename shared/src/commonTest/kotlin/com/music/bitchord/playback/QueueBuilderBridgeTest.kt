package com.music.bitchord.playback

import com.music.bitchord.data.settings.AppSettings
import kotlinx.serialization.json.*
import kotlin.test.*

class QueueBuilderBridgeTest {
    @Test fun freshRecommendationsCanReuseUnplayedSuggestionsButExcludePlayedAndManualSongs() {
        val old = AppSettings.dontRepeatSuggestions.value
        try {
            AppSettings.setDontRepeatSuggestions(true)
            QueueBuilderBridge.clearSession()
            val kept = """[{"videoId":"seed","title":"Seed","artist":"Seed Artist"},{"videoId":"manual","title":"Manual","artist":"Manual Artist"}]"""
            val candidates = """[{"videoId":"manual","title":"Manual","artist":"Manual Artist"},{"videoId":"fresh","title":"Fresh","artist":"New Artist"},{"videoId":"fresh-copy","title":"Fresh (Official Audio)","artist":"New Artist"}]"""
            fun ids(json: String) = Json.parseToJsonElement(json).jsonArray.map { it.jsonObject.getValue("videoId").jsonPrimitive.content }
            assertEquals(listOf("fresh"), ids(QueueBuilderBridge.extendJson(kept, candidates, 8)))
            assertEquals(listOf("fresh"), ids(QueueBuilderBridge.extendJson(kept, candidates, 8)))
            QueueBuilderBridge.rememberPlayed("fresh")
            assertEquals(listOf("fresh-copy"), ids(QueueBuilderBridge.extendJson(kept, candidates, 8)))
            // Played recordings in the queue prefix also exclude alternate IDs.
            val playedPrefix = """[{"videoId":"fresh","title":"Fresh","artist":"New Artist"}]"""
            assertEquals(listOf("manual"), ids(QueueBuilderBridge.extendJson(playedPrefix, candidates, 8)))
        } finally {
            QueueBuilderBridge.clearSession()
            AppSettings.setDontRepeatSuggestions(old)
        }
    }
    @Test fun originalVideoStationsUseVideosWhenEnoughAreAvailable() {
        fun track(id: String, isVideo: Boolean) = com.music.bitchord.data.model.Song(
            videoId = id, title = id, artist = id, isVideo = isVideo
        )
        val seed = track("seed", true)
        val mix = listOf(track("audio-a", false), track("video-a", true), track("video-b", true), track("video-c", true))
        val videos = QueueBuilder.extend(listOf(seed), mix, 10, preferVideos = true)
        assertEquals(listOf("video-a", "video-b", "video-c"), videos.map { it.videoId })
        val shortMix = QueueBuilder.extend(listOf(seed), mix.dropLast(1), 10, preferVideos = true)
        assertEquals(listOf("audio-a", "video-a", "video-b"), shortMix.map { it.videoId })
        val audioRadio = QueueBuilder.extend(listOf(seed), mix, 10)
        assertEquals(listOf("audio-a"), audioRadio.map { it.videoId })
    }

    @Test fun suggestionsAreRememberedAcrossRefillsWhenEnabled() {
        val original = AppSettings.dontRepeatSuggestions.value
        try {
            AppSettings.setDontRepeatSuggestions(true)
            QueueBuilderBridge.clearSession()
            val existing = """[{"videoId":"seed","title":"Seed","artist":"Band"}]"""
            val candidates = """[{"videoId":"one","title":"One","artist":"Band"},
                {"videoId":"two","title":"Two","artist":"Else"}]"""
            fun ids(value: String) = Json.parseToJsonElement(value).jsonArray.map {
                it.jsonObject.getValue("videoId").jsonPrimitive.content
            }
            assertEquals(listOf("one"), ids(QueueBuilderBridge.extendJson(existing, candidates, 1)))
            assertEquals(listOf("two"), ids(QueueBuilderBridge.extendJson(existing, candidates, 1)))
            assertTrue(ids(QueueBuilderBridge.extendJson(existing, candidates, 1)).isEmpty())
        } finally {
            QueueBuilderBridge.clearSession()
            AppSettings.setDontRepeatSuggestions(original)
        }
    }


}
