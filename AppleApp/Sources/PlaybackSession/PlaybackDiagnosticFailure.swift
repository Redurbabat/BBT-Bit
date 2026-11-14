/// Feste Diagnosekategorien; keine Titel, URLs oder Fehlermeldungen im JSON.
enum PlaybackDiagnosticFailure: String, Codable {
    case audioSession, engine, load, output, streamRecovery, networkWait
}
