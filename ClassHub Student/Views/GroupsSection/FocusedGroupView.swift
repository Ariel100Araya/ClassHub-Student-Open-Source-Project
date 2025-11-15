//
//  FocusedGroupView.swift
//  ClassHub Student
//
//  Created by Ariel Araya-Madrigal on 11/1/25.
//

import SwiftUI
import FirebaseAuth

struct FocusedGroupView: View {
    @State var groupName: String
    @State var groupID: String
    @ObservedObject private var fm = FirebaseManager.shared
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var newTaskText: String = ""
    // Local set for optimistic UI animations of completed tasks
    @State private var animCompleted: Set<String> = []
    // View-level: hide tasks that are marked completed for the whole group
    @State private var hideCompleted: Bool = true
    // Which task is showing the action popover (force-touch menu)
    @State private var selectedTaskID: String? = nil
    // Which attachment is showing the action popover
    @State private var selectedAttachmentID: String? = nil
    // Which message is showing the action popover
    @State private var selectedMessageID: String? = nil
    // Sheets for the plus-menu actions
    @State private var showNewTaskSheet: Bool = false
    @State private var showNewFileSheet: Bool = false
    @State private var showNewMessageSheet: Bool = false
    // Temporary inputs for sheets
    @State private var sheetTaskText: String = ""
    @State private var sheetFileLink: String = ""
    @State private var sheetFileTitle: String = ""
    @State private var sheetMessageText: String = ""

    private var tasksForGroup: [CHGroupTask] {
        return fm.groupTasks
            .filter { $0.groupID == groupID }
            .filter { task in
                if hideCompleted { return !task.completed }
                return true
            }
            .sorted { ($0.creationDate ?? 0) > ($1.creationDate ?? 0) }
    }

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()
    // Attachments and messages for this group
    private var attachmentsForGroup: [CHGroupAttachment] {
        return fm.groupAttachments.filter { $0.groupID == groupID }
            .sorted { ($0.date ?? 0) > ($1.date ?? 0) }
    }

    private var messagesForGroup: [CHGroupMessage] {
        return fm.groupMessages.filter { $0.groupID == groupID }
            .sorted { ($0.messageDate ?? 0) > ($1.messageDate ?? 0) }
    }

    // Cross-platform link opener
    private func openLink(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        #if os(macOS)
        NSWorkspace.shared.open(url)
        #else
        UIApplication.shared.open(url)
        #endif
    }
    var body: some View {
        HStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(groupName)
                            .font(.largeTitle)
                            .bold()
                        Spacer()
                    }
                }
                .padding()
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("To do")
                            .font(.title)
                        Spacer()
                        // Hide completed toggle
                        Toggle(isOn: $hideCompleted) {
                            Text("Hide completed")
                        }
                        .toggleStyle(SwitchToggleStyle())
                    }
                    /*
                    // Add task input + button
                    HStack(spacing: 8) {
                        TextField("New task", text: $newTaskText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(minWidth: 200)
                        Button(action: { addTask() }) {
                            Text("Add")
                        }
                        .disabled(newTaskText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                     */
                    // Tasks are loaded from FirebaseManager and filtered by groupID
                    if tasksForGroup.isEmpty {
                        ScrollView(.horizontal) {
                            HStack {
                                Text("No tasks yet — add one from the group view.")
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                            }
                        }
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(tasksForGroup) { task in
                                    // Determine if current user has completed this task (optimistic + persisted)
                                    let completedByMe = isCompletedByCurrentUser(task: task)
                                    AssignmentCardDesign(title: task.title ?? "Untitled task", subtitle: "")
                                        .opacity(task.completed ? 0.5 : (completedByMe ? 0.6 : 1.0))
                                        .scaleEffect(completedByMe ? 0.98 : 1.0)
                                        .overlay(
                                            VStack {
                                                Spacer()
                                                if let ts = task.creationDate {
                                                    Text(dateFormatter.string(from: Date(timeIntervalSince1970: ts)))
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                        .padding(.bottom, 8)
                                                }
                                            }
                                        )
                                        // double-tap still toggles per-user completion
                                        .onTapGesture(count: 2) { toggleCompletion(task: task) }
                                        // Force touch / long-press shows the group-wide menu
                                        .overlay {
                                            #if os(macOS)
                                            PressureSensitiveView(onPressureExceeded: {
                                                selectedTaskID = task.id
                                            })
                                            #else
                                            Color.clear.onLongPressGesture(minimumDuration: 0.5) {
                                                selectedTaskID = task.id
                                            }
                                            #endif
                                        }
                                        // Popover attached to this card when selected
                                        .popover(isPresented: Binding<Bool>(get: { selectedTaskID == task.id }, set: { newValue in if !newValue { selectedTaskID = nil } })) {
                                            VStack(spacing: 12) {
                                                HStack {
                                                    if task.completed {
                                                        Button("Unmark Complete") {
                                                            fm.updateGroupTask(id: task.id, values: ["taskCompleted": false]) { _ in }
                                                            selectedTaskID = nil
                                                        }
                                                    } else {
                                                        Button("Mark Complete") {
                                                            fm.updateGroupTask(id: task.id, values: ["taskCompleted": true]) { _ in }
                                                            selectedTaskID = nil
                                                        }
                                                    }
                                                    Button("Delete Task") {
                                                        // Remove any per-user completions for this task
                                                        let comps = fm.groupTaskCompletions.filter { $0.taskID == task.id }
                                                        for c in comps { fm.deleteGroupTaskCompletion(id: c.id) }
                                                        // Delete the task itself
                                                        fm.deleteGroupTask(id: task.id) { _ in }
                                                        selectedTaskID = nil
                                                    }
                                                    .foregroundColor(.red)
                                                }
                                            }
                                            .padding()
                                            .frame(minWidth: 200)
                                        }
                                 }
                             }
                         }
                     }
                 }
                 .padding()
                 VStack(alignment: .leading, spacing: 12) {
                     Text("Group files")
                         .font(.title)
                     if attachmentsForGroup.isEmpty {
                         Text("No attachments yet")
                             .foregroundColor(.secondary)
                     } else {
                         ScrollView(.horizontal, showsIndicators: false) {
                             HStack(spacing: 12) {
                                 ForEach(attachmentsForGroup) { att in
                                     AssignmentCardDesign(title: att.attachmentTitle ?? (att.attachmentLink ?? "Attachment"), subtitle: "")
                                         .onTapGesture {
                                             if let link = att.attachmentLink { openLink(link) }
                                         }
                                         // Force touch / long-press shows the attachment menu
                                         .overlay {
                                             #if os(macOS)
                                             PressureSensitiveView(onPressureExceeded: {
                                                 selectedAttachmentID = att.id
                                             })
                                             #else
                                             Color.clear.onLongPressGesture(minimumDuration: 0.5) {
                                                 selectedAttachmentID = att.id
                                             }
                                             #endif
                                         }
                                         .popover(isPresented: Binding<Bool>(get: { selectedAttachmentID == att.id }, set: { newValue in if !newValue { selectedAttachmentID = nil } })) {
                                             VStack(alignment: .leading, spacing: 12) {
                                                 Text(att.attachmentTitle ?? (att.attachmentLink ?? "Attachment"))
                                                     .font(.headline)
                                                     .lineLimit(2)
                                                 if let link = att.attachmentLink {
                                                     Text(link)
                                                         .font(.caption)
                                                         .foregroundColor(.secondary)
                                                         .lineLimit(3)
                                                         .contextMenu {
                                                             Button("Copy Link") {
                                                                 #if os(macOS)
                                                                 NSPasteboard.general.clearContents()
                                                                 NSPasteboard.general.setString(link, forType: .string)
                                                                 #else
                                                                 UIPasteboard.general.string = link
                                                                 #endif
                                                             }
                                                         }
                                                 }
                                                 HStack {
                                                     if let link = att.attachmentLink {
                                                         Button("Open Link") {
                                                             openLink(link)
                                                             selectedAttachmentID = nil
                                                         }
                                                     }
                                                     Spacer()
                                                     Button("Delete Attachment") {
                                                         // Delete attachment from Firebase
                                                         fm.deleteGroupAttachment(id: att.id) { _ in }
                                                         selectedAttachmentID = nil
                                                     }
                                                     .foregroundColor(.red)
                                                 }
                                             }
                                             .padding()
                                             .frame(minWidth: 260)
                                         }
                                 }
                             }
                         }
                     }
                 }
                 .padding()
                 VStack(alignment: .leading, spacing: 12) {
                     Text("Messages")
                         .font(.title)
                     if messagesForGroup.isEmpty {
                         Text("No messages yet")
                             .foregroundColor(.secondary)
                     } else {
                         ScrollView(.horizontal, showsIndicators: false) {
                             HStack(spacing: 12) {
                                 ForEach(messagesForGroup) { msg in
                                     VStack(alignment: .leading, spacing: 8) {
                                         Text(msg.messageText ?? "")
                                             .font(.body)
                                             .fixedSize(horizontal: false, vertical: true)
                                         HStack {
                                             Spacer()
                                             if let t = msg.messageDate {
                                                 Text(dateFormatter.string(from: Date(timeIntervalSince1970: t)))
                                                     .font(.caption)
                                                     .foregroundColor(.secondary)
                                             }
                                         }
                                     }
                                     .padding(12)
                                     .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.06)))
                                     .frame(width: 340)
                                     // Force touch / long-press to show the message menu
                                     .overlay {
                                         #if os(macOS)
                                         PressureSensitiveView(onPressureExceeded: {
                                             selectedMessageID = msg.id
                                         })
                                         #else
                                         Color.clear.onLongPressGesture(minimumDuration: 0.5) {
                                             selectedMessageID = msg.id
                                         }
                                         #endif
                                     }
                                     .popover(isPresented: Binding<Bool>(get: { selectedMessageID == msg.id }, set: { newValue in if !newValue { selectedMessageID = nil } })) {
                                         VStack(alignment: .leading, spacing: 12) {
                                             Text(msg.messageText ?? "")
                                                 .font(.body)
                                                 .lineLimit(4)
                                             HStack {
                                                 Spacer()
                                                 Button("Delete Message") {
                                                     fm.deleteGroupMessage(id: msg.id) { _ in }
                                                     selectedMessageID = nil
                                                 }
                                                 .foregroundColor(.red)
                                             }
                                         }
                                         .padding()
                                         .frame(minWidth: 260)
                                     }
                                 }
                             }
                         }
                     }
                 }
                 .padding()
             }
             Spacer()
         }
         // Toolbar with plus menu
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("New Task") { showNewTaskSheet = true }
                    Button("New File") { showNewFileSheet = true }
                    Button("New Message") { showNewMessageSheet = true }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        // New Task sheet
        .sheet(isPresented: $showNewTaskSheet) {
            VStack(spacing: 12) {
                Text("New Task")
                    .font(.headline)
                TextField("Task title", text: $sheetTaskText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                HStack {
                    Button("Cancel") { showNewTaskSheet = false; sheetTaskText = "" }
                    Spacer()
                    Button("Add") {
                        let trimmed = sheetTaskText.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        let uid = currentUserID()
                        _ = fm.createGroupTask(groupID: groupID, creatorID: uid, title: trimmed) { _ in }
                        sheetTaskText = ""
                        showNewTaskSheet = false
                    }
                    .disabled(sheetTaskText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
                .frame(minWidth: 360)
            }
            .padding()
        }
        // New File sheet
        .sheet(isPresented: $showNewFileSheet) {
            VStack(spacing: 12) {
                Text("Attach File / Link")
                    .font(.headline)
                TextField("Title (optional)", text: $sheetFileTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                TextField("Attachment link", text: $sheetFileLink)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                HStack {
                    Button("Cancel") { showNewFileSheet = false; sheetFileLink = ""; sheetFileTitle = "" }
                    Spacer()
                    Button("Add") {
                        let link = sheetFileLink.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !link.isEmpty else { return }
                        let uid = currentUserID()
                        _ = fm.createGroupAttachment(groupID: groupID, creatorID: uid, attachmentLink: link, title: sheetFileTitle.isEmpty ? nil : sheetFileTitle) { _ in }
                        sheetFileLink = ""; sheetFileTitle = ""
                        showNewFileSheet = false
                    }
                    .disabled(sheetFileLink.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
                .frame(minWidth: 360)
            }
            .padding()
        }
        // New Message sheet
        .sheet(isPresented: $showNewMessageSheet) {
            VStack(spacing: 12) {
                Text("New Message")
                    .font(.headline)
                TextEditor(text: $sheetMessageText)
                    .frame(minHeight: 120)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.2)))
                    .padding()
                HStack {
                    Button("Cancel") { showNewMessageSheet = false; sheetMessageText = "" }
                    Spacer()
                    Button("Send") {
                        let msg = sheetMessageText.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !msg.isEmpty else { return }
                        let uid = currentUserID()
                        _ = fm.createGroupMessage(groupID: groupID, creatorID: uid, messageText: msg) { _ in }
                        sheetMessageText = ""
                        showNewMessageSheet = false
                    }
                    .disabled(sheetMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
                .frame(minWidth: 360)
            }
            .padding()
        }
     }

    // MARK: - Helpers
    private func currentUserID() -> String? {
        return authViewModel.user?.uid ?? Auth.auth().currentUser?.uid
    }

    private func isCompletedByCurrentUser(task: CHGroupTask) -> Bool {
        if animCompleted.contains(task.id) { return true }
        guard let uid = currentUserID() else { return false }
        return fm.groupTaskCompletions.contains(where: { $0.taskID == task.id && $0.creatorID == uid })
    }

    private func toggleCompletion(task: CHGroupTask) {
        guard let uid = currentUserID() else {
            // Not signed in; optimistic toggle but don't persist
            withAnimation(.easeInOut) {
                if animCompleted.contains(task.id) { _ = animCompleted.remove(task.id) } else { _ = animCompleted.insert(task.id) }
            }
            return
        }

        // If there's an existing completion entry by this user, remove it
        if let existing = fm.groupTaskCompletions.first(where: { $0.taskID == task.id && $0.creatorID == uid }) {
            // Optimistic UI
            withAnimation(.easeInOut) { _ = animCompleted.remove(task.id) }
            fm.deleteGroupTaskCompletion(id: existing.id) { _ in }
        } else {
            // Create new completion
            withAnimation(.easeInOut) { _ = animCompleted.insert(task.id) }
             _ = fm.createGroupTaskCompletion(taskID: task.id, groupID: task.groupID ?? groupID, creatorID: uid) { _ in }
        }
    }

    private func addTask() {
        let trimmed = newTaskText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let uid = currentUserID()
        _ = fm.createGroupTask(groupID: groupID, creatorID: uid, title: trimmed) { _ in }
        newTaskText = ""
    }
}
