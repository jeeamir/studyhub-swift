import Foundation

struct CourseSection: Identifiable {
    let id: UUID
    var subjectName: String
    var sectionCode: String   
    var professorId: UUID
    var professorName: String
    var maxStudents: Int
    var enrolledCount: Int
    
    var isFull: Bool {
        enrolledCount >= maxStudents
    }
    
    var availableSpots: Int {
        max(0, maxStudents - enrolledCount)
    }
    
    init(subjectName: String, sectionCode: String,
         professorId: UUID, professorName: String, maxStudents: Int = 30) {
        self.id             = UUID()
        self.subjectName    = subjectName
        self.sectionCode    = sectionCode
        self.professorId    = professorId
        self.professorName  = professorName
        self.maxStudents    = maxStudents
        self.enrolledCount  = 0
    }
}
