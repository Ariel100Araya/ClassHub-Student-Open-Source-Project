import Foundation
import FirebaseDatabase

// Simple data models mapped from Realtime Database snapshots
struct CHUser: Identifiable {
    var id: String
    var firstName: String?
    var lastName: String?
    var email: String?
    var userType: String?

    init(id: String, dict: [String: Any]) {
        self.id = id
        self.firstName = dict["userFirstName"] as? String
        self.lastName = dict["userLastName"] as? String
        self.email = dict["userEmail"] as? String
        self.userType = dict["userType"] as? String
    }
}

struct CHClass: Identifiable {
    var id: String
    var name: String
    var teacherID: String?
    var students: [String]

    init(id: String, dict: [String: Any]) {
        self.id = id
        self.name = dict["className"] as? String ?? "Untitled Class"
        self.teacherID = dict["classTeacherID"] as? String
        self.students = dict["classStudents"] as? [String] ?? []
    }
}

struct CHAssignment: Identifiable {
    var id: String
    var title: String
    var subtitle: String?
    var makerID: String?
    var classID: String?
    var maxPoints: Int
    var dueDate: TimeInterval?
    var retakes: Bool = false
    var category: String?

    init(id: String, dict: [String: Any]) {
        self.id = id
        self.title = dict["assignmentTitle"] as? String ?? "Untitled"
        self.subtitle = dict["assignmentSubtitle"] as? String
        self.makerID = dict["assignmentMakerID"] as? String
        self.classID = dict["classID"] as? String
        self.maxPoints = dict["maxPoints"] as? Int ?? 0
        // Normalize dueDate: accept Double or NSNumber; convert milliseconds -> seconds if necessary
        if let raw = dict["assignmentDueDate"] as? TimeInterval {
            // if the epoch looks like milliseconds (e.g. > 1e12), convert to seconds
            self.dueDate = raw > 1_000_000_000_000 ? raw / 1000.0 : raw
        } else if let num = dict["assignmentDueDate"] as? NSNumber {
            let raw = num.doubleValue
            self.dueDate = raw > 1_000_000_000_000 ? raw / 1000.0 : raw
        } else {
            self.dueDate = nil
        }
        self.retakes = dict["assignmentRetakes"] as? Bool ?? false
        self.category = dict["assignmentCategory"] as? String
    }
}

struct CHGrade: Identifiable {
    var id: String
    var assignmentID: String?
    var graderID: String?
    var classID: String?
    var points: Double?
    var maxPoints: Double?
    var gradeSection: String? // new: optional section label for grouping grades

    init(id: String, dict: [String: Any]) {
        self.id = id
        self.assignmentID = dict["assignmentID"] as? String
        self.graderID = dict["graderID"] as? String
        self.classID = dict["classID"] as? String
        if let p = dict["gradePoints"] as? Double { self.points = p }
        else if let p = dict["gradePoints"] as? NSNumber { self.points = p.doubleValue }
        if let m = dict["gradeMaxPoints"] as? Double { self.maxPoints = m }
        else if let m = dict["gradeMaxPoints"] as? NSNumber { self.maxPoints = m.doubleValue }
        // Read optional gradeSection if present
        self.gradeSection = dict["gradeSection"] as? String
    }
}

struct CHGroup: Identifiable {
    var id: String
    var classID: String?
    var leaderID: String?
    var participants: [String]
    var title: String?
    var assignmentID: String?

    init(id: String, dict: [String: Any]) {
        self.id = id
        self.classID = dict["classID"] as? String
        self.leaderID = dict["leaderID"] as? String
        self.participants = dict["groupParticipants"] as? [String] ?? []
        self.title = dict["groupTitle"] as? String
        self.assignmentID = dict["assignmentID"] as? String
    }
}

struct CHAnnouncement: Identifiable {
    var id: String
    var makerID: String?
    var classID: String?
    var sendDate: TimeInterval?
    var title: String?
    var subtitle: String?
    var links: [String]

    init(id: String, dict: [String: Any]) {
        self.id = id
        self.makerID = dict["announementMakerID"] as? String
        self.classID = dict["classID"] as? String
        // Normalize announcement sendDate similarly
        if let raw = dict["announcementSendDate"] as? TimeInterval {
            self.sendDate = raw > 1_000_000_000_000 ? raw / 1000.0 : raw
        } else if let num = dict["announcementSendDate"] as? NSNumber {
            let raw = num.doubleValue
            self.sendDate = raw > 1_000_000_000_000 ? raw / 1000.0 : raw
        } else {
            self.sendDate = nil
        }
        self.title = dict["announementTitle"] as? String
        self.subtitle = dict["announementSubtitle"] as? String
        self.links = dict["announementLinks"] as? [String] ?? []
    }
}

struct CHAssignmentSubmission: Identifiable {
    var id: String
    var submitterID: String?
    var assignmentID: String?
    var classID: String?
    var submissionLink: String?

    init(id: String, dict: [String: Any]) {
        self.id = id
        self.submitterID = dict["assignmentSubmitterID"] as? String
        self.assignmentID = dict["assignmentID"] as? String
        self.classID = dict["classID"] as? String
        self.submissionLink = dict["submissionLink"] as? String
    }
}

// New: Group task model for to-dos inside a group
struct CHGroupTask: Identifiable {
    var id: String
    var groupID: String?
    var creatorID: String?
    var title: String?
    var creationDate: TimeInterval?
    var completed: Bool = false

    init(id: String, dict: [String: Any]) {
        self.id = id
        self.groupID = dict["groupID"] as? String
        self.creatorID = dict["creatorID"] as? String
        // Data structure uses `taskValue` for the title
        self.title = dict["taskValue"] as? String
        // Normalize date (accept Double/NSNumber, convert ms->s)
        if let raw = dict["taskCreationDate"] as? TimeInterval {
            self.creationDate = raw > 1_000_000_000_000 ? raw / 1000.0 : raw
        } else if let num = dict["taskCreationDate"] as? NSNumber {
            let raw = num.doubleValue
            self.creationDate = raw > 1_000_000_000_000 ? raw / 1000.0 : raw
        } else {
            self.creationDate = nil
        }
        // Read group-wide completed flag (taskCompleted)
        if let b = dict["taskCompleted"] as? Bool {
            self.completed = b
        } else if let n = dict["taskCompleted"] as? NSNumber {
            self.completed = n.boolValue
        } else {
            self.completed = false
        }
    }
}

// Tracks a user crossing out/completing a group task. Mirrors the Data structure `GroupTaskCompletion`.
struct CHGroupTaskCompletion: Identifiable {
    var id: String
    var taskID: String?
    var groupID: String?
    var creatorID: String?
    var completionDate: TimeInterval?

    init(id: String, dict: [String: Any]) {
        self.id = id
        self.taskID = dict["taskID"] as? String
        self.groupID = dict["groupID"] as? String
        self.creatorID = dict["creatorID"] as? String
        if let raw = dict["completionDate"] as? TimeInterval {
            self.completionDate = raw > 1_000_000_000_000 ? raw / 1000.0 : raw
        } else if let num = dict["completionDate"] as? NSNumber {
            let raw = num.doubleValue
            self.completionDate = raw > 1_000_000_000_000 ? raw / 1000.0 : raw
        } else {
            self.completionDate = nil
        }
    }
}

// Group attachment (file/link) model
struct CHGroupAttachment: Identifiable {
    var id: String
    var groupID: String?
    var creatorID: String?
    var attachmentLink: String?
    var attachmentTitle: String?
    var date: TimeInterval?

    init(id: String, dict: [String: Any]) {
        self.id = id
        self.groupID = dict["groupID"] as? String
        self.creatorID = dict["creatorID"] as? String
        self.attachmentLink = dict["attachmentLink"] as? String
        self.attachmentTitle = dict["attachmentTitle"] as? String
        if let raw = dict["attachmentDate"] as? TimeInterval {
            self.date = raw > 1_000_000_000_000 ? raw / 1000.0 : raw
        } else if let num = dict["attachmentDate"] as? NSNumber {
            let raw = num.doubleValue
            self.date = raw > 1_000_000_000_000 ? raw / 1000.0 : raw
        } else {
            self.date = nil
        }
    }
}

// Group message model
struct CHGroupMessage: Identifiable {
    var id: String
    var groupID: String?
    var creatorID: String?
    var messageText: String?
    var messageDate: TimeInterval?

    init(id: String, dict: [String: Any]) {
        self.id = id
        self.groupID = dict["groupID"] as? String
        self.creatorID = dict["creatorID"] as? String
        self.messageText = dict["messageText"] as? String
        if let raw = dict["messageDate"] as? TimeInterval {
            self.messageDate = raw > 1_000_000_000_000 ? raw / 1000.0 : raw
        } else if let num = dict["messageDate"] as? NSNumber {
            let raw = num.doubleValue
            self.messageDate = raw > 1_000_000_000_000 ? raw / 1000.0 : raw
        } else {
            self.messageDate = nil
        }
    }
}
