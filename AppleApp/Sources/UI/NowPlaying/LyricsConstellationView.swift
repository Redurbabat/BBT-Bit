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
    @State private var lineCaptions: [String] = []
    @State private var beats: [Double] = []
    @State private var voices: [ConstellationVoice] = []

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

    /// Neue Messung nur bei anderer Datei, anderen Wortzeiten oder anderem Versatz.
    private var voiceKey: String {
        "\(controller.loadedSourcePath ?? "")|\(timelineWords.count)|\(timelineWords.first?.start ?? 0)|\(timelineWords.last?.end ?? 0)|\(offsetMs)"
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
            duration: duration, audioPosition: position, beatTimes: beats, lineTexts: lineCaptions,
            voices: voices
        )
        .onChange(of: lines, initial: true) { _, _ in
            timelineWords = lines.indices.flatMap { starWords(for: $0) }.sorted { $0.start < $1.start }
            lineCaptions = lines.map(\.text)
        }
        .task(id: "\(controller.loadedSourcePath ?? "")-\(controller.automixPlanRevision)") {
            beats = []
            let found = await controller.cachedLyricsBeats()
            guard !Task.isCancelled else { return }
            beats = found
        }
        .task(id: voiceKey) {
            // Kurz warten: Wortzeiten aus der lokalen Ausrichtung kommen schubweise.
            try? await Task.sleep(for: .milliseconds(900))
            guard !Task.isCancelled, !timelineWords.isEmpty else { return }
            // Liedtextzeit plus Versatz ergibt die Audiozeit der Datei.
            let shift = Swift.Int64(offsetMs)
            let found = await controller.lyricVoiceShape(starts: timelineWords.map { $0.start + shift },
                                                         ends: timelineWords.map { $0.end + shift })
            guard !Task.isCancelled else { return }
            voices = found
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
    /// Gemessene Stimme je Wort; leer, solange keine lokale Messung vorliegt.
    var voices: [ConstellationVoice] = []
    @State private var historyIndex: Int?
    @State private var manualMap = false
    @State private var finaleDismissed = false
    @State private var finaleStart: Date?
    @State private var layout = ConstellationLayout.empty
    @State private var historyDrag: CGFloat = 0
    @State private var peek: CGFloat = 0
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
    private var motion: Animation? { reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.86) }
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Günstiger Vergleichsschlüssel: Die Form wird nur bei neuen Daten neu berechnet.
    private struct LayoutKey: Equatable {
        let count: Int
        let timing: Swift.Int64
        let voices: Int
        let voiceSum: Double
        let beats: Int
        let lastBeat: Double
        let title: String
    }

    private var layoutKey: LayoutKey {
        LayoutKey(count: words.count,
                  timing: words.reduce(Swift.Int64(0)) { (sum: Swift.Int64, word: ConstellationWord) -> Swift.Int64 in
                      let mixed: Swift.Int64 = word.start &* 31 &+ word.end
                      return sum &+ mixed &+ Swift.Int64(word.line)
                  },
                  voices: voices.count,
                  voiceSum: voices.reduce(0.0) { (sum: Double, voice: ConstellationVoice) -> Double in
                      sum + voice.pitchHz + voice.energyDb
                  },
                  beats: beatTimes.count, lastBeat: beatTimes.last ?? 0, title: trackTitle)
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Color.black.opacity(immersive ? 1 : 0.65)
            RhythmicConstellationCanvas(words: words, layout: layout, positionMs: positionMs,
                audioPosition: audioPosition ?? Double(positionMs) / 1000,
                beats: beatTimes, historyIndex: historyIndex, historyDrag: historyDrag, peek: peek,
                overview: manualMap, finale: finale, finaleStart: finaleStart, reduced: reduceMotion)
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
                    .font(.caption2).foregroundStyle(.white.opacity(0.35))
                if layout.signature.voiced {
                    Text("Shape follows the singing voice")
                        .font(.caption2).foregroundStyle(.white.opacity(0.3))
                }
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
        .onChange(of: layoutKey, initial: true) { _, _ in
            layout = ConstellationVoiceLayout.layout(words: words, voices: voices, beats: beatTimes,
                                                     seed: ConstellationVoiceLayout.seed(trackTitle))
        }
        .onChange(of: finaleWindow != nil, initial: true) { _, entering in
            // Vorheriges Blättern darf den automatischen Schlussblitz nicht sperren.
            finaleDismissed = false
            finaleStart = entering ? Date() : nil
            if entering {
                withAnimation(motion) { historyIndex = nil; manualMap = false; historyDrag = 0; peek = 0 }
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 18)
                .onChanged { value in
                    guard finale == nil, abs(value.translation.width) > abs(value.translation.height) else { return }
                    if historyIndex != nil {
                        historyDrag = value.translation.width
                    } else {
                        peek = min(1, max(0, -value.translation.width / 160))
                    }
                }
                .onEnded { value in
                    let horizontal = abs(value.translation.width) > abs(value.translation.height) * 1.3
                    withAnimation(motion) {
                        if horizontal { settle(value) }
                        historyDrag = 0
                        peek = 0
                    }
                    if !horizontal, immersive, value.translation.height > 100 {
                        onClose()
                    }
                }
        )
    }

    /// Nach links wischen öffnet den Verlauf. Im Verlauf folgt der Inhalt dem
    /// Finger; wer über das aktuelle Wort hinaus wischt, ist wieder live.
    private func settle(_ value: DragGesture.Value) {
        guard let historyIndex else {
            if value.translation.width < -40 { review(0) }
            return
        }
        let momentum = value.translation.width + (value.predictedEndTranslation.width - value.translation.width) * 0.4
        self.historyIndex = ConstellationVoiceLayout.settledHistory(layout: layout, from: historyIndex,
                                                                    drag: momentum, current: current)
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
            // Wie im Original: Titel mittig in Versalien, Bedienung zurückhaltend.
            ZStack {
                Text(trackTitle.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(2.2)
                    .foregroundStyle(.white.opacity(0.55))
                    .lineLimit(1)
                    .padding(.horizontal, 72)
                HStack {
                    Spacer(minLength: 0)
                    Button(action: onShowList ?? onClose) {
                        Label("List", systemImage: "text.alignleft")
                            .labelStyle(.iconOnly)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Show lyrics list")
                    .accessibilityIdentifier("bbt.lyrics.constellation.list")
                }
            }
            .padding(.horizontal, 12)
            HStack(spacing: 6) {
                Button { withAnimation(motion) { review(-8) } } label: { Image(systemName: "chevron.left").frame(width: 44, height: 44) }
                    .accessibilityLabel("Earlier lyrics").disabled(words.isEmpty)
                if historyIndex != nil || showsMap {
                    Button("Current line") {
                        withAnimation(motion) { historyIndex = nil; manualMap = false; finaleDismissed = true }
                    }
                    .frame(minHeight: 44).accessibilityIdentifier("red.lyrics.current")
                }
                Spacer(minLength: 0)
                Button(showsMap ? LocalizedStringKey("Close song map") : LocalizedStringKey("Song map")) {
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.6)) {
                        if showsMap { manualMap = false; finaleDismissed = true }
                        else { manualMap = true; historyIndex = nil }
                    }
                }.frame(minHeight: 44).accessibilityIdentifier("red.lyrics.map")
                if historyIndex != nil {
                    Button { withAnimation(motion) { review(8) } } label: { Image(systemName: "chevron.right").frame(width: 44, height: 44) }
                        .accessibilityLabel("Later lyrics")
                }
            }.font(.caption2).buttonStyle(.plain).foregroundStyle(.white.opacity(0.5)).padding(.horizontal, 16)
        }
        .padding(.top, immersive ? 44 : 0)
    }

}
