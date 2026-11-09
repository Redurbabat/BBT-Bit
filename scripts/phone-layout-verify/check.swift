import Foundation

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
        bloom.playbackStartedOrTrackChanged()
        precondition(!bloom.isVisible, "Wiedergabestart öffnet ungefragt einen zweiten Player")
        bloom.scrollChanged(.towardTop)
        precondition(!bloom.isVisible, "Hochscrollen überdeckt die Kopfzeile mit einem zweiten Player")
        bloom.logoTapped()
        precondition(bloom.phase == .compact, "Logo-Tipp muss die Steuerung weiterhin öffnen")
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
