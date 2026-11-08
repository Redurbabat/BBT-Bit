import SwiftUI
import BitChordShared

/// Zusätzliche Lyrics-Darstellung; Zeitbasis, Versatz und Daten bleiben mit der Liste geteilt.
struct LyricsConstellationView: View {
    let lines: [LyricLineDto]
    let position: Double
    var offsetMs: Int32 = 0
    var onClose: () -> Void = {}
    var immersive = false
    var trackTitle = ""
    var sourceLabel: String? = nil
    var onShowList: (() -> Void)? = nil

    var duration: Double = 0
    @Environment(PlaybackController.self) private var controller
    @State private var timelineWords: [ConstellationWord] = []
    @State private var beats: [Double] = []

    static func isAvailable(lines: [LyricLineDto]) -> Bool {
        !lines.isEmpty && LyricFocus.shared.isSynced(lines: lines)
    }

    private var adjustedMs: Swift.Int64 {
        ConstellationGeometry.milliseconds(position: position, offset: offsetMs)
    }

    private var leadIndex: Int? {
        guard !lines.isEmpty else { return nil }
        let lead = LyricFocus.shared.leadRow(lines: lines, positionMs: adjustedMs)
        return lead < 0 ? 0 : min(Int(lead), lines.count - 1)
    }

    var body: some View {
        ConstellationStage(
            words: timelineWords,
            lineText: leadIndex.map { lines[$0].text } ?? "",
            positionMs: adjustedMs,
            lineStart: leadIndex.map { min(Swift.Int64.max / 2, max(0, lines[$0].timeMs)) } ?? 0,
            immersive: immersive,
            trackTitle: trackTitle,
            sourceLabel: sourceLabel,
            onClose: onClose,
            onShowList: onShowList,
            duration: duration, audioPosition: position, beatTimes: beats, lineTexts: lines.map(\.text)
        )
        .onChange(of: lines, initial: true) { _, _ in
            timelineWords = lines.indices.flatMap { starWords(for: $0) }.sorted { $0.start < $1.start }
        }
        .task(id: "\(controller.loadedSourcePath ?? "")-\(controller.automixPlanRevision)") {
            beats = []
            guard let path = controller.loadedSourcePath else { return }
            let found = await Task.detached(priority: .utility) { cachedBeatTimes(path: path) }.value
            guard !Task.isCancelled, controller.loadedSourcePath == path else { return }
            beats = found
        }
    }

    /// Ohne Wortmarker bildet die ganze Zeile einen Knoten. Kein künstliches
    /// Verteilen von Wörtern und keine aus BPM erzeugten Schein-Beats.
    private func starWords(for index: Int) -> [ConstellationWord] {
        let line = lines[index]
        let timed = line.words.filter {
            !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && $0.endMs > $0.startMs
        }
        if !timed.isEmpty {
            return timed.map { ConstellationWord(text: $0.text, start: max(0, $0.startMs),
                end: max(0, $0.endMs), line: index) }
        }
        guard !line.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return [] }
        let next = index + 1 < lines.count ? lines[index + 1].timeMs : line.timeMs
        return [ConstellationWord(text: line.text, start: max(0, line.timeMs), end: max(0, next), line: index)]
    }
}

/// Dieselbe native Zeichenfläche wird in der echten Ansicht und im gekennzeichneten UI-Fixture verwendet.
struct ConstellationStage: View {
    let words: [ConstellationWord]
    let lineText: String
    let positionMs: Swift.Int64
    let lineStart: Swift.Int64
    var immersive = false
    var trackTitle = ""
    var sourceLabel: String? = nil
    var onClose: () -> Void = {}
    var onShowList: (() -> Void)? = nil
    var duration: Double = 0
    var audioPosition: Double? = nil
    var beatTimes: [Double] = []
    var lineTexts: [String] = []
    @State private var historyIndex: Int?
    @State private var manualMap = false
    @State private var finaleDismissed = false
    private var finaleWindow: Double? {
        ConstellationTimeline.finaleProgress(position: audioPosition ?? Double(positionMs) / 1000, duration: duration)
    }
    private var current: Int { ConstellationTimeline.activeIndex(words: words, milliseconds: positionMs) ?? 0 }
    private var finale: Double? {
        finaleDismissed ? nil : finaleWindow
    }
    private var showsMap: Bool { manualMap || finale != nil }
    private var caption: String {
        guard let historyIndex, words.indices.contains(historyIndex), lineTexts.indices.contains(words[historyIndex].line) else { return lineText }
        return lineTexts[words[historyIndex].line]
    }
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Color.black.opacity(immersive ? 1 : 0.65)
            RhythmicConstellationCanvas(words: words, positionMs: positionMs,
                audioPosition: audioPosition ?? Double(positionMs) / 1000, duration: duration,
                beats: beatTimes, historyIndex: historyIndex, overview: showsMap, finale: finale,
                reduced: reduceMotion)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 12) {
                if finale != nil {
                    Text("Song map · final ten seconds").font(.caption).foregroundStyle(.white.opacity(0.7))
                        .accessibilityIdentifier("red.lyrics.finale")
                        .accessibilityValue(Text("\(Int((finale ?? 0) * 100)) %"))
                } else if historyIndex != nil {
                    Text("Lyrics history").font(.caption).foregroundStyle(.white.opacity(0.7))
                        .accessibilityIdentifier("red.lyrics.history")
                }
                Text(caption)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("bbt.lyrics.constellation.line")
                Text(beatTimes.isEmpty ? LocalizedStringKey("Light follows lyric timestamps") : LocalizedStringKey("Light follows detected beats"))
                    .font(.caption2).foregroundStyle(.white.opacity(0.55))
                if let sourceLabel, !sourceLabel.isEmpty {
                    Text("Lyrics source: \(sourceLabel)")
                        .font(.system(size: 9, weight: .semibold))
                        .tracking(1)
                        .foregroundStyle(.white.opacity(0.25))
                }
            }
            .padding(.horizontal, 22)
            .padding(.bottom, immersive ? 58 : 20)
        }
        .overlay(alignment: .top) { header }
        .clipShape(RoundedRectangle(cornerRadius: immersive ? 0 : 22, style: .continuous))
        .onChange(of: finaleWindow != nil) { _, entering in
            // Vorheriges Blättern darf den automatischen Schlusszoom nicht sperren.
            finaleDismissed = false
            if entering { historyIndex = nil; manualMap = false }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 24).onEnded { value in
                if abs(value.translation.width) > abs(value.translation.height) * 1.3 {
                    review(Int((value.translation.width / 8).rounded()))
                } else if immersive, value.translation.height > 100 {
                    onClose()
                }
            }
        )
    }

    private func review(_ delta: Int) {
        manualMap = false
        finaleDismissed = true
        historyIndex = min(current, max(0, (historyIndex ?? current) + delta))
    }

    private var header: some View {
        VStack(spacing: 8) {
            Button(action: onClose) {
                Capsule().fill(.white.opacity(0.35)).frame(width: 36, height: 4)
                    .frame(width: 60, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back to player")
            .accessibilityIdentifier("bbt.lyrics.constellation.close")
            HStack {
                Text(trackTitle.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.8)
                    .foregroundStyle(.white.opacity(0.45))
                    .lineLimit(1)
                Spacer(minLength: 8)
                Button(action: onShowList ?? onClose) {
                    Label("List", systemImage: "text.alignleft")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.75))
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Show lyrics list")
                .accessibilityIdentifier("bbt.lyrics.constellation.list")
            }
            .padding(.horizontal, 22)
            HStack(spacing: 8) {
                Button { review(-8) } label: { Image(systemName: "chevron.left").frame(width: 44, height: 44) }
                    .accessibilityLabel("Earlier lyrics").disabled(words.isEmpty)
                Button("Current line") { historyIndex = nil; manualMap = false; finaleDismissed = true }
                    .frame(minHeight: 44).accessibilityIdentifier("red.lyrics.current")
                Spacer(minLength: 0)
                Button(showsMap ? LocalizedStringKey("Close song map") : LocalizedStringKey("Song map")) {
                    if showsMap { manualMap = false; finaleDismissed = true }
                    else { manualMap = true }
                }.frame(minHeight: 44).accessibilityIdentifier("red.lyrics.map")
                Button { review(8) } label: { Image(systemName: "chevron.right").frame(width: 44, height: 44) }
                    .accessibilityLabel("Later lyrics").disabled(historyIndex == nil)
            }.font(.caption).buttonStyle(.plain).foregroundStyle(.white.opacity(0.85)).padding(.horizontal, 16)
        }
        .padding(.top, immersive ? 44 : 0)
    }

}
