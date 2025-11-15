import Foundation
import FirebaseDatabase
import Combine
import SwiftUI

/// Simple manager that observes the Realtime Database and publishes arrays of models.
final class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    private var ref: DatabaseReference
    // Keep reference+handle pairs so we can remove specific observers later
    private var handles: [(ref: DatabaseReference, handle: DatabaseHandle)] = []

    @Published var classes: [CHClass] = []
    @Published var grades: [CHGrade] = []
    @Published var assignments: [CHAssignment] = []
    @Published var announcements: [CHAnnouncement] = []
    @Published var assignmentSubmissions: [CHAssignmentSubmission] = []
    @Published var groups: [CHGroup] = []
    @Published var groupTasks: [CHGroupTask] = []
    @Published var groupTaskCompletions: [CHGroupTaskCompletion] = []
    @Published var groupAttachments: [CHGroupAttachment] = []
    @Published var groupMessages: [CHGroupMessage] = []

    private init() {
        ref = Database.database().reference()
        observeClasses()
        observeGrades()
        observeGroups()
        observeGroupTasks()
        observeGroupTaskCompletions()
        observeGroupAttachments()
        observeGroupMessages()
        observeAssignments()
        observeAnnouncements()
        observeAssignmentSubmissions()
    }

    deinit {
        // Remove observers we registered
        for h in handles {
            h.ref.removeObserver(withHandle: h.handle)
        }
        handles.removeAll()
    }

    private func observeClasses() {
        let classesRef = ref.child("classes")
        let handle = classesRef.observe(.value) { snapshot in
            var results: [CHClass] = []
            for case let child as DataSnapshot in snapshot.children {
                if let dict = child.value as? [String: Any] {
                    let c = CHClass(id: child.key, dict: dict)
                    results.append(c)
                }
            }
            DispatchQueue.main.async {
                self.classes = results
            }
        }
        handles.append((classesRef, handle))
    }

    private func observeGrades() {
        let gradesRef = ref.child("grades")
        let handle = gradesRef.observe(.value) { snapshot in
            var results: [CHGrade] = []
            for case let child as DataSnapshot in snapshot.children {
                if let dict = child.value as? [String: Any] {
                    let g = CHGrade(id: child.key, dict: dict)
                    results.append(g)
                }
            }
            DispatchQueue.main.async {
                self.grades = results
            }
        }
        handles.append((gradesRef, handle))
    }

    private func observeGroups() {
        let groupsRef = ref.child("groups")
        let handle = groupsRef.observe(.value) { snapshot in
            var results: [CHGroup] = []
            for case let child as DataSnapshot in snapshot.children {
                if let dict = child.value as? [String: Any] {
                    let grp = CHGroup(id: child.key, dict: dict)
                    results.append(grp)
                }
            }
            DispatchQueue.main.async {
                self.groups = results
            }
        }
        handles.append((groupsRef, handle))
    }

    private func observeGroupTasks() {
        let tasksRef = ref.child("groupTasks")
        let handle = tasksRef.observe(.value) { snapshot in
            var results: [CHGroupTask] = []
            for case let child as DataSnapshot in snapshot.children {
                if let dict = child.value as? [String: Any] {
                    let t = CHGroupTask(id: child.key, dict: dict)
                    results.append(t)
                }
            }
            DispatchQueue.main.async {
                self.groupTasks = results
            }
        }
        handles.append((tasksRef, handle))
    }

    private func observeGroupTaskCompletions() {
        let compRef = ref.child("groupTaskCompletions")
        let handle = compRef.observe(.value) { snapshot in
            var results: [CHGroupTaskCompletion] = []
            for case let child as DataSnapshot in snapshot.children {
                if let dict = child.value as? [String: Any] {
                    let c = CHGroupTaskCompletion(id: child.key, dict: dict)
                    results.append(c)
                }
            }
            DispatchQueue.main.async {
                self.groupTaskCompletions = results
            }
        }
        handles.append((compRef, handle))
    }

    private func observeGroupAttachments() {
        let attRef = ref.child("groupAttachments")
        let handle = attRef.observe(.value) { snapshot in
            var results: [CHGroupAttachment] = []
            for case let child as DataSnapshot in snapshot.children {
                if let dict = child.value as? [String: Any] {
                    let a = CHGroupAttachment(id: child.key, dict: dict)
                    results.append(a)
                }
            }
            DispatchQueue.main.async {
                self.groupAttachments = results
            }
        }
        handles.append((attRef, handle))
    }

    private func observeGroupMessages() {
        let msgRef = ref.child("groupMessages")
        let handle = msgRef.observe(.value) { snapshot in
            var results: [CHGroupMessage] = []
            for case let child as DataSnapshot in snapshot.children {
                if let dict = child.value as? [String: Any] {
                    let m = CHGroupMessage(id: child.key, dict: dict)
                    results.append(m)
                }
            }
            DispatchQueue.main.async {
                self.groupMessages = results
            }
        }
        handles.append((msgRef, handle))
    }

    private func observeAssignments() {
        let assignmentsRef = ref.child("assignments")
        let handle = assignmentsRef.observe(.value) { snapshot in
            var results: [CHAssignment] = []
            for case let child as DataSnapshot in snapshot.children {
                if let dict = child.value as? [String: Any] {
                    let a = CHAssignment(id: child.key, dict: dict)
                    results.append(a)
                }
            }
            DispatchQueue.main.async {
                self.assignments = results
            }
        }
        handles.append((assignmentsRef, handle))
    }

    private func observeAnnouncements() {
        let annRef = ref.child("announcements")
        let handle = annRef.observe(.value) { snapshot in
            var results: [CHAnnouncement] = []
            for case let child as DataSnapshot in snapshot.children {
                if let dict = child.value as? [String: Any] {
                    let a = CHAnnouncement(id: child.key, dict: dict)
                    results.append(a)
                }
            }
            DispatchQueue.main.async {
                self.announcements = results
            }
        }
        handles.append((annRef, handle))
    }

    private func observeAssignmentSubmissions() {
        let subsRef = ref.child("assignmentSubmissions")
        let handle = subsRef.observe(.value) { snapshot in
            var results: [CHAssignmentSubmission] = []
            for case let child as DataSnapshot in snapshot.children {
                if let dict = child.value as? [String: Any] {
                    let s = CHAssignmentSubmission(id: child.key, dict: dict)
                    results.append(s)
                }
            }
            // Debug: print a compact summary of submissions loaded
            var summary: [String] = []
            for s in results {
                let aid = s.assignmentID ?? "nil"
                let sid = s.submitterID ?? "nil"
                summary.append("{id:\(s.id), assignmentID:\(aid), submitterID:\(sid)}")
            }
            print("[FirebaseManager] Loaded assignmentSubmissions count=\(results.count): \(summary)")
            DispatchQueue.main.async {
                self.assignmentSubmissions = results
            }
        }
        handles.append((subsRef, handle))
    }

    // Convenience: fetch a class by id
    func className(for id: String) -> String {
        return classes.first(where: { $0.id == id })?.name ?? "Unknown Class"
    }

    // MARK: - CRUD helpers
    @discardableResult
    func createClass(name: String, teacherID: String? = nil, students: [String] = [], completion: ((Error?) -> Void)? = nil) -> String? {
        let newRef = ref.child("classes").childByAutoId()
        let payload: [String: Any] = [
            "className": name,
            "classTeacherID": teacherID ?? "",
            "classStudents": students
        ]
        newRef.setValue(payload) { error, _ in
            completion?(error)
        }
        return newRef.key
    }

    func updateClass(id: String, values: [String: Any], completion: ((Error?) -> Void)? = nil) {
        ref.child("classes").child(id).updateChildValues(values) { error, _ in
            completion?(error)
        }
    }

    func deleteClass(id: String, completion: ((Error?) -> Void)? = nil) {
        ref.child("classes").child(id).removeValue { error, _ in
            completion?(error)
        }
    }

    @discardableResult
    func createGrade(classID: String, assignmentID: String?, graderID: String?, points: Double?, maxPoints: Double?, completion: ((Error?) -> Void)? = nil) -> String? {
        let newRef = ref.child("grades").childByAutoId()
        var payload: [String: Any] = ["classID": classID]
        if let a = assignmentID { payload["assignmentID"] = a }
        if let g = graderID { payload["graderID"] = g }
        if let p = points { payload["gradePoints"] = p }
        if let m = maxPoints { payload["gradeMaxPoints"] = m }
        newRef.setValue(payload) { error, _ in completion?(error) }
        return newRef.key
    }

    func updateGrade(id: String, values: [String: Any], completion: ((Error?) -> Void)? = nil) {
        ref.child("grades").child(id).updateChildValues(values) { error, _ in completion?(error) }
    }

    func deleteGrade(id: String, completion: ((Error?) -> Void)? = nil) {
        ref.child("grades").child(id).removeValue { error, _ in completion?(error) }
    }

    @discardableResult
    func createGroup(classID: String, leaderID: String?, title: String?, participants: [String] = [], assignmentID: String? = nil, completion: ((Error?) -> Void)? = nil) -> String? {
        let newRef = ref.child("groups").childByAutoId()
        var payload: [String: Any] = ["classID": classID, "groupParticipants": participants]
        if let l = leaderID { payload["leaderID"] = l }
        if let t = title { payload["groupTitle"] = t }
        if let a = assignmentID { payload["assignmentID"] = a }
        newRef.setValue(payload) { error, _ in completion?(error) }
        return newRef.key
    }

    // Create a group task (to-do) for a group
    @discardableResult
    func createGroupTask(groupID: String, creatorID: String? = nil, title: String, completion: ((Error?) -> Void)? = nil) -> String? {
        let newRef = ref.child("groupTasks").childByAutoId()
        var payload: [String: Any] = ["groupID": groupID, "taskValue": title]
        if let c = creatorID { payload["creatorID"] = c }
        payload["taskCreationDate"] = Date().timeIntervalSince1970
        newRef.setValue(payload) { error, _ in completion?(error) }
        return newRef.key
    }

    // Update group task fields (e.g. set taskCompleted = true/false)
    func updateGroupTask(id: String, values: [String: Any], completion: ((Error?) -> Void)? = nil) {
        ref.child("groupTasks").child(id).updateChildValues(values) { error, _ in completion?(error) }
    }

    // Delete a group task
    func deleteGroupTask(id: String, completion: ((Error?) -> Void)? = nil) {
        ref.child("groupTasks").child(id).removeValue { error, _ in completion?(error) }
    }

    // Create assignment helper
    @discardableResult
    func createAssignment(title: String, subtitle: String? = nil, classID: String, makerID: String? = nil, dueDate: Date? = nil, turnIn: Bool = true, retakes: Bool = false, category: String? = nil, completion: ((Error?) -> Void)? = nil) -> String? {
        let newRef = ref.child("assignments").childByAutoId()
        var payload: [String: Any] = [
            "assignmentTitle": title,
            "classID": classID,
            "assignmentMakerID": makerID ?? "",
            "assignmentTurnIn": turnIn,
            "assignmentRetakes": retakes
        ]
        if let subtitle = subtitle { payload["assignmentSubtitle"] = subtitle }
        if let due = dueDate { payload["assignmentDueDate"] = due.timeIntervalSince1970 }
        if let cat = category { payload["assignmentCategory"] = cat }
        newRef.setValue(payload) { error, _ in completion?(error) }
        return newRef.key
    }

    // Create announcement helper
    @discardableResult
    func createAnnouncement(classID: String, makerID: String? = nil, title: String, subtitle: String? = nil, links: [String] = [], sendDate: Date = Date(), completion: ((Error?) -> Void)? = nil) -> String? {
        let newRef = ref.child("announcements").childByAutoId()
        var payload: [String: Any] = [
            "announementMakerID": makerID ?? "",
            "classID": classID,
            "announcementSendDate": sendDate.timeIntervalSince1970,
            "announementTitle": title
        ]
        if let subtitle = subtitle { payload["announementSubtitle"] = subtitle }
        if !links.isEmpty { payload["announementLinks"] = links }
        newRef.setValue(payload) { error, _ in completion?(error) }
        return newRef.key
    }

    // Create assignment submission
    @discardableResult
    func createAssignmentSubmission(submitterID: String?, assignmentID: String, classID: String? = nil, submissionLink: String? = nil, completion: ((Error?) -> Void)? = nil) -> String? {
        let newRef = ref.child("assignmentSubmissions").childByAutoId()
        var payload: [String: Any] = ["assignmentSubmitterID": submitterID ?? "", "assignmentID": assignmentID]
        if let cid = classID { payload["classID"] = cid }
        if let link = submissionLink { payload["submissionLink"] = link }
        newRef.setValue(payload) { error, _ in completion?(error) }
        return newRef.key
    }

    func deleteAssignmentSubmission(id: String, completion: ((Error?) -> Void)? = nil) {
        ref.child("assignmentSubmissions").child(id).removeValue { error, _ in completion?(error) }
    }

    @discardableResult
    func createGroupTaskCompletion(taskID: String, groupID: String, creatorID: String? = nil, completion: ((Error?) -> Void)? = nil) -> String? {
        let newRef = ref.child("groupTaskCompletions").childByAutoId()
        var payload: [String: Any] = ["taskID": taskID, "groupID": groupID]
        if let c = creatorID { payload["creatorID"] = c }
        // Add a completion timestamp so we can present/sort by when a task was checked off
        payload["completionDate"] = Date().timeIntervalSince1970
        newRef.setValue(payload) { err, _ in completion?(err) }
        return newRef.key
    }

    func deleteGroupTaskCompletion(id: String, completion: ((Error?) -> Void)? = nil) {
        ref.child("groupTaskCompletions").child(id).removeValue { err, _ in completion?(err) }
    }

    // Create a group attachment (file/link)
    @discardableResult
    func createGroupAttachment(groupID: String, creatorID: String? = nil, attachmentLink: String, title: String? = nil, completion: ((Error?) -> Void)? = nil) -> String? {
        let newRef = ref.child("groupAttachments").childByAutoId()
        var payload: [String: Any] = ["groupID": groupID, "attachmentLink": attachmentLink]
        if let c = creatorID { payload["creatorID"] = c }
        if let t = title { payload["attachmentTitle"] = t }
        payload["attachmentDate"] = Date().timeIntervalSince1970
        newRef.setValue(payload) { err, _ in completion?(err) }
        return newRef.key
    }

    // Delete a group attachment
    func deleteGroupAttachment(id: String, completion: ((Error?) -> Void)? = nil) {
        ref.child("groupAttachments").child(id).removeValue { err, _ in completion?(err) }
    }

    // Create a group message
    @discardableResult
    func createGroupMessage(groupID: String, creatorID: String? = nil, messageText: String, completion: ((Error?) -> Void)? = nil) -> String? {
        let newRef = ref.child("groupMessages").childByAutoId()
        var payload: [String: Any] = ["groupID": groupID, "messageText": messageText]
        if let c = creatorID { payload["creatorID"] = c }
        payload["messageDate"] = Date().timeIntervalSince1970
        newRef.setValue(payload) { err, _ in completion?(err) }
        return newRef.key
    }

    // Delete a group message
    func deleteGroupMessage(id: String, completion: ((Error?) -> Void)? = nil) {
        ref.child("groupMessages").child(id).removeValue { err, _ in completion?(err) }
    }

    // Fetch a user email by user id (single read). Calls completion with the email or nil.
    func fetchUserEmail(userID: String, completion: @escaping (String?) -> Void) {
        let userRef = ref.child("users").child(userID)
        userRef.observeSingleEvent(of: .value) { snapshot in
            guard let dict = snapshot.value as? [String: Any] else {
                completion(nil)
                return
            }
            let email = dict["userEmail"] as? String
            completion(email)
        } withCancel: { error in
            print("fetchUserEmail error: \(error.localizedDescription)")
            completion(nil)
        }
    }
}
