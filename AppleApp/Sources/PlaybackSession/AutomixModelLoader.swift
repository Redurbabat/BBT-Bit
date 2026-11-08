import Foundation

/// Actual native model configuration: the three meanings are intentionally
/// separate. The vocal path is only a request; proof of inference comes from
/// Rust's last real pair plan ([vocals:open_unmix]).
struct AutomixRuntimeSnapshot: Sendable {
    let beatReady: Bool
    let vocalsRequested: Bool
    let coreMLLoaded: Bool
    let configuredAt: Date?
}

enum AutomixModelPolicy {
    static func paths(
        beat: String,
        vocal: String,
        accelerator: AutomixAccelerator?,
        playbackStarted: Bool,
        enabled: Bool,
        efficient: Bool
    ) -> (beat: String, vocal: String, accelerator: AutomixAccelerator?) {
        guard playbackStarted && enabled else { return ("", "", nil) }
        let accelerated = efficient || beat.isEmpty ? nil : accelerator
        return (beat, efficient ? "" : vocal, accelerated)
    }
}

/// Serialize native model replacement off-main so preference changes do not
/// interleave graph configurations.
actor AutomixModelLoader {
    static let shared = AutomixModelLoader()
    private var live = AutomixRuntimeSnapshot(
        beatReady: false, vocalsRequested: false,
        coreMLLoaded: false, configuredAt: nil
    )

    func snapshot() -> AutomixRuntimeSnapshot { live }

    func configure(beat: String, vocal: String, accelerator: AutomixAccelerator?) async -> Bool {
        let ready = configureAnalyzer(beatModelPath: beat, vocalModelPath: vocal)
        live = AutomixRuntimeSnapshot(
            beatReady: ready, vocalsRequested: !vocal.isEmpty,
            coreMLLoaded: false, configuredAt: Date()
        )
        guard ready, !beat.isEmpty, let accelerator else {
            setBeatAccelerator(accelerator: nil, identity: "")
            return ready
        }
        if let model = BeatThisCoreML(modelURL: accelerator.modelURL) {
            setBeatAccelerator(accelerator: model, identity: accelerator.identity)
            live = AutomixRuntimeSnapshot(
                beatReady: ready, vocalsRequested: !vocal.isEmpty,
                coreMLLoaded: true, configuredAt: Date()
            )
            return ready
        }
        let rebuilt = await AutomixModelStore.shared.recompileBeatCoreML()
        if let rebuilt, let model = BeatThisCoreML(modelURL: rebuilt.modelURL) {
            setBeatAccelerator(accelerator: model, identity: rebuilt.identity)
            live = AutomixRuntimeSnapshot(
                beatReady: ready, vocalsRequested: !vocal.isEmpty,
                coreMLLoaded: true, configuredAt: Date()
            )
        } else {
            setBeatAccelerator(accelerator: nil, identity: "")
        }
        return ready
    }
}
