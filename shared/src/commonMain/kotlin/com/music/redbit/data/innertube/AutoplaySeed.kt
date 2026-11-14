package com.music.redbit.data.innertube

import com.music.redbit.data.model.Song
import com.music.redbit.data.sources.TrackMatcher
import kotlinx.coroutines.withTimeoutOrNull

/** Radio-Startpunkt für Addon-Aufnahmen; verändert weder Quelle noch Queue. */
internal suspend fun findAutoplaySeed(
    target: TrackMatcher.Target,
    timeoutMillis: Long = 8_000,
    search: suspend (String) -> List<Song>,
): String? = withTimeoutOrNull(timeoutMillis) {
    val query = TrackMatcher.queries(target).firstOrNull() ?: return@withTimeoutOrNull null
    TrackMatcher.ranked(search(query).filter {
        !it.isVideo && it.videoId.matches(YOUTUBE_ID) &&
            (target.artist.isBlank() || TrackMatcher.sharesArtist(target.artist, it.artist))
    }, target)
        .firstOrNull()?.videoId
}

private val YOUTUBE_ID = Regex("[A-Za-z0-9_-]{11}")
