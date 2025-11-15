//
//  FocusedClassView.swift
//  ClassHub Student
//
//  Created by Ariel Araya-Madrigal on 10/30/25.
//

import SwiftUI
import FirebaseAuth

struct FocusedClassView: View {
    // The name and id of the class being focused.
    var className: String = ""
    var classID: String = ""

    @ObservedObject private var firebase = FirebaseManager.shared
    @State private var progress: Double = 8/15
    @State private var teacherEmail: String? = nil
    @State private var showGradebook: Bool = false
    @Environment(\.openURL) private var openURL

    // Current user helper
    private var currentUID: String? { Auth.auth().currentUser?.uid }

    // Return true when the assignment should be visible.
    // Hide only when the CURRENT USER has already submitted for this assignment (submitterID == current user uid).
    private func shouldShowAssignment(_ a: CHAssignment) -> Bool {
        guard a.classID == classID else { return false }
        // If the user is not signed in, show assignments.
        guard let uid = currentUID else {
            print("[FocusedClassView] shouldShowAssignment -> user not signed in, showing assignmentID=\(a.id)")
            return true
        }
        // Normalize/trim IDs before comparing to avoid whitespace mismatches
        func normalized(_ s: String?) -> String? {
            guard let s = s else { return nil }
            let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        let aid = normalized(a.id)
        let nuid = normalized(uid)
        let found = firebase.assignmentSubmissions.contains(where: { sub in
            let sid = normalized(sub.submitterID)
            let subAid = normalized(sub.assignmentID)
            return sid != nil && nuid != nil && sid == nuid && subAid == aid
        })
        // Debug logging to help trace why assignments might be hidden
        print("[FocusedClassView] shouldShowAssignment -> assignmentID=\(a.id), classID=\(String(describing: a.classID)), submissionsCount=\(firebase.assignmentSubmissions.count), foundSubmissionByCurrentUser=\(found), currentUID=\(uid)")
        return !found
    }

    // Compute a simple class grade (0..1) from grades for this class
    private var classGradeValue: Double {
        let classGrades = firebase.grades.filter { $0.classID == classID }
        var gradeValue: Double = 0.0
        if !classGrades.isEmpty {
            var totalPoints: Double = 0
            var totalMax: Double = 0
            for g in classGrades {
                if let p = g.points, let m = g.maxPoints {
                    totalPoints += p
                    totalMax += m
                }
            }
            if totalMax > 0 { gradeValue = totalPoints / totalMax }
        }
        return gradeValue
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            // Single vertical stack with consistent spacing and a single padding call (like ClassSummaryView)
            VStack(alignment: .leading) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        if !className.isEmpty {
                            Text(className)
                                .font(.largeTitle)
                                .bold()
                        }
                    }
                    Spacer()
                }

                // Action buttons (compact)
                HStack(spacing: 12) {
                    Button("E-mail teacher"){
                        // Resolve teacher ID from the class record and fetch their email, then open mailto:
                        if let teacherID = firebase.classes.first(where: { $0.id == classID })?.teacherID {
                            if let email = teacherEmail {
                                if let mailURL = URL(string: "mailto:\(email.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? email)") {
                                    openURL(mailURL)
                                }
                            } else {
                                firebase.fetchUserEmail(userID: teacherID) { email in
                                    DispatchQueue.main.async {
                                        self.teacherEmail = email
                                        if let e = email, let mailURL = URL(string: "mailto:\(e.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? e)") {
                                            openURL(mailURL)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .buttonStyle(.glass)

                    Button("See Gradebook"){
                        withAnimation { showGradebook = true }
                    }
                    .buttonStyle(.glass)

                    Spacer()
                }
                .padding(.bottom)

                // Announcements section (compact horizontal list)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Latest Announcements")
                        .font(.title)
                        .bold()
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(firebase.announcements.filter { $0.classID == classID }) { ann in
                                NavigationLink {
                                    AnnouncementView(announementTitle: ann.title ?? "", announementSubtitle: ann.subtitle ?? "")
                                } label: {
                                    AssignmentCardDesign(title: ann.title ?? "Announcement", subtitle: ann.subtitle ?? "")
                                        .frame(maxWidth: 400, maxHeight: 100)
                                }
                                .buttonStyle(.borderless)
                                .buttonStyle(.glass)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                // Assignments section
                VStack(alignment: .leading) {
                    Text("Latest Assignments")
                        .font(.title)
                        .bold()
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(firebase.assignments.filter { shouldShowAssignment($0) }) { a in
                                NavigationLink {
                                    // Open assignment with submission enabled (assignment is visible because no submission exists)
                                    // Safely convert optional epoch to Date; fall back to now if missing
                                    let destDueDate = a.dueDate != nil ? Date(timeIntervalSince1970: a.dueDate!) : Date()
                                    AssignmentView(assignmentName: a.title,
                                                   assignmentDescription: a.subtitle ?? "",
                                                   assignmentDueDate: destDueDate,
                                                   assignmentID: a.id,
                                                   assignmentCollaberative: false,
                                                   assignmentPoints: a.maxPoints,
                                                   assignmentScoredPoints: 0,
                                                   showSubmit: true)
                                } label: {
                                    // Format due date safely for the subtitle
                                    let subtitle = a.dueDate.map { Date(timeIntervalSince1970: $0).formatted(date: .abbreviated, time: .omitted) } ?? ""
                                    AssignmentCardDesign(title: a.title, subtitle: "\(a.maxPoints) points | Due " + subtitle)
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                        .padding(.vertical, 4)
                     }
                 }

                // Due Soon
                VStack(alignment: .leading, spacing: 8) {
                    Text("Due Soon")
                        .font(.title)
                        .bold()
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(firebase.assignments.filter { a in
                                guard a.classID == classID, let due = a.dueDate else { return false }
                                let dueDate = Date(timeIntervalSince1970: due)
                                let inRange = dueDate <= Date().addingTimeInterval(60*60*24*7) && dueDate >= Date()
                                return inRange && shouldShowAssignment(a)
                            }) { a in
                                // Format due date safely for the subtitle
                                let subtitle = a.dueDate.map { Date(timeIntervalSince1970: $0).formatted(date: .abbreviated, time: .omitted) } ?? ""
                                AssignmentCardDesign(title: a.title, subtitle: subtitle)
                            }
                        }
                        .padding(.vertical, 4)
                     }
                 }
             }
            .padding()
        }
        // Use the NavigationStack's modern API to present the gradebook when requested
        .navigationDestination(isPresented: $showGradebook) {
            FocusedGradeView(className: className, classID: classID, classGrade: classGradeValue)
        }
    }
}

#Preview {
    FocusedClassView(className: "Network Fundamentals", classID: "0")
}
