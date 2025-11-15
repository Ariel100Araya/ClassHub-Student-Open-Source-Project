//
//  FocusedGradeView.swift
//  ClassHub Student
//
//  Created by Ariel Araya-Madrigal on 10/30/25.
//

import SwiftUI

struct FocusedGradeView: View {
    @State var className: String
    @State var classID: String
    @State var classGrade: Double
    @ObservedObject private var firebase = FirebaseManager.shared

    // Colors palette for sections
    private let palette: [Color] = [.mint, .orange, .pink, .green, .yellow, .purple, .blue, .red, .teal]

    var body: some View {
        // Build trend items dynamically from grades grouped by `gradeSection`
        let sectionItems = buildTrendItems()

        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 12) {
                Text(className)
                    .font(.title)
                    .bold()

                // Progress capsule
                VStack(alignment: .leading, spacing: 6) {
                    ProgressCapsuleView(progress: classGrade, height: 20, showsLabel: true)
                        .frame(height: 20)

                    HStack {
                        // Compute percent as an integer to avoid C-format specifier issues
                        let percent = Int((classGrade * 100).rounded())
                        Text("\(percent)% out of 100%")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }

                // Trends built from gradeSection aggregates
                VStack(alignment: .leading, spacing: 12) {
                    Text("Class Trends")
                        .font(.title)
                        .bold()

                    // Two-column grid
                    let columns = [GridItem(.flexible()), GridItem(.flexible())]
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(sectionItems) { item in
                            TrendCard(item: item)
                        }
                    }
                    .padding(.top, 6)
                }
                .padding(.vertical)

                VStack(alignment: .leading) {
                    Text("Latest Assignments Graded")
                        .font(.title)
                        .bold()
                    Divider()

                    // Live graded assignments for this class (show up to 5 most recent entries)
                    let graded = firebase.grades
                        .filter { $0.classID == classID }
                        // Prefer to show only those with a points value
                        .filter { $0.points != nil }
                        // There's no timestamp on CHGrade yet, so keep server order; show most recent first by id
                        .sorted { $0.id > $1.id }
                        .prefix(5)

                    if graded.isEmpty {
                        Text("No graded assignments yet")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.vertical)
                    } else {
                        ForEach(Array(graded)) { g in
                            VStack(alignment: .leading) {
                                // Resolve assignment title when possible
                                let title: String = {
                                    if let aid = g.assignmentID,
                                       let a = firebase.assignments.first(where: { $0.id == aid }) {
                                        return a.title
                                    }
                                    return "Assignment"
                                }()

                                Text(title)
                                    .font(.title2)
                                    .bold()

                                if let p = g.points, let m = g.maxPoints, m > 0 {
                                    let pct = Int((p / m * 100).rounded())
                                    Text("\(pct)% - \(Int(p))/\(Int(m))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else if let p = g.points {
                                    Text("\(Int(p)) points")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("Not turned in")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                if let section = g.gradeSection {
                                    Text("Section: \(section)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical)
                        }
                    }
                    Divider()
                }
                .padding(.vertical)
            }
            .padding()
        }
    }

    // Build TrendItem array by grouping grades for the current class by gradeSection
    private func buildTrendItems() -> [TrendItem] {
        let relevantGrades = firebase.grades.filter { $0.classID == classID }

        // Group grades by section label (use "Ungrouped" for nil/empty)
        var groups: [String: (points: Double, maxPoints: Double)] = [:]

        for g in relevantGrades {
            let section = (g.gradeSection ?? "Ungrouped").trimmingCharacters(in: .whitespacesAndNewlines)
            if section.isEmpty { continue }

            let p = g.points ?? 0.0
            let m = g.maxPoints ?? 0.0

            // accumulate only when there's some maxPoints to avoid dividing by zero later
            let existing = groups[section] ?? (points: 0.0, maxPoints: 0.0)
            groups[section] = (points: existing.points + p, maxPoints: existing.maxPoints + m)
        }

        // If there are no sections (or they were empty), return a small default
        if groups.isEmpty {
            return [TrendItem(title: "Overview", subtitle: "-", color: .mint, direction: .same)]
        }

        // Sort sections by total maxPoints descending so the most valuable sections appear first
        let sorted = groups.sorted { $0.value.maxPoints > $1.value.maxPoints }

        // Map each group into a TrendItem
        var items: [TrendItem] = []
        for (idx, entry) in sorted.enumerated() {
            let section = entry.key
            let pts = entry.value.points
            let maxPts = entry.value.maxPoints
            let ratio: Double = maxPts > 0 ? (pts / maxPts) : 0.0

            // Decide direction
            let dir: TrendItem.Direction
            if abs(ratio - 0.8) < 0.0001 { dir = .same }
            else if ratio > 0.8 { dir = .up }
            else { dir = .down }

            // Subtitle as percent
            let pct = Int((ratio * 100).rounded())
            let subtitle = "\(pct)%"

            let color = palette[idx % palette.count]
            items.append(TrendItem(title: section, subtitle: subtitle, color: color, direction: dir))
        }

        return items
    }
}
