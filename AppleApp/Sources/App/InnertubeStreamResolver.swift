import Foundation
import BitChordShared

/// A resolved YouTube Music stream: the URL the engine fetches plus the
/// headers the CDN demands and the quality description for display.
struct ResolvedYouTubeStream {
    let url: String
    let kbps: Int
    let mimeType: String
    let headers: [String: String]
    /// Player-response loudness figure for the engine's normalization stage
    /// (nil when the response carried none, or the payload predates it).
    let durationSeconds: Int?
    let loudnessDb: Double?
    let clientName: String
}

struct VideoSideError: Error, LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

/// Swift bridge over the shared module's `StreamResolver` (via `PlayerBridge`):
/// resolves a videoId to a playable audio URL. The resolved payload crosses FFI
/// as JSON.
///
/// The resolution *policy* — which identities to ask, what to remember between
/// attempts, when to stand one down, and the signed-in retries — lives in the
/// shared module, mirroring upstream's own split. This is only the seam.
final class InnertubeStreamResolver: Sendable {
    static let shared = InnertubeStreamResolver()

    func resolve(videoId: String, maxKbps: Int = Int.max, background: Bool = false) async throws -> ResolvedYouTubeStream {
        let request = ResolutionRequest()
        let payload: ResolvedYouTubeStream = try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                request.install(continuation)
                guard !Task.isCancelled else { request.cancel(); return }
                let ceiling = Swift.Int32(clamping: maxKbps)
                let callback = ResolveCallbackAdapter { json, message in
                    if let json {
                        do {
                            let decoded = try JSONDecoder().decode(StreamPayload.self, from: Data(json.utf8))
                            request.finish(.success(ResolvedYouTubeStream(url: decoded.url, kbps: decoded.kbps,
                                mimeType: decoded.mimeType, headers: decoded.headers, durationSeconds: decoded.durationSeconds,
                                loudnessDb: decoded.loudnessDb, clientName: decoded.clientName)))
                        } catch { request.finish(.failure(error)) }
                    } else {
                        let raw = message ?? "Stream resolution failed"
                        let error = StreamError(message: StreamError.say(raw), raw: raw)
                        if error.reason == .cancelled {
                            request.finish(.failure(CancellationError()))
                        } else {
                            request.finish(.failure(error))
                        }
                    }
                }
                let id = background
                    ? PlayerBridge.shared.resolveBackgroundRequest(videoId: videoId, maxKbps: ceiling, callback: callback)
                    : PlayerBridge.shared.resolveRequest(videoId: videoId, maxKbps: ceiling, callback: callback)
                request.setID(id)
            }
        } onCancel: { request.cancel() }

        // The shared resolver transforms both direct and ciphered URLs before
        // probing. Applying the n transform again corrupts a verified URL.
        try Task.checkCancellation()
        return payload
    }

    /// The track's AVC/MP4 video side, or a side whose `url` is nil when the
    /// track has none. The audio path is untouched: this is its own request,
    /// through the same direct profile the audio resolved with.
    func resolveVideo(videoId: String, forceRefresh: Bool = false) async throws -> ResolvedVideoSide {
        try await withCheckedThrowingContinuation { continuation in
            PlayerBridge.shared.resolveVideo(
                videoId: videoId,
                forceRefresh: forceRefresh,
                callback: VideoCallbackAdapter { json, message in
                    guard let json else {
                        continuation.resume(throwing: VideoSideError(
                            message: message ?? "Video side lookup failed"
                        ))
                        return
                    }
                    do {
                        let payload = try JSONDecoder().decode(VideoSidePayload.self, from: Data(json.utf8))
                        continuation.resume(returning: ResolvedVideoSide(
                            url: payload.url,
                            width: payload.width,
                            height: payload.height,
                            itag: payload.itag,
                            mimeType: payload.mimeType,
                            codecs: payload.codecs,
                            bitrate: payload.bitrate,
                            headers: payload.headers ?? [:],
                            availableVideoHeights: payload.availableVideoHeights ?? [],
                            hasNParameter: payload.urlHasNParameter ?? false,
                            clientName: payload.clientName,
                            profileId: payload.profileId,
                            musicVideoType: payload.musicVideoType
                        ))
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            )
        }
    }

    typealias StreamError = YouTubeStreamError
}

private struct StreamPayload: Codable {
    let url: String
    let kbps: Int
    let mimeType: String
    let headers: [String: String]
    /// Nil on payloads minted before the shared module parsed the figure.
    let durationSeconds: Int?
    let loudnessDb: Double?
    let clientName: String

    private enum CodingKeys: String, CodingKey { case url, kbps, mimeType, headers, loudnessDb, durationSeconds, clientName }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        url = try values.decode(String.self, forKey: .url)
        kbps = try values.decode(Int.self, forKey: .kbps)
        mimeType = try values.decode(String.self, forKey: .mimeType)
        // Kotlin omits empty default maps. Some upstream profiles correctly
        // need no CDN headers, so an omitted map is a valid empty map.
        headers = try values.decodeIfPresent([String: String].self, forKey: .headers) ?? [:]
        durationSeconds = try values.decodeIfPresent(Int.self, forKey: .durationSeconds)
        loudnessDb = try values.decodeIfPresent(Double.self, forKey: .loudnessDb)
        clientName = try values.decodeIfPresent(String.self, forKey: .clientName) ?? "unknown"
    }
}

private final class ResolveCallbackAdapter: PlayerBridgeResolveCallback {
    private let onResult: (String?, String?) -> Void

    init(onResult: @escaping (String?, String?) -> Void) {
        self.onResult = onResult
    }

    func onResult(json: String?, message: String?) {
        onResult(json, message)
    }
}

private struct VideoSidePayload: Decodable {
    let url: String?
    let width: Int?
    let height: Int?
    let itag: Int?
    let mimeType: String?
    let codecs: String?
    let bitrate: Int?
    /// Kotlin omits an empty default map and list.
    let headers: [String: String]?
    let availableVideoHeights: [Int]?
    let urlHasNParameter: Bool?
    let clientName: String
    let profileId: String
    let musicVideoType: String?
}

private final class VideoCallbackAdapter: PlayerBridgeVideoCallback {
    private let onResult: (String?, String?) -> Void

    init(onResult: @escaping (String?, String?) -> Void) {
        self.onResult = onResult
    }

    func onResult(json: String?, message: String?) {
        onResult(json, message)
    }
}

/// Cancellation resumes Swift immediately and releases its shared Kotlin flight.
private final class ResolutionRequest: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<ResolvedYouTubeStream, Error>?
    private var id: Int64?
    private var cancelled = false
    private var completed = false
    func install(_ value: CheckedContinuation<ResolvedYouTubeStream, Error>) {
        lock.lock()
        if cancelled { lock.unlock(); value.resume(throwing: CancellationError()); return }
        continuation = value; lock.unlock()
    }
    func setID(_ value: Int64) {
        lock.lock(); id = value; let cancel = cancelled; lock.unlock()
        if cancel { PlayerBridge.shared.cancelResolve(requestId: value) }
    }
    func finish(_ result: Result<ResolvedYouTubeStream, Error>) {
        lock.lock()
        guard !completed, !cancelled, let value = continuation else { lock.unlock(); return }
        completed = true; continuation = nil; lock.unlock()
        value.resume(with: result)
    }
    func cancel() {
        lock.lock(); cancelled = true
        let value = continuation; continuation = nil
        let requestID = id; lock.unlock()
        value?.resume(throwing: CancellationError())
        if let requestID { PlayerBridge.shared.cancelResolve(requestId: requestID) }
    }
}
