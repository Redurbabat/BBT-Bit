import Foundation

enum AppAutomaticCheck: String, Codable, CaseIterable, Identifiable {
    case playbackProgress, queueIntegrity, decoder, outputStream, audioSession
    case playbackErrors, appErrors, networkStatus, pauseResume, trackChange
    case automixPlan, automixTransition, beatFile, coreMLFile, vocalFile
    case homeFeed, feedPaging, search, library, albumPreview, dayMix, queueNext, coverDrop
    case downloads, offlinePlayback, lyrics, backgroundPlayback, audioRoute, partySync
    case playerNavigation, dockInline, settings, designPreviews
    var id: String { rawValue }
    var title: String {
        switch self {
        case .playbackProgress: "Wiedergabefortschritt"
        case .queueIntegrity: "Queue-Index und aktuelle Auswahl"
        case .decoder: "Decoder gemeldet"
        case .outputStream: "Nativer Ausgabestream"
        case .audioSession: "iPhone-Audiositzung"
        case .playbackErrors: "Playback-Fehlerüberwachung"
        case .appErrors: "App-Fehlerüberwachung"
        case .networkStatus: "Netzwerkstatus gelesen"
        case .pauseResume: "Pause und Fortsetzen beobachtet"
        case .trackChange: "Titelwechsel mit Fortschritt"
        case .automixPlan: "Neue Engine-Mixplanung"
        case .automixTransition: "Engine-Übergang gemeldet"
        case .beatFile: "Beat-Datei und SHA-256"
        case .coreMLFile: "Core-ML-Datei und SHA-256"
        case .vocalFile: "Vocal-Datei und SHA-256"
        case .homeFeed: "Home-Feed geladen"
        case .feedPaging: "Weitere Feed-Seite geladen"
        case .search: "Suchanfrage beantwortet"
        case .library: "Bibliotheksansicht angezeigt"
        case .albumPreview: "Album-Vorschau geladen"
        case .dayMix: "Tagesmix in Queue übernommen"
        case .queueNext: "Als Nächstes eingereiht"
        case .coverDrop: "Cover-Drop eingereiht"
        case .downloads: "Neuer Download abgeschlossen"
        case .offlinePlayback: "Fortschritt bei gemeldetem Offline-Status"
        case .lyrics: "Lyricsdaten geladen"
        case .backgroundPlayback: "Fortschritt im Hintergrund"
        case .audioRoute: "Fortschritt nach Audio-Routenwechsel"
        case .partySync: "Lokaler Party-Zustand abgeglichen"
        case .playerNavigation: "Vollplayer angezeigt"
        case .dockInline: "Native Inline-Pill angezeigt"
        case .settings: "Einstellungen angezeigt"
        case .designPreviews: "15 Vorschauen als PNG gerendert"
        }
    }
}

enum AppTestOutcome: String, Codable { case observation, success, failure, unavailable }
enum AppTestEvidenceCode: String, Codable {
    case pending, validState, invalidState, positionAdvanced, failureReported
    case responseReceived, requestFailed, emptyResponse, queueUpdated, screenDisplayed
    case fileVerified, fileMissing, integrityFailed, modelBusy, platformUnsupported
    case backgroundEntered, routeChanged, previewRendered, previewFailed
}
enum AppTestCheckStatus: String, Codable {
    case notObserved, observed, passed, failed, unavailable
    var title: String {
        switch self {
        case .notObserved: "Nicht beobachtet"
        case .observed: "Beobachtet – Prüfung offen"
        case .passed: "Automatisch geprüft"
        case .failed: "Fehler beobachtet"
        case .unavailable: "Nicht verfügbar"
        }
    }
}

struct AppTestCheckResult: Codable, Identifiable {
    let id: AppAutomaticCheck
    var observations = 0
    var successes = 0
    var failures = 0
    var lastOutcome: AppTestOutcome?
    var lastCode: AppTestEvidenceCode?
    var lastFailure: AppTestEvidenceCode?
    var lastAt: Date?
    private(set) var status: AppTestCheckStatus = .notObserved
    mutating func record(_ outcome: AppTestOutcome, code: AppTestEvidenceCode, at date: Date) {
        observations = min(observations, 999_999) + 1
        if outcome == .success { successes = min(successes, 999_999) + 1 }
        if outcome == .failure { failures = min(failures, 999_999) + 1; lastFailure = code }
        lastOutcome = outcome; lastCode = code; lastAt = date
        if failures > 0 { status = .failed }
        else if successes > 0 { status = .passed }
        else if outcome == .unavailable { status = .unavailable }
        else { status = .observed }
    }
}

/// Ereignisse enthalten nur feste Kennungen. Keine Suchtexte, Song-IDs oder Pfade.
@MainActor enum AppTestEvents {
    struct Probe { let session: UUID?; let check: AppAutomaticCheck }
    private static var session: UUID?
    private static var receiver: ((AppAutomaticCheck, AppTestOutcome, AppTestEvidenceCode) -> Void)?
    static func start(_ id: UUID, receiver: @escaping (AppAutomaticCheck, AppTestOutcome, AppTestEvidenceCode) -> Void) {
        session = id; self.receiver = receiver
    }
    static func stop(_ id: UUID) {
        guard session == id else { return }
        session = nil; receiver = nil
    }
    static func begin(_ check: AppAutomaticCheck) -> Probe { Probe(session: session, check: check) }
    static func finish(_ probe: Probe, _ outcome: AppTestOutcome, _ code: AppTestEvidenceCode) {
        guard let id = probe.session, id == session else { return }
        receiver?(probe.check, outcome, code)
    }
    static func emit(_ check: AppAutomaticCheck, _ outcome: AppTestOutcome, _ code: AppTestEvidenceCode) {
        finish(begin(check), outcome, code)
    }
    static func verify(_ check: AppAutomaticCheck, _ condition: Bool, _ code: AppTestEvidenceCode) {
        emit(check, condition ? .success : .failure, condition ? code : .invalidState)
    }
}
