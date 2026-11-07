import SwiftUI
import Observation
import Foundation

/// One genuine player observation. Deliberately excludes titles, IDs,
/// file paths, stream URLs, account metadata and private diagnostic logs.
struct AutomixLiveSample: Codable {
    let second: Int
    let playing: Bool
    let buffering: Bool
    let progressed: Bool
    let position: Double
    let duration: Double
    let automixEnabled: Bool
    let planRevision: UInt64
    let transitionRevision: UInt64
    let engineTransitionActive: Bool
    let analysisSource: String
    let analysisStyle: String
    let playbackErrorPresent: Bool
}

@MainActor
@Observable
final class AutomixLiveTestMonitor {
    static let shared = AutomixLiveTestMonitor()
    private(set) var running = false
    private(set) var startedAt: Date?
    private(set) var samples: [AutomixLiveSample] = []
    private(set) var progressObserved = false
    private(set) var plansObserved = 0
    private(set) var transitionsObserved = 0
    private(set) var onnxObserved = false
    private(set) var coreMLObserved = false
    private(set) var vocalsObserved = false
    private(set) var lastPlanSource: String?
    private(set) var runtime = AutomixRuntimeSnapshot(
        beatReady: false, vocalsRequested: false, coreMLLoaded: false,
        configuredAt: nil
    )
    private(set) var message: String?

    @ObservationIgnored private var sampleTask: Task<Void, Never>?
    @ObservationIgnored private var basePlan: UInt64 = 0
    @ObservationIgnored private var baseTransition: UInt64 = 0
    @ObservationIgnored private var observedPlanRevision: UInt64 = 0
    @ObservationIgnored private var lastTrackID: String?
    @ObservationIgnored private var lastPosition: Double?

    private init() {}

    func start(controller: PlaybackController) {
        stop()
        startedAt = Date()
        samples = []
        progressObserved = false
        plansObserved = 0
        transitionsObserved = 0
        onnxObserved = false
        coreMLObserved = false
        vocalsObserved = false
        lastPlanSource = nil
        message = nil
        lastTrackID = nil
        lastPosition = nil
        basePlan = controller.automixPlanRevision
        baseTransition = controller.automixTransitionRevision
        observedPlanRevision = basePlan
        running = true
        // This monitor observes the real user queue without starting, stopping,
        // muting, seeking or replacing any audio.
        sampleTask = Task { @MainActor [weak self, weak controller] in
            while !Task.isCancelled {
                guard let self, self.running, let controller else { return }
                self.record(controller: controller)
                self.runtime = await AutomixModelLoader.shared.snapshot()
                if self.samples.count >= 300 {
                    self.message = "Fünf Minuten aufgezeichnet. Der Test wurde automatisch beendet."
                    self.stop()
                    return
                }
                do { try await Task.sleep(for: .seconds(1)) }
                catch { return }
            }
        }
    }

    func stop() {
        running = false
        sampleTask?.cancel()
        sampleTask = nil
    }

    private func record(controller: PlaybackController) {
        guard let startedAt else { return }
        let currentID = controller.current?.id
        let position = max(0, controller.position)
        if currentID == lastTrackID, let prior = lastPosition,
           controller.isPlaying, !controller.isBuffering,
           position.isFinite, position > prior + 0.25 {
            progressObserved = true
        }
        lastTrackID = currentID
        lastPosition = position

        if controller.automixPlanRevision > observedPlanRevision {
            observedPlanRevision = controller.automixPlanRevision
            plansObserved = Int(controller.automixPlanRevision - basePlan)
            let source = controller.analysisSources ?? ""
            lastPlanSource = source.isEmpty ? nil : source
            onnxObserved = onnxObserved || source.contains("[beat:rten]")
            coreMLObserved = coreMLObserved || source.contains("[beat:coreml]")
            vocalsObserved = vocalsObserved || source.contains("[vocals:open_unmix]")
        }
        transitionsObserved = Int(
            controller.automixTransitionRevision >= baseTransition
                ? controller.automixTransitionRevision - baseTransition : 0
        )
        let item = AutomixLiveSample(
            second: Int(Date().timeIntervalSince(startedAt)),
            playing: controller.isPlaying,
            buffering: controller.isBuffering,
            progressed: progressObserved,
            position: position.isFinite ? position : 0,
            duration: controller.duration.isFinite ? max(0, controller.duration) : 0,
            automixEnabled: controller.automixEnabled,
            planRevision: controller.automixPlanRevision,
            transitionRevision: controller.automixTransitionRevision,
            engineTransitionActive: controller.smartMixInProgress,
            analysisSource: lastPlanSource ?? "",
            analysisStyle: controller.analysisTier ?? "",
            playbackErrorPresent: controller.lastError != nil
        )
        samples.append(item)
    }

    /// A privacy-minimal on-device report. Saving never sends anything;
    /// the user decides whether to share the resulting file.
    func saveReport() throws -> URL {
        struct Model: Codable {
            let name: String
            let installedPinned: Bool
            let usablePreviousVersion: Bool
        }
        struct Report: Codable {
            let version: Int
            let startedAt: Date?
            let endedAt: Date
            let modelState: [Model]
            let beatRuntimeReady: Bool
            let vocalRuntimeRequested: Bool
            let coreMLRuntimeLoaded: Bool
            let playedProgressed: Bool
            let newPlans: Int
            let transitionsReportedByEngine: Int
            let onnxPlanObserved: Bool
            let coreMLPlanObserved: Bool
            let vocalModelPlanObserved: Bool
            let samples: [AutomixLiveSample]
            let notice: String
        }
        let store = AutomixModelStore.shared
        let payload = Report(
            version: 1, startedAt: startedAt, endedAt: Date(),
            modelState: AutomixModelStore.ModelID.allCases.map { id in
                Model(name: id.rawValue, installedPinned: store.status(of: id).isInstalled,
                      usablePreviousVersion: store.isUsingPreviousGraph(id))
            },
            beatRuntimeReady: runtime.beatReady,
            vocalRuntimeRequested: runtime.vocalsRequested,
            coreMLRuntimeLoaded: runtime.coreMLLoaded,
            playedProgressed: progressObserved,
            newPlans: plansObserved,
            transitionsReportedByEngine: transitionsObserved,
            onnxPlanObserved: onnxObserved,
            coreMLPlanObserved: coreMLObserved,
            vocalModelPlanObserved: vocalsObserved,
            samples: samples,
            notice: "Engine-Meldungen und Zeitfortschritt sind kein Nachweis fuer hoerbare Audioausgabe."
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("BBT-Bit-Automix-Livetest.json")
        try encoder.encode(payload).write(to: url, options: .atomic)
        return url
    }
}

/// An in-app test that can run alongside ordinary playback and continue when
/// the listener navigates away. No synthetic track and no extra audio engine.
struct AutomixLiveTestView: View {
    @Environment(PlaybackController.self) private var controller
    private let store = AutomixModelStore.shared
    private let monitor = AutomixLiveTestMonitor.shared

    @State private var checkingHashes = false
    @State private var hashResults: [AutomixModelStore.ModelID: String] = [:]
    @State private var reportURL: URL?
    @State private var exportError: String?

    var body: some View {
        Form {
            Section {
                Text("Teste die drei KI-Modelle während du BBT-Bit normal benutzt. Du kannst diese Seite verlassen: Die Aufzeichnung läuft bis zum Stoppen oder maximal fünf Minuten weiter. Es wird kein Song gestartet oder deine Queue verändert.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button {
                    if monitor.running {
                        monitor.stop()
                    } else {
                        reportURL = nil
                        exportError = nil
                        monitor.start(controller: controller)
                    }
                } label: {
                    Label(monitor.running ? "Livetest stoppen" : "Livetest starten",
                          systemImage: monitor.running ? "stop.circle" : "record.circle")
                }
                .accessibilityIdentifier("bbt.automixLive.toggle")
                if monitor.running {
                    Label("Aufzeichnung läuft – auch beim Wechsel zu anderen App-Seiten",
                          systemImage: "record.circle")
                        .foregroundStyle(.secondary)
                } else if monitor.startedAt != nil {
                    Label("Aufzeichnung beendet", systemImage: "checkmark.circle")
                        .foregroundStyle(.secondary)
                }
                if let message = monitor.message {
                    Text(message).font(.footnote).foregroundStyle(.secondary)
                }
                LabeledContent("Messpunkte", value: "\(monitor.samples.count)")
                LabeledContent("Maximale Laufzeit", value: "5 Minuten")
            } header: {
                Text("Livetest")
            }

            Section {
                ForEach(AutomixModelStore.ModelID.allCases) { id in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(modelName(id)).font(.subheadline.weight(.semibold))
                        LabeledContent("Datei", value: installedText(id))
                        LabeledContent("Echte Analyse", value: inferredText(id))
                        if let result = hashResults[id] {
                            Text(result).font(.footnote).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                Button {
                    Task { await verifyAll() }
                } label: {
                    if checkingHashes {
                        HStack(spacing: 8) {
                            ProgressView().controlSize(.small)
                            Text("SHA-256 wird geprüft …")
                        }
                    } else {
                        Label("Alle drei SHA-256-Dateien prüfen",
                              systemImage: "checkmark.shield")
                    }
                }
                .disabled(checkingHashes || store.anyBusy)
                .accessibilityIdentifier("bbt.automixLive.verifyHashes")
                NavigationLink("Modelle herunterladen oder verwalten") {
                    AutomixModelsPage()
                }
            } header: {
                Text("Drei KI-Modelle")
            } footer: {
                Text("„Installiert“ bedeutet auf Datenträger geprüft, nicht automatisch in der letzten Analyse verwendet. Eine Core-ML-Datei kann installiert sein, ohne dass eine Core-ML-Inferenz ausgeführt wurde. Die Prüfsummenprüfung liest die Dateien erneut.")
            }

            Section {
                LabeledContent("Automix", value: controller.automixEnabled ? "Ein" : "Aus")
                LabeledContent("Analyse im Rust-Player", value: monitor.plansObserved > 0
                               ? "\(monitor.plansObserved) neue Planung(en)" : "Noch nicht nachgewiesen")
                LabeledContent("Analysequelle", value: monitor.lastPlanSource ?? "Noch kein neuer Plan seit Testbeginn")
                LabeledContent("Geplanter Übergang", value: controller.analysisTier ?? "Noch keiner")
                LabeledContent("Start des Übergangs", value: monitor.transitionsObserved > 0
                               ? "\(monitor.transitionsObserved) Engine-Meldung(en)" : "Noch nicht gemeldet")
                LabeledContent("Wiedergabezeit läuft", value: monitor.progressObserved
                               ? "Ja, Fortschritt beobachtet" : "Noch nicht nachgewiesen")
                if let reason = controller.transitionReason, !reason.isEmpty {
                    Text("Planer: \(reason)").font(.footnote).foregroundStyle(.secondary)
                }
                TimelineView(.periodic(from: .now, by: 1)) { _ in
                    LabeledContent("Aktuelle Position", value: String(
                        format: "%.1f / %.1f s",
                        max(0, controller.position),
                        max(0, controller.duration)
                    ))
                }
            } header: {
                Text("Echter Player-Status")
            } footer: {
                Text("Die Anzeige liest echte Analyse- und Übergangsereignisse aus dem Rust-/Swift-Player. Ein gemeldeter Übergang oder fortschreitender Zeitwert beweist noch keine hörbare Audioausgabe. Bitte den Klang selbst auf dem iPhone prüfen.")
            }

            Section {
                Button("Lokalen Testbericht speichern") {
                    do {
                        reportURL = try monitor.saveReport()
                        exportError = nil
                    } catch {
                        exportError = "Bericht konnte nicht gespeichert werden: \(error.localizedDescription)"
                    }
                }
                .disabled(monitor.samples.isEmpty)
                .accessibilityIdentifier("bbt.automixLive.saveReport")
                if let reportURL {
                    ShareLink("Testbericht teilen", item: reportURL)
                        .accessibilityIdentifier("bbt.automixLive.shareReport")
                }
                if let exportError {
                    Text(exportError).font(.footnote).foregroundStyle(.secondary)
                }
            } header: {
                Text("Ergebnis")
            } footer: {
                Text("Der Bericht enthält nur technische Statuswerte und Messpunkte. Keine Songtitel, YouTube-IDs, Dateipfade oder Zugangsdaten. Erst beim Teilen wird er von deinem Gerät weitergegeben.")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Automix-Livetest")
        .task {
            await store.refresh()
        }
    }

    private func modelName(_ id: AutomixModelStore.ModelID) -> String {
        switch id {
        case .beat: return "Beat + Downbeat"
        case .beatCoreML: return "Accelerated Beat · Core ML"
        case .vocals: return "Vocal + Clash"
        }
    }

    private func installedText(_ id: AutomixModelStore.ModelID) -> String {
        switch store.status(of: id) {
        case .installed: return "Installiert · bei Installation geprüft"
        case .outdated: return "Nur ältere Version verfügbar"
        case .notInstalled: return "Nicht installiert"
        case .paused: return "Download unterbrochen"
        case .downloading: return "Wird heruntergeladen"
        case .verifying: return "Prüfung läuft"
        case .blockedByWifi: return "Wartet auf WLAN"
        case .failed: return "Fehler – Details in Automix Models"
        }
    }

    private func inferredText(_ id: AutomixModelStore.ModelID) -> String {
        switch id {
        case .beat:
            if monitor.onnxObserved { return "ONNX bei neuer Planung benutzt" }
            if monitor.coreMLObserved { return "Beat-Modell über Core ML benutzt" }
            if monitor.runtime.beatReady { return "Rust geladen; noch keine Inferenz nachgewiesen" }
        case .beatCoreML:
            if monitor.coreMLObserved { return "Core ML bei neuer Planung benutzt" }
            if monitor.runtime.coreMLLoaded { return "Core ML geladen; Inferenz noch offen" }
        case .vocals:
            if monitor.vocalsObserved { return "Open-Unmix in neuer Planung benutzt" }
            if monitor.runtime.vocalsRequested { return "Von Rust angefordert; Inferenz noch offen" }
        }
        return "Noch nicht nachgewiesen"
    }

    private func verifyAll() async {
        guard !checkingHashes else { return }
        checkingHashes = true
        defer { checkingHashes = false }
        for id in AutomixModelStore.ModelID.allCases {
            // verify() can report an old fallback as usable: only .installed
            // proves the checksum of the *current* pinned artifact.
            _ = await store.verify(id)
            hashResults[id] = store.status(of: id).isInstalled
                ? "SHA-256 und Dateigröße der aktuellen Version bestätigt"
                : "Aktuelle SHA-256-Datei nicht bestätigt"
        }
    }
}
