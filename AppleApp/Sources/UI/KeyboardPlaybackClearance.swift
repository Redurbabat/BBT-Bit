#if os(iOS)
import SwiftUI
import UIKit

/// Liest ausschließlich öffentliche Suchfeld-Geometrie. Bei der nativen
/// externen Tab-Suche meldet die Navigation deren Höhe nicht als Safe Area.
struct NativeSearchClearance: UIViewRepresentable {
    let active: Bool
    let onChange: (CGFloat) -> Void

    func makeUIView(context: Context) -> SearchClearanceView { SearchClearanceView() }
    func updateUIView(_ view: SearchClearanceView, context: Context) {
        view.active = active
        view.onChange = onChange
        view.sampleSoon()
    }

    final class SearchClearanceView: UIView {
        var active = false
        var onChange: ((CGFloat) -> Void)?
        private var pending = false
        private var last: CGFloat = -1
        private var keyboardFrame: CGRect?
        private var tokens: [NSObjectProtocol] = []

        override init(frame: CGRect) {
            super.init(frame: frame)
            isUserInteractionEnabled = false
            isAccessibilityElement = false
            for name in [UIResponder.keyboardWillChangeFrameNotification, UIResponder.keyboardDidShowNotification,
                         UIResponder.keyboardDidChangeFrameNotification] {
                tokens.append(NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] notification in
                    MainActor.assumeIsolated {
                        self?.keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
                        self?.sampleSoon()
                    }
                })
            }
        }
        required init?(coder: NSCoder) { fatalError("init(coder:) wird nicht verwendet") }
        deinit { for token in tokens { NotificationCenter.default.removeObserver(token) } }
        override func layoutSubviews() { super.layoutSubviews(); sampleSoon() }
        override func didMoveToWindow() { super.didMoveToWindow(); sampleSoon() }

        func sampleSoon() {
            guard !pending else { return }
            pending = true
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.pending = false
                self.sample()
            }
        }

        private func sample() {
            guard active, let window else { publish(0); return }
            let hostBottom = convert(bounds, to: window).maxY
            let keyboardTop = keyboardFrame.map { window.convert($0, from: nil).minY } ?? (hostBottom - safeAreaInsets.bottom)
            // Die Messbasis darf sich nicht mit unserem zusätzlichen Inset
            // verschieben, sonst würde der Abstand abwechselnd ein-/ausblenden.
            let bottom = keyboardFrame == nil ? hostBottom : keyboardTop
            var top = bottom
            func visit(_ view: UIView) {
                guard !view.isHidden, view.alpha > 0.01 else { return }
                if view is UISearchBar || view is UISearchTextField {
                    let frame = view.convert(view.bounds, to: window)
                    if frame.width > 44, frame.height > 12,
                       frame.minY > window.bounds.height * 0.35, frame.minY < bottom,
                       frame.maxY < bottom + 100 {
                        top = min(top, frame.minY - 8)
                    }
                }
                for child in view.subviews { visit(child) }
            }
            visit(window)
            publish(max(0, bottom - top))
        }

        private func publish(_ value: CGFloat) {
            guard abs(value - last) > 0.5 else { return }
            last = value
            onChange?(value)
        }
    }
}
#endif
