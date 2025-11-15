//
//  ContentView.swift
//  ClassHub Student
//
//  Created by Ariel Araya-Madrigal on 10/25/25.
//

import SwiftUI
import Foundation
import UniformTypeIdentifiers
import FirebaseAuth

struct ContentView: View {
    var body: some View {
        navigationTabs()
    }
    
}

struct navigationTabs: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            ClassesView()
                .tabItem {
                    Label("Classes", systemImage: "list.bullet")
                }
            GradesView()
                .tabItem {
                    Label("Grades", systemImage: "chart.bar")
                }
            GroupsView()
                .tabItem {
                    Label("Groups", systemImage: "person.3")
                }
            YouView()
                .tabItem {
                    Label("You", systemImage: "person.crop.circle")
                }
        }
    }
}

struct HomeView: View {
    @State private var pendingAssignmentName: String = ""
    @State private var pendingFileName: String = ""
    @State private var additionalFiles: [String] = []
    @State private var navigateToSubmission: Bool = false

    // Add environment and firebase manager similar to ClassSummaryView so we can show per-user announcements
    @EnvironmentObject var authViewModel: AuthViewModel
    @ObservedObject private var firebase = FirebaseManager.shared

    // Helper to get current UID and normalize ids
    private var currentUID: String? { authViewModel.user?.uid }

    private func normalized(_ s: String?) -> String? {
        guard let s = s else { return nil }
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }

    private var enrolledClasses: [CHClass] {
        guard let uid = currentUID else { return [] }
        return firebase.classes.filter { cls in
            return cls.students.contains(uid) || cls.teacherID == uid
        }
    }

    private var enrolledClassIDs: Set<String> { Set(enrolledClasses.map { $0.id }) }

    private var announcementsForUser: [CHAnnouncement] {
        firebase.announcements.filter { a in
            if let cid = a.classID { return enrolledClassIDs.contains(cid) }
            return false
        }
    }

    private var latestAnnouncements: [CHAnnouncement] {
        announcementsForUser.sorted { a, b in
            let da = Date(timeIntervalSince1970: a.sendDate ?? 0)
            let db = Date(timeIntervalSince1970: b.sendDate ?? 0)
            return da > db
        }
    }

    // Top 10 announcements for quick access (keeps view builder free of local statements)
    private var topAnnouncements: [CHAnnouncement] {
        Array(latestAnnouncements.prefix(10))
    }
    
    // MARK: - Assignment helpers (for "To do next")
    private var submittedAssignmentIDsForCurrentUser: Set<String> {
        guard let uid = currentUID else { return [] }
        guard let nuid = normalized(uid) else { return [] }
        let ids = firebase.assignmentSubmissions.compactMap { sub -> String? in
            if let subSid = normalized(sub.submitterID), subSid == nuid {
                return normalized(sub.assignmentID)
            }
            return nil
        }
        return Set(ids)
    }

    private var pendingAssignments: [CHAssignment] {
        // assignments in enrolled classes that the user hasn't submitted and that don't have a grade
        let submitted = submittedAssignmentIDsForCurrentUser
        return firebase.assignments.filter { a in
            guard let cid = a.classID, enrolledClassIDs.contains(cid) else { return false }
            if let aid = normalized(a.id), submitted.contains(aid) { return false }
            // exclude if there's already a grade for this assignment
            let hasGrade = firebase.grades.contains { g in
                guard let gid = normalized(g.assignmentID), let aid = normalized(a.id) else { return false }
                return gid == aid
            }
            if hasGrade { return false }
            return true
        }
        .sorted { a, b in
            // sort by due date ascending (soonest first); missing dueDate goes to the end
            let da = a.dueDate.map { Date(timeIntervalSince1970: $0) } ?? Date.distantFuture
            let db = b.dueDate.map { Date(timeIntervalSince1970: $0) } ?? Date.distantFuture
            return da < db
        }
    }

    private var topPendingAssignments: [CHAssignment] {
        Array(pendingAssignments.prefix(10))
    }
    
    // Assignments for enrolled classes
    private var assignmentsForEnrolledClasses: [CHAssignment] {
        firebase.assignments.filter { a in
            if let cid = a.classID { return enrolledClassIDs.contains(cid) }
            return false
        }
    }

    // Date range for current week
    private var weekInterval: DateInterval? {
        Calendar.current.dateInterval(of: .weekOfYear, for: Date())
    }

    // Assignments due this week
    private var assignmentsDueThisWeek: [CHAssignment] {
        guard let interval = weekInterval else { return [] }
        return assignmentsForEnrolledClasses.filter { a in
            guard let due = a.dueDate else { return false }
            let d = Date(timeIntervalSince1970: due)
            return d >= interval.start && d <= interval.end
        }
    }

    // Completed assignments (for this week)
    private var completedDueThisWeek: [CHAssignment] {
        let submitted = submittedAssignmentIDsForCurrentUser
        return assignmentsDueThisWeek.filter { a in
            if let aid = normalized(a.id) { return submitted.contains(aid) }
            return false
        }
    }
    
    // Progress ratio for this week (0.0 - 1.0)
    private var progressThisWeek: Double {
        let total = assignmentsDueThisWeek.count
        guard total > 0 else { return 0.0 }
        return Double(completedDueThisWeek.count) / Double(total)
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                HStack {
                    VStack(alignment: .leading) {
                        // Use the current date with a friendly formatter
                        Text(Date(), format: Date.FormatStyle(date: .complete, time: .omitted))
                            .padding()
                            .font(.largeTitle)
                            .bold()
                        VStack(alignment: .leading)  {
                            // Show friendly progress-based header
                            if assignmentsDueThisWeek.isEmpty {
                                Text("All caught up!")
                                    .font(.title)
                                Text("No assignments due this week.")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Almost done!")
                                    .font(.title)

                                // Progress capsule + summary (matches ClassSummaryView)
                                Text("You have completed \(completedDueThisWeek.count) out of \(assignmentsDueThisWeek.count) assignments this week.")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                                /*
                                VStack(alignment: .leading, spacing: 6) {
                                    ProgressCapsuleView(progress: progressThisWeek, height: 20, showsLabel: true)
                                        .frame(height: 20)
                                        .frame(maxWidth: .infinity)
                                        .id(progressThisWeek)

                                    HStack {
                                        Text(String(format: "%.0f%% Complete", progressThisWeek * 100))
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                    }
                                }
                                */
                            }
                        }
                        .padding()
                        .clipped()
                    }
                    Spacer()
                }
                // To do next horizontal list with pending assignments
                VStack(alignment: .leading, spacing: 12) {
                    Text("To do next")
                        .font(.title)
                        .bold()

                    if topPendingAssignments.isEmpty {
                        Text("No actions required right now.")
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(topPendingAssignments.indices, id: \.self) { idx in
                                    let a = topPendingAssignments[idx]
                                    AssignmentCardRow(assignment: a)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .padding()
                // Announcements (replaced with announcements-only scroller)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Latest Announcements")
                        .font(.title)
                        .bold()

                    if latestAnnouncements.isEmpty {
                        Text("No recent announcements.")
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Array(zip(topAnnouncements.indices, topAnnouncements)), id: \.0) { (idx, ann) in
                                    AnnouncementCardRow(ann: ann)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Home")
            .padding()
            .navigationDestination(isPresented: $navigateToSubmission) {
                SubmissionView(
                    assignmentName: pendingAssignmentName,
                    initialFileName: pendingFileName
                )
            }
        }
    }

    // MARK: - Drop Handling
    private func handleDrop(providers: [NSItemProvider], forAssignment assignment: String) -> Bool {
        print("[Drop] Received drop on assignment: \(assignment). Providers count: \(providers.count)")
        for (index, provider) in providers.enumerated() {
            print("[Drop] Provider #\(index): has fileURL? \(provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier)), has data? \(provider.hasItemConformingToTypeIdentifier(UTType.data.identifier)), has content? \(provider.hasItemConformingToTypeIdentifier(UTType.content.identifier))")
        }
        // Try to load a file URL first
        if let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }) {
            print("[Drop] Using fileURL provider for assignment: \(assignment)")
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                print("[Drop] Loaded URL: \(String(describing: url))")
                if let url = url {
                    DispatchQueue.main.async {
                        print("[Drop] Setting state from URL. assignment=\(assignment), file=\(url.lastPathComponent)")
                        self.pendingAssignmentName = assignment
                        self.pendingFileName = url.lastPathComponent
                        self.additionalFiles = []
                        self.navigateToSubmission = true
                    }
                }
            }
            return true
        }
        return false
    }
}

// MARK: - A simple drop area used inside the form
//struct DropAreaView: View {
//    var onReceive: (String) -> Void
//    @State private var isTargeted: Bool = false
//
//    var body: some View {
//        ZStack {
//            RoundedRectangle(cornerRadius: 10)
//                .stroke(isTargeted ? Color.accentColor : Color.secondary, style: StrokeStyle(lineWidth: 2, dash: [6]))
//                .frame(maxWidth: .infinity, minHeight: 80)
//            Text("Drag more files here")
//                .foregroundStyle(.secondary)
//        }
//        .contentShape(Rectangle())
//        .onDrop(of: [UTType.fileURL.identifier], isTargeted: $isTargeted) { providers in
//            print("[DropArea] Received drop. Providers count: \(providers.count)")
//            if let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }) {
//                print("[DropArea] Using fileURL provider")
//                _ = provider.loadObject(ofClass: URL.self) { url, _ in
//                    print("[DropArea] Loaded URL: \(String(describing: url))")
//                    if let url = url {
//                        DispatchQueue.main.async {
//                            onReceive(url.lastPathComponent)
//                        }
//                    }
//                }
//                return true
//            }
//            return false
//        }
//        .padding(.vertical, 4)
//    }
//}

// PressureSensitiveView (macOS-only) moved to `PressureSensitiveView.swift`

struct AnnouncementCardRow: View {
    let ann: CHAnnouncement

    private var className: String {
        FirebaseManager.shared.className(for: ann.classID ?? "")
    }

    private var relativeDate: String {
        guard let sd = ann.sendDate else { return "" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        let d = Date(timeIntervalSince1970: sd)
        return formatter.localizedString(for: d, relativeTo: Date())
    }

    var body: some View {
        let third = [className, "Announcement", relativeDate].filter({ !$0.isEmpty }).joined(separator: " • ")
        NavigationLink {
            AnnouncementView(announementTitle: ann.title ?? "", announementSubtitle: ann.subtitle ?? "")
        } label: {
            AssignmentCardDesign(title: ann.title ?? "Announcement",
                                 subtitle: ann.subtitle ?? "",
                                 thirdtitle: third)
                .frame(maxWidth: 400, maxHeight: 100)
        }
        .buttonStyle(.borderless)
    }
}

// Small row for assignment cards in the Home "To do next" scroller
struct AssignmentCardRow: View {
    let assignment: CHAssignment

    private var className: String {
        FirebaseManager.shared.className(for: assignment.classID ?? "")
    }

    private var relativeDue: String {
        guard let dd = assignment.dueDate else { return "" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        let d = Date(timeIntervalSince1970: dd)
        return formatter.localizedString(for: d, relativeTo: Date())
    }

    var body: some View {
        let third = [className, (relativeDue.isEmpty ? "" : "Due " + relativeDue)].filter({ !$0.isEmpty }).joined(separator: " • ")
        NavigationLink {
            let destDueDate = assignment.dueDate != nil ? Date(timeIntervalSince1970: assignment.dueDate!) : Date()
            AssignmentView(assignmentName: assignment.title,
                           assignmentDescription: assignment.subtitle ?? "",
                           assignmentDueDate: destDueDate,
                           assignmentID: assignment.id,
                           assignmentCollaberative: false,
                           assignmentPoints: assignment.maxPoints,
                           assignmentScoredPoints: 0,
                           showSubmit: true)
        } label: {
            AssignmentCardDesign(title: assignment.title, subtitle: assignment.subtitle ?? "", thirdtitle: third)
                .frame(maxWidth: 400, maxHeight: 100)
        }
        .buttonStyle(.borderless)
    }
}
