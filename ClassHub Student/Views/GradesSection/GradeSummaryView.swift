//
//  GradeSummaryView.swift
//  ClassHub Student
//
//  Created by Ariel Araya-Madrigal on 10/30/25.
//

import SwiftUI

// GradeSummaryView uses shared `TrendItem` and `TrendCard` defined in Helpers/TrendCard.swift

struct GradeSummaryView: View {
    @ObservedObject private var firebase = FirebaseManager.shared

    var body: some View {
        // Build per-class trend items once per body evaluation
        let classTrendItems = buildClassTrendItems()

        ScrollView(showsIndicators: false) {
            HStack {
                VStack(alignment: .leading, spacing: 12) {
                    // Determine per-class means and decide which message to show
                    let stats = computeGradeStats()
                    if stats.mean > 80 {
                        Text("You're doing great!")
                            .font(.largeTitle)
                            .bold()
                    } else if stats.mean > 70 {
                        Text("Keep on working!")
                            .font(.largeTitle)
                            .bold()
                    } else if stats.mean > 60 {
                        Text("Let's get back on track.")
                            .font(.largeTitle)
                            .bold()
                    } else {
                        Text("Your grades")
                            .font(.largeTitle)
                            .bold()
                    }
                    // Replace the static descriptive text with a computed summary from Firebase
                    Group {
                        let stats = computeGradeStats()
                        if stats.count == 0 {
                            Text("No grades have been recorded yet.")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        } else {
                            Text("The latest grades that came in have a mean of \(stats.mean)% with the highest grade being \(stats.max)% and the lowest being \(stats.min)% (based on \(stats.count) grades).")
                                .font(.title2)
                                .foregroundColor(.secondary)
                            }
                    }
                }
                .padding(.horizontal)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Trends")
                    .font(.title)
                    .bold()

                // Two-column grid
                let columns = [GridItem(.flexible()), GridItem(.flexible())]
                LazyVGrid(columns: columns, spacing: 12) {
                    if classTrendItems.isEmpty {
                        Text("No classes to show trends for")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(classTrendItems) { item in
                            TrendCard(item: item)
                        }
                    }
                }
                .padding(.top, 6)
            }
            .padding()

            HStack {
                VStack(alignment: .leading) {
                    Text("Latest Assignments Graded")
                        .font(.title)
                        .bold()

                    // Dynamic latest graded assignments
                    let latest = latestGradedAssignments(limit: 5)

                    if latest.isEmpty {
                        Text("No graded assignments yet")
                            .foregroundColor(.secondary)
                            .padding(.vertical)
                    } else {
                        ForEach(latest) { item in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(alignment: .firstTextBaseline) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.assignmentTitle)
                                            .font(.headline)
                                        Text(item.className)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text("\(item.percent)%")
                                        .bold()
                                }
                                if let section = item.section {
                                    Text("Section: \(section)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 6)
                            Divider()
                        }
                    }
                }
                .padding()
                Spacer()
            }
        }
    }

    // MARK: - Latest graded helpers
    private struct LatestGraded: Identifiable {
        let id: String
        let assignmentTitle: String
        let className: String
        let percent: Int
        let points: Double?
        let maxPoints: Double?
        let section: String?
    }

    private func latestGradedAssignments(limit: Int = 5) -> [LatestGraded] {
        // Take grades that have points and maxPoints, sort by id desc as proxy for recent
        let graded = firebase.grades
            .filter { ($0.points != nil) }
            .sorted { $0.id > $1.id }
            .prefix(limit)

        var result: [LatestGraded] = []
        for g in graded {
            let aid = g.assignmentID
            let assignmentTitle = aid.flatMap { id in firebase.assignments.first(where: { $0.id == id })?.title } ?? "Assignment"
            let className = (g.classID != nil) ? firebase.className(for: g.classID!) : "Unknown Class"
            let pct: Int = {
                if let p = g.points, let m = g.maxPoints, m > 0 { return Int((p / m * 100.0).rounded()) }
                else if let p = g.points { return Int(p.rounded()) }
                else { return 0 }
            }()
            result.append(LatestGraded(id: g.id, assignmentTitle: assignmentTitle, className: className, percent: pct, points: g.points, maxPoints: g.maxPoints, section: g.gradeSection))
        }
        return result
    }

    // Build TrendItem list where each Trend corresponds to a class.
    // Direction mapping: mean > 80 => .up, 60..80 => .same, < 60 => .down
    private func buildClassTrendItems() -> [TrendItem] {
        let classes = firebase.classes
        let classMeans = computeClassMeans() // returns percent 0..100
        let palette: [Color] = [.mint, .orange, .pink, .green, .yellow, .purple, .blue, .red, .teal]

        var items: [TrendItem] = []
        for (idx, cls) in classes.enumerated() {
            let mean = classMeans[cls.id] ?? 0.0
            let title = cls.name
            let pct = Int(mean.rounded())
            let subtitle = "\(pct)%"

            let dir: TrendItem.Direction
            if mean > 80.0 { dir = .up }
            else if mean >= 60.0 { dir = .same }
            else { dir = .down }

            let color = palette[idx % palette.count]
            items.append(TrendItem(title: title, subtitle: subtitle, color: color, direction: dir))
        }
        return items
    }

    // Compute mean, min, max percent across all grades that have valid points and maxPoints > 0
    private func computeGradeStats() -> (mean: Int, min: Int, max: Int, count: Int) {
        let valid = firebase.grades.filter { g in
            if let p = g.points, let m = g.maxPoints { return m > 0 && p >= 0 }
            return false
        }
        guard !valid.isEmpty else { return (mean: 0, min: 0, max: 0, count: 0) }

        var sum: Double = 0
        var minPct: Double = 100.0
        var maxPct: Double = 0.0
        for g in valid {
            let p = g.points ?? 0.0
            let m = g.maxPoints ?? 1.0
            let pct = (m > 0) ? (p / m * 100.0) : 0.0
            sum += pct
            if pct < minPct { minPct = pct }
            if pct > maxPct { maxPct = pct }
        }
        let mean = Int((sum / Double(valid.count)).rounded())
        return (mean: mean, min: Int(minPct.rounded()), max: Int(maxPct.rounded()), count: valid.count)
    }

    // Compute mean percent for each class (0..100). If a class has no grades, it's counted as 0.
    private func computeClassMeans() -> [String: Double] {
        // Map classID -> grades
        var result: [String: Double] = [:]

        // Gather classes list from firebase; if none, fall back to classIDs in grades
        let classes = firebase.classes
        let classIDs: [String]
        if classes.isEmpty {
            // derive unique classIDs from grades
            classIDs = Array(Set(firebase.grades.compactMap { $0.classID }))
        } else {
            classIDs = classes.map { $0.id }
        }

        for cid in classIDs {
            let gradesForClass = firebase.grades.filter { $0.classID == cid && ($0.points != nil || $0.maxPoints != nil) }
            if gradesForClass.isEmpty {
                // treat no grades as 0% (you can change this behaviour if you'd rather exclude empty classes)
                result[cid] = 0.0
                continue
            }
            var sumPct: Double = 0
            var count: Int = 0
            for g in gradesForClass {
                if let p = g.points, let m = g.maxPoints, m > 0 {
                    let pct = (p / m) * 100.0
                    sumPct += pct
                    count += 1
                }
            }
            if count == 0 { result[cid] = 0.0 }
            else { result[cid] = sumPct / Double(count) }
        }
        return result
    }

    // Return true if every class mean meets or exceeds the threshold
    private func meetsAllClassesThreshold(classMeans: [String: Double], threshold: Double) -> Bool {
        guard !classMeans.isEmpty else { return false }
        for (_, mean) in classMeans {
            if mean < threshold { return false }
        }
        return true
    }

    // Choose one of five blurbs based on the lowest class percent (0..100)
    private func blurbFor(lowestPercent: Int) -> String {
        switch lowestPercent {
        case 70...100:
            return "You're doing well in most areas — keep it up!"
        case 60..<70:
            return "You're getting close — a bit more effort and you'll be above 70% in all classes."
        case 50..<60:
            return "You're making progress, but some classes need more attention. Try reviewing recent feedback."
        case 40..<50:
            return "You're falling behind in a few classes. Consider reaching out to instructors for help."
        default:
            return "It looks like some classes need significant attention. Let's make a plan to improve your scores."
        }
    }
}

#Preview {
    GradeSummaryView()
}
