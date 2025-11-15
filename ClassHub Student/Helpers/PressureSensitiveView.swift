#if os(macOS)
import SwiftUI
import AppKit

/// A lightweight NSViewRepresentable that detects Force Touch / pressure events
/// and calls the `onPressureExceeded` closure when pressure crosses a threshold.
///
/// Usage (SwiftUI):
/// ```.overlay(PressureSensitiveView(onPressureExceeded: { /* ... */ }))```
///
public struct PressureSensitiveView: NSViewRepresentable {
    public var onPressureExceeded: () -> Void
    /// Pressure threshold (0..1 typical). Adjust for sensitivity on different hardware.
    public var threshold: Float = 1.0

    public init(onPressureExceeded: @escaping () -> Void, threshold: Float = 0.6) {
        self.onPressureExceeded = onPressureExceeded
        self.threshold = threshold
    }

    public func makeNSView(context: Context) -> PressureTrackingView {
        let v = PressureTrackingView()
        v.onPressureExceeded = onPressureExceeded
        v.threshold = threshold
        v.wantsLayer = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }

    public func updateNSView(_ nsView: PressureTrackingView, context: Context) {
        // no-op for now
        nsView.onPressureExceeded = onPressureExceeded
        nsView.threshold = threshold
    }

    // MARK: - NSView that receives pressure events
    public class PressureTrackingView: NSView {
        public var onPressureExceeded: (() -> Void)?
        public var threshold: Float = 0.6

        public override func pressureChange(with event: NSEvent) {
            super.pressureChange(with: event)
            // Convert event.pressure to Float so we compare like-for-like with `threshold` (Float)
            if Float(event.pressure) >= threshold {
                onPressureExceeded?()
            }
        }

        // Accept first responder so pressure events are delivered
        public override var acceptsFirstResponder: Bool { true }

        public override func mouseDown(with event: NSEvent) {
            // Ensure subsequent pressureChange events are delivered to this view
            window?.makeFirstResponder(self)
        }

        public override func viewDidMoveToSuperview() {
            super.viewDidMoveToSuperview()
            // Fill the superview so the overlay covers the SwiftUI view area
            if let superV = superview {
                translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    widthAnchor.constraint(equalTo: superV.widthAnchor),
                    heightAnchor.constraint(equalTo: superV.heightAnchor)
                ])
            }
        }
    }
}
#endif
