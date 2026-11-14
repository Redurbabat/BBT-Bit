import SwiftUI

struct HomeDiscoveryDashboard: View {
    let model: HomeDiscoveryModel
    let mix: [QueueEntry]
    let mixTitle: String
    @Environment(PlaybackController.self) private var controller
    @Environment(AppModel.self) private var appModel
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Für dich").font(.title2.weight(.bold))
            if typeSize.isAccessibilitySize {
                mainTile
                shortcuts
            } else {
                HStack(alignment: .top, spacing: 12) {
                    mainTile.frame(maxWidth: .infinity)
                    shortcuts.frame(width: 126)
                }
            }
        }
    }

    private var mainTile: some View {
        Button {
            guard !PartyStore.shared.inParty else { return }
            if controller.current != nil {
                if controller.isPlaying { appModel.nowPlayingPresented = true }
                else { controller.togglePlayPause() }
            } else if !mix.isEmpty {
                controller.play(mix, context: mixTitle, shuffleRequested: false)
                AppTestEvents.verify(.dayMix, controller.current?.id == mix.first?.id, .queueUpdated)
            } else { appModel.requestedTab = .explore }
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: controller.current == nil ? "sparkles" : "bookmark.fill")
                    Text(controller.current == nil ? "Deine Auswahl" : "Weiterhören").font(.caption.weight(.semibold))
                }.foregroundStyle(.secondary)
                ArtworkView(entry: controller.current ?? mix.first, side: 76)
                    .clipShape(.rect(cornerRadius: 12))
                Text(controller.current == nil ? mixTitle : (controller.playbackContext ?? controller.current?.albumName ?? controller.current?.title ?? "Deine Musik"))
                    .font(.title3.weight(.bold)).lineLimit(3)
                if let current = controller.current {
                    Text(current.title).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                } else {
                    Text(mix.isEmpty ? "Entdecke Musik für deinen Start" : "\(mix.count) Titel aus deiner Musik")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Label(controller.current == nil ? (mix.isEmpty ? "Entdecken" : "Mix starten")
                    : (controller.isPlaying ? "Zum Player" : "Fortsetzen"), systemImage: "play.fill")
                    .font(.subheadline.weight(.semibold)).padding(.top, 2)
            }
            .frame(maxWidth: .infinity, minHeight: 228, alignment: .topLeading)
            .padding(16)
            .background(Color.primary.opacity(0.055), in: .rect(cornerRadius: 22))
            .contentShape(.rect(cornerRadius: 22))
        }
        .buttonStyle(.plain)
        .disabled(PartyStore.shared.inParty)
        .accessibilityHint(controller.current == nil ? Text("Öffnet deine Musikauswahl")
            : (controller.isPlaying ? Text("Öffnet den Vollplayer") : Text("Setzt die vorhandene Wiedergabesitzung fort")))
        .accessibilityIdentifier("red.home.continue")
    }

    private var shortcuts: some View {
        VStack(spacing: 12) {
            ForEach(0..<2, id: \.self) { index in
                if let card = shortcut(at: index) {
                    ShelfCardTap(card: card) {
                        VStack(alignment: .leading, spacing: 8) {
                            ArtworkView(url: card.thumbnailUrl, data: nil, side: 48)
                                .clipShape(.rect(cornerRadius: 9))
                            Text(card.title).font(.caption.weight(.semibold)).lineLimit(2)
                            if model.pins.indices.contains(index) {
                                Label("Angeheftet", systemImage: "pin.fill").font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
                        .padding(12)
                        .background(Color.primary.opacity(0.055), in: .rect(cornerRadius: 18))
                    }
                    .shelfCardContextMenu(card)
                } else {
                    Button {
                        appModel.requestedTab = index == 0 ? .libraryYouTube : .explore
                    } label: {
                        VStack(alignment: .leading, spacing: 12) {
                            Image(systemName: index == 0 ? "books.vertical" : "safari").font(.title2)
                            Text(index == 0 ? "Deine Bibliothek" : "Neu entdecken").font(.subheadline.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity, minHeight: 100, alignment: .leading)
                        .padding(12)
                        .background(Color.primary.opacity(0.055), in: .rect(cornerRadius: 18))
                    }.buttonStyle(.plain)
                }
            }
        }
    }

    private func shortcut(at index: Int) -> ShelfCard? {
        if model.pins.indices.contains(index) { return model.pins[index] }
        let pinned = Set(model.pins.map(\.id))
        let fallback = model.collections.filter { !pinned.contains($0.id) }
        let offset = index - model.pins.count
        return fallback.indices.contains(offset) ? fallback[offset] : nil
    }
}

struct HomeDayMixSection: View {
    let entries: [QueueEntry]
    let title: String
    @Binding var mood: HomeMixMood
    @Environment(PlaybackController.self) private var controller
    @Environment(AuthController.self) private var auth
    @State private var presented = false
    @State private var presentedEntries: [QueueEntry] = []
    @State private var presentedTitle = ""
    @State private var presentedSession: Int64?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title).font(.title2.weight(.bold))
                Spacer()
                if !entries.isEmpty {
                    Button("Ansehen") {
                        presentedEntries = entries; presentedTitle = title
                        presentedSession = PageSession.generation(); presented = true
                    }.frame(minHeight: 44)
                }
            }
            Picker("Mixauswahl", selection: $mood) {
                ForEach(HomeMixMood.allCases) { Text(LocalizedStringKey($0.title)).tag($0) }
            }.pickerStyle(.segmented)
            if entries.isEmpty {
                Text(mood == .curious ? "Hier erscheinen neue Titel aus deinem geladenen Feed."
                    : "Höre Musik oder lade deinen Feed, um deinen Mix zu füllen.")
                    .font(.subheadline).foregroundStyle(.secondary)
            } else {
                HStack(spacing: 10) {
                    HStack(spacing: -8) {
                        ForEach(Array(entries.prefix(3).enumerated()), id: \.offset) { _, entry in
                            ArtworkView(entry: entry, side: 48).clipShape(.rect(cornerRadius: 9))
                        }
                    }.accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("\(entries.count) Titel").font(.subheadline.weight(.semibold))
                        Text("Aus Hörverlauf und Feed").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 4)
                    Button {
                        controller.play(entries, context: title, shuffleRequested: false)
                        AppTestEvents.verify(.dayMix, controller.current?.id == entries.first?.id, .queueUpdated)
                    } label: {
                        Image(systemName: "play.fill").frame(width: 44, height: 44)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("Tagesmix starten")
                    .disabled(PartyStore.shared.inParty)
                }
            }
        }
        .onChange(of: auth.sessionEpoch) { _, _ in
            presented = false; presentedEntries = []; presentedTitle = ""; presentedSession = nil
        }
        .sheet(isPresented: $presented) {
            NavigationStack {
                List {
                    Section {
                        Button("Mix starten") { playPresented(at: 0) }
                            .disabled(PartyStore.shared.inParty)
                    }
                    ForEach(Array(presentedEntries.enumerated()), id: \.offset) { index, entry in
                        Button {
                            playPresented(at: index)
                        } label: {
                            HStack(spacing: 12) {
                                ArtworkView(entry: entry, side: 44).clipShape(.rect(cornerRadius: 8))
                                VStack(alignment: .leading) {
                                    Text(entry.title).font(.body).lineLimit(1)
                                    Text(entry.artist).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .songContextMenu(entry)
                        .disabled(PartyStore.shared.inParty)
                    }
                }
                .navigationTitle(presentedTitle)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Fertig") { presented = false } } }
            }
            #if os(macOS)
            .frame(minWidth: 420, minHeight: 520)
            #endif
        }
    }

    private func playPresented(at index: Int) {
        guard presentedSession == PageSession.generation(), !PartyStore.shared.inParty,
              presentedEntries.indices.contains(index) else { presented = false; return }
        controller.play(presentedEntries, at: index, context: presentedTitle, shuffleRequested: false)
        AppTestEvents.verify(.dayMix, controller.current?.id == presentedEntries[index].id, .queueUpdated)
    }
}
