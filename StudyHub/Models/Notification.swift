import Foundation

enum NotificationType: String {
    case deadline   = "Deadline"
    case reminder   = "Reminder"
}

struct AppNotification: Identifiable {
    let id: UUID
    var title: String
    var message: String
    var date: Date
    var type: NotificationType
    var isRead: Bool

    init(title: String, message: String, date: Date, type: NotificationType) {
        self.id      = UUID()
        self.title   = title
        self.message = message
        self.date    = date
        self.type    = type
        self.isRead  = false
    }
}
