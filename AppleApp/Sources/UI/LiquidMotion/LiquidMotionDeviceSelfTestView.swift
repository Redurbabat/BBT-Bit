#if os(iOS)
import SwiftUI
import UIKit

/// A deliberately narrow, offline smoke test: can the 15 design-review
/// previews render to a valid PNG on this iPhone? No playback, account,
/// network, party, Handoff or download workflows are claimed to be tested.
struct LiquidMotionDeviceSelfTestView: View {
    @Environment(PlaybackController.self) private var controller
    @Environment(\.locale) private var locale
    @State private var running = false
    @State private var completed = 0
    @State private var results: [DesignCheckResult] = []
    @State private var reportURL: URL?
    @State private var errorMessage: String?
    @State private var selectedPreview: LiquidPhotoFeature?
    @State private var sharing = false

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("15 Beispiel-Vorschauen prüfen")
                        .font(.headline)
                    Text("RED Bit rendert alle 15 Design-Vorschauen auf deinem iPhone und prüft, ob jeweils ein gültiges PNG entsteht. Es werden keine Musikdateien, Konten oder Fotos gelesen.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Button {
                        Task { await runAll() }
                    } label: {
                        Label(running ? "Prüfung läuft …" : "Alle 15 Designs prüfen",
                              systemImage: "checkmark.shield")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(running)
                    .accessibilityIdentifier("bbt.selftest.run")

                    if running {
                        ProgressView(value: Double(completed), total: 15)
                        Text("\(completed) von 15").font(.caption.monospacedDigit())
                    }
                    if !running && results.count == 15 {
                        let passed = results.filter { $0.passed }.count
                        Text("\(passed) bestanden · \(15 - passed) fehlgeschlagen")
                            .font(.headline)
                            .foregroundStyle(passed == 15 ? .green : .orange)
                            .accessibilityIdentifier("bbt.selftest.summary")
                    }
                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.orange)
                    }
                    if reportURL != nil {
                        Button {
                            sharing = true
                        } label: {
                            Label("JSON-Testbericht teilen", systemImage: "square.and.arrow.up")
                        }
                        .disabled(running)
                        .accessibilityIdentifier("bbt.selftest.share")
                    }
                }
                .padding(.vertical, 5)
            } header: {
                Text("iPhone-Selbsttest")
            } footer: {
                Text("Ein erfolgreicher Design-Test bestätigt nur das Rendern der Vorschau. Er prüft nicht das Abspielen, echte Songübergänge, Downloads, andere Geräte oder sämtliche App-Funktionen.")
            }

            if !results.isEmpty {
                Section("Einzelergebnisse · Antippen für die Vorschau") {
                    ForEach(results) { result in
                        Button {
                            selectedPreview = LiquidPhotoFeature(rawValue: result.index - 1)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: result.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundStyle(result.passed ? .green : .orange)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(String(format: "%02d · %@", result.index, result.name))
                                        .foregroundStyle(.primary)
                                    Text(result.detail)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier(String(format: "bbt.selftest.feature.%02d", result.index))
                    }
                }
            }
        }
        .navigationTitle("Vorschau-Selbsttest")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedPreview) { feature in
            NavigationStack {
                ScrollView([.vertical, .horizontal]) {
                    LiquidPhotoCard(feature: feature)
                        .padding(12)
                        .frame(maxWidth: .infinity)
                }
                .navigationTitle(feature.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Schließen") { selectedPreview = nil }
                            .accessibilityIdentifier("bbt.selftest.close")
                    }
                }
            }
        }
        .sheet(isPresented: $sharing) {
            if let reportURL {
                DeviceTestShareSheet(url: reportURL)
            }
        }
    }

    @MainActor
    private func runAll() async {
        guard !running else { return }
        running = true
        completed = 0
        results = []
        reportURL = nil
        errorMessage = nil
        defer { running = false }

        var measured: [DesignCheckResult] = []
        for feature in LiquidPhotoFeature.allCases {
            // ImageRenderer beginnt eine eigene View-Hierarchie. Er übernimmt
            // die Wiedergabesitzung der aufrufenden Ansicht nicht automatisch.
            let renderer = ImageRenderer(content: LiquidPhotoCard(feature: feature)
                .environment(controller).environment(\.locale, locale))
            renderer.scale = 1
            let image = renderer.uiImage
            let png = image?.pngData()
            let validSize = (image?.size.width ?? 0) >= 390 && (image?.size.height ?? 0) >= 780
            let passed = validSize && (png?.count ?? 0) > 1_024
            let result = DesignCheckResult(
                index: feature.rawValue + 1,
                name: feature.title,
                location: feature.location,
                passed: passed,
                detail: passed ? "Vorschau gerendert · \(png!.count) Bytes" : "PNG-Rendering fehlgeschlagen"
            )
            measured.append(result)
            results = measured
            completed = measured.count
            await Task.yield()
        }

        let report = DesignDeviceReport(
            schemaVersion: 1,
            testType: "liquid-motion-design-preview-render",
            limitation: "Checks 15 on-device sample-data preview PNG renders only. No real playback, UI button semantics, network, party, downloads, Handoff or end-to-end functionality validated.",
            timestamp: ISO8601DateFormatter().string(from: Date()),
            device: UIDevice.current.model,
            iosVersion: UIDevice.current.systemVersion,
            appVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown",
            buildRevision: Bundle.main.object(forInfoDictionaryKey: "BitChordRevision") as? String ?? "unknown",
            passed: measured.filter(\.passed).count,
            failed: measured.filter { !$0.passed }.count,
            checks: measured
        )

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(report)
            let directory = FileManager.default.temporaryDirectory
                .appendingPathComponent("BBT-Bit-Selbsttest", isDirectory: true)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let url = directory.appendingPathComponent("BBT-Bit-iPhone-Testbericht.json")
            try data.write(to: url, options: .atomic)
            reportURL = url
        } catch {
            errorMessage = "Der Test wurde ausgeführt, aber der Bericht konnte nicht gespeichert werden: \(error.localizedDescription)"
        }
    }
}

private struct DesignCheckResult: Codable, Identifiable {
    let index: Int
    let name: String
    let location: String
    let passed: Bool
    let detail: String
    var id: Int { index }
}

private struct DesignDeviceReport: Codable {
    let schemaVersion: Int
    let testType: String
    let limitation: String
    let timestamp: String
    let device: String
    let iosVersion: String
    let appVersion: String
    let buildRevision: String
    let passed: Int
    let failed: Int
    let checks: [DesignCheckResult]
}

private struct DeviceTestShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
#endif
