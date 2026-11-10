// Kontrollierte Adapter ohne Audio, Netzwerk oder Kontodaten.
@MainActor final class PlaybackController {
    struct Entry { var id: String }
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
    func status(of id: ModelID) -> Status { Status() }
    func isUsingPreviousGraph(_ id: ModelID) -> Bool { false }
}

// Gleiche Datei wie der Produktionsmonitor: private Messung bleibt intern.
extension AutomixLiveTestMonitor {
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
        precondition(json["version"] as? Int == 4)
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
        monitor.stop()
        let savedID = monitor.sessionID
        let finished = monitor.endedAt
        monitor.setManual(.coverQueueDrop, verdict: .fail)
        monitor.setManual(.audibleAudio, verdict: .pass)
        monitor.setModelCheck("beat", passed: true)
        precondition(monitor.endedAt == finished && archive.reports.first?.state == .completed)
        let completed = try archive.read(savedID)
        let report = try JSONSerialization.jsonObject(with: completed) as! [String: Any]
        precondition((report["modelIntegrityChecks"] as? [String: Any])?["beat"] != nil)
        precondition(archive.reports.first?.manualPassed == 1 && archive.reports.first?.manualFailed == 1)
        precondition(archive.reports.first?.manualTotal == 22)
        let restartedArchive = AppTestReportStore(directory: directory)
        precondition(restartedArchive.reports.first?.state == .completed)
        monitor.start(controller: controller)
        precondition(!monitor.progressObserved && !monitor.playbackErrorObserved && !monitor.appErrorObserved)
        precondition(monitor.sessionID != savedID && archive.reports.count == 2)
        let activeID = monitor.sessionID
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
        invalidSummary["manualTotal"] = Int.max
        invalidSummary["manualPassed"] = Int.max
        invalidSummary["manualFailed"] = Int.max
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
        print("BESTANDEN: Produktionsmonitor, JSON v4, Fehlertrennung, Modus, Engine-Revision und Datenschutz")
        print("BESTANDEN: 22 manuelle Bereiche, Modellprüfungen, dauerhaftes Archiv, Wiederöffnung, unterbrochener Lauf, Doppeltstart, defekte Dateien und Schreibfehler ohne Datenverlust")
    }
}

@main struct VerifyAutomixLiveReport {
    @MainActor static func main() throws { try AutomixLiveTestMonitor.verifyReport() }
}
