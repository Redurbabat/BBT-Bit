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
            val offered = QueueBuilderBridge.extendJson(kept, candidates, 8)
            assertEquals(listOf("fresh"), ids(offered))
            // Vor dem tatsächlichen Anhängen darf ein fehlgeschlagener
            // Server-Queue-Batch die Session-Historie noch nicht verändern.
            assertEquals(listOf("fresh"), ids(QueueBuilderBridge.extendJson(kept, candidates, 8)))
            QueueBuilderBridge.rememberSuggestedJson(offered)
            assertTrue(ids(QueueBuilderBridge.extendJson(kept, candidates, 8)).isEmpty())
            QueueBuilderBridge.rememberPlayed("fresh")
            assertTrue(ids(QueueBuilderBridge.extendJson(kept, candidates, 8)).isEmpty())
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
            val first = QueueBuilderBridge.extendJson(existing, candidates, 1)
            assertEquals(listOf("one"), ids(first))
            QueueBuilderBridge.rememberSuggestedJson(first)
            val second = QueueBuilderBridge.extendJson(existing, candidates, 1)
            assertEquals(listOf("two"), ids(second))
            QueueBuilderBridge.rememberSuggestedJson(second)
            assertTrue(ids(QueueBuilderBridge.extendJson(existing, candidates, 1)).isEmpty())
        } finally {
            QueueBuilderBridge.clearSession()
            AppSettings.setDontRepeatSuggestions(original)
        }
    }


    @Test fun playedRecordingFiltersVideoTwinByTitleAndArtist() {
        val original = AppSettings.dontRepeatSuggestions.value
        try {
            AppSettings.setDontRepeatSuggestions(true)
            QueueBuilderBridge.clearSession()
            QueueBuilderBridge.rememberPlayedSongJson(
                """{"videoId":"played-video","title":"New Track (Official Video)","artist":"Band"}"""
            )
            val existing = """[{"videoId":"seed","title":"Seed","artist":"Other"}]"""
            val candidates = """[{"videoId":"audio-twin","title":"New Track","artist":"Band"},
                {"videoId":"other","title":"Other Title","artist":"Other"}]"""
            val ids = Json.parseToJsonElement(
                QueueBuilderBridge.extendJson(existing, candidates, 10)
            ).jsonArray.map { it.jsonObject.getValue("videoId").jsonPrimitive.content }
            assertEquals(listOf("other"), ids)
        } finally {
            QueueBuilderBridge.clearSession()
            AppSettings.setDontRepeatSuggestions(original)
        }
    }


}
