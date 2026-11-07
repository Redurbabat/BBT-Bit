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
    let networkConnected: Bool
    let queueIndexValid: Bool
    let sourceLoaded: Bool
    let decoderReported: Bool
    let outputDeviceStarted: Bool
    let audioSessionActive: Bool?
}

enum BBTManualTest: String, CaseIterable, Identifiable {
    case audibleAudio, pauseAndResume, nextAndPrevious, shuffleAndRepeat
    case automixSound, searchAndDiscover, homeAndLibrary, playlistsAndFavorites
    case downloadsAndOffline, musicVideosAndLyrics, backgroundAndLockScreen
    case bluetoothAndAudioRoute, accessibilityAndGlass, partyAndSync

    var id: String { rawValue }
    var name: String {
        switch self {
        case .audibleAudio: return "Ton tatsächlich hörbar"
        case .pauseAndResume: return "Pause und Fortsetzen"
        case .nextAndPrevious: return "Nächster / vorheriger Song"
        case .shuffleAndRepeat: return "Shuffle und Wiederholen"
        case .automixSound: return "Crossfade wirklich hörbar"
        case .searchAndDiscover: return "Suche und Entdecken"
        case .homeAndLibrary: return "Startseite und Bibliothek"
        case .playlistsAndFavorites: return "Playlists, Favoriten, Verlauf"
        case .downloadsAndOffline: return "Downloads und Offline-Wiedergabe"
        case .musicVideosAndLyrics: return "Musikvideos und Liedtexte"
        case .backgroundAndLockScreen: return "Sperrbildschirm und Hintergrund"
        case .bluetoothAndAudioRoute: return "Bluetooth, Kopfhörer, Audio-Routen"
        case .accessibilityAndGlass: return "Liquid Glass, VoiceOver, große Schrift"
        case .partyAndSync: return "Listen Together und Synchronisation"
        }
    }
    var instruction: String {
        switch self {
        case .audibleAudio: return "Höre einen echten Song über Lautsprecher/Kopfhörer."
        case .pauseAndResume: return "Pausiere und starte denselben Song erneut."
        case .nextAndPrevious: return "Wechsle vor und zurück; prüfe Titel und hörbaren Ton."
        case .shuffleAndRepeat: return "Teste Zufall, Repeat One und Repeat All mit deiner Queue."
        case .automixSound: return "Höre beide Quellen beim Übergang ohne Knacken oder Lücke."
        case .searchAndDiscover: return "Suche echte Musik und öffne ein Suchergebnis."
        case .homeAndLibrary: return "Öffne Start, Entdecken und deine Bibliothek."
        case .playlistsAndFavorites: return "Speichere und entferne einen Test-Favoriten und prüfe den Verlauf."
        case .downloadsAndOffline: return "Teste einen vorhandenen Offline-Song im Flugmodus."
        case .musicVideosAndLyrics: return "Öffne ein Musikvideo und synchronisierte Liedtexte."
        case .backgroundAndLockScreen: return "Sperre das iPhone und prüfe Play/Pause und Fortschritt."
        case .bluetoothAndAudioRoute: return "Wechsle zu AirPods/Bluetooth oder USB und höre weiter."
        case .accessibilityAndGlass: return "Prüfe Dark Mode, Kontrast, VoiceOver und größere Schrift."
        case .partyAndSync: return "Teste Listen Together nur mit einem zweiten Gerät."
        }
    }
}

enum BBTManualVerdict: String, CaseIterable {
    case open = "Nicht getestet"
    case pass = "Bestanden"
    case fail = "Fehler"
}

@MainActor
@Observable
final class AutomixLiveTestMonitor {
    static let shared = AutomixLiveTestMonitor()
    private(set) var running = false
    private(set) var startedAt: Date?
    private(set) var samples: [AutomixLiveSample] = []
    private(set) var progressObserved = false
    private(set) var outputObserved = false
    private(set) var decoderObserved = false
    private(set) var validQueueObserved = false
    private(set) var networkObserved = false
    private(set) var sessionObserved = false
    private(set) var playbackErrorObserved = false
    private(set) var manualVerdicts: [BBTManualTest: BBTManualVerdict] = [:]
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
        outputObserved = false
        decoderObserved = false
        validQueueObserved = false
        networkObserved = false
        sessionObserved = false
        playbackErrorObserved = false
        manualVerdicts = [:]
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
                if Date().timeIntervalSince(self.startedAt ?? Date()) >= 30 * 60 {
                    self.message = "30 Minuten aufgezeichnet. Der Test wurde automatisch beendet."
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

    func setManual(_ test: BBTManualTest, verdict: BBTManualVerdict) {
        manualVerdicts[test] = verdict
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
        let queueValid = controller.queue.isEmpty
            ? controller.current == nil
            : controller.queue.indices.contains(controller.playingIndex)
        let outputStarted = controller.outputDevice.started
        let decoderReported = controller.nerd?.codec.isEmpty == false
        let sourceLoaded = controller.settingsAudioReadout.loaded
        let networkConnected = NetworkQuality.shared.connected
        #if os(iOS)
        let audioSessionActive: Bool? = AudioSessionManager.isActive
        #else
        let audioSessionActive: Bool? = nil
        #endif
        outputObserved = outputObserved || (controller.isPlaying && outputStarted)
        decoderObserved = decoderObserved || (controller.isPlaying && decoderReported)
        validQueueObserved = validQueueObserved || (controller.current != nil && queueValid)
        networkObserved = networkObserved || networkConnected
        sessionObserved = sessionObserved || (audioSessionActive == true)
        playbackErrorObserved = playbackErrorObserved || controller.lastError != nil
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
            playbackErrorPresent: controller.lastError != nil,
            networkConnected: networkConnected,
            queueIndexValid: queueValid,
            sourceLoaded: sourceLoaded,
            decoderReported: decoderReported,
            outputDeviceStarted: outputStarted,
            audioSessionActive: audioSessionActive
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
            let manualChecks: [String: String]
            let nativeAudioOutputObserved: Bool
            let decoderObserved: Bool
            let queueWasValid: Bool
            let internetStatusObserved: Bool
            let audioSessionObserved: Bool
            let playbackErrorObserved: Bool
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
            manualChecks: Dictionary(uniqueKeysWithValues:
                BBTManualTest.allCases.map { ($0.rawValue, (manualVerdicts[$0] ?? .open).rawValue) }
            ),
            nativeAudioOutputObserved: outputObserved,
            decoderObserved: decoderObserved,
            queueWasValid: validQueueObserved,
            internetStatusObserved: networkObserved,
            audioSessionObserved: sessionObserved,
            playbackErrorObserved: playbackErrorObserved,
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
            notice: "Automatische Statuswerte beweisen keine hoerbare Wiedergabe. Manuelle Tests stammen vom Benutzer; Build, Signierung und IPA sind nicht auf dem iPhone testbar."
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
                Text("Prüfe BBT-Bit während der normalen Nutzung: KI-Modelle, Audiopfad, Queue, Streaming, Übergänge und App-Funktionen. Verlasse die Seite und nutze die App weiter. Die Aufzeichnung endet nach spätestens 30 Minuten. Deine Queue und Wiedergabe werden durch den Monitor nicht verändert.")
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
                LabeledContent("Maximale Laufzeit", value: "30 Minuten")
                Text("Im Hintergrund kann iOS die App pausieren. Aufzeichnung läuft nur, solange die App tatsächlich ausgeführt wird.")
                    .font(.caption).foregroundStyle(.secondary)
            } header: {
                Text("BBT-Bit-Livetest")
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
                LabeledContent("Geplanter Übergang", value: monitor.plansObserved > 0
                               ? (controller.analysisTier ?? "—") : "Noch keine neue Planung seit Testbeginn")
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
                LabeledContent("Queue-Index", value:
                    monitor.validQueueObserved ? "Gültige Queue beobachtet" : "Noch nicht geprüft")
                LabeledContent("Stream / Decoder", value:
                    monitor.decoderObserved ? "Decoder gemeldet" : "Noch nicht bestätigt")
                LabeledContent("Nativer Ausgabestream", value:
                    monitor.outputObserved ? "Aktiv gemeldet" : "Noch nicht bestätigt")
                LabeledContent("Netzwerkstatus", value:
                    NetworkQuality.shared.connected ? "Verbunden gemeldet" : "Nicht verbunden")
                #if os(iOS)
                LabeledContent("iPhone-Audiositzung", value:
                    AudioSessionManager.isActive ? "Aktiv" : "Inaktiv")
                #endif
                LabeledContent("Playback-Fehler während Test", value:
                    monitor.playbackErrorObserved ? "Mindestens einer registriert" : "Keiner beobachtet")
                NavigationLink("Audio-Pipeline und DSP ansehen") {
                    AudioPipelineSheet()
                }
                NavigationLink("Musik- und Streamdiagnose ansehen") {
                    DiagnosticReportsView()
                }
                #if os(iOS)
                NavigationLink("15 Liquid-Motion-Designs automatisch prüfen") {
                    LiquidMotionDeviceSelfTestView()
                }
                #endif
            } header: {
                Text("Automatische App-Prüfung")
            } footer: {
                Text("Dies sind echte Zustandsmeldungen, keine künstlichen Testergebnisse. Ein offener Ausgabestream und ein laufender Zeitwert beweisen keinen hörbaren Ton. Ein noch nicht beobachteter Zustand ist kein automatischer Fehler.")
            }

            Section {
                ForEach(BBTManualTest.allCases) { test in
                    VStack(alignment: .leading, spacing: 5) {
                        Text(test.name).font(.subheadline.weight(.medium))
                        Text(test.instruction).font(.caption).foregroundStyle(.secondary)
                        Picker(test.name, selection: Binding(
                            get: { monitor.manualVerdicts[test] ?? .open },
                            set: { monitor.setManual(test, verdict: $0) }
                        )) {
                            Text("Offen").tag(BBTManualVerdict.open)
                            Text("Bestanden").tag(BBTManualVerdict.pass)
                            Text("Fehler").tag(BBTManualVerdict.fail)
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        .accessibilityIdentifier("bbt.fullTest.\(test.rawValue)")
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("Manuelle Tests – alle App-Bereiche")
            } footer: {
                Text("Du markierst nur tatsächlich selbst ausgeführte Tests als bestanden. Diese Auswahl startet keine Funktion und ändert weder Account noch Wiedergabe. Mit ‚Fehler‘ kannst du Probleme im Bericht kennzeichnen.")
            }

            Section {
                LabeledContent("Swift / iPhone-Simulator", value: "Extern prüfen")
                LabeledContent("GitHub Actions / Codemagic", value: "Extern prüfen")
                LabeledContent("Signierte IPA", value: "Extern prüfen")
                LabeledContent("Musik tatsächlich hörbar", value:
                    (monitor.manualVerdicts[.audibleAudio] ?? .open).rawValue)
                Text("Compiler, Xcode-Simulator, GitHub-CI und Codesignierung laufen nicht in dieser iPhone-App. Dafür sind externe Builds und Hardwareprüfungen notwendig.")
                    .font(.footnote).foregroundStyle(.secondary)
            } header: {
                Text("Weitere notwendige Nachweise")
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
                Text("Der Bericht enthält technische Statuswerte und deine manuellen Ergebnisse, aber keine Songtitel, YouTube-IDs, Dateipfade oder Zugangsdaten. Er bleibt lokal, bis du ihn ausdrücklich teilst.")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("BBT-Bit Testzentrale")
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
