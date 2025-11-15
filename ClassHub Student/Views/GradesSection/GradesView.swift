//
//  ClassesView.swift
//  ClassHub Student
//
//  Created by Ariel Araya-Madrigal on 10/30/25.
//


import SwiftUI

struct GradesView: View {
    // Use the shared Firebase manager as the single source of truth
    @StateObject private var firebase = FirebaseManager.shared

    // The currently selected class ID (binds to the sidebar selection)
    @State private var selectedClassID: String? = nil

    var body: some View {
        NavigationSplitView {
            // Sidebar: vertical tab-like buttons for each class
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading) {
                    Text("Grades")
                        .font(.largeTitle)
                        .bold()
                    Button(action: {
                        withAnimation { selectedClassID = nil }
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "calendar.badge.clock")
                            Text("Summary")
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(PlainButtonStyle())

                    // Empty state when no classes are present
                    if firebase.classes.isEmpty {
                        Text("No classes available")
                            .foregroundColor(.secondary)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    // Live classes from Firebase
                    ForEach(firebase.classes) { cls in
                        Button(action: {
                            withAnimation { selectedClassID = cls.id }
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "book.closed")
                                    .foregroundColor(selectedClassID == cls.id ? .white : .accentColor)

                                // Name + percent aligned horizontally
                                Text(cls.name)
                                    .foregroundColor(selectedClassID == cls.id ? .white : .primary)
                                    .lineLimit(1)
                                    .truncationMode(.tail)

                                Spacer()

                                // Compute and show class percent
                                let pct = Int((computeClassGrade(for: cls.id) * 100).rounded())
                                Text("\(pct)%")
                                    .font(.subheadline)
                                    .foregroundColor(selectedClassID == cls.id ? .white : .secondary)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedClassID == cls.id ? Color.accentColor : Color.clear)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .accessibilityLabel(Text("Select class \(cls.name)"))
                    }
                    Spacer()
                }
                .padding(.horizontal)
            }
            .navigationTitle("Grades")
        } detail: {
            // Detail: put a local NavigationStack here so navigation links in the focused view
            // push inside the detail column only.
            NavigationStack {
                if let classID = selectedClassID,
                   let cls = firebase.classes.first(where: { $0.id == classID }) {
                    let grade = computeClassGrade(for: classID)
                    FocusedGradeView(className: cls.name, classID: cls.id, classGrade: grade)
                } else {
                    // placeholder when nothing is selected
                    GradeSummaryView()
                }
            }
        }
    }

    // Compute aggregated class grade as totalPoints / totalMaxPoints clamped to [0,1].
    private func computeClassGrade(for classID: String) -> Double {
        let relevant = firebase.grades.filter { $0.classID == classID }
        var totalPoints: Double = 0
        var totalMax: Double = 0
        for g in relevant {
            if let p = g.points { totalPoints += p }
            if let m = g.maxPoints { totalMax += m }
        }
        guard totalMax > 0 else { return 0.0 }
        let ratio = totalPoints / totalMax
        return min(max(ratio, 0.0), 1.0)
    }
}
