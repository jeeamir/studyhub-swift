import Foundation

enum WeekDay: String, CaseIterable {
    case monday    = "Monday"
    case tuesday   = "Tuesday"
    case wednesday = "Wednesday"
    case thursday  = "Thursday"
    case friday    = "Friday"
    case saturday  = "Saturday"
}

enum LessonType: String {
    case lecture = "Lecture"
    case seminar = "Seminar"
    case lab     = "Lab"
}

struct Lesson: Identifiable {
    let id: UUID
    var sectionCode: String    
    var subjectName: String
    var professorName: String
    var weekDay: WeekDay
    var startTime: String
    var endTime: String
    var room: String
    var lessonType: LessonType

    var timeRange: String { "\(startTime) – \(endTime)" }

    init(sectionCode: String, subjectName: String, professorName: String,
         weekDay: WeekDay, startTime: String, endTime: String,
         room: String, lessonType: LessonType) {
        self.id            = UUID()
        self.sectionCode   = sectionCode
        self.subjectName   = subjectName
        self.professorName = professorName
        self.weekDay       = weekDay
        self.startTime     = startTime
        self.endTime       = endTime
        self.room          = room
        self.lessonType    = lessonType
    }
}
