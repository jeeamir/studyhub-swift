import Foundation

class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var isLoggedIn = false
    @Published var currentUser: AuthUser?
    @Published var accessToken = ""
    
    private let base = SupabaseConfig.url
    private let key  = SupabaseConfig.anonKey
    
    struct AuthUser: Codable {
        let id: String
        let email: String
    }
    
    struct AuthResponse: Codable {
        let accessToken: String
        let user: AuthUser
        
        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case user
        }
    }
    
    
    func signUp(email: String, password: String, fullName: String,
                completion: @escaping (Result<AuthUser, Error>) -> Void) {
        guard let url = URL(string: "\(base)/auth/v1/signup") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(key, forHTTPHeaderField: "apikey")
        
        let body: [String: Any] = [
            "email": email,
            "password": password,
            "data": ["full_name": fullName]
        ]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: req) { data, response, error in
            DispatchQueue.main.async {
                if let error = error { completion(.failure(error)); return }
                
                if let data = data {
                    print("📡 SignUp: \(String(data: data, encoding: .utf8) ?? "")")
                }
                
                if let http = response as? HTTPURLResponse, http.statusCode == 400 {
                    completion(.failure(NSError(domain: "", code: 400,
                                                userInfo: [NSLocalizedDescriptionKey: "Email already registered"])))
                    return
                }
                
                guard let data = data else { return }
                do {
                    let result = try JSONDecoder().decode(AuthResponse.self, from: data)
                    self.saveSession(result)
                    self.createProfile(userId: result.user.id, fullName: fullName,
                                       email: email, accessToken: result.accessToken)
                    UserDefaults.standard.set(true, forKey: "needs_onboarding")  // ← добавь
                    completion(.success(result.user))
                
                } catch {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    
    func signIn(email: String, password: String,
                completion: @escaping (Result<AuthUser, Error>) -> Void) {
        guard let url = URL(string: "\(base)/auth/v1/token?grant_type=password") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(key, forHTTPHeaderField: "apikey")
        
        let body = ["email": email, "password": password]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: req) { data, response, error in
            DispatchQueue.main.async {
                if let data = data {
                    print("📡 SignIn: \(String(data: data, encoding: .utf8) ?? "nil")")
                }
                if let http = response as? HTTPURLResponse {
                    print("📊 Status: \(http.statusCode)")
                }
                
                if let error = error { completion(.failure(error)); return }
                
                if let http = response as? HTTPURLResponse, http.statusCode == 400 {
                    completion(.failure(NSError(domain: "", code: 401,
                                                userInfo: [NSLocalizedDescriptionKey: "Invalid email or password"])))
                    return
                }
                
                guard let data = data else { return }
                do {
                    let result = try JSONDecoder().decode(AuthResponse.self, from: data)
                    self.saveSession(result)
                    completion(.success(result.user))
                } catch {
                    print("❌ Decode error: \(error)")
                    completion(.failure(error))
                }
            }
        }.resume()
    }
    
    
    private func saveSession(_ result: AuthResponse) {
        let expiresAt = Date().timeIntervalSince1970 + 3600
        UserDefaults.standard.set(result.accessToken, forKey: "access_token")
        UserDefaults.standard.set(true, forKey: "is_logged_in")
        UserDefaults.standard.set(result.user.id, forKey: "user_id")
        UserDefaults.standard.set(result.user.email, forKey: "user_email")
        UserDefaults.standard.set(expiresAt, forKey: "token_expires_at")
        UserDefaults.standard.synchronize()

        DispatchQueue.main.async {
            self.accessToken = result.accessToken
            self.currentUser = result.user
            self.isLoggedIn = true
        }
    }
    
    func restoreSession() {
        guard let token = UserDefaults.standard.string(forKey: "access_token"),
              !token.isEmpty,
              let userId = UserDefaults.standard.string(forKey: "user_id"),
              let userEmail = UserDefaults.standard.string(forKey: "user_email"),
              UserDefaults.standard.bool(forKey: "is_logged_in")
        else {
            isLoggedIn = false
            return
        }

        
        let expiresAt = UserDefaults.standard.double(forKey: "token_expires_at")
        if expiresAt > 0 && Date().timeIntervalSince1970 > expiresAt {
            signOut()
            return
        }

        accessToken = token
        currentUser = AuthUser(id: userId, email: userEmail)
        isLoggedIn = true
    }
    
    func signOut() {
        accessToken = ""
        currentUser = nil
        isLoggedIn = false
        UserSession.shared.avatarImage = nil
        UserDefaults.standard.set(false, forKey: "is_logged_in")
        UserDefaults.standard.removeObject(forKey: "access_token")
        UserDefaults.standard.removeObject(forKey: "user_id")
        UserDefaults.standard.removeObject(forKey: "user_email")
    }
    
    private func createProfile(userId: String, fullName: String, email: String, accessToken: String) {
        guard let url = URL(string: "\(base)/rest/v1/profiles") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(key, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization") // ← юзерский токен
        req.setValue("return=minimal", forHTTPHeaderField: "Prefer")
        
        let body: [String: Any] = [
                "user_id": userId,
                "full_name": fullName,
                "email": email
                
        ]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: req) { data, response, error in
            if let data = data {
                print("📝 createProfile: \(String(data: data, encoding: .utf8) ?? "")")
            }
            if let http = response as? HTTPURLResponse {
                print("📝 createProfile status: \(http.statusCode)")
            }
        }.resume()
    }
}
