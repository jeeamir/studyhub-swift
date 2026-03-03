import Foundation

class UserDefaultsManager {
    static let shared = UserDefaultsManager()
    private init() {}

    private let themeKey = "dark_mode"

    func saveDarkMode(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: themeKey)
    }

    func loadDarkMode() -> Bool {
        return UserDefaults.standard.bool(forKey: themeKey)
    }
}
