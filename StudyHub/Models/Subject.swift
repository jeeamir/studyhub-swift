import Foundation

struct Subject: Identifiable {
    let id: UUID
    var name: String
    var professorName: String
    var room: String
    var credits: Int
    var semester: String
    var sectionCode: String
    var color: String  
    
    init(name: String, professorName: String, room: String,
         credits: Int, semester: String, sectionCode: String, color: String = "blue") {
        self.id            = UUID()
        self.name          = name
        self.professorName = professorName
        self.room          = room
        self.credits       = credits
        self.semester      = semester
        self.sectionCode   = sectionCode
        self.color         = color
    }
}
