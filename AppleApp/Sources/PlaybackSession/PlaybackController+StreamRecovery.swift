import Foundation
import BitChordShared
#if canImport(UIKit)
import UIKit
#endif

extension PlaybackController {
    func pollStreamRecovery() {
        if let pending = deferredNetworkRecovery {
            guard NetworkQuality.shared.connected else { return }
            deferredNetworkRecovery = nil
            if current?.id == pending.entryID, playGeneration == pending.generation, state == .buffering {
                engineLoadedId = nil
                streamRecovery.select(pending.entryID, resetAttempts: true)
                SourceResolverBridge.shared.refreshPlaybackSources()
                if let entry = current, let videoID = youtubeVideoID(for: entry) { PlayerBridge.shared.forgetPlaybackUrl(videoId: videoID) }
                loadCurrent(playingIndex, startAt: pending.position, refreshAutoplay: false, freshResolution: true)
                return
            }
        }
        // The range downloader waits for connectivity at its current offset.
        // An outage must not consume the two source-recovery attempts.
        guard NetworkQuality.shared.connected else { return }
        if streamRecoveryPathChanges != NetworkQuality.shared.pathChanges {
            streamRecoveryPathChanges = NetworkQuality.shared.pathChanges
            if let entry = current { streamRecovery.select(entry.id, resetAttempts: false) }
        }
        if state == .paused {
            _ = streamRecovery.observe(position: playbackPosition, now: ProcessInfo.processInfo.systemUptime, playing: false, bufferedFrames: 0)
            return // Keep source failures queued until the listener resumes.
        }
        for failure in engine.drainSourceErrors() {
            if recoverInterruptedStream(source: failure.source, explanation: "The audio stream failed; requesting a fresh stream.") { return }
            if failure.source == loadedSourcePath { stopAfterFailedRecovery(source: failure.source) }
        }
        let stalled = streamRecovery.observe(
            position: playbackPosition, now: ProcessInfo.processInfo.systemUptime,
            playing: state == .playing && !smartMixInProgress && dolbyRenderer == nil,
            bufferedFrames: engine.outputHealth().bufferedFrames
        )
        if stalled, let source = loadedSourcePath {
            if !recoverInterruptedStream(source: source, explanation: "The stream stopped delivering audio; requesting a fresh stream.") {
                stopAfterFailedRecovery(source: source)
            }
        }
    }

    func stopAfterFailedRecovery(source: String) {
        guard let entry = current, source == loadedSourcePath,
              PlaybackRecoveryPolicy.canRecover(entrySource: entry.source, loadedSource: source, origin: resolvedOrigin[entry.id]?.rawValue),
              duration <= 0 || playbackPosition < duration - 3 else { return }
        wakeGrowingReader(source)
        let at = playbackPosition
        let diagnostic = "stream recovery exhausted: position=\(at) duration=\(duration) state=\(state) \(streamStallEvidence(source: source))"
        debugLog.record(diagnostic, about: entry.id)
        pausePlayback()
        engineLoadedId = nil
        restoredStart = (entry.id, at)
        recoveryNeedsFreshResolution = true
        lastError = "Playback interrupted at \(Int(at))s; automatic stream recovery failed. Press Play to retry."
        sourceDecisionNotes[entry.id] = lastError
    }

    /// Kurzer Befund für den Diagnosebericht. Er trennt die möglichen Ursachen eines
    /// Abbruchs mitten im Titel: Download unvollständig (`bytes` unter der erwarteten
    /// Länge, `.failed`), leerer Ausgabepuffer trotz vollständiger Datei (Engine oder
    /// Ausgabe) oder ein Wechsel der App in den Hintergrund (`app`: 0 aktiv, 1 inaktiv,
    /// 2 Hintergrund). Enthält keine URLs und keine Pfade.
    private func streamStallEvidence(source: String) -> String {
        var parts = ["source=\(source.hasPrefix("/") ? "local-cache" : "remote")"]
        if source.hasPrefix("/") {
            let files = FileManager.default
            let attributes = try? files.attributesOfItem(atPath: source)
            let size = (attributes?[.size] as? NSNumber)?.int64Value ?? -1
            let declared = (try? String(contentsOfFile: source + ".len", encoding: .utf8))
                .flatMap { Int64($0.trimmingCharacters(in: .whitespacesAndNewlines)) } ?? -1
            parts.append("bytes=\(size)/\(declared)")
            parts.append("grow=\(files.fileExists(atPath: source + ".grow"))")
            parts.append("complete=\(files.fileExists(atPath: source + ".complete"))")
            parts.append("failed=\(files.fileExists(atPath: source + ".failed"))")
        }
        parts.append("bufferedFrames=\(engine.outputHealth().bufferedFrames)")
        parts.append("network=\(NetworkQuality.shared.connected ? "up" : "down")")
        #if canImport(UIKit)
        parts.append("app=\(UIApplication.shared.applicationState.rawValue)")
        #endif
        return parts.joined(separator: " ")
    }

    private func wakeGrowingReader(_ source: String) {
        if source.hasPrefix("/"), FileManager.default.fileExists(atPath: source + ".grow") {
            try? Data().write(to: URL(fileURLWithPath: source + ".playback-cancelled"), options: .atomic)
        }
    }

    @discardableResult
    func recoverInterruptedStream(source: String, explanation: String) -> Bool {
        guard source == loadedSourcePath, let entry = current,
              PlaybackRecoveryPolicy.canRecover(entrySource: entry.source, loadedSource: source, origin: resolvedOrigin[entry.id]?.rawValue),
              engineLoadedId == entry.id,
              state == .playing || state == .stopped,
              queue.indices.contains(playingIndex), queue[playingIndex].id == entry.id,
              !smartMixInProgress, dolbyRenderer == nil else { return false }
        let at = playbackPosition
        if !NetworkQuality.shared.connected {
            deferredNetworkRecovery = (entry.id, at, playGeneration)
            state = .buffering
            lastError = "Waiting for the network to return."
            return true
        }
        guard streamRecovery.claimRetry(position: at, duration: duration) else { return false }
        wakeGrowingReader(source)
        recoveringEntryID = entry.id
        sourceDecisionNotes[entry.id] = explanation
        debugLog.record("\(explanation) position=\(at) duration=\(duration) \(streamStallEvidence(source: source))", about: entry.id)
        QualityUpgrade.forget(entry.id)
        // A fresh resolution bypasses growing/completed playback caches and clears
        // only issued URLs, preserving local downloads and the user's source order.
        SourceResolverBridge.shared.refreshPlaybackSources()
        if let videoId = youtubeVideoID(for: entry) { PlayerBridge.shared.forgetPlaybackUrl(videoId: videoId) }
        engineLoadedId = nil
        loadCurrent(playingIndex, startAt: max(0, at - 0.25), refreshAutoplay: false, freshResolution: true)
        return true
    }
}
