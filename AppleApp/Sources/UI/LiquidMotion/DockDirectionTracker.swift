import Foundation

/// Reversals are detected while the same finger is still dragging, instead
/// of waiting for another touch-down. Navigation stays owned by the system.
enum DockScrollDirection: Equatable {
    case towardTop
    case towardBottom
}

/// Offline-testable hysteresis; excludes tiny scroll noise and initial layout
/// adjustments. SwiftUI's scroll phase determines whether a finger is active.
struct DockDirectionTracker {
    private(set) var isInteracting = false
    private var previousOffset: CGFloat?
    private var pendingDirection: DockScrollDirection?
    private var pendingDistance: CGFloat = 0
    private var lastEmittedDirection: DockScrollDirection?

    mutating func begin(at offset: CGFloat) {
        isInteracting = true
        previousOffset = offset
        pendingDirection = nil
        pendingDistance = 0
        lastEmittedDirection = nil
    }

    mutating func end() {
        isInteracting = false
        previousOffset = nil
        pendingDirection = nil
        pendingDistance = 0
        lastEmittedDirection = nil
    }

    mutating func sample(_ offset: CGFloat) -> DockScrollDirection? {
        guard isInteracting, let previousOffset else { return nil }
        self.previousOffset = offset
        let delta = offset - previousOffset
        guard abs(delta) > 0.75 else { return nil }

        // Scrolling toward earlier content decreases the content offset.
        let direction: DockScrollDirection = delta < 0 ? .towardTop : .towardBottom
        if pendingDirection != direction {
            pendingDirection = direction
            pendingDistance = 0
        }
        pendingDistance += abs(delta)
        guard pendingDistance >= 13, lastEmittedDirection != direction else { return nil }
        lastEmittedDirection = direction
        pendingDistance = 0
        return direction
    }
}

