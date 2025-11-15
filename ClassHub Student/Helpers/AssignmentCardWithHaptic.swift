import SwiftUI
import UniformTypeIdentifiers

/// A reusable assignment card that handles drops and optional force-touch menu.
/// - onSubmit: called when a file is dropped or the Submit button in the force-touch menu is pressed.
struct AssignmentCard: View {
    let title: String
    let subtitle: String
    /// Called when the card receives a file (filename). If filename is empty, it means Submit without a file.
    var onSubmit: (_ assignmentName: String, _ filename: String) -> Void

    @State private var isDropTargeted: Bool = false
    @State private var showForceMenu: Bool = false

    var body: some View {
        AssignmentCardDesign(title: title, subtitle: subtitle)
        .onDrop(of: [UTType.fileURL.identifier], isTargeted: $isDropTargeted) { providers in
            return handleDrop(providers: providers)
        }
        .overlay {
#if os(macOS)
            PressureSensitiveView(onPressureExceeded: {
                DispatchQueue.main.async {
                    self.showForceMenu = true
                }
            })
            .allowsHitTesting(true)
#else
            EmptyView()
#endif
        }
        .popover(isPresented: $showForceMenu) {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                Divider()
                HStack {
                    Button("View Details") {
                        // Not implemented here; just dismiss
                        self.showForceMenu = false
                    }
                    Button("Submit") {
                        // Submit without a file
                        onSubmit(title, "")
                        self.showForceMenu = false
                    }
                }
            }
            .padding()
            .frame(minWidth: 220)
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        // Try to load a file URL provider like the original implementation
        if let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }) {
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                if let url = url {
                    DispatchQueue.main.async {
                        onSubmit(title, url.lastPathComponent)
                    }
                }
            }
            return true
        }
        return false
    }
}

struct AssignmentCardDesign: View {
    @State var title: String
    @State var subtitle: String
    @State var thirdtitle: String?
    var body: some View {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.title)
                Text(subtitle)
                    .font(.title3)
                if thirdtitle != nil {
                    Text(thirdtitle ?? "")
                        .font(.caption)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(0.08))
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct AssignmentCard_Previews: PreviewProvider {
    static var previews: some View {
        AssignmentCard(title: "Testout Chapter 14", subtitle: "Network Fundamentals - Due Friday") { assignment, filename in
            print("submitted: \(assignment) file: \(filename)")
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
