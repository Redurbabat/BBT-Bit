package com.metrolist.innertubex.models

import kotlin.test.Test
import kotlin.test.assertEquals

class YouTubeLocaleTest {
    @Test fun germanDeviceTagsUseSupportedApiLanguage() {
        for (language in listOf("de-CH", "de-DE", "de-AT", "de_CH", "de_CH@calendar=gregorian")) {
            val locale = systemYouTubeLocale(language, "CH")
            assertEquals("de", locale.hl, language)
            assertEquals("CH", locale.gl, "Die Sprachkorrektur darf die Region nicht ändern.")
        }
    }

    @Test fun otherDeviceRegionsDoNotBecomeApiLanguages() {
        for ((tag, expected) in mapOf("en-US" to "en", "fr-CH" to "fr", "tr-TR" to "tr", "ja-JP" to "ja")) {
            assertEquals(expected, systemYouTubeLocale(tag, "CH").hl)
        }
    }

    @Test fun supportedLanguageVariantsAndChineseScriptsArePreserved() {
        for ((tag, expected) in mapOf(
            "en-GB" to "en-GB", "es-419" to "es-419", "pt-PT" to "pt-PT",
            "zh-Hans-CN" to "zh-CN", "zh-Hant-TW" to "zh-TW", "zh-Hant-HK" to "zh-HK",
        )) assertEquals(expected, systemYouTubeLocale(tag, "CH").hl)
    }

    @Test fun missingRegionRemainsUnknown() {
        assertEquals(YouTubeLocale(gl = "", hl = "de"), systemYouTubeLocale("de", ""))
    }
}
