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
        let monitor = shared
        monitor.start(controller: controller)
        defer { monitor.stop() }
        monitor.record(controller: controller)
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
        precondition(json["version"] as? Int == 3)
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
        monitor.start(controller: controller)
        precondition(!monitor.progressObserved && !monitor.playbackErrorObserved && !monitor.appErrorObserved)
        print("BESTANDEN: Produktionsmonitor, JSON v3, Fehlertrennung, Modus, Engine-Revision, Neustart und Datenschutz")
    }
}

@main struct VerifyAutomixLiveReport {
    @MainActor static func main() throws { try AutomixLiveTestMonitor.verifyReport() }
}
