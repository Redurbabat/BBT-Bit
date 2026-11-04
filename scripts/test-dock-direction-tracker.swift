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
        print("DockDirectionTracker: 8 gesture assertions PASSED")
    }
}
