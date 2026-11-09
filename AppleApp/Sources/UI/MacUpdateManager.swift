#if os(macOS)
import Observation
import Sparkle
import SwiftUI

/// Sparkle owns the Mac download, signature check, replacement, and relaunch flow.
/// Its settings live with the About controls so people can choose scheduled checks
/// and whether verified updates should install in the background when BitChord quits.
@MainActor
@Observable
final class MacUpdateManager {
    static let shared = MacUpdateManager()

    let controller: SPUStandardUpdaterController
    static var isConfigured: Bool {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "SUPublicEDKey") as? String,
              let decoded = Data(base64Encoded: key), decoded.count == 32,
              let feed = Bundle.main.object(forInfoDictionaryKey: "SUFeedURL") as? String else { return false }
        return feed == "https://raw.githubusercontent.com/Redurbabat/RED-Bit/main/appcast.xml"
    }

    private init() {
        controller = SPUStandardUpdaterController(
            startingUpdater: Self.isConfigured,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }

    var updater: SPUUpdater { controller.updater }

    func checkNow() {
        guard Self.isConfigured else { return }
        controller.checkForUpdates(nil)
    }
}

struct MacUpdateSettings: View {
    @State private var manager = MacUpdateManager.shared
    @State private var checksAutomatically = true
    @State private var installsAutomatically = false

    var body: some View {
        Group {
            if !MacUpdateManager.isConfigured {
                Text("Automatische Mac-Updates sind noch nicht eingerichtet.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Toggle("Check for updates automatically", isOn: $checksAutomatically)
            .onChange(of: checksAutomatically) { _, value in
                manager.updater.automaticallyChecksForUpdates = value
            }

            Toggle("Download and install updates automatically", isOn: $installsAutomatically)
            .onChange(of: installsAutomatically) { _, value in
                manager.updater.automaticallyDownloadsUpdates = value
            }
        }
        .disabled(!MacUpdateManager.isConfigured)
        .task {
            checksAutomatically = manager.updater.automaticallyChecksForUpdates
            installsAutomatically = manager.updater.automaticallyDownloadsUpdates
        }
    }
}
#endif
