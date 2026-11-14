package com.music.redbit.data.innertube

import com.music.redbit.data.model.SearchFilter
import com.music.redbit.data.model.SearchResult
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonObject
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * Podcasts nach dem Format echter YouTube-Music-Antworten vom 11.11.2026
 * (Suche mit Podcast-Filter, Sendungsseite „MPSP…“), auf das Nötige gekürzt.
 */
class PodcastParserTest {
    private fun parse(text: String): JsonObject = Json.parseToJsonElement(text).jsonObject

    private val showPage = parse(
        """
        {"contents":{"twoColumnBrowseResultsRenderer":{
          "tabs":[{"tabRenderer":{"content":{"sectionListRenderer":{"contents":[
            {"musicResponsiveHeaderRenderer":{
              "title":{"runs":[{"text":"Learn Kurdish | Kurdish Lessons Podcast"}]},
              "straplineTextOne":{"runs":[{"text":"Kurdish Kurmanji Lessons"}]},
              "thumbnail":{"musicThumbnailRenderer":{"thumbnail":{"thumbnails":[{"url":"https://i.ytimg.com/show.jpg","width":544,"height":544}]}}}
            }}]}}}}],
          "secondaryContents":{"sectionListRenderer":{"contents":[{"musicShelfRenderer":{"contents":[
            {"musicMultiRowListItemRenderer":{
              "title":{"runs":[{"text":"34. Rûtînên min ên sibehê"}]},
              "subtitle":{"runs":[{"text":"1127 Aufrufe • 11. Feb."}]},
              "onTap":{"watchEndpoint":{"videoId":"DKmBy6Awk1g","watchEndpointMusicSupportedConfigs":{"watchEndpointMusicConfig":{"musicVideoType":"MUSIC_VIDEO_TYPE_PODCAST_EPISODE"}}}},
              "thumbnail":{"musicThumbnailRenderer":{"thumbnail":{"thumbnails":[{"url":"https://i.ytimg.com/vi/DKmBy6Awk1g/hq720.jpg","width":853,"height":479}]}}},
              "playbackProgress":{"musicPlaybackProgressRenderer":{"playbackProgressText":{"runs":[{"text":" • "},{"text":"12 Min., 25 Sek."}]}}}
            }},
            {"musicMultiRowListItemRenderer":{
              "title":{"runs":[{"text":"35. Folge ohne Länge"}]},
              "onTap":{"watchEndpoint":{"videoId":"AAAAAAAAAAA"}}
            }},
            {"musicMultiRowListItemRenderer":{
              "title":{"runs":[{"text":"Ohne Abspiel-ID"}]}
            }}
          ]}}]}}
        }}}
        """.trimIndent(),
    )

    @Test
    fun `episodes become playable rows with show and date and length`() {
        val episodes = InnertubeParser.collectPodcastEpisodes(showPage, "Learn Kurdish | Kurdish Lessons Podcast")
        assertEquals(listOf("DKmBy6Awk1g", "AAAAAAAAAAA"), episodes.map { it.videoId })
        val first = episodes.first()
        assertEquals("34. Rûtînên min ên sibehê", first.title)
        assertEquals("Learn Kurdish | Kurdish Lessons Podcast • 1127 Aufrufe • 11. Feb.", first.artist)
        assertEquals("12 Min., 25 Sek.", first.durationText)
        assertEquals("https://i.ytimg.com/vi/DKmBy6Awk1g/hq720.jpg", first.thumbnailUrl)
        assertEquals(false, first.isVideo)
        assertNull(episodes[1].durationText)
        assertEquals("Learn Kurdish | Kurdish Lessons Podcast", episodes[1].artist)
    }

    @Test
    fun `an ordinary song page has no podcast episodes`() {
        assertTrue(InnertubeParser.collectSongsDeep(showPage).isEmpty())
        val songPage = parse("""{"contents":{"musicResponsiveListItemRenderer":{}}}""")
        assertTrue(InnertubeParser.collectPodcastEpisodes(songPage).isEmpty())
    }

    @Test
    fun `the show header is read like any collection`() {
        val header = InnertubeParser.parseBrowseHeader(showPage)
        assertEquals("Learn Kurdish | Kurdish Lessons Podcast", header?.title)
        assertEquals("Kurdish Kurmanji Lessons", header?.subtitle)
    }

    @Test
    fun `podcast search rows are browse results that open the show`() {
        val page = parse(
            """
            {"contents":{"musicShelfRenderer":{"contents":[{"musicResponsiveListItemRenderer":{
              "navigationEndpoint":{"browseEndpoint":{"browseId":"MPSPPLGfUcT_-c1AAOm3YAohoe3Au3rQwePGAq",
                "browseEndpointContextSupportedConfigs":{"browseEndpointContextMusicConfig":{"pageType":"MUSIC_PAGE_TYPE_PODCAST_SHOW_DETAIL_PAGE"}}}},
              "thumbnail":{"musicThumbnailRenderer":{"thumbnail":{"thumbnails":[{"url":"https://i.ytimg.com/show.jpg","width":544,"height":544}]}}},
              "flexColumns":[
                {"musicResponsiveListItemFlexColumnRenderer":{"text":{"runs":[{"text":"avaz kolot - ein Videopodcast von Pek Koach"}]}}},
                {"musicResponsiveListItemFlexColumnRenderer":{"text":{"runs":[{"text":"Pek Koach"}]}}}
              ]}}]}}}
            """.trimIndent(),
        )
        val results = InnertubeParser.parseSearchPage(page)
        val show = results.filterIsInstance<SearchResult.Browse>().single().item
        assertEquals("MPSPPLGfUcT_-c1AAOm3YAohoe3Au3rQwePGAq", show.browseId)
        assertEquals("avaz kolot - ein Videopodcast von Pek Koach", show.title)
    }

    @Test
    fun `the podcasts tab asks youtube music for shows`() {
        assertEquals(SearchFilter.PODCASTS.params, InnertubeParser.paramsFor("podcasts"))
        assertEquals(SearchFilter.PODCASTS.params, InnertubeParser.paramsFor("PODCASTS"))
        assertTrue(!InnertubeParser.isMixedScope("podcasts"))
        assertTrue(InnertubeParser.isMixedScope("all"))
    }
}
