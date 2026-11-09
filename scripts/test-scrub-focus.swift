import Foundation

@main struct VerifyScrubFocus {
    static func main() {
        func focus(_ value: Double, _ center: Double = 0.5,
                   scrubbing: Bool = true, reduced: Bool = false) -> Double {
            ScrubFocusGeometry.emphasis(at: value, focus: center,
                                       scrubbing: scrubbing, reducedMotion: reduced)
        }
        precondition(focus(0.5) == 1)
        precondition(focus(0.44) > 0 && abs(focus(0.44) - focus(0.56)) < 0.000001)
        precondition(focus(0.2) == 0 && focus(0.8) == 0)
        precondition(focus(0, 0) == 1 && focus(1, 1) == 1)
        precondition(focus(0.5, scrubbing: false) == 0)
        precondition(focus(0.5, reduced: true) == 0)
        precondition(focus(.nan) == 0 && focus(0.5, .infinity) == 0)
        precondition(focus(-0.1) == 0 && focus(1.1) == 0)
        for index in 0...100 {
            let value = focus(Double(index) / 100)
            precondition(value.isFinite && (0...1).contains(value))
        }
        print("BESTANDEN: Scrub-Fokus, ruhender Zustand, reduzierte Bewegung, Grenzen und ungültige Werte")
    }
}
