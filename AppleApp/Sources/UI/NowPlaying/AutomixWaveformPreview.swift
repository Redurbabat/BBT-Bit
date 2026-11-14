import SwiftUI

/// Zwei echte Decoder-Fenster. Ein fehlender Abruf bleibt sichtbar fehlend.
struct AutomixWaveformPreview: View {
    @Environment(PlaybackController.self) private var controller
    let request: AutomixPreviewRequest
    @State private var outgoing: AutomixWaveformDecoder.Deck?
    @State private var incoming: AutomixWaveformDecoder.Deck?
    @State private var loading = true
    @State private var retry = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            deck(request.outgoing, data: outgoing, window: request.outgoingWindow, isOutgoing: true)
            deck(request.incoming, data: incoming, window: request.incomingWindow, isOutgoing: false)
            Text("Bass · Mitten · Höhen")
                .font(.caption).foregroundStyle(.secondary)
            Text(String(format: "Überblendung %.1f s · Tempo ×%.3f", request.fade, request.rate))
                .font(.caption.monospacedDigit())
            if loading {
                ProgressView("Wellenformen werden geladen …")
            } else if outgoing == nil || incoming == nil || incomplete {
                Text("Audiodaten sind noch nicht vollständig verfügbar.")
                    .font(.footnote).foregroundStyle(.secondary)
                Button("Wellenformen erneut laden") { retry += 1 }
                    .frame(minHeight: 44)
            }
        }
        .task(id: "\(request.id)-\(retry)") {
            loading = true
            outgoing = nil; incoming = nil
            for attempt in 0..<3 {
                guard !Task.isCancelled else { return }
                let out = await AutomixWaveformDecoder.shared.decode(engine: controller.engine,
                    source: request.outgoingSource, headers: request.outgoingHeaders, window: request.outgoingWindow)
                guard !Task.isCancelled else { return }
                outgoing = out
                let inc = await AutomixWaveformDecoder.shared.decode(engine: controller.engine,
                    source: request.incomingSource, headers: request.incomingHeaders, window: request.incomingWindow)
                guard !Task.isCancelled else { return }
                incoming = inc
                if out != nil && inc != nil && !incomplete { break }
                if attempt < 2 { do { try await Task.sleep(for: .seconds(2)) } catch { return } }
            }
            loading = false
        }
    }

    private var incomplete: Bool {
        (outgoing?.waveform.duration ?? 0) + 0.1 < request.outgoingWindow.length
            || (incoming?.waveform.duration ?? 0) + 0.1 < request.incomingWindow.length
    }

    private func deck(_ entry: QueueEntry, data: AutomixWaveformDecoder.Deck?, window: MixWaveformWindow, isOutgoing: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.title).font(.headline)
            Text(entry.artist).font(.subheadline).foregroundStyle(.secondary)
            Text(String(format: "Ausschnitt %.1f–%.1f s", window.start, window.start + window.length))
                .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
            if let data {
                HStack {
                    if let bpm = data.bpm, bpm.isFinite { Text(String(format: "%.0f BPM", bpm)) }
                    if let key = data.key { Text(key) }
                }.font(.caption.monospacedDigit())
            }
            Canvas { context, size in
                let x0 = (window.blendStart - window.start) / window.length * size.width
                let x1 = min(size.width, (window.blendEnd - window.start) / window.length * size.width)
                context.fill(Path(CGRect(x: x0, y: 0, width: max(0, x1 - x0), height: size.height)), with: .color(.primary.opacity(0.06)))
                if let wave = data?.waveform {
                    let offset = min(1, (data?.offset ?? 0) / window.length) * size.width
                    let width = min(1, wave.duration / window.length) * size.width
                    let step = width / Double(max(1, wave.bars.count))
                    for (i, bands) in wave.bars.enumerated() {
                        for (value, color) in [(bands.low, Color.blue), (bands.mid, Color.orange), (bands.high, Color.pink)] {
                            let height = Double(value) * size.height * 0.9
                            context.fill(Path(CGRect(x: offset + Double(i) * step, y: (size.height - height) / 2,
                                width: max(0.5, step * 0.7), height: height)), with: .color(color.opacity(0.6)))
                        }
                    }
                }
                let sameTrack = request.outgoing.id == request.incoming.id
                let selected = controller.current?.id == entry.id
                    && (!sameTrack || (isOutgoing != controller.smartMixInProgress))
                if selected {
                    let x = (controller.position - window.start) / window.length * size.width
                    if x >= 0 && x <= size.width {
                        context.fill(Path(CGRect(x: x, y: 0, width: 2, height: size.height)), with: .color(.primary))
                    }
                }
            }
            .frame(height: 74)
            .clipped()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(isOutgoing ? "Wellenform des ausgehenden Titels" : "Wellenform des nächsten Titels")
            .accessibilityValue(data == nil ? "Nicht verfügbar" : "Aus Audiodaten gemessen")
        }
    }
}
