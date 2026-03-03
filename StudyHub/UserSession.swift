import SwiftUI

class UserSession: ObservableObject {
    static let shared = UserSession()

    @Published var avatarImage: UIImage? = nil

    func saveAvatar(_ image: UIImage) {
        avatarImage = image
        let uid = UserDefaults.standard.string(forKey: "user_id") ?? "default"
        if let data = image.jpegData(compressionQuality: 0.8) {
            UserDefaults.standard.set(data, forKey: "avatar_\(uid)")
        }
    }

    func loadAvatar() {
        let uid = UserDefaults.standard.string(forKey: "user_id") ?? "default"
        if let data = UserDefaults.standard.data(forKey: "avatar_\(uid)"),
           let image = UIImage(data: data) {
            avatarImage = image
        } else {
            avatarImage = nil
        }
    }

    func clearAvatar() {
        avatarImage = nil
    }
}
