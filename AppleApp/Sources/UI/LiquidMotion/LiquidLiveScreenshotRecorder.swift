import SwiftUI

/// Nur die gekennzeichnete Beispielgalerie aktiviert diesen gemeinsamen Wert.
private struct LiquidDesignSampleKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var liquidDesignSample: Bool {
        get { self[LiquidDesignSampleKey.self] }
        set { self[LiquidDesignSampleKey.self] = newValue }
    }
}

#if os(iOS)
import UIKit
import Observation

/// Active only when the listener explicitly starts a capture session in Settings.
/// The PNG contains the current *actual app window*, never a sample-data card.
@MainActor @Observable
final class LiquidLiveScreenshotRecorder {
    static let shared = LiquidLiveScreenshotRecorder()

    private(set) var recording = false
    private(set) var captures: [LiquidWindowCapture] = []
    private(set) var errorMessage: String?
    private(set) var directory: URL?

    private var sessionToken = UUID()
    private var pending: Set<String> = []
    private init() {}

    var shareFiles: [URL] {
        if let directory {
            let zip = directory.appendingPathComponent("BBT-Bit-Echte-Screenshots.zip")
            if FileManager.default.fileExists(atPath: zip.path) {
                return [zip]
            }
        }
        let images = captures.compactMap { capture -> URL? in
            guard let directory else { return nil }
            let file = directory.appendingPathComponent(capture.filename)
            return FileManager.default.fileExists(atPath: file.path) ? file : nil
        }
        guard let directory else { return images }
        let report = directory.appendingPathComponent("BBT-Bit-Echte-Screenshots.json")
        return images + (FileManager.default.fileExists(atPath: report.path) ? [report] : [])
    }

    func begin() {
        do {
            let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("BBT-Bit-Live-Screenshots", isDirectory: true)
                .appendingPathComponent(UUID().uuidString, isDirectory: true)
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            sessionToken = UUID()
            pending = []
            captures = []
            directory = folder
            errorMessage = nil
            recording = true
        } catch {
            recording = false
            errorMessage = "Aufnahmeordner konnte nicht erstellt werden: \(error.localizedDescription)"
        }
    }

    func finish() {
        recording = false
        sessionToken = UUID() // Cancel pending screen captures from this session.
        pending = []
        saveManifest()
        saveArchive()
    }

    private func saveArchive() {
        guard let directory, !captures.isEmpty else { return }
        let files = captures.map { directory.appendingPathComponent($0.filename) }
            + [directory.appendingPathComponent("BBT-Bit-Echte-Screenshots.json")]
        do {
            try BBTScreenshotZIP.create(
                files: files,
                at: directory.appendingPathComponent("BBT-Bit-Echte-Screenshots.zip")
            )
        } catch {
            errorMessage = "ZIP-Erstellung fehlgeschlagen, einzelne PNG-Dateien sind noch verfügbar: \(error.localizedDescription)"
        }
    }

    func discard() {
        finish()
        if let directory { try? FileManager.default.removeItem(at: directory) }
        directory = nil
        captures = []
        errorMessage = nil
    }

    /// Triggered only by the 15 actual live Liquid Motion components.
    /// The view's context explicitly excludes the synthetic design gallery.
    func schedule(featureID: String, refresh: Bool = false) {
        guard recording, let feature = feature(for: featureID) else { return }
        // Music Island remains mounted under the Settings overlay. Do not
        // mislabel a screenshot of Settings as a live Music Island capture.
        if featureID == "island" && AppServices.shared.appModel.settingsPresented { return }
        if !refresh && captures.contains(where: { $0.featureID == featureID }) { return }
        if !pending.insert(featureID).inserted { return }
        let token = sessionToken
        let milliseconds: Int64 = featureID == "handoff" ? 300 : 850
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(milliseconds))
            guard token == sessionToken, recording else {
                pending.remove(featureID)
                return
            }
            takeScreenshot(of: feature, id: featureID)
            pending.remove(featureID)
        }
    }

    private func feature(for id: String) -> LiquidPhotoFeature? {
        LiquidPhotoFeature.allCases.first { String(describing: $0) == id }
    }

    private func takeScreenshot(of feature: LiquidPhotoFeature, id: String) {
        guard let directory else { return }
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        guard let scene = scenes.first(where: { $0.activationState == .foregroundActive }),
              let window = scene.windows.first(where: { $0.isKeyWindow }),
              window.bounds.width > 100, window.bounds.height > 100 else {
            errorMessage = "Kein aktives iPhone-App-Fenster für \(feature.title) gefunden."
            return
        }

        let format = UIGraphicsImageRendererFormat()
        format.scale = window.screen.scale
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: window.bounds.size, format: format)
        let image = renderer.image { context in
            if !window.drawHierarchy(in: window.bounds, afterScreenUpdates: true) {
                window.layer.render(in: context.cgContext)
            }
        }
        guard let data = image.pngData(), data.count > 1024 else {
            errorMessage = "Echter Screenshot fehlgeschlagen: \(feature.title)."
            return
        }

        do {
            let safeName = feature.title.lowercased()
                .replacingOccurrences(of: " ", with: "-")
            let filename = String(format: "%02d_%@_live.png", feature.rawValue + 1, safeName)
            try data.write(to: directory.appendingPathComponent(filename), options: .atomic)
            let capture = LiquidWindowCapture(
                featureID: id,
                index: feature.rawValue + 1,
                title: feature.title,
                location: feature.location,
                filename: filename,
                capturedAt: ISO8601DateFormatter().string(from: Date()),
                bytes: data.count,
                pixelWidth: Int(image.size.width * image.scale),
                pixelHeight: Int(image.size.height * image.scale)
            )
            if let previous = captures.firstIndex(where: { $0.featureID == id }) {
                captures[previous] = capture
            } else {
                captures.append(capture)
            }
            saveManifest()
        } catch {
            errorMessage = "Screenshot konnte nicht gespeichert werden: \(error.localizedDescription)"
        }
    }

    private func saveManifest() {
        guard let directory else { return }
        let report = LiquidWindowCaptureReport(
            schemaVersion: 1,
            kind: "actual-in-app-window-screenshots",
            capturedOnIPhone: true,
            limitations: "Only currently visible app window content was captured after each real Liquid Motion component appeared. Missing features were not simulated or marked as completed. These images do not certify functional correctness.",
            appVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown",
            buildRevision: Bundle.main.object(forInfoDictionaryKey: "BitChordRevision") as? String ?? "unknown",
            captured: captures.sorted { $0.index < $1.index }
        )
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            try encoder.encode(report).write(
                to: directory.appendingPathComponent("BBT-Bit-Echte-Screenshots.json"),
                options: .atomic
            )
        } catch {
            errorMessage = "Der Screenshot-Bericht konnte nicht gespeichert werden: \(error.localizedDescription)"
        }
    }
}

struct LiquidWindowCapture: Codable, Identifiable {
    let featureID: String
    let index: Int
    let title: String
    let location: String
    let filename: String
    let capturedAt: String
    let bytes: Int
    let pixelWidth: Int
    let pixelHeight: Int
    var id: String { featureID }
}

private struct LiquidWindowCaptureReport: Codable {
    let schemaVersion: Int
    let kind: String
    let capturedOnIPhone: Bool
    let limitations: String
    let appVersion: String
    let buildRevision: String
    let captured: [LiquidWindowCapture]
}

/// Invisible hook which never alters the live feature's layout.
struct LiquidLiveCaptureMarker: View {
    let id: String
    @Environment(\.liquidDesignSample) private var sample

    @MainActor static func refresh(_ id: String) {
        LiquidLiveScreenshotRecorder.shared.schedule(featureID: id, refresh: true)
    }

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .accessibilityHidden(true)
            .onAppear {
                guard !sample else { return }
                LiquidLiveScreenshotRecorder.shared.schedule(featureID: id)
            }
    }
}

struct LiquidLiveScreenshotSettingsView: View {
    @State private var recorder = LiquidLiveScreenshotRecorder.shared
    @State private var sharing = false

    var body: some View {
        List {
            Section {
                NavigationLink {
                    LiquidPhotoWayfinderView()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                            .font(.title2)
                            .foregroundStyle(.cyan)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Foto-Wegweiser mit Pfeilen")
                                .font(.headline)
                            Text("15 Stationen: wohin tippen, wann fotografieren und was bereits erledigt ist")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 7)
                }
                .accessibilityIdentifier("bbt.screenshots.guide")
            } header: {
                Text("Geführter Rundgang")
            }
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Echte App-Screenshots")
                        .font(.headline)
                    Text("Aufnahme starten, diese Seite verlassen und die neuen Funktionen in RED Bit öffnen. Bei jeder sichtbaren Liquid-Motion-Funktion speichert die App automatisch den tatsächlichen Bildschirm als PNG.")
                        .foregroundStyle(.secondary)
                    if recorder.recording {
                        Button {
                            recorder.finish()
                        } label: {
                            Label("Aufnahme beenden", systemImage: "stop.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        Button {
                            recorder.begin()
                        } label: {
                            Label("Echte Screenshots aufnehmen", systemImage: "camera.viewfinder")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    Text(recorder.recording
                         ? "Aufnahme läuft – jetzt zurück zur App wechseln und die Änderungen öffnen."
                         : "Aufnahme nicht aktiv.")
                        .font(.footnote)
                        .foregroundStyle(recorder.recording ? Color.green : Color.secondary)

                    Text("\(recorder.captures.count) von 15 echten Screenshots gespeichert")
                        .font(.subheadline.weight(.semibold))

                    if !recorder.shareFiles.isEmpty {
                        Button {
                            if recorder.recording { recorder.finish() }
                            sharing = true
                        } label: {
                            Label("Screenshots als ZIP teilen", systemImage: "square.and.arrow.up")
                        }
                    }
                    if let error = recorder.errorMessage {
                        Text(error).font(.footnote).foregroundStyle(.orange)
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("Automatische Aufnahme bei sichtbaren Funktionen")
            } footer: {
                Text("Es werden ausschließlich echte RED-Bit-App-Fenster aufgenommen. Manche Funktionen sind nur bei aktiver Musik, Downloads, Canvas oder einer Handoff-/Party-Sitzung sichtbar. Die App öffnet diese Funktionen nicht heimlich und erzeugt keine Fake-Screenshots.")
            }

            Section("Fortschritt") {
                ForEach(LiquidPhotoFeature.allCases) { feature in
                    let found = recorder.captures.contains {
                        $0.featureID == String(describing: feature)
                    }
                    HStack(spacing: 10) {
                        Image(systemName: found ? "checkmark.circle.fill" : "circle.dashed")
                            .foregroundStyle(found ? Color.green : Color.secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(feature.title)
                            Text(feature.location)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 8)
                        if found {
                            Text("PNG")
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            if !recorder.captures.isEmpty {
                Section {
                    Button(role: .destructive) {
                        recorder.discard()
                    } label: {
                        Label("Aktuelle Aufnahmen löschen", systemImage: "trash")
                    }
                } footer: {
                    Text("Screenshots können Songtitel, Albumcover oder andere persönliche Inhalte enthalten. Sie werden nur lokal gespeichert und erst durch „Teilen“ an eine ausgewählte App übergeben.")
                }
            }
        }
        .navigationTitle("Echte Screenshots")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $sharing) {
            LiquidWindowShareSheet(items: recorder.shareFiles)
        }
    }
}

private struct LiquidWindowShareSheet: UIViewControllerRepresentable {
    let items: [URL]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
#else
/// macOS builds retain the existing UI but have no iPhone capture service.
struct LiquidLiveCaptureMarker: View {
    let id: String
    @MainActor static func refresh(_ id: String) {}
    var body: some View { EmptyView() }
}
#endif
