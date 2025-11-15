//
//  YouView.swift
//  ClassHub Student
//
//  Created by Ariel Araya-Madrigal on 11/3/25.
//

import SwiftUI
import FirebaseAuth

struct YouView: View {
    @State private var pageSelected = ""
    var body: some View {
        NavigationSplitView {
            // Sidebar: vertical tab-like buttons for each class
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading) {
                    Text("You")
                        .font(.largeTitle)
                        .bold()
                    Button(action: {
                        withAnimation { pageSelected = "Demo" }
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "desktopcomputer.and.macbook")
                            Text("Demo")
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(PlainButtonStyle())
                    Spacer()
                    Button(action: {
                        withAnimation { pageSelected = "Sign out" }
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "door.left.hand.open")
                            Text("Sign out")
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
        } detail: {
            if pageSelected == "Sign out" {
                SignOutView()
            } else if pageSelected == "Demo" {
                DemoView()
            } else {
                VStack {
                    Text("This is prototype software. Bugs are unfortunatly still alive.")
                }
            }
        }
    }
}

struct SignOutView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    var body: some View {
        VStack {
            Button(action: {
                authViewModel.signOut()
            }) {
                Text("Sign Out")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .cornerRadius(10)
            }
        }
    }
}

struct DemoView: View {
    @State private var lastClassID: String? = nil
    @State private var lastAssignmentID: String? = nil
    @State private var lastAnnouncementID: String? = nil
    @State private var lastGroupID: String? = nil
    @State private var lastGradeID: String? = nil
    @State private var statusMessage: String = ""

    // Form state
    @State private var newClassName: String = ""

    @State private var assignmentTitle: String = ""
    @State private var assignmentSubtitle: String = ""
    @State private var assignmentClassID: String? = nil
    @State private var assignmentDueDate: Date = Date()

    @State private var announcementTitle: String = ""
    @State private var announcementSubtitle: String = ""
    @State private var announcementClassID: String? = nil

    @State private var groupTitle: String = ""
    @State private var groupClassID: String? = nil

    @State private var gradeClassID: String? = nil
    @State private var gradeAssignmentID: String? = nil
    @State private var gradePointsText: String = ""
    @State private var gradeMaxPointsText: String = ""
    @State private var gradeSection: String = ""

    private var fm = FirebaseManager.shared
    private var currentUID: String? { Auth.auth().currentUser?.uid }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("Demo Data Creator")
                    .font(.title2)
                    .bold()

                Form {
                    Section(header: Text("Create Sample Class")) {
                        TextField("Class name", text: $newClassName)
                        Button("Create Class") {
                            let name = newClassName.isEmpty ? "Demo Class " + ISO8601DateFormatter().string(from: Date()) : newClassName
                            let cid = fm.createClass(name: name, teacherID: currentUID)
                            lastClassID = cid
                            statusMessage = "Created class: \(cid ?? "nil")"
                            // Reset field
                            newClassName = ""
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    Section(header: Text("Create Sample Assignment")) {
                        // Precompute a default class id to simplify the Picker binding
                        let defaultAssignmentClassID = assignmentClassID ?? fm.classes.first?.id ?? ""

                        Picker("Class", selection: Binding(get: {
                            defaultAssignmentClassID
                        }, set: { new in
                            assignmentClassID = new.isEmpty ? nil : new
                        })) {
                            if fm.classes.isEmpty {
                                Text("No classes").tag("")
                            } else {
                                ForEach(fm.classes) { c in
                                    Text(c.name).tag(c.id)
                                }
                            }
                        }

                        TextField("Title", text: $assignmentTitle)
                        TextField("Subtitle", text: $assignmentSubtitle)
                        DatePicker("Due date", selection: $assignmentDueDate, displayedComponents: .date)

                        Button("Create Assignment") {
                            guard let cid = assignmentClassID ?? lastClassID ?? fm.classes.first?.id else {
                                statusMessage = "Failed to determine class for assignment"
                                return
                            }
                            let aid = fm.createAssignment(title: assignmentTitle.isEmpty ? "Demo Assignment" : assignmentTitle,
                                                          subtitle: assignmentSubtitle.isEmpty ? nil : assignmentSubtitle,
                                                          classID: cid,
                                                          makerID: currentUID,
                                                          dueDate: assignmentDueDate)
                            lastAssignmentID = aid
                            statusMessage = "Created assignment: \(aid ?? "nil") for class \(cid)"
                            // Reset
                            assignmentTitle = ""
                            assignmentSubtitle = ""
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    Section(header: Text("Create Sample Announcement")) {
                        let defaultAnnouncementClassID = announcementClassID ?? fm.classes.first?.id ?? ""

                        Picker("Class", selection: Binding(get: {
                            defaultAnnouncementClassID
                        }, set: { new in
                            announcementClassID = new.isEmpty ? nil : new
                        })) {
                            if fm.classes.isEmpty { Text("No classes").tag("") }
                            else { ForEach(fm.classes) { c in Text(c.name).tag(c.id) } }
                        }
                        TextField("Title", text: $announcementTitle)
                        TextField("Subtitle", text: $announcementSubtitle)
                        Button("Create Announcement") {
                            guard let cid = announcementClassID ?? lastClassID ?? fm.classes.first?.id else {
                                statusMessage = "Failed to determine class for announcement"
                                return
                            }
                            let annID = fm.createAnnouncement(classID: cid, makerID: currentUID, title: announcementTitle.isEmpty ? "Demo Announcement" : announcementTitle, subtitle: announcementSubtitle.isEmpty ? nil : announcementSubtitle, links: [])
                            lastAnnouncementID = annID
                            statusMessage = "Created announcement: \(annID ?? "nil") for class \(cid)"
                            announcementTitle = ""
                            announcementSubtitle = ""
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    Section(header: Text("Create Sample Group")) {
                        let defaultGroupClassID = groupClassID ?? fm.classes.first?.id ?? ""

                        Picker("Class", selection: Binding(get: {
                            defaultGroupClassID
                        }, set: { new in
                            groupClassID = new.isEmpty ? nil : new
                        })) {
                            if fm.classes.isEmpty { Text("No classes").tag("") }
                            else { ForEach(fm.classes) { c in Text(c.name).tag(c.id) } }
                        }
                        TextField("Group title", text: $groupTitle)
                        Button("Create Group") {
                            guard let cid = groupClassID ?? lastClassID ?? fm.classes.first?.id else {
                                statusMessage = "Failed to determine class for group"
                                return
                            }
                            let gid = fm.createGroup(classID: cid, leaderID: currentUID, title: groupTitle.isEmpty ? "Demo Group" : groupTitle, participants: [currentUID ?? "unknown"])
                            lastGroupID = gid
                            statusMessage = "Created group: \(gid ?? "nil") for class \(cid)"
                            groupTitle = ""
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    Section(header: Text("Create Sample Grade (gradeSection optional)")) {
                        let defaultGradeClassID = gradeClassID ?? fm.classes.first?.id ?? ""

                        Picker("Class", selection: Binding(get: {
                            defaultGradeClassID
                        }, set: { new in
                            gradeClassID = new.isEmpty ? nil : new
                            // reset assignment selection when class changes
                            gradeAssignmentID = nil
                        })) {
                            if fm.classes.isEmpty { Text("No classes").tag("") }
                            else { ForEach(fm.classes) { c in Text(c.name).tag(c.id) } }
                        }

                        // Assignment picker filtered by selected class
                        let classToFilter = gradeClassID ?? fm.classes.first?.id ?? ""
                        let filteredAssignments = fm.assignments.filter { $0.classID == classToFilter }
                        let defaultFilteredAssignmentID = gradeAssignmentID ?? filteredAssignments.first?.id ?? ""

                        Picker("Assignment", selection: Binding(get: {
                            defaultFilteredAssignmentID
                        }, set: { new in
                            gradeAssignmentID = new.isEmpty ? nil : new
                        })) {
                            if filteredAssignments.isEmpty { Text("No assignments").tag("") }
                            else { ForEach(filteredAssignments) { a in Text(a.title).tag(a.id) } }
                        }

                        TextField("Points", text: $gradePointsText)
#if os(iOS) || os(tvOS)
                            .keyboardType(.decimalPad)
#endif
                        TextField("Max Points", text: $gradeMaxPointsText)
#if os(iOS) || os(tvOS)
                            .keyboardType(.decimalPad)
#endif
                        TextField("Grade Section (optional)", text: $gradeSection)
                            .font(.caption)

                        Button("Create Grade") {
                            guard let cid = gradeClassID ?? lastClassID ?? fm.classes.first?.id else {
                                statusMessage = "Failed to determine class for grade"
                                return
                            }
                            // attempt to parse points
                            let p = Double(gradePointsText) ?? Double(Int.random(in: 60...100))
                            let m = Double(gradeMaxPointsText) ?? 100.0
                            let aid = gradeAssignmentID ?? lastAssignmentID ?? fm.assignments.first(where: { $0.classID == cid })?.id

                            guard let assignmentID = aid else {
                                statusMessage = "Failed to determine assignment for grade"
                                return
                            }
                            let gid = fm.createGrade(classID: cid, assignmentID: assignmentID, graderID: currentUID, points: p, maxPoints: m)
                            lastGradeID = gid
                            statusMessage = "Created grade: \(gid ?? "nil") for assignment \(assignmentID)"

                            // If the user provided a gradeSection, store it on the grade node as an extra field
                            if let gid = gid, !gradeSection.trimmingCharacters(in: .whitespaces).isEmpty {
                                fm.updateGrade(id: gid, values: ["gradeSection": gradeSection]) { err in
                                    if let e = err { statusMessage = "Saved grade but failed to write section: \(e.localizedDescription)" }
                                    else { statusMessage = "Created grade: \(gid) (section: \(gradeSection))" }
                                }
                            }

                            // Reset inputs
                            gradePointsText = ""
                            gradeMaxPointsText = ""
                            gradeSection = ""
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    Section(header: Text("Last created IDs")) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Class: \(lastClassID ?? "-")")
                            Text("Assignment: \(lastAssignmentID ?? "-")")
                            Text("Announcement: \(lastAnnouncementID ?? "-")")
                            Text("Group: \(lastGroupID ?? "-")")
                            Text("Grade: \(lastGradeID ?? "-")")
                            Text(statusMessage)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top)
                    }
                }
                .frame(maxWidth: 800)
            }
            .padding()
        }
        .onAppear {
            // ensure we have latest classes/assignments from FirebaseManager
            // FirebaseManager already observes nodes so nothing to do here other than optional fetches.
        }
    }
}

#Preview {
    YouView()
}
