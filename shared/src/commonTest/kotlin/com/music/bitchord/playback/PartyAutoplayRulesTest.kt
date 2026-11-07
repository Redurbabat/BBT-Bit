package com.music.bitchord.playback

import com.music.bitchord.data.listentogether.PartyMember
import com.music.bitchord.data.listentogether.PartyPlayback
import com.music.bitchord.data.listentogether.PartyState
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class PartyAutoplayRulesTest {
    private val host = PartyMember(memberId = "host", isHost = true, connected = true)
    private val first = PartyMember(memberId = "alpha", connected = true)
    private val second = PartyMember(memberId = "beta", connected = true)

    private fun state(
        you: PartyMember = host,
        members: List<PartyMember> = listOf(host, first, second),
        hostOnly: Boolean = false,
        enabled: Boolean = true,
    ) = PartyState(
        inParty = true, you = you, members = members,
        hostOnlyControl = hostOnly,
        playback = PartyPlayback(autoplayEnabled = enabled),
    )

    @Test fun partySettingOverridesLocalSetting() {
        assertTrue(PartyAutoplayRules.enabled(state(), localPreference = false))
        assertFalse(PartyAutoplayRules.enabled(state(enabled = false), localPreference = true))
        assertTrue(PartyAutoplayRules.enabled(PartyState(), localPreference = true))
    }

    @Test fun connectedHostSuppliesEveryoneElseWaits() {
        assertEquals("host", PartyAutoplayRules.supplierId(state()))
        assertTrue(PartyAutoplayRules.canSupply(state(), localPreference = false))
        assertFalse(PartyAutoplayRules.canSupply(state(you = first), localPreference = true))
    }

    @Test fun hostLossElectsLowestConnectedId() {
        val offlineHost = host.copy(connected = false)
        val party = state(you = first, members = listOf(offlineHost, second, first))
        assertEquals("alpha", PartyAutoplayRules.supplierId(party))
        assertTrue(PartyAutoplayRules.canSupply(party, localPreference = true))
    }

    @Test fun lockedPartyWaitsForHostInsteadOfElectingListener() {
        val offlineHost = host.copy(connected = false)
        val party = state(you = first, members = listOf(first, offlineHost), hostOnly = true)
        assertNull(PartyAutoplayRules.supplierId(party))
        assertFalse(PartyAutoplayRules.canSupply(party, localPreference = true))
    }

    @Test fun noSupplierWithoutMembershipOrPartyAutoplay() {
        assertNull(PartyAutoplayRules.supplierId(PartyState()))
        assertFalse(PartyAutoplayRules.canSupply(state(members = emptyList()), true))
        assertFalse(PartyAutoplayRules.canSupply(state(enabled = false), true))
    }
}
