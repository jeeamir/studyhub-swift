import SwiftUI

struct GradesView: View {
    @AppStorage("dark_mode") var darkMode = false
    @State private var grades: [SupabaseGrade] = []
    @State private var sections: [EnrolledSection] = []
    @State private var profile: SupabaseProfile? = nil
    @State private var isLoading = false
    @State private var selectedSemester = "Spring 2026"

    let semesters = ["Spring 2026", "Fall 2025", "Spring 2025", "Fall 2024", "Fall 2023"]

    var groupedGrades: [(sectionId: String, subjectName: String, grades: [SupabaseGrade])] {
        let grouped = Dictionary(grouping: grades) { $0.sectionId ?? "unknown" }
        return grouped.map { sectionId, gradeList in
            let name = sections.first { $0.sectionId == sectionId }?.subjectName ?? "Unknown"
            return (sectionId: sectionId, subjectName: name, grades: gradeList)
        }.sorted { $0.subjectName < $1.subjectName }
    }

    var semesterGPA: Double {
        let completed = grades.filter { $0.gradeType == "Final Exam" && ($0.score ?? 0) > 0 }
        guard !completed.isEmpty else { return 0 }
        return completed.reduce(0.0) { $0 + gradePoints(for: $1) } / Double(completed.count)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // GPA Banner
                    gpaBanner
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 16)

                    // Semester selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(semesters, id: \.self) { sem in
                                Button(action: { selectedSemester = sem; loadAll() }) {
                                    Text(sem)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(selectedSemester == sem ? .white : .appSecondary)
                                        .padding(.horizontal, 16).padding(.vertical, 8)
                                        .background(selectedSemester == sem ? Color.appAccent : Color.appSurface)
                                        .clipShape(Capsule())
                                        .overlay(Capsule().stroke(selectedSemester == sem ? Color.clear : Color.appBorder, lineWidth: 1))
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                    }

                    if isLoading {
                        Spacer()
                        ProgressView().tint(.appAccent)
                        Spacer()
                    } else if grades.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "chart.bar").font(.system(size: 40)).foregroundColor(.appTertiary)
                            Text("No grades for this semester").foregroundColor(.appSecondary)
                        }
                        Spacer()
                    } else {
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 12) {
                                ForEach(groupedGrades, id: \.sectionId) { item in
                                    GradeCard(subjectName: item.subjectName, grades: item.grades)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 32)
                        }
                    }
                }
            }
            .navigationTitle("Grades")
            .navigationBarTitleDisplayMode(.large)
            .onAppear { loadAll() }
        }
        .preferredColorScheme(darkMode ? .dark : .light)
    }

    // MARK: - GPA Banner

    private var gpaBanner: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Overall GPA")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.appSecondary)
                Text(profile?.gpa ?? 0 > 0 ? String(format: "%.2f", profile?.gpa ?? 0) : "—")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(.appAccent)
                Text("out of 4.0")
                    .font(.system(size: 12))
                    .foregroundColor(.appTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(Color.appSurface)
            .cornerRadius(18)
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.appBorder, lineWidth: 1))

            VStack(alignment: .leading, spacing: 4) {
                Text("Semester GPA")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.appSecondary)
                Text(semesterGPA > 0 ? String(format: "%.2f", semesterGPA) : "—")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(.purple)
                Text("calculated")
                    .font(.system(size: 12))
                    .foregroundColor(.appTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .background(Color.appSurface)
            .cornerRadius(18)
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.appBorder, lineWidth: 1))
        }
    }

    func loadAll() {
        isLoading = true
        var count = 0
        func done() { count += 1; if count >= 3 { isLoading = false } }
        SupabaseService.shared.getGrades(semester: selectedSemester) { result in
            if case .success(let d) = result { grades = d }; done()
        }
        SupabaseService.shared.getEnrolledSections(semester: selectedSemester) { result in
            if case .success(let d) = result { sections = d }; done()
        }
        SupabaseService.shared.getProfile { result in
            if case .success(let d) = result { profile = d }; done()
        }
    }

    func gradePoints(for grade: SupabaseGrade) -> Double {
        let pct = ((grade.score ?? 0) / (grade.maxScore ?? 100)) * 100
        switch pct {
        case 95...100: return 4.0
        case 90..<95: return 3.67
        case 85..<90: return 3.33
        case 80..<85: return 3.0
        case 75..<80: return 2.67
        case 70..<75: return 2.33
        case 65..<70: return 2.0
        case 60..<65: return 1.67
        default: return 0.0
        }
    }
}

// MARK: - Grade Card

struct GradeCard: View {
    let subjectName: String
    let grades: [SupabaseGrade]

    var midterm1: [SupabaseGrade] { grades.filter { $0.gradeType == "Midterm 1" } }
    var midterm2: [SupabaseGrade] { grades.filter { $0.gradeType == "Midterm 2" } }
    var finalGrades: [SupabaseGrade] { grades.filter { $0.gradeType == "Final Exam" } }

    var m1Score: Double { scorePercent(midterm1) }
    var m2Score: Double { scorePercent(midterm2) }
    var finalScore: Double { scorePercent(finalGrades) }
    var totalScore: Double { m1Score * 0.3 + m2Score * 0.3 + finalScore * 0.4 }
    var isCompleted: Bool { finalScore > 0 }

    func scorePercent(_ items: [SupabaseGrade]) -> Double {
        let total = items.reduce(0.0) { $0 + ($1.score ?? 0) }
        let max = items.reduce(0.0) { $0 + ($1.maxScore ?? 0) }
        guard max > 0 else { return 0 }
        return (total / max) * 100
    }

    var letterGrade: String {
        switch totalScore {
        case 95...100: return "A"
        case 90..<95: return "A-"
        case 85..<90: return "B+"
        case 80..<85: return "B"
        case 75..<80: return "B-"
        case 70..<75: return "C+"
        case 65..<70: return "C"
        case 50..<65: return "C-"
        default: return "F"
        }
    }

    var gradeColor: Color {
        totalScore >= 85 ? .green : totalScore >= 70 ? .blue : totalScore >= 50 ? .orange : .red
    }

    var body: some View {
        VStack(spacing: 14) {
            // Header
            HStack {
                Text(subjectName)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.appPrimary)
                Spacer()
                if isCompleted {
                    Text(letterGrade)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(gradeColor)
                } else {
                    Text("In Progress")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.orange)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                }
            }

            // Progress bars
            VStack(spacing: 8) {
                GradeProgressRow(label: "Midterm 1", value: m1Score, weight: "30%", color: .appAccent)
                GradeProgressRow(label: "Midterm 2", value: m2Score, weight: "30%", color: .purple)
                GradeProgressRow(label: "Final", value: finalScore, weight: "40%", color: .orange)
            }

            // Total
            HStack {
                Text("Total Score")
                    .font(.system(size: 12))
                    .foregroundColor(.appSecondary)
                Spacer()
                Text(totalScore > 0 ? String(format: "%.1f%%", totalScore) : "—")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(totalScore > 0 ? gradeColor : .appSecondary)
            }
        }
        .padding(16)
        .background(Color.appSurface)
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.appBorder, lineWidth: 1))
    }
}

struct GradeProgressRow: View {
    let label: String
    let value: Double
    let weight: String
    let color: Color

    var body: some View {
        VStack(spacing: 5) {
            HStack {
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.appSecondary)
                Text(weight)
                    .font(.system(size: 10))
                    .foregroundColor(.appTertiary)
                Spacer()
                Text(value > 0 ? String(format: "%.0f%%", value) : "—")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(value > 0 ? color : .appTertiary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(color.opacity(0.1))
                    RoundedRectangle(cornerRadius: 3).fill(color)
                        .frame(width: geo.size.width * CGFloat(min(value / 100, 1)))
                }
            }
            .frame(height: 5)
        }
    }
}
