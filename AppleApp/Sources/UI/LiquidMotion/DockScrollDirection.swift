#if os(iOS)
import SwiftUI
import Observation

@MainActor
@Observable
final class DockScrollCoordinator {
    static let shared = DockScrollCoordinator()
    private(set) var keepExpanded = false
    private(set) var direction: DockScrollDirection = .towardBottom
    private(set) var directionRevision = 0

    private init() {}

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
                        let g = context.geometry
                        let value = g.contentOffset.y + g.contentInsets.top
                        let highest = max(0, g.contentSize.height + g.contentInsets.top +
                                             g.contentInsets.bottom - g.containerSize.height)
                        tracker.begin(at: min(max(0, value), highest))
                        // Den sichtbaren Dock-Zustand bis zur bestätigten
                        // Bewegungsrichtung bewahren; Touch-down ist kein Scroll-down.
                    } else if tracker.isInteracting {
                        tracker.end()
                    }
                }
                .onScrollGeometryChange(for: CGFloat.self) { geometry in
                    let value = geometry.contentOffset.y + geometry.contentInsets.top
                    let highest = max(0, geometry.contentSize.height + geometry.contentInsets.top +
                                         geometry.contentInsets.bottom - geometry.containerSize.height)
                    return min(max(0, value), highest)
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
