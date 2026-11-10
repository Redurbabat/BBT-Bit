// Kontrollierte Adapter ohne Audio, Netzwerk oder Kontodaten.
@MainActor final class PlaybackController {
    struct Entry { var id: String; var source = "yt:private-fixture-title" }
    struct Nerd { var codec: String; var buildRevision: String }
    struct Output { var started: Bool }
    struct Readout { var loaded: Bool }
    var current: Entry? = Entry(id: "private-fixture-title")
    var position = 10.0
    var duration = 200.0
    var isPlaying = true
    var isBuffering = false
    var automixEnabled = true
    var automixPlanRevision: UInt64 = 0
    var automixTransitionRevision: UInt64 = 0
    var analysisSources: String? = nil
    var analysisTier: String? = nil
    var smartMixInProgress = false
    var queue = [Entry(id: "private-fixture-title")]
    var playingIndex = 0
    var outputDevice = Output(started: true)
    var nerd: Nerd? = Nerd(codec: "Opus", buildRevision: "fixture-engine-revision")
    var settingsAudioReadout = Readout(loaded: true)
    var loadedSourcePath: String?
    var lyrics: [Int] = []
    var lyricsLoading = false
    // PRODUCTION_ERROR_STATE
}

@MainActor final class PlatformSettings {
    static let shared = PlatformSettings()
    var mode = "EFFICIENT"
    func getString(key: String, default value: String) -> String { mode }
}
@MainActor final class NetworkQuality {
    static let shared = NetworkQuality()
    var connected = true
}
struct AutomixRuntimeSnapshot {
    let beatReady: Bool
    let vocalsRequested: Bool
    let coreMLLoaded: Bool
    let configuredAt: Date?
}
actor AutomixModelLoader {
    static let shared = AutomixModelLoader()
    func snapshot() -> AutomixRuntimeSnapshot {
        .init(beatReady: true, vocalsRequested: false, coreMLLoaded: false, configuredAt: nil)
    }
}
@MainActor final class AutomixModelStore {
    static let shared = AutomixModelStore()
    enum ModelID: String, CaseIterable { case beat, beatCoreML, vocals }
    struct Status { var isInstalled = true }
    var installed = Set(ModelID.allCases)
    var verified: [ModelID] = []
    var anyBusy = false
    func status(of id: ModelID) -> Status { Status(isInstalled: installed.contains(id)) }
    func inspectIntegrity(_ id: ModelID) async -> Bool? {
        await Task.yield()
        guard installed.contains(id) else { return nil }
        verified.append(id); return true
    }
    func isUsingPreviousGraph(_ id: ModelID) -> Bool { false }
}

@MainActor final class DownloadStore {
    static let shared = DownloadStore()
    enum Status { case running, done }
    struct Job { let id: String; let status: Status }
    var jobs: [Job] = []
}

// Gleiche Datei wie der Produktionsmonitor: private Messung bleibt intern.
extension AutomixLiveTestMonitor {
    func waitForModelsInCheck() async { await modelTask?.value }
    @MainActor static func verifyReport() throws {
        let controller = PlaybackController()
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("red-bit-test-\(UUID())")
        defer { try? FileManager.default.removeItem(at: directory) }
        let archive = AppTestReportStore(directory: directory)
        let monitor = AutomixLiveTestMonitor(archive: archive)
        monitor.start(controller: controller)
        defer { monitor.stop() }
        precondition(monitor.samples.last?.progressed == false)
        controller.position += 0.3
        monitor.record(controller: controller)
        precondition(monitor.samples.last?.progressed == true && monitor.progressObserved)
        monitor.record(controller: controller)
        precondition(monitor.samples.last?.progressed == false && monitor.progressObserved)

        controller.lastError = "private action https://example.invalid/?token=secret"
        monitor.record(controller: controller)
        precondition(monitor.samples.last?.appErrorPresent == true)
        precondition(monitor.samples.last?.playbackErrorPresent == false)
        precondition(!monitor.playbackErrorObserved)

        controller.reportPlaybackFailure(.streamRecovery, message: "private playback error")
        monitor.record(controller: controller)
        precondition(monitor.samples.last?.playbackErrorKind == .streamRecovery)
        precondition(monitor.playbackErrorObserved)
        controller.lastError = nil
        monitor.record(controller: controller)
        precondition(monitor.samples.last?.playbackErrorPresent == false)
        precondition(monitor.samples.last?.appErrorPresent == false)
        PlatformSettings.shared.mode = "private-setting-value"
        monitor.record(controller: controller)
        precondition(monitor.samples.last?.automixPerformanceMode == "BALANCED")

        let url = try monitor.saveReport()
        defer { try? FileManager.default.removeItem(at: url) }
        let data = try Data(contentsOf: url)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        precondition(json["version"] as? Int == 5)
        precondition(json["engineBuildRevision"] as? String == "fixture-engine-revision")
        precondition(json["playedProgressed"] as? Bool == true)
        precondition(json["appErrorObserved"] as? Bool == true)
        precondition(json["playbackErrorObserved"] as? Bool == true)
        let samples = json["samples"] as! [[String: Any]]
        precondition(samples[1]["progressed"] as? Bool == true)
        precondition(samples[2]["progressed"] as? Bool == false)
        precondition(samples[0]["automixPerformanceMode"] as? String == "EFFICIENT")
        precondition(samples[4]["playbackErrorKind"] as? String == "streamRecovery")
        let text = String(decoding: data, as: UTF8.self)
        for secret in ["private-fixture-title", "private action", "example.invalid", "secret", "private playback", "private-setting"] {
            precondition(!text.contains(secret), "Private Daten im Bericht: \(secret)")
        }
        controller.loadedSourcePath = "/private-fixture-file"
        NetworkQuality.shared.connected = false
        controller.position += 0.3
        monitor.record(controller: controller)
        precondition(monitor.result(.offlinePlayback).status == .passed)
        NetworkQuality.shared.connected = true
        precondition(monitor.result(.albumPreview).status == .notObserved)
        AppTestEvents.emit(.albumPreview, .success, .responseReceived)
        precondition(monitor.result(.albumPreview).status == .passed)
        AppTestEvents.emit(.albumPreview, .failure, .requestFailed)
        AppTestEvents.emit(.albumPreview, .success, .responseReceived)
        precondition(monitor.result(.albumPreview).status == .failed)
        precondition(monitor.result(.albumPreview).lastFailure == .requestFailed)
        let oldProbe = AppTestEvents.begin(.search)
        monitor.stop()
        let savedID = monitor.sessionID
        precondition(archive.reports.first?.state == .completed)
        let completed = try archive.read(savedID)
        let report = try JSONSerialization.jsonObject(with: completed) as! [String: Any]
        precondition(!String(decoding: completed, as: UTF8.self).contains("private-fixture"))
        precondition(report["manualChecks"] == nil)
        precondition(!(report["summary"] as! [String: Any]).keys.contains("manualPassed"))
        let checks = report["automaticChecks"] as! [[String: Any]]
        precondition(checks.count == AppAutomaticCheck.allCases.count)
        precondition(checks.first { $0["id"] as? String == "albumPreview" }?["status"] as? String == "failed")
        precondition(archive.reports.first?.automaticFailed ?? 0 >= 1)
        precondition(archive.reports.first?.automaticTotal == AppAutomaticCheck.allCases.count)
        let restartedArchive = AppTestReportStore(directory: directory)
        precondition(restartedArchive.reports.first?.state == .completed)
        monitor.start(controller: controller)
        precondition(!monitor.progressObserved && !monitor.playbackErrorObserved && !monitor.appErrorObserved)
        precondition(monitor.sessionID != savedID && archive.reports.count == 2)
        let activeID = monitor.sessionID
        AppTestEvents.finish(oldProbe, .success, .responseReceived)
        precondition(monitor.result(.search).status == .notObserved)
        AppTestEvents.stop(savedID)
        AppTestEvents.emit(.settings, .success, .screenDisplayed)
        precondition(monitor.result(.settings).status == .passed)
        monitor.start(controller: controller)
        precondition(monitor.sessionID == activeID && monitor.samples.count == 1)
        let recovered = AppTestReportStore(directory: directory)
        precondition(recovered.reports.first { $0.id == activeID }?.state == .interrupted)
        precondition(recovered.reports.first { $0.id == activeID }?.finishedAt == nil)
        let snapshot = try recovered.read(activeID)
        do { _ = try recovered.save(Data("invalid".utf8)); preconditionFailure() } catch { }
        let unchanged = try recovered.read(activeID)
        precondition(unchanged == snapshot)
        var invalid = try JSONSerialization.jsonObject(with: snapshot) as! [String: Any]
        var invalidSummary = invalid["summary"] as! [String: Any]
        invalidSummary["automaticTotal"] = Int.max
        invalidSummary["automaticPassed"] = Int.max
        invalidSummary["automaticFailed"] = Int.max
        invalid["summary"] = invalidSummary
        let invalidData = try JSONSerialization.data(withJSONObject: invalid)
        do { _ = try recovered.save(invalidData); preconditionFailure() } catch { }
        monitor.setModelCheck("private-fixture-title", passed: true)
        precondition(monitor.modelChecks["private-fixture-title"] == nil)
        let damagedID = UUID()
        try Data("damaged".utf8).write(to: recovered.fileURL(damagedID))
        recovered.refresh()
        precondition(recovered.unreadableCount == 1 && recovered.reports.count == 2)
        precondition(FileManager.default.fileExists(atPath: recovered.fileURL(damagedID).path))
        let blockedURL = directory.appendingPathComponent("blocked")
        try Data().write(to: blockedURL)
        let blocked = AutomixLiveTestMonitor(archive: AppTestReportStore(directory: blockedURL))
        blocked.start(controller: controller)
        precondition(blocked.running && blocked.storageError != nil)
        blocked.stop()
        let blockedID = blocked.sessionID
        blocked.start(controller: controller)
        precondition(blocked.sessionID == blockedID && !blocked.running)
        let bounded = AutomixLiveTestMonitor(archive: archive)
        bounded.start(controller: controller)
        for _ in 0..<1900 { bounded.record(controller: controller) }
        precondition(bounded.samples.count == 1800)
        bounded.stop()
        let boundedData = try Data(contentsOf: archive.fileURL(bounded.sessionID))
        precondition(boundedData.count < 8 * 1024 * 1024)
        var legacy = report
        legacy["version"] = 4; legacy.removeValue(forKey: "automaticChecks")
        var header = legacy["summary"] as! [String: Any]
        let legacyID = UUID(); header["id"] = legacyID.uuidString
        for key in ["automaticTotal", "automaticPassed", "automaticFailed", "automaticObserved"] { header.removeValue(forKey: key) }
        header["manualPassed"] = 1; header["manualFailed"] = 2; header["manualTotal"] = 22
        legacy["summary"] = header; legacy["manualChecks"] = ["audibleAudio": "Bestanden"]
        let legacyData = try JSONSerialization.data(withJSONObject: legacy)
        _ = try archive.save(legacyData)
        let legacyRead = try archive.read(legacyID)
        precondition(legacyRead == legacyData)
        precondition(archive.reports.first { $0.id == legacyID }?.automaticTotal == nil)
        print("BESTANDEN: Produktionsmonitor, JSON v5, Fehlertrennung, Modus, Engine-Revision und Datenschutz")
        print("BESTANDEN: Automatische Nachweise ohne Bewertung, Fehler bleiben sichtbar, alte Ereignisse verworfen, v4 unverändert lesbar, Archiv, Abbruch, Schreibfehler und 1800-Punkte-Grenze")
    }
}

@main struct VerifyAutomixLiveReport {
    @MainActor static func main() async throws {
        try AutomixLiveTestMonitor.verifyReport()
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("red-bit-auto-\(UUID())")
        defer { try? FileManager.default.removeItem(at: directory) }
        let monitor = AutomixLiveTestMonitor(archive: AppTestReportStore(directory: directory))
        let controller = PlaybackController(), store = AutomixModelStore.shared
        store.verified = []
        monitor.start(controller: controller)
        await monitor.waitForModelsInCheck()
        precondition(store.verified.count == 3 && monitor.result(.beatFile).status == .passed)
        monitor.stop()
        store.installed = []; store.verified = []
        monitor.start(controller: controller)
        await monitor.waitForModelsInCheck()
        precondition(store.verified.isEmpty && monitor.result(.beatFile).status == .unavailable)
        monitor.stop()
        store.installed = Set(AutomixModelStore.ModelID.allCases)
        print("BESTANDEN: Drei vorhandene Modelle automatisch geprüft; fehlende optionale Dateien ohne Download als nicht verfügbar erkannt")
    }
}
