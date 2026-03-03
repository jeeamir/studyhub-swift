import Foundation

enum AssignmentStatus: String, CaseIterable, Codable, Equatable {
    case notStarted = "Not Started"
    case inProgress = "In Progress"
    case submitted  = "Submitted"
}

struct Assignment: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var subjectName: String
    var deadline: Date
    var status: AssignmentStatus
    var personalNote: String
    
    init(title: String, subjectName: String, deadline: Date,
         status: AssignmentStatus = .notStarted, personalNote: String = "") {
        self.id           = UUID()
        self.title        = title
        self.subjectName  = subjectName
        self.deadline     = deadline
        self.status       = status
        self.personalNote = personalNote
    }
    
    var daysUntilDeadline: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: deadline).day ?? 0
    }
    
    var isOverdue: Bool {
        deadline < Date() && status != .submitted
    }
}
