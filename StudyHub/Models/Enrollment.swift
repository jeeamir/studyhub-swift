import Foundation

enum EnrollmentStatus: String {
    case active    = "Active"
    case dropped   = "Dropped"
    case completed = "Completed"
}

struct Enrollment: Identifiable {
    let id: UUID
    var studentId: UUID
    var sectionId: UUID
    var sectionCode: String
    var subjectName: String
    var semester: String
    var status: EnrollmentStatus
    var enrolledDate: Date

    init(studentId: UUID, sectionId: UUID, sectionCode: String,
         subjectName: String, semester: String, status: EnrollmentStatus = .active) {
        self.id           = UUID()
        self.studentId    = studentId
        self.sectionId    = sectionId
        self.sectionCode  = sectionCode
        self.subjectName  = subjectName
        self.semester     = semester
        self.status       = status
        self.enrolledDate = Date()
    }
}
