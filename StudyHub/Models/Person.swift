import Foundation

class Person {
    let id: UUID
    var firstName: String
    var lastName: String
    var email: String
    var phoneNumber: String

    var fullName: String {
        return "\(firstName) \(lastName)"
    }

    var formattedPhone: String {
        let digits = phoneNumber.filter { $0.isNumber }
        guard digits.count >= 11 else { return phoneNumber }
        let country = digits.prefix(1)
        let area    = digits.dropFirst(1).prefix(3)
        let part1   = digits.dropFirst(4).prefix(3)
        let part2   = digits.dropFirst(7).prefix(2)
        let part3   = digits.dropFirst(9).prefix(2)
        return "+\(country) (\(area)) \(part1)-\(part2)-\(part3)"
    }

    init(firstName: String, lastName: String, email: String, phoneNumber: String) {
        self.id          = UUID()
        self.firstName   = firstName
        self.lastName    = lastName
        self.email       = email
        self.phoneNumber = phoneNumber
    }

    func describe() -> String {
        return "Person: \(fullName) | \(email)"
    }
}

class Student: Person {
    var year: Int
    var major: String
    var gpa: Double

    var isEmailValid: Bool {
        return email.contains("@") && email.contains(".")
    }

    var isPhoneValid: Bool {
        return phoneNumber.filter { $0.isNumber }.count >= 10
    }

    var yearLabel: String {
        switch year {
        case 1: return "1st year"
        case 2: return "2nd year"
        case 3: return "3rd year"
        case 4: return "4th year"
        default: return "\(year)th year"
        }
    }

    init(firstName: String, lastName: String, email: String,
         phoneNumber: String, year: Int, major: String, gpa: Double = 0.0) {
        self.year  = year
        self.major = major
        self.gpa   = gpa
        super.init(firstName: firstName, lastName: lastName,
                   email: email, phoneNumber: phoneNumber)
    }

    override func describe() -> String {
        return "Student: \(fullName) | \(major) | \(yearLabel) | GPA: \(String(format: "%.2f", gpa))"
    }
}

class Professor: Person {
    var department: String
    var title: String

    init(firstName: String, lastName: String, email: String,
         phoneNumber: String, department: String, title: String = "Prof.") {
        self.department = department
        self.title      = title
        super.init(firstName: firstName, lastName: lastName,
                   email: email, phoneNumber: phoneNumber)
    }

    override func describe() -> String {
        return "Professor: \(title) \(fullName) | \(department)"
    }
}
