import SwiftUI
import UniformTypeIdentifiers

/// A simple drop area view used inside submission forms. Calls `onReceive` with the dropped file's lastPathComponent.
struct DropAreaView: View {
    var onReceive: (String) -> Void
    @State private var isTargeted: Bool = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .stroke(isTargeted ? Color.accentColor : Color.secondary, style: StrokeStyle(lineWidth: 2, dash: [6]))
                .frame(maxWidth: .infinity, minHeight: 80)
            Text("Drag more files here")
                .foregroundStyle(.secondary)
        }
        .contentShape(Rectangle())
        .onDrop(of: [UTType.fileURL.identifier], isTargeted: $isTargeted) { providers in
            if let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }) {
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    if let url = url {
                        DispatchQueue.main.async {
                            onReceive(url.lastPathComponent)
                        }
                    }
                }
                return true
            }
            return false
        }
        .padding(.vertical, 4)
    }
}

struct DropAreaView_Previews: PreviewProvider {
    static var previews: some View {
        DropAreaView { name in
            print("Dropped: \(name)")
        }
        .frame(height: 100)
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
