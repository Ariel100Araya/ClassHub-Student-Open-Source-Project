import SwiftUI

/// A capsule-shaped progress bar that fills from 0.0 to 1.0
/// Displays an optional percentage label centered on top.
struct ProgressCapsuleView: View {
    /// progress: 0.0 .. 1.0
    var progress: Double
    /// height of the capsule
    var height: CGFloat = 18
    /// whether to show the percentage label inside the capsule
    var showsLabel: Bool = true

    /// Initialize with a normalized progress 0.0 .. 1.0
    init(progress: Double, height: CGFloat = 18, showsLabel: Bool = true) {
        // Defensively handle NaN/Infinity and clamp to 0..1
        let safe = progress.isFinite ? progress : 0.0
        self.progress = min(max(safe, 0.0), 1.0)
        self.height = height
        self.showsLabel = showsLabel
    }

    /// Initialize with a percent value 0 .. 100
    init(percent: Double, height: CGFloat = 18, showsLabel: Bool = true) {
        let p = percent / 100.0
        let safe = p.isFinite ? p : 0.0
        self.progress = min(max(safe, 0.0), 1.0)
        self.height = height
        self.showsLabel = showsLabel
    }

    var body: some View {
        // Defensive local copy
        let pct = min(max(progress, 0.0), 1.0)

        ZStack {
            // background track
            Capsule()
                .fill(Color.secondary.opacity(0.12))
                .frame(height: height)

            // foreground fill: full-size capsule scaled horizontally from leading edge
            Capsule()
                .fill(LinearGradient(colors: [Color.accentColor, Color.accentColor.opacity(0.7)], startPoint: .leading, endPoint: .trailing))
                .frame(height: height)
                .frame(maxWidth: .infinity, alignment: .leading)
                .scaleEffect(x: CGFloat(pct), y: 1.0, anchor: .leading)
                .animation(.easeInOut(duration: 0.35), value: pct)

            if showsLabel {
                Text(String(format: "%.0f%%", pct * 100))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(pct > 0.5 ? Color.white : Color.primary)
            }
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
    }
}

struct ProgressCapsuleView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            ProgressCapsuleView(progress: 0.0)
            ProgressCapsuleView(progress: 0.25)
            ProgressCapsuleView(progress: 0.5)
            ProgressCapsuleView(progress: 0.9)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
