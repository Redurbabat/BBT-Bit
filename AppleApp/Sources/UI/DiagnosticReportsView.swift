import SwiftUI

/// On-device playback triage. Observes the actual controller, not design
/// previews, test songs, or assumed network errors.
struct DiagnosticReportsView: View {
    @Environment(PlaybackController.self) private var controller
    @State private var report: URL?
    @State private var message: String?

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Warum spielt die Musik nicht?")
                        .font(.headline)
                    Text(reason)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)

                LabeledContent("Wiedergabe", value: status)
                LabeledContent("Song", value: controller.current?.title ?? "Kein Song ausgewählt")
                LabeledContent("Quelle", value: sourceLabel)
                LabeledContent("Position", value: String(format: "%.1f s", controller.position))
                LabeledContent("Dauer", value: controller.duration > 0
                               ? String(format: "%.1f s", controller.duration) : "Unbekannt / 0")
                LabeledContent("Internet", value: NetworkQuality.shared.connected ? "Verbunden" : "Nicht verbunden")
                #if os(iOS)
                LabeledContent("iPhone-Audiositzung", value: AudioSessionManager.isActive ? "Aktiv" : "Inaktiv")
                #endif

                if let error = controller.lastError, !error.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Letzter Wiedergabefehler")
                            .font(.subheadline.weight(.semibold))
                        Text(PlaybackDebugLog.sanitize(error, limit: 1200))
                            .font(.footnote)
                            .foregroundStyle(.orange)
                            .textSelection(.enabled)
                    }
                    .padding(.vertical, 4)
                }

                if controller.current != nil && !controller.isPlaying && !controller.isBuffering {
                    Button {
                        retryCurrentTrack()
                    } label: {
                        Label("Aktuellen Song neu laden", systemImage: "arrow.clockwise")
                    }
                    .accessibilityIdentifier("bbt.playbackDiagnosis.retry")
                }
                if controller.isBuffering {
                    Label("Song wird geladen – bitte nicht mehrfach Play/Pause drücken.", systemImage: "hourglass")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Live-Wiedergabestatus")
            } footer: {
                Text("0:00 allein beweist keine bestimmte Ursache. Der folgende Bericht zeigt, ob Stream-Auflösung, Netzwerk oder Audioausgabe einen Fehler gemeldet haben.")
            }

            Section {
                Text("Nach einem fehlgeschlagenen Abspielversuch zuerst „Diagnosebericht speichern“ antippen, danach den Bericht teilen. Technische Ereignisse bleiben bis zum Teilen lokal auf diesem Gerät.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button("Diagnosebericht speichern") {
                    do {
                        report = try PlaybackDebugLog.shared.saveReport(snapshot: controller.diagnosticSnapshot)
                        message = "Bericht gespeichert. Jetzt „Diagnosebericht teilen“ auswählen."
                    } catch {
                        message = "Bericht fehlgeschlagen: \(error.localizedDescription)"
                    }
                }
                .accessibilityIdentifier("bbt.playbackDiagnosis.saveReport")
                if let report {
                    ShareLink("Diagnosebericht teilen", item: report)
                        .accessibilityIdentifier("bbt.playbackDiagnosis.shareReport")
                }
                if let message {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Bericht für die Fehlersuche")
            } footer: {
                Text("Der Bericht wird automatisch bereinigt, kann aber Songtitel und technische Angaben enthalten. Vor dem Weitergeben prüfen. Niemals Passwörter oder Zugangscodes senden.")
            }

            Section {
                Button("Clear Diagnostic History", role: .destructive) {
                    PlaybackDebugLog.shared.clearHistory()
                    report = nil
                    message = "Diagnostic history cleared."
                }
            }
        }
        .navigationTitle("Musik-Diagnose")
    }

    private var status: String {
        if controller.isBuffering { return "Lädt / puffert" }
        if controller.isPlaying { return "Wiedergabe läuft" }
        switch controller.state {
        case .paused: return "Pausiert"
        case .stopped: return "Gestoppt"
        default: return String(describing: controller.state)
        }
    }

    private var sourceLabel: String {
        guard let entry = controller.current else { return "Keine" }
        if entry.videoId != nil { return "YouTube / Online-Stream" }
        if entry.source.hasPrefix("http") { return "Online-Datei" }
        return "Lokal / andere Quelle"
    }

    private var reason: String {
        if let error = controller.lastError, !error.isEmpty {
            return "Die App hat einen Fehler registriert. Siehe „Letzter Wiedergabefehler“ unten. Ein Diagnosebericht hilft, die Ursache zu bestimmen."
        }
        if !NetworkQuality.shared.connected && controller.current?.videoId != nil {
            return "Das iPhone meldet keine Netzwerkverbindung. Für diesen Online-Song ist Internet erforderlich."
        }
        if controller.current == nil {
            return "Es ist noch kein Song ausgewählt. Öffne einen Titel in der Bibliothek und tippe auf Play."
        }
        if controller.isBuffering {
            return "Der Song ist ausgewählt, aber die Audioquelle wird noch geladen. Wenn die Anzeige lange stehen bleibt: Bericht speichern."
        }
        if controller.isPlaying && controller.position <= 0 && controller.duration <= 0 {
            return "Die App meldet Wiedergabe, aber weder Zeit noch Dauer sind verfügbar. Stream und Audioausgabe müssen anhand des Berichts geprüft werden."
        }
        if controller.isPlaying {
            return "Der Player meldet aktive Wiedergabe. Wenn trotzdem nichts zu hören ist, überprüfe die Audioausgabe und die Lautstärke."
        }
        return "Der Player ist nicht aktiv. Drücke Play oder lade den aktuellen Song über den Knopf unten neu."
    }

    private func retryCurrentTrack() {
        guard controller.current != nil,
              !controller.isPlaying,
              !controller.isBuffering,
              controller.queue.indices.contains(controller.playingIndex) else { return }
        report = nil
        message = "Der ausgewählte Song wird ab Anfang mit einer frisch aufgelösten Quelle geladen. Nach einem Fehler den Bericht speichern."
        controller.loadCurrent(
            controller.playingIndex,
            startAt: 0,
            refreshAutoplay: false,
            freshResolution: true
        )
    }
}
