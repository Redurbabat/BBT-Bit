#if os(iOS)
import SwiftUI
import Observation

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

@MainActor
@Observable
final class DockScrollCoordinator {
    static let shared = DockScrollCoordinator()
    private(set) var keepExpanded = false
    private(set) var direction: DockScrollDirection = .towardBottom
    private(set) var directionRevision = 0

    private init() {}

    /// Re-arm Apple's normal minimization at the beginning of a new drag.
    /// The previous upward reversal used .never to restore its native bar.
    func beganDragging() {
        keepExpanded = false
    }

    func moved(_ newDirection: DockScrollDirection) {
        direction = newDirection
        directionRevision &+= 1
        // Apple's onScrollDown can wait for a new drag boundary before
        // expanding on reversal. Temporarily selecting never requests the
        // original tab bar, not a competing custom dock.
        keepExpanded = newDirection == .towardTop
    }
}

/// Attach directly to the primary vertical ScrollView, not a parent containing
/// multiple horizontal carousels. No competing custom DragGesture is installed.
struct DockScrollDirectionObserver: ViewModifier {
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var tracker = DockDirectionTracker()
    @State private var coordinator = DockScrollCoordinator.shared

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *), sizeClass == .compact {
            content
                .onScrollPhaseChange { _, phase, context in
                    if phase == .interacting {
                        tracker.begin(at: context.geometry.contentOffset.y)
                        coordinator.beganDragging()
                    } else if tracker.isInteracting {
                        tracker.end()
                    }
                }
                .onScrollGeometryChange(for: CGFloat.self) { geometry in
                    geometry.contentOffset.y
                } action: { _, newOffset in
                    if let direction = tracker.sample(newOffset) {
                        coordinator.moved(direction)
                    }
                }
        } else {
            content
        }
    }
}
#endif
