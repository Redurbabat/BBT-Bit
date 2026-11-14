package com.music.redbit.data.innertube

import com.music.redbit.data.model.ShelfItem
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/** Home-Videos und ihre Kennzeichnung gegen kontrollierte Innertube-Antworten. */
class HomeVideoParserTest {
    private val json = Json { ignoreUnknownKeys = true }

    private fun card(id: String?, title: String, width: Int = 480, height: Int = 480): String {
        val endpoint = if (id == null) {
            """{"browseEndpoint":{"browseId":"MPREtest"}}"""
        } else """{"watchEndpoint":{"videoId":"$id"}}"""
        return """{"musicTwoRowItemRenderer":{
            "title":{"runs":[{"text":"$title"}]},
            "navigationEndpoint":$endpoint,
            "thumbnailRenderer":{"musicThumbnailRenderer":{"thumbnail":{
                "thumbnails":[{"url":"https://example.invalid/cover.jpg","width":$width,"height":$height}]
            }}}
        }}"""
    }

    private fun shelf(title: String, vararg cards: String): String = """
        {"musicCarouselShelfRenderer":{
            "header":{"musicCarouselShelfBasicHeaderRenderer":{"title":{"runs":[{"text":"$title"}]}}},
            "contents":[${cards.joinToString(",")}]
        }}"""

    private fun page(vararg shelves: String): JsonObject = json.parseToJsonElement("""
        {"contents":{"singleColumnBrowseResultsRenderer":{"tabs":[{"tabRenderer":{
            "content":{"sectionListRenderer":{"contents":[${shelves.joinToString(",")}]}}
        }}]}}}
    """) as JsonObject

    @Test
    fun videosAppearInTheHomeFeedAndKeepTheirFlag() {
        val feed = InnertubeParser.parseHome(
            page(shelf("Für dich", card("audio", "Song"), card("video", "Official Video", 640, 360))),
            includeVideos = true,
        )
        assertEquals(listOf("audio", "video"), feed.single().items.map { it.videoId })
        assertFalse(feed.single().items.first().isVideo)
        assertTrue(feed.single().items.last().isVideo)
    }

    @Test
    fun exploreAndOtherConsumersKeepPreviousVideoFiltering() {
        val feed = InnertubeParser.parseHome(
            page(shelf("Für dich", card("audio", "Song"), card("video", "Official Video", 640, 360)))
        )
        assertEquals(listOf("audio"), feed.single().items.map { it.videoId })
    }

    @Test
    fun aPureVideoShelfAppearsOnlyInHome() {
        val response = page(shelf("Music videos", card("video", "Official Video", 640, 360)))
        assertEquals(listOf("video"), InnertubeParser.parseHome(response, includeVideos = true)
            .single().items.map { it.videoId })
        assertTrue(InnertubeParser.parseHome(response).isEmpty())
    }

    @Test
    fun videoCompilationsNeverBecomeFakePlayableVideos() {
        val response = page(shelf("Video charts", card(null, "Compilation"), card("video", "Video", 640, 360)))
        val results = InnertubeParser.parseHome(response, includeVideos = true)
        assertEquals(listOf("video"), results.single().items.map { it.videoId })
    }

    @Test
    fun continuationPreservesHomeVideoPolicy() {
        val response = json.parseToJsonElement(shelf("Videos", card("video", "Official Video", 640, 360)))
        assertEquals(1, InnertubeParser.parseHomeContinuation(response, includeVideos = true).size)
        assertTrue(InnertubeParser.parseHomeContinuation(response).isEmpty())
    }

    @Test
    fun theVideoFlagSurvivesSerialization() {
        val card = ShelfItem("Video", "Artist", null, videoId = "v1", isVideo = true)
        val restored = json.decodeFromString<ShelfItem>(json.encodeToString(card))
        assertTrue(restored.isVideo)
        assertEquals("v1", restored.videoId)
    }
}
