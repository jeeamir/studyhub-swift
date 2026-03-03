import Foundation

struct SupabaseConfig {
    static let url = "https://cofsbogasrzydlwtjgaz.supabase.co"
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNvZnNib2dhc3J6eWRsd3RqZ2F6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYxMzY0NDEsImV4cCI6MjA5MTcxMjQ0MX0.QSSTYCi8C4pV2T4BychjYDvgtMMFUJRp351OmrLNwnU"
}

struct SupabaseProfile: Codable, Identifiable {
    let id: String
    let userId: String?
    let fullName: String?
    let email: String?
    let phone: String?
    let major: String?
    let year: Int?
    let gpa: Double?
    let university: String?

    enum CodingKeys: String, CodingKey {
        case id, email, phone, major, year, gpa, university
        case userId = "user_id"
        case fullName = "full_name"
    }
}

struct SupabaseSubject: Codable, Identifiable {
    let id: String
    let name: String
    let code: String?
    let description: String?
    let credits: Int?
    let department: String?
}

struct SupabaseSection: Codable, Identifiable {
    let id: String
    let subjectId: String?
    let sectionCode: String?
    let professorName: String?
    let room: String?
    let semester: String?
    let maxStudents: Int?
    let days: [Int]?
    let startTime: String?
    let endTime: String?
    let color: String?

    enum CodingKeys: String, CodingKey {
        case id, room, semester, color, days
        case subjectId = "subject_id"
        case sectionCode = "section_code"
        case professorName = "professor_name"
        case maxStudents = "max_students"
        case startTime = "start_time"
        case endTime = "end_time"
    }
}

struct EnrolledSection: Identifiable {
    let id: String
    let subjectName: String
    let subjectCode: String
    let sectionCode: String
    let professorName: String
    let room: String
    let semester: String
    let credits: Int
    let days: [Int]
    let startTime: String
    let endTime: String
    let color: String
    let sectionId: String
}

struct SupabaseAssignment: Codable, Identifiable {
    let id: String
    let sectionId: String?
    let title: String
    let description: String?
    let assignmentType: String?
    let midtermPeriod: String?
    let deadline: String?
    let maxScore: Double?

    enum CodingKeys: String, CodingKey {
        case id, title, description, deadline
        case sectionId = "section_id"
        case assignmentType = "assignment_type"
        case midtermPeriod = "midterm_period"
        case maxScore = "max_score"
    }
}

struct SupabaseStudentAssignment: Codable, Identifiable {
    let id: String
    let userId: String?
    let assignmentId: String?
    var status: String?
    let personalNote: String?

    enum CodingKeys: String, CodingKey {
        case id, status
        case userId = "user_id"
        case assignmentId = "assignment_id"
        case personalNote = "personal_note"
    }
}

struct SupabaseGrade: Codable, Identifiable {
    let id: String
    let userId: String?
    let sectionId: String?
    let taskName: String?
    let score: Double?
    let maxScore: Double?
    let gradeType: String?
    let semester: String?

    enum CodingKeys: String, CodingKey {
        case id, semester, score
        case userId = "user_id"
        case sectionId = "section_id"
        case taskName = "task_name"
        case maxScore = "max_score"
        case gradeType = "grade_type"
    }
}

struct AssignmentWithStatus: Identifiable {
    let id: String
    let assignment: SupabaseAssignment
    var status: String
    let personalNote: String
    let subjectName: String
    let subjectCode: String
}

class SupabaseService {
    static let shared = SupabaseService()

    private let base = SupabaseConfig.url
    private let key  = SupabaseConfig.anonKey

    private var authToken: String {
        let token = AuthService.shared.accessToken
        return token.isEmpty ? key : token
    }

    private var userId: String {
        let id = AuthService.shared.currentUser?.id ?? ""
        return id.isEmpty ? (UserDefaults.standard.string(forKey: "user_id") ?? "") : id
    }

    private var headers: [String: String] {[
        "apikey": key,
        "Authorization": "Bearer \(authToken)",
        "Content-Type": "application/json",
        "Prefer": "return=representation"
    ]}

    private func makeRequest(_ path: String, params: [String: String] = [:],
                              method: String = "GET", body: Data? = nil) -> URLRequest? {
        var components = URLComponents(string: "\(base)/rest/v1/\(path)")
        if !params.isEmpty {
            components?.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        guard let url = components?.url else { return nil }
        var req = URLRequest(url: url)
        req.httpMethod = method
        headers.forEach { req.setValue($1, forHTTPHeaderField: $0) }
        req.httpBody = body
        return req
    }

    func getProfile(completion: @escaping (Result<SupabaseProfile, Error>) -> Void) {
        let uid = userId
        let params = uid.isEmpty
            ? ["limit": "1"]
            : ["user_id": "eq.\(uid)", "limit": "1"]
        guard let req = makeRequest("profiles", params: params) else { return }

        URLSession.shared.dataTask(with: req) { data, _, error in
            DispatchQueue.main.async {
                if let error = error { completion(.failure(error)); return }
                guard let data = data else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: nil))); return
                }
                do {
                    let items = try JSONDecoder().decode([SupabaseProfile].self, from: data)
                    if let first = items.first {
                        completion(.success(first))
                    } else {
                        completion(.failure(NSError(domain: "", code: 404,
                            userInfo: [NSLocalizedDescriptionKey: "No profile"])))
                    }
                } catch {
                    completion(.failure(error))
                }
            }
        }.resume()
    }

    func getEnrolledSections(semester: String,
                              completion: @escaping (Result<[EnrolledSection], Error>) -> Void) {
        let uid = userId
        guard !uid.isEmpty else { completion(.success([])); return }

        guard let req = makeRequest("enrollments", params: [
            "user_id": "eq.\(uid)",
            "select": "section_id"
        ]) else { completion(.success([])); return }

        URLSession.shared.dataTask(with: req) { data, _, error in
            DispatchQueue.main.async {
                if let error = error { completion(.failure(error)); return }
                guard let data = data else { completion(.success([])); return }

                struct EnrollmentRaw: Codable { let section_id: String }
                guard let enrollments = try? JSONDecoder().decode([EnrollmentRaw].self, from: data),
                      !enrollments.isEmpty else {
                    completion(.success([])); return
                }

                let sectionIds = enrollments.map { $0.section_id }.joined(separator: ",")

                guard let sectReq = self.makeRequest("sections", params: [
                    "id": "in.(\(sectionIds))",
                    "semester": "eq.\(semester)",
                    "select": "*,subjects(*)"
                ]) else { completion(.success([])); return }

                URLSession.shared.dataTask(with: sectReq) { data2, _, error2 in
                    DispatchQueue.main.async {
                        if let error2 = error2 { completion(.failure(error2)); return }
                        guard let data2 = data2 else { completion(.success([])); return }

                        struct SectionWithSubject: Codable {
                            let id: String
                            let section_code: String?
                            let professor_name: String?
                            let room: String?
                            let semester: String?
                            let days: [Int]?
                            let start_time: String?
                            let end_time: String?
                            let color: String?
                            let subjects: SubjectRaw?
                            struct SubjectRaw: Codable {
                                let name: String
                                let code: String?
                                let credits: Int?
                            }
                        }

                        guard let sections = try? JSONDecoder().decode([SectionWithSubject].self, from: data2) else {
                            completion(.success([])); return
                        }

                        let result = sections.map { s in
                            EnrolledSection(
                                id: s.id,
                                subjectName: s.subjects?.name ?? "Unknown",
                                subjectCode: s.subjects?.code ?? "",
                                sectionCode: s.section_code ?? "",
                                professorName: s.professor_name ?? "",
                                room: s.room ?? "",
                                semester: s.semester ?? "",
                                credits: s.subjects?.credits ?? 5,
                                days: s.days ?? [],
                                startTime: s.start_time ?? "",
                                endTime: s.end_time ?? "",
                                color: s.color ?? "blue",
                                sectionId: s.id
                            )
                        }
                        completion(.success(result))
                    }
                }.resume()
            }
        }.resume()
    }

    func getAssignments(completion: @escaping (Result<[AssignmentWithStatus], Error>) -> Void) {
        let uid = userId
        guard !uid.isEmpty else { completion(.success([])); return }

        guard let req = makeRequest("enrollments", params: [
            "user_id": "eq.\(uid)",
            "select": "section_id"
        ]) else { completion(.success([])); return }

        URLSession.shared.dataTask(with: req) { data, _, error in
            DispatchQueue.main.async {
                if let error = error { completion(.failure(error)); return }
                guard let data = data else { completion(.success([])); return }

                struct EnrollmentRaw: Codable { let section_id: String }
                guard let enrollments = try? JSONDecoder().decode([EnrollmentRaw].self, from: data),
                      !enrollments.isEmpty else {
                    completion(.success([])); return
                }

                let sectionIds = enrollments.map { $0.section_id }.joined(separator: ",")

                guard let assReq = self.makeRequest("assignments", params: [
                    "section_id": "in.(\(sectionIds))",
                    "select": "*,sections(section_code,professor_name,subjects(name,code))",
                    "order": "deadline"
                ]) else { completion(.success([])); return }

                URLSession.shared.dataTask(with: assReq) { data2, _, error2 in
                    DispatchQueue.main.async {
                        if let error2 = error2 { completion(.failure(error2)); return }
                        guard let data2 = data2 else { completion(.success([])); return }

                        struct AssignmentRaw: Codable {
                            let id: String
                            let section_id: String?
                            let title: String
                            let description: String?
                            let assignment_type: String?
                            let midterm_period: String?
                            let deadline: String?
                            let max_score: Double?
                            let sections: SectionRaw?
                            struct SectionRaw: Codable {
                                let section_code: String?
                                let professor_name: String?
                                let subjects: SubjectRaw?
                                struct SubjectRaw: Codable {
                                    let name: String
                                    let code: String?
                                }
                            }
                        }

                        guard let assignments = try? JSONDecoder().decode([AssignmentRaw].self, from: data2) else {
                            completion(.success([])); return
                        }

                        guard let statusReq = self.makeRequest("student_assignments", params: [
                            "user_id": "eq.\(uid)"
                        ]) else { completion(.success([])); return }

                        URLSession.shared.dataTask(with: statusReq) { data3, _, _ in
                            DispatchQueue.main.async {
                                var statusMap: [String: String] = [:]
                                var noteMap: [String: String] = [:]
                                if let data3 = data3,
                                   let statuses = try? JSONDecoder().decode([SupabaseStudentAssignment].self, from: data3) {
                                    statuses.forEach {
                                        if let aid = $0.assignmentId {
                                            statusMap[aid] = $0.status ?? "Not Started"
                                            noteMap[aid] = $0.personalNote ?? ""
                                        }
                                    }
                                }

                                let result = assignments.map { a in
                                    AssignmentWithStatus(
                                        id: a.id,
                                        assignment: SupabaseAssignment(
                                            id: a.id,
                                            sectionId: a.section_id,
                                            title: a.title,
                                            description: a.description,
                                            assignmentType: a.assignment_type,
                                            midtermPeriod: a.midterm_period,
                                            deadline: a.deadline,
                                            maxScore: a.max_score
                                        ),
                                        status: statusMap[a.id] ?? "Not Started",
                                        personalNote: noteMap[a.id] ?? "",
                                        subjectName: a.sections?.subjects?.name ?? "",
                                        subjectCode: a.sections?.subjects?.code ?? ""
                                    )
                                }
                                completion(.success(result))
                            }
                        }.resume()
                    }
                }.resume()
            }
        }.resume()
    }

    func updateAssignmentStatus(assignmentId: String, status: String,
                                completion: @escaping (Result<Bool, Error>) -> Void) {
        let uid = userId
        guard let checkReq = makeRequest("student_assignments", params: [
            "user_id": "eq.\(uid)",
            "assignment_id": "eq.\(assignmentId)"
        ]) else { return }

        URLSession.shared.dataTask(with: checkReq) { data, _, _ in
            DispatchQueue.main.async {
                let exists = (try? JSONDecoder().decode([SupabaseStudentAssignment].self,
                    from: data ?? Data()))?.isEmpty == false

                let dict: [String: Any] = [
                    "user_id": uid,
                    "assignment_id": assignmentId,
                    "status": status
                ]
                guard let body = try? JSONSerialization.data(withJSONObject: dict) else { return }

                let path = exists ? "student_assignments" : "student_assignments"
                let extraParams = exists ? ["user_id": "eq.\(uid)", "assignment_id": "eq.\(assignmentId)"] : [String:String]()
                let method = exists ? "PATCH" : "POST"

                guard let req = self.makeRequest(path, params: extraParams, method: method, body: body) else { return }
                URLSession.shared.dataTask(with: req) { _, _, error in
                    DispatchQueue.main.async {
                        if let error = error { completion(.failure(error)); return }
                        completion(.success(true))
                    }
                }.resume()
            }
        }.resume()
    }

    func deleteStudentAssignment(assignmentId: String,
                                  completion: @escaping (Result<Bool, Error>) -> Void) {
        let uid = userId
        guard let req = makeRequest("student_assignments", params: [
            "user_id": "eq.\(uid)",
            "assignment_id": "eq.\(assignmentId)"
        ], method: "DELETE") else { return }

        URLSession.shared.dataTask(with: req) { _, _, error in
            DispatchQueue.main.async {
                if let error = error { completion(.failure(error)); return }
                completion(.success(true))
            }
        }.resume()
    }

    func getGrades(semester: String = "Spring 2026",
                   completion: @escaping (Result<[SupabaseGrade], Error>) -> Void) {
        let uid = userId
        var params: [String: String] = [
            "semester": "eq.\(semester)",
            "order": "section_id"
        ]
        if !uid.isEmpty { params["user_id"] = "eq.\(uid)" }

        guard let req = makeRequest("grades", params: params) else {
            completion(.success([])); return
        }
        URLSession.shared.dataTask(with: req) { data, _, error in
            DispatchQueue.main.async {
                if let error = error { completion(.failure(error)); return }
                guard let data = data else {
                    completion(.success([])); return
                }
                do { completion(.success(try JSONDecoder().decode([SupabaseGrade].self, from: data))) }
                catch { completion(.failure(error)) }
            }
        }.resume()
    }

    func getSchedule(completion: @escaping (Result<[EnrolledSection], Error>) -> Void) {
        getEnrolledSections(semester: "Spring 2026", completion: completion)
    }

    func getSubjectCatalog(completion: @escaping (Result<[SupabaseSubject], Error>) -> Void) {
        guard let req = makeRequest("subjects", params: ["order": "name"]) else { return }
        URLSession.shared.dataTask(with: req) { data, _, error in
            DispatchQueue.main.async {
                if let error = error { completion(.failure(error)); return }
                guard let data = data else { return }
                do { completion(.success(try JSONDecoder().decode([SupabaseSubject].self, from: data))) }
                catch { completion(.failure(error)) }
            }
        }.resume()
    }
    
    func updateProfile(major: String, year: Int, university: String = "",
                       completion: @escaping (Result<Bool, Error>) -> Void) {
        let uid = userId
        guard !uid.isEmpty else { completion(.success(true)); return }

        var body: [String: Any] = ["major": major, "year": year]
        if !university.isEmpty { body["university"] = university }

        guard let data = try? JSONSerialization.data(withJSONObject: body),
              let req = makeRequest("profiles",
                                    params: ["user_id": "eq.\(uid)"],
                                    method: "PATCH",
                                    body: data) else { return }

        URLSession.shared.dataTask(with: req) { data, response, error in
            DispatchQueue.main.async {
                if let http = response as? HTTPURLResponse {
                    print("📝 updateProfile status: \(http.statusCode)")
                }
                if let error = error { completion(.failure(error)); return }
                completion(.success(true))
            }
        }.resume()
    }
    
    func getUniversities(completion: @escaping (Result<[University], Error>) -> Void) {
        guard let req = makeRequest("universities", params: ["order": "city,name"]) else { return }
        URLSession.shared.dataTask(with: req) { data, _, error in
            DispatchQueue.main.async {
                if let error = error { completion(.failure(error)); return }
                guard let data = data else { return }
                do { completion(.success(try JSONDecoder().decode([University].self, from: data))) }
                catch { completion(.failure(error)) }
            }
        }.resume()
    }

    func findUniversity(byDomain domain: String, completion: @escaping (University?) -> Void) {
        getUniversities { result in
            if case .success(let unis) = result {
                completion(unis.first { $0.domain == domain })
            } else {
                completion(nil)
            }
        }
    }

    func createAssignment(sectionId: String, title: String, description: String,
                          type: String, midterm: String, deadline: String, maxScore: Double,
                          completion: @escaping (Result<Bool, Error>) -> Void) {
        let uid = userId
        let assignmentDict: [String: Any] = [
            "section_id": sectionId,
            "title": title,
            "description": description,
            "assignment_type": type,
            "midterm_period": midterm,
            "deadline": deadline,
            "max_score": maxScore
        ]
        guard let body = try? JSONSerialization.data(withJSONObject: assignmentDict),
              let req = makeRequest("assignments", method: "POST", body: body) else { return }

        URLSession.shared.dataTask(with: req) { data, _, error in
            DispatchQueue.main.async {
                if let error = error { completion(.failure(error)); return }
                guard let data = data,
                      let assignments = try? JSONDecoder().decode([SupabaseAssignment].self, from: data),
                      let newAssignment = assignments.first else { return }

                let statusDict: [String: Any] = [
                    "user_id": uid,
                    "assignment_id": newAssignment.id,
                    "status": "Not Started"
                ]
                guard let statusBody = try? JSONSerialization.data(withJSONObject: statusDict),
                      let statusReq = self.makeRequest("student_assignments", method: "POST", body: statusBody) else { return }
                URLSession.shared.dataTask(with: statusReq) { _, _, _ in
                    DispatchQueue.main.async { completion(.success(true)) }
                }.resume()
            }
        }.resume()
    }
}

struct University: Codable, Identifiable {
    let id: String
    let name: String
    let city: String
    let shortName: String
    let domain: String?

    enum CodingKeys: String, CodingKey {
        case id, name, city, domain
        case shortName = "short_name"
    }
}
