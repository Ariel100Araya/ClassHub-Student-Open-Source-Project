//
//  GroupsSummaryView.swift
//  ClassHub Student
//
//  Created by Ariel Araya-Madrigal on 11/1/25.
//

import SwiftUI
import FirebaseAuth

struct GroupsSummaryView: View {
    @ObservedObject private var fm = FirebaseManager.shared
    @EnvironmentObject var authViewModel: AuthViewModel

    // Cache of userID -> email/name so we can display who completed a task
    @State private var userEmails: [String: String] = [:]

    // Recent completion view model
    struct RecentCompletion: Identifiable {
        let id: String // completion id
        let taskID: String?
        let taskTitle: String
        let groupID: String?
        let groupTitle: String?
        let completerID: String?
        var completerEmail: String? = nil
        let taskDate: TimeInterval?
    }

    private var currentUserID: String? {
        return authViewModel.user?.uid
    }

    // Groups the current user belongs to (leader or participant)
    private var myGroupIDs: [String] {
        guard let uid = currentUserID else { return [] }
        return fm.groups.filter { ($0.leaderID == uid) || ($0.participants.contains(uid)) }.map { $0.id }
    }

    // Build recent completions for groups the user belongs to
    private var recentCompletions: [RecentCompletion] {
        // Filter completions to only those in user's groups
        let comps = fm.groupTaskCompletions.filter { comp in
            guard let gid = comp.groupID else { return false }
            return myGroupIDs.contains(gid)
        }

        // Map to richer view models by looking up the task and group
        let mapped: [RecentCompletion] = comps.compactMap { comp in
            let task = fm.groupTasks.first(where: { $0.id == comp.taskID })
            let group = fm.groups.first(where: { $0.id == comp.groupID })
            let title = task?.title ?? "(untitled)"
            // Prefer the time the task was checked off (completionDate); fall back to the task creation date
            let eventDate = comp.completionDate ?? task?.creationDate
            return RecentCompletion(id: comp.id, taskID: comp.taskID, taskTitle: title, groupID: comp.groupID, groupTitle: group?.title, completerID: comp.creatorID, completerEmail: nil, taskDate: eventDate)
        }

        // Sort by taskDate descending (most recent completions first)
        return mapped.sorted { (a, b) in
            let ta = a.taskDate ?? 0
            let tb = b.taskDate ?? 0
            return ta > tb
        }
    }

    var body: some View {
        HStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Latest edits")
                            .font(.largeTitle)
                            .bold()
                        Spacer()
                    }
                }
                .padding()
                // Recent completions across the user's groups
                VStack(alignment: .leading, spacing: 12) {
                    Text("Things checked off")
                        .font(.title)

                    if recentCompletions.isEmpty {
                        Text("No recent completions in your groups")
                            .foregroundColor(.secondary)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(recentCompletions.prefix(8)) { rc in
                                    AssignmentCardDesign(title: rc.taskTitle, subtitle: "\(userEmails[rc.completerID ?? ""] ?? rc.completerID ?? "Someone") | \(rc.groupTitle ?? "Group")")
                                        .frame(width: 300)
                                        .strikethrough()
                                        .onAppear {
                                            // Fetch completer email if missing
                                            if let cid = rc.completerID, userEmails[cid] == nil {
                                                fm.fetchUserEmail(userID: cid) { email in
                                                    DispatchQueue.main.async {
                                                        if let email = email { userEmails[cid] = email }
                                                    }
                                                }
                                            }
                                        }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .padding()

                VStack(alignment: .leading, spacing: 12) {
                    Text("Two files has been edited")
                        .font(.title)
                    ScrollView(.horizontal) {
                        HStack {
                            Text("Script for final project")
                                .font(.title3)
                                .padding(.trailing)
                            Text("Notes presentation")
                                .font(.title3)
                                .padding(.trailing)
                        }
                    }
                }
                .padding()
                VStack(alignment: .leading, spacing: 12) {
                    Text("Urgent Messages")
                        .font(.title)
                    ScrollView(.horizontal) {
                        HStack {
                            AssignmentCardDesign(title: "The final is due this sunday! Make sure that everyone has their parts done.", subtitle: "Ariel Araya | Final Project Group")
                                .frame(width: 300)
                        }
                    }
                }
                .padding()
            }
            Spacer()
        }
    }
}

#Preview {
    GroupsSummaryView()
        .environmentObject(AuthViewModel())
}
