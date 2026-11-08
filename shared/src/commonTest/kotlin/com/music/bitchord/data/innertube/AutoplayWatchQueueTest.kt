package com.music.bitchord.data.innertube

import kotlinx.serialization.json.Json
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/** BitChord-v1.9.1-Radio: Paarung belegt nur eine Warteschlangenposition. */
class AutoplayWatchQueueTest {
    private val json = Json { ignoreUnknownKeys = true }

    private fun row(id: String, type: String, credit: String) = """
        {"videoId":"$id",
         "title":{"runs":[{"text":"Track"}]},
         "longBylineText":{"runs":[{"text":"Band"},{"text":" • "},{"text":"$credit"}]},
         "navigationEndpoint":{"watchEndpoint":{"watchEndpointMusicSupportedConfigs":{
           "watchEndpointMusicConfig":{"musicVideoType":"$type"}
         }}}}
    """

    private val video = row("video", "MUSIC_VIDEO_TYPE_OMV", "5M views")
    private val audio = row("audio", "MUSIC_VIDEO_TYPE_ATV", "Album")

    private fun pair() = json.parseToJsonElement("""
        {"contents":{"playlistPanelVideoWrapperRenderer":{
            "primaryRenderer":{"playlistPanelVideoRenderer":$video},
            "counterpart":[{"counterpartRenderer":{"playlistPanelVideoRenderer":$audio}}]
        }}}
    """)

    @Test fun defaultQueueKeepsBothVersions() {
        val songs = InnertubeParser.parseWatchQueue(pair())
        assertEquals(setOf("video", "audio"), songs.map { it.videoId }.toSet())
        assertTrue(songs.first { it.videoId == "video" }.isVideo)
        assertFalse(songs.first { it.videoId == "audio" }.isVideo)
    }

    @Test fun audioPreferenceChoosesCatalogueSongForThePair() {
        val songs = InnertubeParser.parseWatchQueue(pair(), preferAudio = true)
        assertEquals(listOf("audio"), songs.map { it.videoId })
    }

    @Test fun videoPreferenceChoosesOfficialVideoForThePair() {
        val songs = InnertubeParser.parseWatchQueue(pair(), preferVideo = true)
        assertEquals(listOf("video"), songs.map { it.videoId })
    }

    @Test fun unsupportedAudioCounterpartDoesNotEraseVideo() {
        val standalone = json.parseToJsonElement("""
            {"playlistPanelVideoRenderer":$video}
        """)
        val songs = InnertubeParser.parseWatchQueue(standalone, preferAudio = true)
        assertEquals(listOf("video"), songs.map { it.videoId })
    }
}
