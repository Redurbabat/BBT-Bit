package com.music.bitchord.playback

import com.music.bitchord.data.listentogether.PartyState

/**
 * BitChord-v1.9.1-Regeln für AutoPlay in Listen Together.
 *
 * Alle Mitglieder berechnen denselben Lieferanten aus derselben Mitgliedsliste.
 * In Host-only-Partys gibt es beim Ausfall des Hosts keinen Ersatzlieferanten.
 */
object PartyAutoplayRules {
    fun enabled(party: PartyState, localPreference: Boolean): Boolean =
        if (party.inParty) party.playback.autoplayEnabled else localPreference

    fun supplierId(party: PartyState): String? {
        if (!party.inParty) return null
        val host = party.members.firstOrNull { it.isHost && it.connected }?.memberId
        if (party.hostOnlyControl) return host
        return host ?: party.members.asSequence()
            .filter { it.connected }
            .minByOrNull { it.memberId }
            ?.memberId
    }

    fun canSupply(party: PartyState, localPreference: Boolean): Boolean {
        if (!enabled(party, localPreference)) return false
        if (!party.inParty) return true
        val you = party.you?.memberId ?: return false
        return supplierId(party) == you
    }
}
