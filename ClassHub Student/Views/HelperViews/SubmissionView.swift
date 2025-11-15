import SwiftUI
import Foundation

struct SubmissionView: View {
    let assignmentName: String
    let initialFileName: String

    @Environment(\.dismiss) private var dismiss
    @State private var additionalFiles: [String] = []

    private func displayName(for filename: String) -> String {
        let ext = URL(fileURLWithPath: filename).pathExtension.lowercased()
        switch ext {
        case "docx": return filename + " — Word Document"
        case "xlsx": return filename + " — Excel Workbook"
        case "pptx": return filename + " — PowerPoint Presentation"
        default: return filename
        }
    }

    var body: some View {
        Form {
            Text(assignmentName)
                .bold()
                .font(.largeTitle)
                .padding()
            Text(displayName(for: initialFileName))
                .font(.title2)
                .padding()
            if !additionalFiles.isEmpty {
                ForEach(additionalFiles, id: \.self) { name in
                    Text(displayName(for: name))
                        .font(.title2)
                        .padding()
                }
            }
            // Add more by dropping into this area, too
            DropAreaView(onReceive: { name in
                additionalFiles.append(name)
            })
        }
        .navigationTitle(Text("Submit \(assignmentName)"))
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Send") {
                    // TODO: Hook into submission flow
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SubmissionView(assignmentName: "Testout Chapter 14", initialFileName: "Progress on ClassHub.docx")
    }
}
