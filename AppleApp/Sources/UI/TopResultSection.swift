import SwiftUI
import BitChordShared

/// Das hervorgehobene Suchergebnis mit getrennten Wiedergabe- und Playlist-Aktionen.
struct TopResultSection: View {
    @Environment(PlaybackController.self) private var controller
    @Environment(AppModel.self) private var appModel

    let hit: SearchHitDTO
    let scope: SearchView.Scope
    /// "Go to album" needs a query rather than an id, because the album page is
    /// reached by name — and by the time someone wants it, the name is what they
    /// typed.
    let onGoToAlbum: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Top result")
                .font(.headline)
                .padding(.horizontal, 24)

            card
                .padding(.horizontal, 24)
        }
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                Button(action: play) {
                    artwork
                }
                .buttonStyle(.plain)
                .accessibilityLabel(hit.title)
                .accessibilityHint("Plays the top result")
                details
                Menu {
                    menu
                } label: {
                    Image(systemName: "ellipsis")
                        .scaledFont(size: 16, weight: .semibold)
                        .foregroundStyle(.secondary)
                        .frame(width: 44, height: 44)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .help("More")
                .accessibilityLabel("More")
            }
            actionsRow
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.separator.opacity(0.35), lineWidth: 0.5)
        )
        // Keine Tap-Geste auf der gesamten Karte: sie konnte unabhängig
        // von den eingebetteten Buttons "Play" auslösen, etwa beim Hinzufügen
        // zur Playlist. Artwork, Titel und Play besitzen eigene Aktionen.
        .liftPreview {
            menu
        } preview: {
            ContextMenuPreview(
                artworkUrl: hit.thumbnailUrl, title: hit.title, subtitle: hit.subtitle,
                roundArtwork: hit.browseType?.uppercased() == "ARTIST"
            )
        }
        // Aktionen bleiben für VoiceOver einzeln erreichbar.
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("bbt.search.topResult")
    }

    @ViewBuilder
    private var artwork: some View {
        let isArtist = hit.browseType?.uppercased() == "ARTIST"
        if let url = hit.thumbnailUrl, !url.isEmpty {
            AsyncImage(url: URL(string: url)) { phase in
                if let image = phase.image {
                    image.resizable().aspectRatio(contentMode: .fill)
                } else {
                    artworkPlaceholder
                }
            }
            .frame(width: 72, height: 72)
            .modifier(ArtworkClipModifier(isArtist: isArtist))
        } else {
            artworkPlaceholder
                .frame(width: 72, height: 72)
        }
    }

    private struct ArtworkClipModifier: ViewModifier {
        let isArtist: Bool
        func body(content: Content) -> some View {
            if isArtist {
                content.clipShape(Circle())
            } else {
                content.clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
    }

    private var artworkPlaceholder: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(.quaternary)
            .overlay(
                Image(systemName: "music.note")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            )
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 3) {
            Button(action: play) {
                Text(hit.title)
                    .font(.headline.weight(.semibold))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Plays the top result")
            if let subtitle = hit.subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            if let album = hit.albumName, !album.isEmpty, let artist = hit.subtitle {
                Button(album) { onGoToAlbum("\(artist) \(album)") }
                    .buttonStyle(.plain)
                    .font(.subheadline)
                    .foregroundStyle(.tint)
                    .lineLimit(1)
                    .frame(minHeight: 44, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Upstream's `TopResultCard` button pair: Play and Add to Playlist.
    /// Abgestufte Aktionstasten: nebeneinander, solange der intrinsische
    /// Text passt; auf schmalen Geräten oder mit großer Schrift untereinander.
    /// Beide Aktionen bleiben auch im vertikalen Layout mindestens 44 pt hoch.
    private var actionsRow: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                playButton
                addToPlaylistButton
            }
            .fixedSize(horizontal: true, vertical: true)

            VStack(alignment: .leading, spacing: 8) {
                playButton
                addToPlaylistButton
            }
        }
        // List bietet der Zeile bei der Messung auch große Höhen an.
        // Die Aktionsleiste braucht ihre Texthöhe, nicht diese verfügbare Höhe.
        .fixedSize(horizontal: false, vertical: true)
        .labelStyle(.titleAndIcon)
    }

    private var playButton: some View {
        Button(action: play) {
            Label("Play", systemImage: "play.fill")
                .font(.callout.weight(.semibold))
                .frame(minHeight: 44)
                .fixedSize(horizontal: false, vertical: true)
        }
        .buttonStyle(.bordered)
        .accessibilityIdentifier("bbt.search.topResult.play")
    }

    private var addToPlaylistButton: some View {
        Button {
            if let videoId = hit.videoId {
                RecentSearchStore.record(RecentSearchEntity(
                    id: videoId, title: hit.title,
                    subtitle: hit.subtitle ?? "",
                    artworkUrl: hit.thumbnailUrl,
                    entityType: "TRACK"
                ))
                appModel.playlistPicker = PlaylistPickerRequest(
                    videoId: videoId, title: hit.title
                )
            }
        } label: {
            Label("Add to Playlist", systemImage: "text.badge.plus")
                .font(.callout.weight(.semibold))
                .frame(minHeight: 44)
                .fixedSize(horizontal: false, vertical: true)
        }
        .buttonStyle(.bordered)
        .accessibilityIdentifier("bbt.search.topResult.playlist")
        .disabled(hit.videoId == nil)
    }

    @ViewBuilder
    private var menu: some View {
        // The same three actions every other row offers, so the card is not a
        // place where the queue cannot be reached from.
        let entry = hit.asEntry()
        Button("Play") { play() }
        Button("Play Next") { controller.playNext(entry) }
        Button("Add to Queue") { controller.addToQueue(entry) }
    }

    /// The top result plays on its own.
    ///
    /// Deliberately not "play the results from here": the card is a single answer,
    /// and tapping it should play *that*, the way a link does. A listener who
    /// wants the list presses the first row.
    private func play() {
        if let videoId = hit.videoId {
            RecentSearchStore.record(RecentSearchEntity(
                id: videoId, title: hit.title,
                subtitle: hit.subtitle ?? "",
                artworkUrl: hit.thumbnailUrl,
                entityType: "TRACK"
            ))
        }
        controller.playRadio(hit.asEntry())
    }
}
