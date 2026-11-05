package com.metrolist.innertubex.models

import kotlinx.serialization.Serializable

@Serializable
data class YouTubeLocale(
    val gl: String,
    val hl: String,
) {
    internal fun acceptLanguageHeader(): String {
        val languageTag = hl.replace('_', '-')
        val regionalTag = if ('-' in languageTag || gl.isEmpty()) languageTag else "$languageTag-$gl"
        val fallback = languageTag.substringBefore('-')
        return if (regionalTag == fallback) regionalTag else "$regionalTag,$fallback;q=0.9"
    }
}

/** Gerätesprachen sind BCP-47-Tags, aber der Player akzeptiert nur seine UI-Sprachen.
 * Beispielsweise führt hl=de-CH zu playabilityStatus=ERROR statt zu Audioformaten.
 * Die Inhaltsregion bleibt unabhängig davon erhalten.
 */
internal fun systemYouTubeLocale(languageTag: String, countryCode: String): YouTubeLocale {
    val parts = languageTag.substringBefore('@').trim().replace('_', '-').lowercase().split('-')
    val language = parts.first().ifBlank { "en" }
    val languageParts = parts.drop(1).takeWhile { it.length != 1 }.toSet()
    val apiLanguage = when {
        language == "zh" && "hk" in languageParts -> "zh-HK"
        language == "zh" && ("hant" in languageParts || "tw" in languageParts) -> "zh-TW"
        language == "zh" -> "zh-CN"
        language == "en" && "gb" in languageParts -> "en-GB"
        language == "es" && "419" in languageParts -> "es-419"
        language == "pt" && "pt" in languageParts -> "pt-PT"
        else -> language
    }
    return YouTubeLocale(gl = countryCode.uppercase(), hl = apiLanguage)
}
