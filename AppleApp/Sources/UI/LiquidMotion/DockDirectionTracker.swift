import Foundation

/// Erkennt Richtungswechsel innerhalb einer Berührung; die Navigation bleibt nativ.
enum DockScrollDirection: Equatable {
    case towardTop
    case towardBottom
}

/// Misst den Weg ab dem letzten Wendepunkt statt einzelne Bilddeltas zu filtern.
/// So bleiben langsame Gesten erkennbar, ohne auf Mikrozittern zu reagieren.
final class DockDirectionTracker {
    private(set) var isInteracting = false
    private var turningOffset: CGFloat?
    private var lastEmittedDirection: DockScrollDirection?

    func begin(at offset: CGFloat) {
        isInteracting = true
        turningOffset = offset.isFinite ? offset : nil
        lastEmittedDirection = nil
    }

    func end() {
        isInteracting = false
        turningOffset = nil
        lastEmittedDirection = nil
    }

    func sample(_ offset: CGFloat) -> DockScrollDirection? {
        guard isInteracting, offset.isFinite else { return nil }
        guard let turningOffset else {
            self.turningOffset = offset
            return nil
        }
        // Nach einer bestätigten Richtung den äußersten Punkt mitführen.
        // Erst 13 pt Gegenbewegung dürfen eine neue Richtung auslösen.
        if lastEmittedDirection == .towardBottom, offset > turningOffset {
            self.turningOffset = offset
            return nil
        }
        if lastEmittedDirection == .towardTop, offset < turningOffset {
            self.turningOffset = offset
            return nil
        }
        let distance = offset - turningOffset
        guard abs(distance) >= 13 else { return nil }
        let direction: DockScrollDirection = distance < 0 ? .towardTop : .towardBottom
        guard lastEmittedDirection != direction else { return nil }
        lastEmittedDirection = direction
        self.turningOffset = offset
        return direction
    }
}

