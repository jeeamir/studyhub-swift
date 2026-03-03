import SwiftUI

struct StatisticsView: View {
    @State private var grades: [SupabaseGrade] = []
    @State private var sections: [EnrolledSection] = []
    @State private var profile: SupabaseProfile? = nil
    @State private var isLoading = true

    var overallGPA: Double { profile?.gpa ?? 0 }

    var subjectStats: [(name: String, score: Double, color: String)] {
        let grouped = Dictionary(grouping: grades) { $0.sectionId ?? "" }
        return grouped.compactMap { sectionId, items in
            let completed = items.filter { ($0.score ?? 0) > 0 }
            guard !completed.isEmpty else { return nil }
            let total = completed.reduce(0.0) { $0 + (($1.score ?? 0) / ($1.maxScore ?? 100)) * 100 }
            let name = sections.first { $0.sectionId == sectionId }?.subjectName ?? "Unknown"
            let color = sections.first { $0.sectionId == sectionId }?.color ?? "blue"
            return (name: name, score: total / Double(completed.count), color: color)
        }.sorted { $0.score > $1.score }
    }

    var gradeDistribution: [(letter: String, count: Int, color: Color)] {
        var dist = ["A": 0, "B": 0, "C": 0, "D": 0, "F": 0]
        for item in subjectStats {
            switch item.score {
            case 90...100: dist["A"]! += 1
            case 75..<90:  dist["B"]! += 1
            case 60..<75:  dist["C"]! += 1
            case 50..<60:  dist["D"]! += 1
            default:       dist["F"]! += 1
            }
        }
        return [
            ("A", dist["A"]!, .green),
            ("B", dist["B"]!, .blue),
            ("C", dist["C"]!, .orange),
            ("D", dist["D"]!, .red),
            ("F", dist["F"]!, .gray)
        ]
    }

    var totalCredits: Int { sections.reduce(0) { $0 + $1.credits } }

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                if isLoading {
                    ProgressView("Loading statistics...")
                } else {
                    ScrollView {
                        VStack(spacing: 20) {

                            // GPA Hero Card
                            ZStack {
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.blue, Color.purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: .blue.opacity(0.4), radius: 20, y: 8)

                                HStack {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Overall GPA")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white.opacity(0.8))
                                        Text(String(format: "%.2f", overallGPA))
                                            .font(.system(size: 56, weight: .bold))
                                            .foregroundColor(.white)
                                        Text("out of 4.0 · \(sections.count) courses")
                                            .font(.system(size: 13))
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    Spacer()
                                    ZStack {
                                        Circle()
                                            .stroke(Color.white.opacity(0.2), lineWidth: 8)
                                        Circle()
                                            .trim(from: 0, to: min(overallGPA / 4.0, 1.0))
                                            .stroke(Color.white, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                            .rotationEffect(.degrees(-90))
                                        Text(String(format: "%.0f%%", (overallGPA / 4.0) * 100))
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                    .frame(width: 80, height: 80)
                                }
                                .padding(24)
                            }
                            .padding(.horizontal)

                            // Summary cards
                            HStack(spacing: 12) {
                                MiniStatCard(title: "Courses", value: "\(sections.count)", icon: "book.fill", color: .blue)
                                MiniStatCard(title: "Credits", value: "\(totalCredits)", icon: "star.fill", color: .purple)
                                MiniStatCard(title: "Semester", value: "Spring", icon: "calendar", color: .orange)
                            }
                            .padding(.horizontal)

                            // Performance bars
                            if !subjectStats.isEmpty {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Performance")
                                        .font(.system(size: 18, weight: .bold))
                                        .padding(.horizontal)

                                    VStack(spacing: 12) {
                                        ForEach(subjectStats.prefix(6), id: \.name) { item in
                                            PerformanceBar(
                                                name: item.name,
                                                score: item.score,
                                                color: colorFrom(item.color)
                                            )
                                        }
                                    }
                                    .padding()
                                    .background(Color(.systemBackground))
                                    .cornerRadius(16)
                                    .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
                                    .padding(.horizontal)
                                }
                            }

                            // Grade distribution
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Grade Distribution")
                                    .font(.system(size: 18, weight: .bold))
                                    .padding(.horizontal)

                                HStack(spacing: 8) {
                                    ForEach(gradeDistribution, id: \.letter) { item in
                                        VStack(spacing: 8) {
                                            ZStack {
                                                Circle()
                                                    .fill(item.color.opacity(0.12))
                                                    .frame(width: 48, height: 48)
                                                Text("\(item.count)")
                                                    .font(.system(size: 18, weight: .bold))
                                                    .foregroundColor(item.count > 0 ? item.color : .secondary)
                                            }
                                            Text(item.letter)
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundColor(.secondary)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background(Color(.systemBackground))
                                        .cornerRadius(14)
                                    }
                                }
                                .padding(.horizontal)
                                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.large)
            .onAppear { loadAll() }
        }
    }

    func loadAll() {
        isLoading = true
        var count = 0

        SupabaseService.shared.getGrades(semester: "Spring 2026") { result in
            if case .success(let data) = result { grades = data }
            count += 1; if count >= 3 { isLoading = false }
        }

        SupabaseService.shared.getEnrolledSections(semester: "Spring 2026") { result in
            if case .success(let data) = result { sections = data }
            count += 1; if count >= 3 { isLoading = false }
        }

        SupabaseService.shared.getProfile { result in
            if case .success(let data) = result { profile = data }
            count += 1; if count >= 3 { isLoading = false }
        }
    }

    func colorFrom(_ name: String) -> Color {
        switch name {
        case "blue": return .blue
        case "orange": return .orange
        case "purple": return .purple
        case "green": return .green
        case "red": return .red
        case "teal": return .teal
        default: return .blue
        }
    }
}

struct MiniStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle().fill(color.opacity(0.12)).frame(width: 40, height: 40)
                Image(systemName: icon).font(.system(size: 16)).foregroundColor(color)
            }
            Text(value).font(.system(size: 20, weight: .bold))
            Text(title).font(.system(size: 11)).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}

struct PerformanceBar: View {
    let name: String
    let score: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(String(name.prefix(20)))
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                Spacer()
                Text(String(format: "%.0f%%", score))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(color)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.12))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.8), color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * CGFloat(score / 100))
                }
            }
            .frame(height: 8)
        }
    }
}

struct CircleProgressStat: View {
    let value: Double
    var body: some View {
        ZStack {
            Circle().stroke(Color.gray.opacity(0.2), lineWidth: 8)
            Circle()
                .trim(from: 0, to: min(value, 1.0))
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text(String(format: "%.0f%%", value * 100))
                .font(.caption.bold())
        }
    }
}
