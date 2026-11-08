import Foundation

@main
struct DockDirectionTrackerSmokeTests {
    static func main() {
        var drag = DockDirectionTracker()
        precondition(drag.sample(10) == nil, "No active finger: ignore layout and momentum")
        drag.begin(at: 50)
        precondition(drag.sample(54) == nil, "Tiny downward movement is noise")
        precondition(drag.sample(68) == .towardBottom, "Scroll down minimizes the dock")
        precondition(drag.sample(83) == nil, "Do not repeat the same direction")
        precondition(drag.sample(78) == nil, "Small upward jitter must not reveal")
        precondition(drag.sample(64) == .towardTop,
                     "Reversing upward WITHOUT releasing the finger must reveal")
        precondition(drag.sample(49) == nil, "Only one reveal per direction")
        drag.end()
        precondition(drag.sample(30) == nil, "Inertial scroll must be ignored")
        drag.begin(at: 30)
        precondition(drag.sample(10) == .towardTop,
                     "A fresh upward gesture is recognized")
        drag.end()
        drag.begin(at: 120)
        precondition(drag.sample(99) == .towardTop,
                     "Upward motion can be the first movement")
        precondition(drag.sample(125) == .towardBottom,
                     "Reverse downward during SAME touch is recognized")
        // Kleine Schritte auf 120-Hz-Displays müssen sich zu einem Weg addieren.
        drag.end()
        drag.begin(at: 100)
        var slowDirection: DockScrollDirection?
        for step in 1...60 {
            slowDirection = drag.sample(100 - CGFloat(step) * 0.25) ?? slowDirection
        }
        precondition(slowDirection == .towardTop,
                     "Langsame Bewegung unter 0,75 pt pro Bild muss erkannt werden")

        // Abwechselndes Mikrozittern darf den Gesamtweg nicht löschen.
        drag.end()
        drag.begin(at: 100)
        for offset: CGFloat in [104, 103, 108, 107, 112, 111] {
            precondition(drag.sample(offset) == nil, "Unterhalb der Hysterese bleibt das Dock ruhig")
        }
        precondition(drag.sample(114) == .towardBottom,
                     "Ein kleiner Gegenimpuls darf den erkennbaren Scrollweg nicht zurücksetzen")
        precondition(drag.sample(.nan) == nil, "Ungültige Layoutwerte ignorieren")
        precondition(drag.sample(130) == nil, "Ein ungültiger Wert darf den Tracker nicht vergiften")
        precondition(drag.sample(116) == .towardTop, "Umkehr nach einem Layoutfehler bleibt möglich")
        drag.end()
        drag.begin(at: .infinity)
        precondition(drag.sample(100) == nil, "Erster gültiger Wert setzt den Startpunkt")
        precondition(drag.sample(80) == .towardTop, "Nach ungültigem Start normal weiterarbeiten")
        print("DockDirectionTracker: Scrollumkehr, langsame Schritte, Zittern und ungültige Werte BESTANDEN")
    }
}
