//
//  ClassSummaryView.swift
//  ClassHub Student
//
//  Created by Ariel Araya-Madrigal on 10/30/25.
//
import SwiftUI
import Foundation
import FirebaseAuth

struct ClassSummaryView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @ObservedObject private var firebase = FirebaseManager.shared

    // Compute enrolled classes for current user. Fallback to FirebaseAuth directly if the view appears
    // before `authViewModel.user` is populated.
    private var currentUID: String? { authViewModel.user?.uid ?? Auth.auth().currentUser?.uid }

    // Small helper to normalize/trim optional string IDs (shared to avoid duplication)
    private func normalized(_ s: String?) -> String? {
        guard let s = s else { return nil }
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }

    private var enrolledClasses: [CHClass] {
        guard let uid = currentUID else { return [] }
        return firebase.classes.filter { cls in
            // user is a student or teacher in the class
            return cls.students.contains(uid) || cls.teacherID == uid
        }
    }

    private var enrolledClassIDs: Set<String> { Set(enrolledClasses.map { $0.id }) }

    // Assignment IDs the current user has submitted for (normalized)
    private var submittedAssignmentIDsForCurrentUser: Set<String> {
        guard let uid = currentUID else { return [] }
        let nuid = normalized(uid)
        if nuid == nil { return [] }
        let ids = firebase.assignmentSubmissions.compactMap { sub -> String? in
            if let subSid = normalized(sub.submitterID), subSid == nuid {
                return normalized(sub.assignmentID)
            }
            return nil
        }
        return Set(ids)
    }

    private var assignmentsForUser: [CHAssignment] {
        // Include assignments from enrolled classes OR assignments the user has already submitted
        let submittedIDs = submittedAssignmentIDsForCurrentUser
        return firebase.assignments.filter { a in
            if let cid = a.classID, enrolledClassIDs.contains(cid) { return true }
            // Normalize assignment id before checking submitted set
            if let na = normalized(a.id), submittedIDs.contains(na) { return true }
            return false
        }
    }

    private var announcementsForUser: [CHAnnouncement] {
        firebase.announcements.filter { a in
            if let cid = a.classID { return enrolledClassIDs.contains(cid) }
            return false
        }
    }

    // Date range for current week
    private var weekInterval: DateInterval? {
        let cal = Calendar.current
        return cal.dateInterval(of: .weekOfYear, for: Date())
    }

    // Assignments due this week
    private var assignmentsDueThisWeek: [CHAssignment] {
        guard let interval = weekInterval else { return [] }
        return assignmentsForUser.filter { a in
            guard let due = a.dueDate else { return false }
            let d = Date(timeIntervalSince1970: due)
            return d >= interval.start && d <= interval.end
        }
    }

    // Completed this week: assignments the current user has submitted (for assignments due this week)
    private var completedDueThisWeek: [CHAssignment] {
        let submittedIDs = submittedAssignmentIDsForCurrentUser
        // Debugging: print sets to help diagnose missing matches
        #if DEBUG
        // Print only in debug builds to avoid noisy logs in production
        print("[ClassSummaryView] completedDueThisWeek -> assignmentsDueThisWeek ids=\(assignmentsDueThisWeek.map({ $0.id }))")
        print("[ClassSummaryView] completedDueThisWeek -> submittedAssignmentIDsForCurrentUser=\(submittedIDs)")
        #endif
        return assignmentsDueThisWeek.filter { a in
            guard let aid = normalized(a.id) else { return false }
            return submittedIDs.contains(aid)
        }
    }

    // Progress ratio
    private var progressThisWeek: Double {
        let total = assignmentsDueThisWeek.count
        guard total > 0 else { return 0.0 }
        return Double(completedDueThisWeek.count) / Double(total)
    }

    // Latest updates: combine announcements & assignments, sort by date desc
    private struct UpdateItem: Identifiable {
        var id: String
        var title: String
        var subtitle: String
        var date: Date
        var className: String
        var kind: String
    }

    private var latestUpdates: [UpdateItem] {
        var items: [UpdateItem] = []
        for ann in announcementsForUser {
            let date = Date(timeIntervalSince1970: ann.sendDate ?? 0)
            // Resolve class name from classID (falls back to "Unknown Class" inside firebase.className)
            let clsName = firebase.className(for: ann.classID ?? "")
            items.append(.init(id: "ann_\(ann.id)", title: ann.title ?? "Announcement", subtitle: ann.subtitle ?? "", date: date, className: clsName, kind: "Announcement"))
        }
        for a in assignmentsForUser {
            let date = Date(timeIntervalSince1970: a.dueDate ?? 0)
            let clsName = firebase.className(for: a.classID ?? "")
            items.append(.init(id: "ass_\(a.id)", title: a.title, subtitle: a.subtitle ?? "", date: date, className: clsName, kind: "Assignment"))
        }
        return items.sorted(by: { $0.date > $1.date })
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Your progress this week")
                    .font(.title)
                    .bold()

                // Progress capsule
                VStack(alignment: .leading, spacing: 6) {
                    // Compute totals locally for clarity
                    let totalDue = assignmentsDueThisWeek.count
                    let completedCount = completedDueThisWeek.count

                    if totalDue == 0 {
                        // Friendly placeholder when nothing is due this week
                        Text("No assignments due this week.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 6)
                    } else {
                        ProgressCapsuleView(progress: progressThisWeek, height: 20, showsLabel: true)
                            .frame(height: 20)
                            .frame(maxWidth: .infinity)
                            // Ensure SwiftUI invalidates the capsule when the progress value changes
                            .id(progressThisWeek)

                        HStack {
                            Text(String(format: "%.0f%% Complete", progressThisWeek * 100))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(completedCount)/\(totalDue)")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding()

            // Latest Updates — only for classes the user is enrolled in
            VStack(alignment: .leading, spacing: 12) {
                Text("Latest Updates")
                    .font(.title)
                    .bold()

                if latestUpdates.isEmpty {
                    Text("No recent updates in your classes.")
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(latestUpdates) { item in
                                let third = item.className + " • " + item.kind
                                AssignmentCardDesign(title: item.title, subtitle: item.subtitle, thirdtitle: third)
                                    .frame(maxWidth: 400, maxHeight: 100)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding()
            
            // Waiting on you — assignments in enrolled classes that are not marked completed
            VStack(alignment: .leading, spacing: 12) {
                Text("Waiting on you")
                    .font(.title)
                    .bold()

                // Build the pending list: exclude assignments that already have a grade OR that the
                // current user has already submitted for (matching FocusedClassView behavior).
                let pending = assignmentsForUser.filter { a in
                    // If the current user has already submitted this assignment, don't show it
                    if let aid = normalized(a.id), submittedAssignmentIDsForCurrentUser.contains(aid) {
                        return false
                    }

                    // pending if there's no grade yet (heuristic). If a grade exists, don't show.
                    let hasGrade = firebase.grades.contains(where: { g in
                        guard let gid = normalized(g.assignmentID), let aid = normalized(a.id) else { return false }
                        return gid == aid
                    })
                    if hasGrade { return false }

                    // If dueDate exists and it's past, still show as pending (overdue)
                    return true
                }

                if pending.isEmpty {
                    Text("No actions required right now.")
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(pending) { a in
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
                                    AssignmentCardDesign(title: a.title, subtitle: "Due " + subtitle)
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding()
        }
        .onAppear {
            // No-op: observers in FirebaseManager keep data updated.
            // Debugging: print counts/ids to understand progress calculation
            print("[ClassSummaryView] assignmentsForUser count=\(assignmentsForUser.count)")
            for a in assignmentsForUser {
                let dueEpoch = a.dueDate ?? 0
                let dueDate = a.dueDate != nil ? Date(timeIntervalSince1970: dueEpoch).description : "nil"
                let classIdStr = a.classID ?? "nil"
                print("[ClassSummaryView] assignment -> id=\(a.id), classID=\(classIdStr), dueEpoch=\(dueEpoch), dueDate=\(dueDate)")
            }
            print("[ClassSummaryView] submittedAssignmentIDsForCurrentUser=\(submittedAssignmentIDsForCurrentUser)")
            print("[ClassSummaryView] onAppear: currentUID=\(String(describing: currentUID))")
            print("[ClassSummaryView] assignmentsDueThisWeek count=\(assignmentsDueThisWeek.count)")
            print("[ClassSummaryView] assignmentsDueThisWeek ids=\(assignmentsDueThisWeek.map({ $0.id }))")
            print("[ClassSummaryView] completedDueThisWeek count=\(completedDueThisWeek.count)")
            print("[ClassSummaryView] completedDueThisWeek ids=\(completedDueThisWeek.map({ $0.id }))")
            print("[ClassSummaryView] progressThisWeek=\(progressThisWeek)")
            print("[ClassSummaryView] firebase.assignmentSubmissions count=\(firebase.assignmentSubmissions.count)")
            for s in firebase.assignmentSubmissions {
                let aid = s.assignmentID ?? "nil"
                let sid = s.submitterID ?? "nil"
                print("[ClassSummaryView] submission -> id=\(s.id), assignmentID=\(aid), submitterID=\(sid)")
            }
            print("[ClassSummaryView] enrolledClasses count=\(enrolledClasses.count)")
            print("[ClassSummaryView] enrolledClassIDs=\(enrolledClassIDs)")
            print("[ClassSummaryView] submittedAssignmentIDsForCurrentUser=\(submittedAssignmentIDsForCurrentUser)")
        }
        .onChange(of: progressThisWeek) {
            // No-op; kept to trigger view updates if needed. Use console prints in onAppear for diagnostics.
        }
    }
}

#Preview {
    ClassSummaryView()
        .environmentObject(AuthViewModel())
}
