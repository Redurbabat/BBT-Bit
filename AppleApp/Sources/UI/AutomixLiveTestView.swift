import SwiftUI
import Observation
import Foundation
import BitChordShared

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
    let automixPerformanceMode: String
    let planRevision: UInt64
    let transitionRevision: UInt64
    let engineTransitionActive: Bool
    let analysisSource: String
    let analysisStyle: String
    let playbackErrorPresent: Bool
    let playbackErrorKind: PlaybackDiagnosticFailure?
    let appErrorPresent: Bool
    let networkConnected: Bool
    let queueIndexValid: Bool
    let sourceLoaded: Bool
    let decoderReported: Bool
    let outputDeviceStarted: Bool
    let audioSessionActive: Bool?
}

struct AppTestModelCheck: Codable {
    let passed: Bool
    let checkedAt: Date
}

@MainActor
@Observable
final class AutomixLiveTestMonitor {
    static let shared = AutomixLiveTestMonitor()
    private(set) var running = false
    private(set) var startedAt: Date?
    private(set) var endedAt: Date?
    private(set) var sessionID = UUID()
    private(set) var lastSavedAt: Date?
    private(set) var storageError: String?
    private(set) var modelChecks: [String: AppTestModelCheck] = [:]
    private(set) var samples: [AutomixLiveSample] = []
    private(set) var progressObserved = false
    private(set) var outputObserved = false
    private(set) var decoderObserved = false
    private(set) var validQueueObserved = false
    private(set) var networkObserved = false
    private(set) var sessionObserved = false
    private(set) var playbackErrorObserved = false
    private(set) var appErrorObserved = false
    private(set) var engineBuildRevision = "unknown"
    private(set) var automaticResults: [AppAutomaticCheck: AppTestCheckResult] = [:]
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
    @ObservationIgnored private var progressTracker = PlaybackProgressTracker()
    @ObservationIgnored private let archive: AppTestReportStore
    @ObservationIgnored private var modelTask: Task<Void, Never>?
    @ObservationIgnored private var designTask: Task<Void, Never>?
    @ObservationIgnored private var previousTrackID: String?
    @ObservationIgnored private var pausedTrackID: String?
    @ObservationIgnored private var changedTrackID: String?
    @ObservationIgnored private var wasPlaying = false
    @ObservationIgnored private var inBackground = false
    @ObservationIgnored private var routePending = false
    @ObservationIgnored private var sampling = false
    @ObservationIgnored private var needsCheckpoint = false
    @ObservationIgnored private var completedDownloads: Set<String> = []
    @ObservationIgnored private var modelsChecking = false

    init(archive: AppTestReportStore) { self.archive = archive }
    convenience init() { self.init(archive: .shared) }

    func start(controller: PlaybackController, locale: Locale = .current) {
        guard !running else { return }
        if startedAt != nil {
            do { _ = try saveReport() } catch { return }
        }
        sessionID = UUID(); endedAt = nil; lastSavedAt = nil; storageError = nil
        startedAt = Date()
        samples = []
        progressObserved = false
        outputObserved = false
        decoderObserved = false
        validQueueObserved = false
        networkObserved = false
        sessionObserved = false
        playbackErrorObserved = false
        appErrorObserved = false
        engineBuildRevision = "unknown"
        automaticResults = [:]; previousTrackID = nil; pausedTrackID = nil; changedTrackID = nil
        wasPlaying = false; inBackground = false; routePending = false
        modelChecks = [:]
        modelsChecking = false
        completedDownloads = Set(DownloadStore.shared.jobs.filter { $0.status == .done }.map(\.id))
        plansObserved = 0
        transitionsObserved = 0
        onnxObserved = false
        coreMLObserved = false
        vocalsObserved = false
        lastPlanSource = nil
        message = nil
        runtime = AutomixRuntimeSnapshot(beatReady: false, vocalsRequested: false, coreMLLoaded: false, configuredAt: nil)
        progressTracker = PlaybackProgressTracker()
        basePlan = controller.automixPlanRevision
        baseTransition = controller.automixTransitionRevision
        observedPlanRevision = basePlan
        running = true
        AppTestEvents.start(sessionID) { [weak self] check, outcome, code in
            self?.note(check, outcome, code)
        }
        record(controller: controller)
        checkpoint()
        scheduleModelChecks()
        #if os(iOS)
        designTask = Task { await AppTestDesignSmoke.run(controller: controller, locale: locale) }
        if #available(iOS 26, *) {} else { note(.dockInline, .unavailable, .platformUnsupported) }
        #else
        note(.designPreviews, .unavailable, .platformUnsupported)
        note(.dockInline, .unavailable, .platformUnsupported)
        #endif
        let run = sessionID
        // Nur beobachten: Queue, Lautstärke und Wiedergabe bleiben beim Player.
        sampleTask = Task { @MainActor [weak self, weak controller] in
            while !Task.isCancelled {
                do { try await Task.sleep(for: .seconds(1)) } catch { return }
                guard let self, self.running, self.sessionID == run, let controller else { return }
                if Date().timeIntervalSince(self.startedAt ?? Date()) >= 30 * 60 {
                    self.message = "Zeitlimit erreicht. Der Test wurde automatisch beendet."
                    self.stop()
                    return
                }
                self.record(controller: controller)
                let snapshot = await AutomixModelLoader.shared.snapshot()
                guard !Task.isCancelled, self.running, self.sessionID == run else { return }
                self.runtime = snapshot
                if self.samples.count % 30 == 0 { self.checkpoint(); self.scheduleModelChecks() }
            }
        }
    }

    func stop() {
        guard running else { return }
        running = false
        endedAt = Date()
        sampleTask?.cancel()
        sampleTask = nil
        modelTask?.cancel(); modelTask = nil
        designTask?.cancel(); designTask = nil
        AppTestEvents.stop(sessionID)
        checkpoint()
    }

    func setModelCheck(_ id: String, passed: Bool) {
        guard AutomixModelStore.ModelID.allCases.contains(where: { $0.rawValue == id }) else { return }
        modelChecks[id] = AppTestModelCheck(passed: passed, checkedAt: Date())
        checkpoint()
    }

    func result(_ check: AppAutomaticCheck) -> AppTestCheckResult {
        automaticResults[check] ?? AppTestCheckResult(id: check)
    }

    private func note(_ check: AppAutomaticCheck, _ outcome: AppTestOutcome, _ code: AppTestEvidenceCode) {
        guard running else { return }
        let previous = result(check)
        var updated = previous
        updated.record(outcome, code: code, at: Date())
        automaticResults[check] = updated
        if check == .audioRoute, code == .routeChanged { routePending = true }
        if previous.status != updated.status {
            if sampling { needsCheckpoint = true } else { checkpoint() }
        }
    }

    func applicationBackgroundChanged(_ background: Bool) {
        guard running else { return }
        inBackground = background
        if background { note(.backgroundPlayback, .observation, .backgroundEntered) }
    }

    private func scheduleModelChecks() {
        guard running, !modelsChecking else { return }
        let run = sessionID
        modelTask = Task { [weak self] in
            guard let self else { return }; await self.verifyModels(run: run)
        }
    }

    private func verifyModels(run: UUID) async {
        guard running, sessionID == run, !modelsChecking else { return }
        modelsChecking = true
        defer { if sessionID == run { modelsChecking = false } }
        let store = AutomixModelStore.shared
        for id in AutomixModelStore.ModelID.allCases {
            guard !Task.isCancelled, running, sessionID == run else { return }
            let check: AppAutomaticCheck
            switch id { case .beat: check = .beatFile; case .beatCoreML: check = .coreMLFile; case .vocals: check = .vocalFile }
            if result(check).status == .passed || result(check).status == .failed { continue }
            if store.anyBusy { note(check, .observation, .modelBusy); continue }
            let installed = store.status(of: id).isInstalled
            guard installed || store.isUsingPreviousGraph(id) else {
                note(check, .unavailable, .fileMissing); continue
            }
            note(check, .observation, .pending)
            _ = await store.verify(id)
            guard !Task.isCancelled, running, sessionID == run else { return }
            let verified = store.status(of: id).isInstalled
            setModelCheck(id.rawValue, passed: verified)
            note(check, verified ? .success : (installed ? .failure : .unavailable),
                verified ? .fileVerified : (installed ? .integrityFailed : .fileMissing))
        }
    }

    func checkpoint() {
        guard startedAt != nil else { return }
        do { _ = try saveReport() } catch { }
    }

    private func record(controller: PlaybackController) {
        guard running, let startedAt, samples.count < 1800 else { return }
        sampling = true
        defer { sampling = false; if needsCheckpoint { needsCheckpoint = false; checkpoint() } }
        let currentID = controller.current?.id
        let position = controller.position
        let progressed = progressTracker.observe(
            trackID: currentID, position: position,
            at: ProcessInfo.processInfo.systemUptime,
            playing: controller.isPlaying, buffering: controller.isBuffering
        )
        progressObserved = progressObserved || progressed

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
        if let revision = controller.nerd?.buildRevision { engineBuildRevision = revision }
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
        playbackErrorObserved = playbackErrorObserved || controller.lastPlaybackFailure != nil
        appErrorObserved = appErrorObserved || controller.lastError != nil
        let configuredMode = PlatformSettings.shared.getString(key: "automix_performance", default: "BALANCED")
        let performanceMode = ["EFFICIENT", "BALANCED", "PERFORMANCE"].contains(configuredMode)
            ? configuredMode : "BALANCED"
        let item = AutomixLiveSample(
            second: Int(Date().timeIntervalSince(startedAt)),
            playing: controller.isPlaying,
            buffering: controller.isBuffering,
            progressed: progressed,
            position: position.isFinite ? max(0, position) : 0,
            duration: controller.duration.isFinite ? max(0, controller.duration) : 0,
            automixEnabled: controller.automixEnabled,
            automixPerformanceMode: performanceMode,
            planRevision: controller.automixPlanRevision,
            transitionRevision: controller.automixTransitionRevision,
            engineTransitionActive: controller.smartMixInProgress,
            analysisSource: lastPlanSource ?? "",
            analysisStyle: controller.analysisTier ?? "",
            playbackErrorPresent: controller.lastPlaybackFailure != nil,
            playbackErrorKind: controller.lastPlaybackFailure,
            appErrorPresent: controller.lastError != nil,
            networkConnected: networkConnected,
            queueIndexValid: queueValid,
            sourceLoaded: sourceLoaded,
            decoderReported: decoderReported,
            outputDeviceStarted: outputStarted,
            audioSessionActive: audioSessionActive
        )
        samples.append(item)
        if !controller.queue.isEmpty || controller.current != nil {
            note(.queueIntegrity, queueValid && controller.current != nil ? .success : .failure,
                queueValid && controller.current != nil ? .validState : .invalidState)
        }
        if progressed {
            note(.playbackProgress, .success, .positionAdvanced)
            if pausedTrackID == currentID { note(.pauseResume, .success, .positionAdvanced); pausedTrackID = nil }
            if changedTrackID == currentID { note(.trackChange, .success, .positionAdvanced); changedTrackID = nil }
            if !networkConnected, sourceLoaded, let path = controller.loadedSourcePath,
               path.hasPrefix("/") || path.hasPrefix("file:") { note(.offlinePlayback, .success, .positionAdvanced) }
            if inBackground { note(.backgroundPlayback, .success, .positionAdvanced) }
            if routePending, outputStarted { note(.audioRoute, .success, .positionAdvanced); routePending = false }
        }
        if wasPlaying, !controller.isPlaying, !controller.isBuffering { pausedTrackID = currentID }
        if let previousTrackID, previousTrackID != currentID { changedTrackID = currentID }
        previousTrackID = currentID; wasPlaying = controller.isPlaying
        if controller.isPlaying, decoderReported { note(.decoder, .success, .validState) }
        if controller.isPlaying, outputStarted { note(.outputStream, .success, .validState) }
        if audioSessionActive == true { note(.audioSession, .success, .validState) }
        if audioSessionActive == nil, result(.audioSession).observations == 0 { note(.audioSession, .unavailable, .platformUnsupported) }
        note(.networkStatus, .success, .validState)
        if controller.lastPlaybackFailure != nil {
            if result(.playbackErrors).failures == 0 { note(.playbackErrors, .failure, .failureReported) }
        } else { note(.playbackErrors, .success, .validState) }
        if controller.lastError != nil {
            if result(.appErrors).failures == 0 { note(.appErrors, .failure, .failureReported) }
        } else { note(.appErrors, .success, .validState) }
        if plansObserved > 0 { note(.automixPlan, .success, .validState) }
        if transitionsObserved > 0 { note(.automixTransition, .success, .validState) }
        if !controller.lyrics.isEmpty, !controller.lyricsLoading { note(.lyrics, .success, .responseReceived) }
        let done = Set(DownloadStore.shared.jobs.filter { $0.status == .done }.map(\.id))
        if !done.subtracting(completedDownloads).isEmpty { note(.downloads, .success, .fileVerified) }
        completedDownloads.formUnion(done)
    }

    /// Gemeinsame Berichtsdaten für Zwischenstand, Abschluss und Datei-Export.
    func reportData() throws -> Data {
        guard let startedAt else { throw AppTestReportError.noSession }
        struct Model: Codable {
            let name: String
            let installedPinned: Bool
            let usablePreviousVersion: Bool
        }
        struct Report: Codable {
            let version: Int
            let automaticChecks: [AppTestCheckResult]
            let summary: AppTestSessionSummary
            let appVersion: String
            let buildNumber: String
            let buildRevision: String
            let engineBuildRevision: String
            let operatingSystem: String
            let startedAt: Date?
            let endedAt: Date?
            let modelIntegrityChecks: [String: AppTestModelCheck]
            let modelState: [Model]
            let nativeAudioOutputObserved: Bool
            let decoderObserved: Bool
            let queueWasValid: Bool
            let internetStatusObserved: Bool
            let audioSessionObserved: Bool
            let playbackErrorObserved: Bool
            let appErrorObserved: Bool
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
            version: 5,
            automaticChecks: AppAutomaticCheck.allCases.map { result($0) },
            summary: AppTestSessionSummary(id: sessionID, startedAt: startedAt, updatedAt: Date(),
                finishedAt: endedAt, state: running ? .running : .completed, sampleCount: samples.count,
                automaticPassed: AppAutomaticCheck.allCases.filter { result($0).status == .passed }.count,
                automaticFailed: AppAutomaticCheck.allCases.filter { result($0).status == .failed }.count,
                automaticTotal: AppAutomaticCheck.allCases.count,
                automaticObserved: AppAutomaticCheck.allCases.filter { result($0).observations > 0 }.count,
                manualPassed: nil, manualFailed: nil, manualTotal: nil),
            appVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown",
            buildNumber: Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown",
            buildRevision: Bundle.main.object(forInfoDictionaryKey: "BitChordRevision") as? String ?? "unknown",
            engineBuildRevision: engineBuildRevision,
            operatingSystem: ProcessInfo.processInfo.operatingSystemVersionString,
            startedAt: startedAt, endedAt: endedAt,
            modelIntegrityChecks: modelChecks,
            modelState: AutomixModelStore.ModelID.allCases.map { id in
                Model(name: id.rawValue, installedPinned: store.status(of: id).isInstalled,
                      usablePreviousVersion: store.isUsingPreviousGraph(id))
            },
            nativeAudioOutputObserved: outputObserved,
            decoderObserved: decoderObserved,
            queueWasValid: validQueueObserved,
            internetStatusObserved: networkObserved,
            audioSessionObserved: sessionObserved,
            playbackErrorObserved: playbackErrorObserved,
            appErrorObserved: appErrorObserved,
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
            notice: "Automatische Ergebnisse belegen die jeweils beobachteten Softwareprüfungen. Nicht verwendete Funktionen bleiben nicht beobachtet. Physische Hörbarkeit, vollständige Bildschirmqualität und externe Builds werden damit nicht bestätigt."
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(payload)
    }

    func saveReport() throws -> URL {
        do {
            let url = try archive.save(reportData())
            lastSavedAt = Date(); storageError = nil
            return url
        } catch {
            storageError = "Der Testbericht konnte nicht lokal gespeichert werden. Bitte erneut versuchen."
            throw error
        }
    }
}

/// An in-app test that can run alongside ordinary playback and continue when
/// the listener navigates away. No synthetic track and no extra audio engine.
struct AutomixLiveTestView: View {
    @Environment(PlaybackController.self) private var controller
    private let store = AutomixModelStore.shared
    private let monitor = AutomixLiveTestMonitor.shared
    @Environment(\.locale) private var locale

    @State private var reportURL: URL?
    @State private var exportData: Data?
    @State private var exportError: String?

    var body: some View {
        Form {
            Section {
                Text("Starte den automatischen App-Test und nutze RED Bit wie gewohnt. Modell-Dateien und Vorschauen werden automatisch geprüft; während deiner Nutzung kommen Ergebnisse der ausgeführten Funktionen dazu. Es gibt keine manuelle Bewertung. Beende und speichere den Lauf, wenn du fertig bist.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button {
                    if monitor.running {
                        monitor.stop()
                        prepareExport()
                    } else {
                        reportURL = nil
                        exportData = nil
                        exportError = nil
                        monitor.start(controller: controller, locale: locale)
                    }
                } label: {
                    Label(monitor.running ? "Beenden und speichern" : "App-Test starten",
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
                if let saved = monitor.lastSavedAt {
                    LabeledContent("Letzter Speicherstand") { Text(saved, style: .time) }
                }
                if let error = monitor.storageError {
                    Text(LocalizedStringKey(error)).foregroundStyle(.red)
                }
                NavigationLink("Gespeicherte Testberichte") { AppTestReportsView() }
                    .accessibilityIdentifier("red.tests.openHistory")
                Text("Im Hintergrund kann iOS die App pausieren. Aufzeichnung läuft nur, solange die App tatsächlich ausgeführt wird.")
                    .font(.caption).foregroundStyle(.secondary)
            } header: {
                Text("RED-Bit-Livetest")
            }

            Section {
                ForEach(AutomixModelStore.ModelID.allCases) { id in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(modelName(id)).font(.subheadline.weight(.semibold))
                        LabeledContent("Datei", value: installedText(id))
                        LabeledContent("Echte Analyse", value: inferredText(id))
                        if let result = monitor.modelChecks[id.rawValue] {
                            Text(result.passed ? "SHA-256 und Dateigröße der aktuellen Version bestätigt"
                                : "Aktuelle SHA-256-Datei nicht bestätigt")
                                .font(.footnote).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
                Text("Vorhandene Modell-Dateien werden automatisch geprüft. Optionale fehlende Modelle erscheinen als nicht verfügbar.")
                    .font(.footnote).foregroundStyle(.secondary)
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
                LabeledContent("Wiedergabezeit läuft", value: monitor.samples.last?.progressed == true
                               ? "Fortschritt im letzten Messintervall" : "Kein Fortschritt im letzten Messintervall")
                LabeledContent("Fortschritt seit Testbeginn", value: monitor.progressObserved
                               ? "Mindestens einmal beobachtet" : "Noch nicht nachgewiesen")
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
                Text("Die Prüfung bestätigt Engine-Ereignisse und Zeitfortschritt. Physische Hörbarkeit ist damit nicht messbar.")
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
                LabeledContent("App-Fehler während Test", value:
                    monitor.appErrorObserved ? "Mindestens einer registriert" : "Keiner beobachtet")
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
                LabeledContent("Automatisch geprüft", value: "\(AppAutomaticCheck.allCases.filter { monitor.result($0).status == .passed }.count)/\(AppAutomaticCheck.allCases.count)")
                ForEach(AppAutomaticCheck.allCases) { check in
                    let result = monitor.result(check)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(LocalizedStringKey(check.title)).font(.subheadline.weight(.medium))
                        Text(LocalizedStringKey(result.status.title))
                            .foregroundStyle(result.status == .failed ? Color.red : Color.secondary)
                        if let at = result.lastAt { Text(at, style: .time).font(.caption).foregroundStyle(.secondary) }
                    }.padding(.vertical, 4)
                    .accessibilityIdentifier("red.tests.auto.\(check.rawValue)")
                }
            } header: { Text("Automatische Ergebnisse") } footer: {
                Text("Ergebnisse stammen aus echten Ereignissen und Prüfungen. Unbenutzte Funktionen bleiben nicht beobachtet. Ein gemeldeter Ausgabestream bestätigt nicht die physische Hörbarkeit; Vorschau-PNGs bestätigen nur das Rendern.")
            }

            Section {
                Button("Lokalen Testbericht speichern") { prepareExport() }
                .disabled(monitor.startedAt == nil)
                .accessibilityIdentifier("bbt.automixLive.saveReport")
                if let exportData {
                    AppTestReportExportButton(data: exportData, name: "RED-Bit-Test-\(monitor.sessionID.uuidString)",
                        latestData: { try monitor.reportData() })
                }
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
                Text("Der Bericht enthält automatische Prüfergebnisse und technische Statuswerte, aber keine Songtitel, Suchtexte, Dateipfade oder Zugangsdaten. Er bleibt lokal, bis du ihn ausdrücklich teilst.")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("RED Bit Testzentrale")
    }

    private func prepareExport() {
        reportURL = nil; exportData = nil
        do {
            let url = try monitor.saveReport()
            exportData = try Data(contentsOf: url)
            reportURL = url
            exportError = nil
        } catch {
            exportError = "Der Testbericht konnte nicht lokal gespeichert werden. Bitte erneut versuchen."
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


}
