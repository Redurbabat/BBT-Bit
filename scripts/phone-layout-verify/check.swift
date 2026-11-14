import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

// UIKit-/Animationsadapter für den echten Präsentationskoordinator.
struct Animation {
    static func spring(response: Double, dampingFraction: Double) -> Animation { Animation() }
    static func easeOut(duration: Double) -> Animation { Animation() }
}
func withAnimation<T>(_ animation: Animation?, _ action: () -> T) -> T { action() }
enum UIAccessibility { static let isReduceMotionEnabled = true }

// PRODUCTION_LOGO_COORDINATOR

@main enum PhoneLayoutChecks {
    @MainActor static func main() {
        let bloom = LogoGlassBloomCoordinator.shared
        bloom.dismiss()
        let logo = CGRect(x: 12, y: 40, width: 44, height: 44)
        let action = CGRect(x: 280, y: 40, width: 44, height: 44)
        bloom.updateLogoFrame(logo)
        bloom.updateLogoFrame(CGRect(x: CGFloat.infinity, y: 40, width: 44, height: 44))
        bloom.updateLogoFrame(CGRect(x: 20, y: 40, width: 0, height: 44))
        bloom.updateToolbarFrame(CGRect(x: 100, y: 140, width: 44, height: 44), id: UUID())
        bloom.updateToolbarFrame(CGRect(x: 330, y: 40, width: 44, height: 44), id: UUID())
        bloom.updateToolbarFrame(action, id: UUID())
        bloom.playbackStartedOrTrackChanged()
        precondition(!bloom.isVisible, "Wiedergabestart öffnet ungefragt einen zweiten Player")
        bloom.scrollChanged(.towardTop)
        precondition(!bloom.isVisible, "Hochscrollen überdeckt die Kopfzeile mit einem zweiten Player")
        bloom.logoTapped()
        precondition(bloom.phase == .compact, "Logo-Tipp muss die Steuerung weiterhin öffnen")
        precondition(bloom.presentationLogoFrame == logo, "Ungültige Geometrie darf den Logo-Ursprung nicht ersetzen")
        precondition(bloom.presentationTrailingFrame == action, "Nur die nächste Toolbar-Aktion derselben Zeile begrenzt die Insel")
        bloom.logoTapped()
        precondition(bloom.phase == .expanded)
        bloom.playbackStartedOrTrackChanged()
        precondition(bloom.phase == .expanded, "Ein Titelwechsel darf bewusst geöffnete Steuerung nicht einklappen")
        bloom.scrollChanged(.towardTop)
        precondition(!bloom.isVisible, "Weiterlesen muss die Zusatzsteuerung schließen")
        bloom.logoHeld()
        precondition(bloom.phase == .expanded)
        bloom.scrollChanged(.towardBottom)
        precondition(!bloom.isVisible)
        print("BESTANDEN: Kein automatischer Zweitplayer; Logo-Tipp/Halten, Titelwechsel und Scroll-Abbruch")
    }
}
