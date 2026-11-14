#if os(iOS)
import SwiftUI
import UIKit

/// Dieselben 15 gekennzeichneten Vorschauen wie im vorhandenen Geräte-Selbsttest.
@MainActor enum AppTestDesignSmoke {
    static func run(controller: PlaybackController, locale: Locale) async {
        let probe = AppTestEvents.begin(.designPreviews)
        AppTestEvents.finish(probe, .observation, .pending)
        var valid = true
        for feature in LiquidPhotoFeature.allCases {
            while UIApplication.shared.applicationState != .active {
                do { try await Task.sleep(for: .seconds(1)) } catch { return }
            }
            guard !Task.isCancelled else { return }
            let renderer = ImageRenderer(content: LiquidPhotoCard(feature: feature)
                .environment(controller).environment(\.locale, locale))
            renderer.scale = 1
            let image = renderer.uiImage
            let passed = (image?.size.width ?? 0) >= 390 && (image?.size.height ?? 0) >= 780
                && (image?.pngData()?.count ?? 0) > 1024
            valid = valid && passed
            do { try await Task.sleep(for: .milliseconds(100)) } catch { return }
        }
        guard !Task.isCancelled else { return }
        AppTestEvents.finish(probe, valid ? .success : .failure, valid ? .previewRendered : .previewFailed)
    }
}
#endif
