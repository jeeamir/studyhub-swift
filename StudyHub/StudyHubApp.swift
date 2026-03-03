import SwiftUI

@main
struct StudyHubApp: App {
    @StateObject private var auth = AuthService.shared
    @AppStorage("dark_mode") var darkMode = false
    @AppStorage("needs_onboarding") var needsOnboarding = false

    init() {
        AuthService.shared.restoreSession()
        UserSession.shared.loadAvatar()
        print("🔐 isLoggedIn: \(AuthService.shared.isLoggedIn)")
        print("👤 userId: \(UserDefaults.standard.string(forKey: "user_id") ?? "nil")")
        print("📧 email: \(UserDefaults.standard.string(forKey: "user_email") ?? "nil")")
    }

    var body: some Scene {
        WindowGroup {
            if auth.isLoggedIn {
                if needsOnboarding {
                    OnboardingView(needsOnboarding: $needsOnboarding)
                        .preferredColorScheme(darkMode ? .dark : .light)
                } else {
                    ContentView()
                        .preferredColorScheme(darkMode ? .dark : .light)
                        .environmentObject(auth)
                }
            } else {
                LoginScreen()
                    .preferredColorScheme(darkMode ? .dark : .light)
            }
        }
    }
}
