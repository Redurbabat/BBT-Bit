import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif
import BitChordShared
import UniformTypeIdentifiers

/// Home tab — upstream's "Play" tab: signed out it leads with the sign-in
/// banner over the anonymous home feed (FEmusic_home + new releases),
/// skeleton while loading, retry on error. Local music lives in Library.
struct HomeView: View {
    @Bindable var feed: FeedLoader
    @Environment(PlaybackController.self) private var controller
    @Environment(AuthController.self) private var auth
    @Environment(ToastCenter.self) private var toast
    /// An externally owned scroll position, when the caller survives the view:
    /// the Mac sidebar recreates this view on every row switch, and the feed
    /// is a singleton while the reader's place in it was not (upstream hoists
    /// `homeListState` outside its tab switch for the same reason).
    var scrollPosition: Binding<ScrollPosition>? = nil
    @AppStorage("hide_recents") private var hideRecents = false
    @AppStorage("hide_home_videos") private var hideHomeVideos = false
    @AppStorage("redbit.home.media_filter") private var mediaFilterRaw = HomeMediaFilter.all.rawValue
    @AppStorage("redbit.home.mix_mood") private var mixMoodRaw = HomeMixMood.balanced.rawValue
    @State private var discovery = HomeDiscoveryModel()

    private var mediaFilter: HomeMediaFilter { HomeMediaFilter(rawValue: mediaFilterRaw) ?? .all }
    private var mixMood: Binding<HomeMixMood> {
        Binding(get: { HomeMixMood(rawValue: mixMoodRaw) ?? .balanced }, set: { mixMoodRaw = $0.rawValue })
    }

    var body: some View {
        PageStack {
            content
                .navigationTitle("Listen Now")
                #if os(iOS)
                .toolbarBackground(.visible, for: .navigationBar)
                #endif
                .toolbar {
                    #if os(iOS)
                    // Upstream FrostedTopBar's root-page leading BitChord logo.
                    TopBarLeadingItems()
                    ToolbarItem(placement: .topBarTrailing) { TopBarAccountButton() }
                    #endif
                }
                .refreshable { await loadFeed(force: true) }
                .task(id: auth.sessionEpoch) {
                    discovery.clear(); discovery.seedHistory()
                    await loadFeed(force: false)
                    if case .failed = feed.phase {
                        await discovery.refresh(shelves: [], session: PageSession.generation())
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: PlaylistPinning.didChange)) { _ in
                    if case .loaded(let shelves) = feed.phase {
                        Task { await discovery.refresh(shelves: shelves, session: feed.sessionGeneration) }
                    }
                }
                .onChange(of: NetworkQuality.shared.pathChanges) { oldValue, newValue in
                    guard newValue != oldValue, NetworkQuality.shared.connected else { return }
                    if case .failed = feed.phase {
                        Task { await loadFeed(force: true) }
                    }
                }
                .onAppear {
                    // Upstream's onHomeShown refetches only when a play has
                    // been registered since the feed was fetched
                    // (MainViewModel.kt:1478-1494): re-fetching otherwise
                    // would rearrange the page under whoever is reading it,
                    // and a NavigationStack root's onAppear fires on every
                    // pop back as well. "A play since" reads here as "the
                    // current track is not the one the feed loaded under".
                    if case .loaded = feed.phase,
                       feed.loadedDuringTrackId != controller.current?.id {
                        Task { await loadFeed(force: true) }
                    }
                }
                .onChange(of: feed.refreshError) { _, message in
                    // A refresh that failed over content leaves the content
                    // up, as upstream does — but silently. The toast is the
                    // difference between "nothing happened" and "this feed is
                    // from this morning".
                    if let message { toast.show(message) }
                }
        }
    }

    /// Every Home load goes through here so the loader knows what was playing
    /// when it finished — the staleness mark the onAppear check reads.
    private func loadFeed(force: Bool) async {
        await feed.load(force: force, epoch: auth.sessionEpoch)
        feed.noteLoaded(duringTrackId: controller.current?.id)
    }

    @ViewBuilder
    private var content: some View {
        switch feed.phase {
        case .loading:
            homeScroll(shelves: [], loading: true)
        case .failed(let message):
            homeScroll(shelves: [], failure: message)
        case .loaded(let shelves):
            homeScroll(shelves: shelves)
                .task(id: shelves.hashValue) {
                    await discovery.refresh(shelves: shelves, session: feed.sessionGeneration)
                }
        }
    }

    private func filtered(_ shelves: [FeedShelf]) -> [FeedShelf] {
        shelves.compactMap { shelf in
            if hideRecents && isRecentsShelf(shelf) { return nil }
            let cards = shelf.items.filter { (!hideHomeVideos || !$0.isVideo) && mediaFilter.includes(video: $0.isVideo) }
            return cards.isEmpty ? nil : FeedShelf(title: shelf.title, items: cards, subtitle: shelf.subtitle)
        }
    }

    private func homeScroll(shelves: [FeedShelf], loading: Bool = false, failure: String? = nil) -> some View {
        let visible = filtered(shelves)
        return ScrollView {
            LazyVStack(alignment: .leading, spacing: 26) {
                Picker("Inhalt", selection: $mediaFilterRaw) {
                    ForEach(HomeMediaFilter.allCases) { Text(LocalizedStringKey($0.title)).tag($0.rawValue) }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("red.home.filter")
                if !auth.signedIn { SignInBanner { auth.loginPresented = true } }
                if mediaFilter != .videos {
                    TimelineView(.periodic(from: .now, by: 60)) { timeline in
                        let mood = HomeMixMood(rawValue: mixMoodRaw) ?? .balanced
                        let title = HomeDayPart.at(timeline.date).title
                        let entries = HomeMixBuilder.build(history: discovery.history, feed: discovery.feedTracks,
                            mood: mood, date: timeline.date)
                        VStack(alignment: .leading, spacing: 26) {
                            HomeDiscoveryDashboard(model: discovery, mix: entries, mixTitle: title)
                            HomeDayMixSection(entries: entries, title: title, mood: mixMood)
                        }
                    }
                }
                if loading {
                    ProgressView("Dein Feed wird geladen …").frame(maxWidth: .infinity, minHeight: 80)
                } else if let failure {
                    EmptyStateView(icon: Image(.bchMusicNote), title: "Your feed couldn't load", subtitle: failure,
                        buttonTitle: "Retry") { Task { await loadFeed(force: true) } }
                } else if visible.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(mediaFilter == .videos && hideHomeVideos ? "Videos sind in deinen Einstellungen ausgeblendet."
                            : "Für diesen Filter sind noch keine Inhalte geladen.")
                            .font(.subheadline).foregroundStyle(.secondary)
                        if feed.canLoadMore, !(mediaFilter == .videos && hideHomeVideos) {
                            Button("Weitere Inhalte laden") { Task { await feed.loadMore() } }
                                .frame(minHeight: 44).disabled(feed.loadingMore)
                        }
                    }
                }
                ForEach(Array(visible.enumerated()), id: \.element.id) { index, shelf in
                    Group {
                        if index == 0, isRecentsShelf(shelf) { RecentShelf(shelf: shelf) }
                        else {
                            ShelfCarousel(shelf: shelf, preferTrack: true,
                                records: shelf.items.contains { $0.browseId?.hasPrefix("MPRE") == true })
                        }
                    }
                    .onAppear {
                        if shelf.id == visible.last?.id { Task { await feed.loadMore() } }
                    }
                }
                if feed.loadingMore { ProgressView().frame(maxWidth: .infinity, minHeight: 44) }
                if !visible.isEmpty, feed.canLoadMore {
                    Button("Weitere Inhalte laden") { Task { await feed.loadMore() } }
                        .frame(maxWidth: .infinity, minHeight: 44).disabled(feed.loadingMore)
                }
            }
            .padding(.horizontal, 24).padding(.vertical, 20)
        }
        .modifier(ExternalScrollPosition(position: scrollPosition))
        #if os(iOS)
        .modifier(DockScrollDirectionObserver())
        #endif
        .task(id: "\(mediaFilterRaw)-\(hideHomeVideos)-\(hideRecents)-\(feed.canLoadMore)") {
            // Bei einem leeren Filter begrenzt vorblättern; weitere Seiten
            // bleiben bewusst über den sichtbaren Ladebutton erreichbar.
            for _ in 0..<3 {
                guard !Task.isCancelled, !(mediaFilter == .videos && hideHomeVideos), case .loaded(let current) = feed.phase,
                      filtered(current).isEmpty, feed.canLoadMore, !feed.loadingMore else { return }
                await feed.loadMore()
            }
        }
    }

    /// Upstream's `RECENTS_TITLE` — the first shelf is a recents rail when the
    /// service titles it so, matched case-insensitively like upstream.
    private func isRecentsShelf(_ shelf: FeedShelf) -> Bool {
        let title = shelf.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        // Accept the earlier Apple bridge title as well as upstream's canonical
        // "Recents" so the feed keeps the four-row treatment.
        return title == "recents" || title == "recently played"
    }
}

private enum RecentShelfLayout {
    static let columnSpacing: CGFloat = 12

    static func columnWidth(viewportWidth: CGFloat) -> CGFloat {
        min(viewportWidth * 0.88, 400)
    }

    static func placeholderCount(availableWidth: CGFloat, itemWidth: CGFloat, spacing: CGFloat) -> Int {
        max(1, Int(ceil((availableWidth + spacing) / (itemWidth + spacing))))
    }
}

/// The upstream Home loading state reserves the Recents shelf and matches the
/// saved list/grid layout so content does not jump when the feed arrives.
private struct HomeFeedSkeleton: View {
    @AppStorage("hide_recents") private var hideRecents = false
    @State private var viewType = PlatformSettings.shared.getString(
        key: "home_recents_view_type", default: "LIST"
    )

    private var isList: Bool { viewType.uppercased() != "GRID" }

    var body: some View {
        VStack(alignment: .leading, spacing: 26) {
            if !hideRecents {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    RecentsSkeletonBlock(height: 22, cornerRadius: 6).frame(width: 112)
                    Spacer(minLength: 8)
                    RecentsSkeletonBlock(height: 32, cornerRadius: 16).frame(width: 32)
                }
                if isList {
                    GeometryReader { geometry in
                        let columnWidth = RecentShelfLayout.columnWidth(viewportWidth: geometry.size.width + 48)
                        let count = RecentShelfLayout.placeholderCount(
                            availableWidth: geometry.size.width, itemWidth: columnWidth,
                            spacing: RecentShelfLayout.columnSpacing
                        )
                        HStack(alignment: .top, spacing: RecentShelfLayout.columnSpacing) {
                            ForEach(0..<count, id: \.self) { _ in
                                VStack(spacing: 0) {
                                    ForEach(0..<4, id: \.self) { index in
                                        HStack(spacing: 12) {
                                            RecentsSkeletonBlock(height: 48, cornerRadius: 7).frame(width: 48)
                                            VStack(alignment: .leading, spacing: 7) {
                                                RecentsSkeletonBlock(height: 14, cornerRadius: 4)
                                                    .frame(width: [150.0, 112.0, 134.0, 96.0][index])
                                                RecentsSkeletonBlock(height: 12, cornerRadius: 4)
                                                    .frame(width: [92.0, 122.0, 78.0, 106.0][index])
                                            }
                                            Spacer(minLength: 4)
                                            RecentsSkeletonBlock(height: 20, cornerRadius: 10).frame(width: 20)
                                        }
                                        .frame(height: 56)
                                    }
                                }
                                .frame(width: columnWidth, alignment: .leading)
                            }
                        }
                        .frame(width: geometry.size.width, alignment: .leading)
                        .clipped()
                    }
                    .frame(height: 4 * 56)
                } else {
                    GeometryReader { geometry in
                        let count = RecentShelfLayout.placeholderCount(
                            availableWidth: geometry.size.width, itemWidth: 160, spacing: 14
                        )
                        HStack(alignment: .top, spacing: 14) {
                            ForEach(0..<count, id: \.self) { _ in
                                VStack(alignment: .leading, spacing: 8) {
                                    RecentsSkeletonBlock(height: 160, cornerRadius: 10).frame(width: 160)
                                    RecentsSkeletonBlock(height: 14, cornerRadius: 4).frame(width: 118)
                                    RecentsSkeletonBlock(height: 12, cornerRadius: 4).frame(width: 82)
                                }
                            }
                        }
                        .frame(width: geometry.size.width, alignment: .leading)
                        .clipped()
                    }
                    .frame(height: 202)
                }
            }
            }
            ForEach(0..<2, id: \.self) { shelf in
                VStack(alignment: .leading, spacing: 10) {
                    SkeletonBlock(height: 22, cornerRadius: 6).frame(width: shelf == 0 ? 140 : 110)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(0..<4, id: \.self) { _ in
                                VStack(alignment: .leading, spacing: 8) {
                                    SkeletonBlock(height: 156, cornerRadius: 12).frame(width: 156)
                                    SkeletonBlock(height: 14, cornerRadius: 4).frame(width: 118)
                                    SkeletonBlock(height: 12, cornerRadius: 4).frame(width: 82)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }
}

/// The Recents placeholder uses the same moving highlight sweep as upstream's
/// shimmer blocks, while respecting the listener's Reduce Motion setting.
private struct RecentsSkeletonBlock: View {
    let height: CGFloat
    var cornerRadius: CGFloat = 6
    @State private var sweep = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.quaternary)
                if !reduceMotion {
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.22), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 0.55)
                    .offset(x: sweep ? geometry.size.width : -geometry.size.width * 0.55)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        }
        .frame(height: height)
        .onAppear { sweep = true }
        .animation(
            reduceMotion ? nil : .linear(duration: 1.4).repeatForever(autoreverses: false),
            value: sweep
        )
        .accessibilityHidden(true)
    }
}

/// Upstream's `RecentShelf`: the first Home shelf when titled "Recents".
/// LIST mode is a horizontal rail of two columns × four track rows;
/// GRID mode is the ordinary card carousel. The choice persists in
/// `home_recents_view_type` like upstream's `homeRecentsViewType`.
struct RecentShelf: View {
    let shelf: FeedShelf
    @Environment(PlaybackController.self) private var controller

    /// LIST or GRID, persisted. Read off `PlatformSettings` rather than
    /// `@AppStorage` so the value is the same store the Android side reads.
    @State private var viewType: String = PlatformSettings.shared.getString(
        key: "home_recents_view_type", default: "LIST"
    )
    /// The grid row's own width, measured — the hero tile's height hangs off
    /// it, and a GeometryReader cannot supply that: its ideal height is ten
    /// points, and the heroes drew straight through the shelf below.
    @State private var gridWidth: CGFloat = 0

    private var isList: Bool { viewType.uppercased() == "LIST" }

    /// Upstream's hero width: 70% of the row, capped at 320.
    private var heroSide: CGFloat {
        guard gridWidth > 0 else { return 240 }
        return min(gridWidth * 0.70, 320)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Recents").font(.title2.weight(.bold)).lineLimit(1)
                    if let subtitle = shelf.subtitle, !subtitle.isEmpty {
                        Text(subtitle).font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
                    }
                }
                Spacer(minLength: 8)
                Menu {
                    Button("Liste", systemImage: "list.bullet") { selectView("LIST") }
                    Button("Raster", systemImage: "square.grid.2x2") { selectView("GRID") }
                    Button("Depth Ribbon", systemImage: "square.stack.3d.up") { selectView("RIBBON") }
                } label: {
                    Image(systemName: viewType == "RIBBON" ? "square.stack.3d.up" : "square.grid.2x2")
                        .frame(width: 32, height: 32)
                }
                .accessibilityLabel("Ansicht auswählen")
            }
            if isList {
                GeometryReader { geometry in
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(alignment: .top, spacing: 12) {
                            ForEach(Array(shelf.items.chunked(4).enumerated()), id: \.offset) { _, column in
                                VStack(spacing: 0) {
                                    ForEach(column) { card in
                                        RecentTrackRow(card: card)
                                    }
                                }
                                // Upstream's trackColumnWidth is 88% of the
                                // viewport, capped at 400 points.
                                .frame(width: RecentShelfLayout.columnWidth(viewportWidth: geometry.size.width), alignment: .leading)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 2)
                    }
                }
                .frame(height: 4 * 56 + 4)
                .padding(.horizontal, -24)
            } else if viewType == "RIBBON" {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 6) {
                        ForEach(shelf.items) { card in
                            HeroCard(card: card, preferTrack: true, side: 184)
                                .modifier(RecentRibbonTransform())
                        }
                    }
                    .padding(.vertical, 18)
                }
                .frame(height: 242)
            } else {
                // Upstream's Recents GRID mode is the hero treatment: the
                // same 0.92-ratio scrim-caption tiles as Home's first shelf.
                // The row's height is the tile's height, nothing extra — the
                // caption is inside the tile.
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .top, spacing: 14) {
                        ForEach(shelf.items) { card in
                            HeroCard(card: card, preferTrack: true, side: heroSide)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .frame(height: heroSide * 0.92 + 4)
                .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { gridWidth = $0 }
            }
        }
    }
    private func selectView(_ type: String) {
        viewType = type
        PlatformSettings.shared.putString(key: "home_recents_view_type", value: type)
    }

}

/// One recent track: 48pt sleeve, title/artist, overflow menu. Matches
/// upstream's `RecentTrackRow` (artwork + two lines + more button), with the
/// now-playing accent the other shelf cards carry.
private struct RecentTrackRow: View {
    let card: ShelfCard
    @Environment(PlaybackController.self) private var controller

    /// Whether this row is the track loaded in the player right now.
    private var isCurrentTrack: Bool {
        guard let videoId = card.videoId, !videoId.isEmpty else { return false }
        return controller.current?.id == videoId
    }

    var body: some View {
        HStack(spacing: 8) {
            Button {
                if let videoId = card.videoId, !videoId.isEmpty {
                    controller.playRadio(QueueEntry.youtube(
                        videoId: videoId, title: card.title, artist: card.subtitle ?? "",
                        thumbnailUrl: card.thumbnailUrl
                    ), context: "Recents")
                }
            } label: {
                HStack(spacing: 12) {
                    ArtworkView(url: card.thumbnailUrl, data: nil, side: 48)
                        .clipShape(.rect(cornerRadius: 7, style: .continuous))
                        .modifier(NowPlayingCardAccent(
                            isCurrent: isCurrentTrack,
                            isPlaying: controller.isPlaying
                        ))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(card.title)
                            .font(.body.weight(.medium))
                            .foregroundStyle(isCurrentTrack ? Theme.accent : .primary)
                            .lineLimit(1)
                        if let subtitle = card.subtitle, !subtitle.isEmpty {
                            Text(subtitle).font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
                        }
                    }
                    Spacer(minLength: 4)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .shelfCardContextMenu(card)

            Menu { ShelfCardActionButtons(card: card) } label: {
                Image(systemName: "ellipsis")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 36, height: 36)
                    .contentShape(Circle())
            }
            #if os(macOS)
            // Without this the Mac draws a boxed pop-up button with a chevron.
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            #endif
            .tint(.gray)
            .accessibilityLabel("More actions for \(card.title)")
        }
        .padding(.vertical, 4)
    }
}

private extension Array {
    /// Splits into consecutive runs of `size`, like Kotlin's `chunked`.
    func chunked(_ size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        var out: [[Element]] = []
        var index = startIndex
        while index < endIndex {
            let end = self.index(index, offsetBy: size, limitedBy: endIndex) ?? endIndex
            out.append(Array(self[index..<end]))
            index = end
        }
        return out
    }
}


private struct RecentRibbonTransform: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content.scrollTransition(.interactive, axis: .horizontal) { view, phase in
                view
                    .rotation3DEffect(.degrees(Double(phase.value) * -30), axis: (0, 1, 0), perspective: 0.75)
                    .rotationEffect(.degrees(Double(phase.value) * 5))
                    .offset(y: abs(phase.value) * 24)
                    .scaleEffect(1 - abs(phase.value) * 0.14)
                    .opacity(1 - abs(phase.value) * 0.25)
            }
        }
    }
}
