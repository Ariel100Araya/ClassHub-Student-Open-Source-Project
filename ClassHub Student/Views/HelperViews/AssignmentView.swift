//
//  AssignmentView.swift
//  ClassHub Student
//
//  Created by Ariel Araya-Madrigal on 10/30/25.
//

import SwiftUI
import UniformTypeIdentifiers
import FirebaseAuth

struct AssignmentView: View {
    @State var assignmentName: String
    @State var assignmentDescription: String
    @State var assignmentDueDate: Date
    @State var assignmentID: String
    @State var assignmentCollaberative: Bool
    @State var assignmentPoints: Int
    @State var assignmentScoredPoints: Int
    // When false the view is read-only (no submit UI)
    var showSubmit: Bool = true

    // Explicit initializer so callers can create this view by passing values.
    init(assignmentName: String,
         assignmentDescription: String,
         assignmentDueDate: Date,
         assignmentID: String,
         assignmentCollaberative: Bool,
         assignmentPoints: Int,
         assignmentScoredPoints: Int,
         showSubmit: Bool = true) {
        // Initialize property-wrapped @State properties using the projected/value initializer
        self._assignmentName = State(initialValue: assignmentName)
        self._assignmentDescription = State(initialValue: assignmentDescription)
        self._assignmentDueDate = State(initialValue: assignmentDueDate)
        self._assignmentID = State(initialValue: assignmentID)
        self._assignmentCollaberative = State(initialValue: assignmentCollaberative)
        self._assignmentPoints = State(initialValue: assignmentPoints)
        self._assignmentScoredPoints = State(initialValue: assignmentScoredPoints)
        self.showSubmit = showSubmit
    }

    // Drop state
    @State private var primaryFileName: String = ""
    @State private var additionalFiles: [String] = []
    @State private var isDropTargeted: Bool = false
    // Submission state
    @State private var isSubmitting: Bool = false
    @State private var showSubmissionResult: Bool = false
    @State private var submissionResultMessage: String = ""

    // Observe grades to show real scored/max points when available
    @ObservedObject private var firebase = FirebaseManager.shared

    // Current user helper
    private var currentUID: String? { Auth.auth().currentUser?.uid }

    // Effective flag: show submit UI only when there is no submission for this assignment by the current user.
    private var showSubmitEffective: Bool {
        // If assignmentID is empty treat as read-only
        guard !assignmentID.isEmpty else { return false }
        // If the caller explicitly set showSubmit to false, respect that as a hard override
        if showSubmit == false { return false }
        // If user isn't signed in, allow showing submit UI (they'll be prompted to sign in when submitting).
        guard let uid = currentUID else { return true }
        let userHasSubmitted = firebase.assignmentSubmissions.contains(where: { sub in
            return sub.assignmentID == assignmentID && sub.submitterID == uid
        })
        let effective = !userHasSubmitted
        print("[AssignmentView] showSubmitEffective -> assignmentID=\(assignmentID), currentUID=\(uid), userHasSubmitted=\(userHasSubmitted), passedShowSubmit=\(showSubmit), effective=\(effective)")
        return effective
    }

    private var gradeForAssignment: CHGrade? {
        return firebase.grades.first(where: { $0.assignmentID == assignmentID })
    }

    private var displayedMaxPoints: Int {
        if let m = gradeForAssignment?.maxPoints { return Int(m.rounded()) }
        return assignmentPoints
    }

    private var displayedScoredPoints: Int? {
        if let p = gradeForAssignment?.points { return Int(p.rounded()) }
        return nil
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // Header with title and submit
                HStack {
                    VStack(alignment: .leading, spacing: 12) {
                        if !assignmentName.isEmpty {
                            Text(assignmentName)
                                .font(.largeTitle)
                                .bold()
                        }
                        // show due date and points briefly
                        HStack(spacing: 12) {
                            Text("Due: \(assignmentDueDate.formatted(date: .abbreviated, time: .omitted))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("Points: \(displayedMaxPoints)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            if let scored = displayedScoredPoints {
                                Text("Scored: \(scored)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    Spacer()
                    if showSubmitEffective {
                        Button(action: {
                            submitAssignment()
                        }) {
                            if isSubmitting {
                                ProgressView()
                            } else {
                                Text("Submit")
                            }
                        }
                        .disabled(isSubmitting)
                        .buttonStyle(.glassProminent)
                    }
                }
                .padding([.leading, .top, .trailing])

                // Description area
                VStack(alignment: .leading) {
                    Text(assignmentDescription)
                        .padding()
                        .font(.title2)
                }

                // Drop target area (visual) — accepts files dropped anywhere on this area
                if showSubmitEffective {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isDropTargeted ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: isDropTargeted ? 2 : 1)
                            .frame(maxWidth: .infinity, minHeight: 120)

                        if primaryFileName.isEmpty {
                            VStack {
                                Text("Drag a file here to attach")
                                    .foregroundColor(.secondary)
                                Text("or continue to Submit without attaching a file")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Attached:")
                                    .font(.headline)
                                Text(primaryFileName)
                                    .font(.subheadline)
                                if !additionalFiles.isEmpty {
                                    ForEach(additionalFiles, id: \.self) { f in
                                        Text("• \(f)")
                                            .font(.subheadline)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                        }
                    }
                    .padding(.horizontal)
                    .onDrop(of: [UTType.fileURL.identifier], isTargeted: $isDropTargeted) { providers in
                        handleDrop(providers: providers)
                    }

                    // allow dropping more files into a small drop area
                    if !primaryFileName.isEmpty {
                        DropAreaView(onReceive: { name in
                            additionalFiles.append(name)
                        })
                        .padding(.horizontal)
                    }
                }

                Spacer()
            }
        }
        .onAppear {
            print("[AssignmentView] onAppear -> assignmentID=\(assignmentID), showSubmit=\(showSubmit), primaryFile=\(primaryFileName)")
        }
        .alert(isPresented: $showSubmissionResult) {
            Alert(title: Text("Submission"), message: Text(submissionResultMessage), dismissButton: .default(Text("OK")))
        }
    }

    // MARK: - Drop handling
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        print("[AssignmentView] Received drop. Providers: \(providers.count)")
        if let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }) {
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                print("[AssignmentView] Loaded URL: \(String(describing: url))")
                if let url = url {
                    DispatchQueue.main.async {
                        self.primaryFileName = url.lastPathComponent
                    }
                }
            }
            return true
        }
        return false
    }

    // MARK: - Submission
    private func submitAssignment() {
        guard !isSubmitting else { return }
        guard let uid = Auth.auth().currentUser?.uid else {
            submissionResultMessage = "You're not signed in. Please sign in to submit."
            showSubmissionResult = true
            return
        }

        isSubmitting = true

        // Build a simple submission link from attached filenames. Ideally you'd upload to Storage and use a real URL.
        var link: String? = nil
        if !primaryFileName.isEmpty {
            if additionalFiles.isEmpty {
                link = primaryFileName
            } else {
                link = ([primaryFileName] + additionalFiles).joined(separator: ",")
            }
        } else if !additionalFiles.isEmpty {
            link = additionalFiles.joined(separator: ",")
        }

        FirebaseManager.shared.createAssignmentSubmission(submitterID: uid, assignmentID: assignmentID, classID: nil, submissionLink: link) { error in
            DispatchQueue.main.async {
                self.isSubmitting = false
                if let error = error {
                    self.submissionResultMessage = "Failed to submit: \(error.localizedDescription)"
                } else {
                    self.submissionResultMessage = "Submission created successfully."
                    // Clear attachments after successful submission
                    self.primaryFileName = ""
                    self.additionalFiles.removeAll()
                }
                self.showSubmissionResult = true
            }
        }
    }
}

// no preview needed here; existing preview in other files can navigate to this view
