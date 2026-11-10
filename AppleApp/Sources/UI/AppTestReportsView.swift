import SwiftUI
import UniformTypeIdentifiers

struct AppTestReportsView: View {
    private let archive = AppTestReportStore.shared

    var body: some View {
        List {
            Section {
                if archive.reports.isEmpty {
                    Text("Noch keine Testberichte gespeichert.").foregroundStyle(.secondary)
                }
                ForEach(archive.reports) { summary in
                    NavigationLink {
                        AppTestSavedReportView(summary: summary)
                    } label: {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(summary.startedAt, format: .dateTime.day().month().year().hour().minute())
                                .font(.headline)
                            Text(LocalizedStringKey(summary.state.title)).font(.subheadline)
                            if let total = summary.automaticTotal {
                                Text("\(summary.sampleCount) Messpunkte · \(summary.automaticPassed ?? 0)/\(total) automatisch geprüft · \(summary.automaticFailed ?? 0) Fehler")
                                    .font(.caption).foregroundStyle(.secondary)
                            } else { Text("Älterer Bericht").font(.caption).foregroundStyle(.secondary) }
                        }.padding(.vertical, 4)
                    }
                }
            } footer: {
                Text("Berichte bleiben auf diesem Gerät. Eine unterbrochene Aufzeichnung enthält den letzten gespeicherten Stand und gilt nicht als abgeschlossen.")
            }
            if archive.unreadableCount > 0 {
                Text("Einige Berichte konnten nicht gelesen werden. Ihre Dateien wurden nicht gelöscht.")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Gespeicherte Testberichte")
        .accessibilityIdentifier("red.tests.history")
        .onAppear { archive.refresh() }
    }
}

private struct AppTestSavedReportView: View {
    let summary: AppTestSessionSummary
    private let archive = AppTestReportStore.shared
    @State private var data: Data?
    @State private var automaticChecks: [AppTestCheckResult] = []
    @State private var readError = false
    @State private var buildRevision = "—"

    var body: some View {
        Form {
            Section("Testlauf") {
                LabeledContent("Status", value: AppLanguage.localized(summary.state.title))
                LabeledContent("Beginn") { Text(summary.startedAt, format: .dateTime) }
                LabeledContent("Letzter Speicherstand") { Text(summary.updatedAt, format: .dateTime) }
                LabeledContent("Messpunkte", value: "\(summary.sampleCount)")
                LabeledContent("Build-Revision", value: buildRevision)
            }
            if let data {
                Section("Datei speichern oder teilen") {
                    AppTestReportExportButton(data: data, name: "RED-Bit-Test-\(summary.id.uuidString)")
                    ShareLink("Testbericht teilen", item: archive.fileURL(summary.id))
                }
                Section("Automatische Ergebnisse") {
                    ForEach(automaticChecks) { check in
                        LabeledContent(LocalizedStringKey(check.id.title),
                            value: AppLanguage.localized(check.status.title))
                    }
                    if automaticChecks.isEmpty {
                        Text("Ergebnisse dieses älteren Berichts bleiben in der Originaldatei erhalten.")
                    }
                }
            }
            if readError { Text("Der Bericht konnte nicht geöffnet werden. Die Datei bleibt erhalten.") }
        }
        .formStyle(.grouped)
        .navigationTitle("Testbericht")
        .task(id: summary.id) {
            do {
                let content = try archive.read(summary.id)
                let object = try JSONSerialization.jsonObject(with: content) as? [String: Any]
                struct Payload: Decodable { let automaticChecks: [AppTestCheckResult]? }
                let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
                automaticChecks = (try? decoder.decode(Payload.self, from: content).automaticChecks) ?? []
                buildRevision = object?["buildRevision"] as? String ?? "—"
                data = content
            } catch { readError = true }
        }
    }
}

struct AppTestReportExportButton: View {
    let data: Data
    let name: String
    var latestData: (@MainActor () throws -> Data)? = nil
    @State private var presented = false
    @State private var failed = false
    @State private var document = SettingsBackupFile(text: "")
    var body: some View {
        Button("In Dateien sichern", systemImage: "square.and.arrow.down") {
            do {
                let current = try latestData?() ?? data
                document = SettingsBackupFile(text: String(decoding: current, as: UTF8.self))
                presented = true
            } catch { failed = true }
        }
            .accessibilityIdentifier("red.tests.exportFile")
            .fileExporter(isPresented: $presented,
                document: document,
                contentType: .json, defaultFilename: name) { result in
                if case .failure(let error) = result {
                    let cause = error as NSError
                    failed = !(cause.domain == NSCocoaErrorDomain && cause.code == NSUserCancelledError)
                }
            }
            .alert("Datei konnte nicht gespeichert werden", isPresented: $failed) {
                Button("OK", role: .cancel) {}
            } message: { Text("Der Bericht bleibt in der App gespeichert. Bitte erneut versuchen.") }
    }
}

extension AppTestSessionState {
    var title: String {
        switch self {
        case .running: "Aufzeichnung läuft"
        case .completed: "Abgeschlossen"
        case .interrupted: "Unterbrochen – letzter Speicherstand"
        }
    }
}
