import SwiftUI

struct SectionDetailView: View {
    let section: EnrolledSection

    @State private var selectedTab = 0
    @State private var grades: [SupabaseGrade] = []
    @State private var assignments: [AssignmentWithStatus] = []
    @State private var isLoading = true

    var cardColor: Color { colorFrom(section.color) }

    var sectionGrades: [SupabaseGrade] {
        grades.filter { $0.sectionId == section.sectionId }
    }

    var midterm1: [SupabaseGrade] { sectionGrades.filter { $0.gradeType == "Midterm 1" } }
    var midterm2: [SupabaseGrade] { sectionGrades.filter { $0.gradeType == "Midterm 2" } }
    var finalGrades: [SupabaseGrade] { sectionGrades.filter { $0.gradeType == "Final Exam" } }

    var sectionAssignments: [AssignmentWithStatus] {
        assignments.filter { $0.assignment.sectionId == section.sectionId }
    }

    var pendingCount: Int {
        sectionAssignments.filter { $0.status != "Submitted" }.count
    }

    var averageScore: Double {
        let completed = sectionGrades.filter { ($0.score ?? 0) > 0 }
        guard !completed.isEmpty else { return 0 }
        let total = completed.reduce(0.0) { $0 + (($1.score ?? 0) / ($1.maxScore ?? 100)) * 100 }
        return total / Double(completed.count)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerSection
                tabSelector
                if isLoading {
                    ProgressView().padding(40)
                } else {
                    if selectedTab == 0 { gradesTab }
                    else if selectedTab == 1 { assignmentsTab }
                    else { infoTab }
                }
            }
        }
        .navigationTitle(section.subjectName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { loadData() }
    }

    var headerSection: some View {
        VStack(spacing: 16) {
            Circle()
                .fill(cardColor.opacity(0.2))
                .frame(width: 70, height: 70)
                .overlay(
                    Text(String(section.subjectName.prefix(1)))
                        .font(.title.bold())
                        .foregroundColor(cardColor)
                )

            VStack(spacing: 4) {
                Text(section.subjectName).font(.title2.bold())
                Text(section.sectionCode)
                    .font(.subheadline).foregroundColor(.secondary)
            }

            HStack(spacing: 24) {
                VStack {
                    Text(averageScore > 0 ? String(format: "%.0f%%", averageScore) : "—")
                        .font(.title3.bold()).foregroundColor(cardColor)
                    Text("Avg Score").font(.caption).foregroundColor(.secondary)
                }
                Divider().frame(height: 30)
                VStack {
                    Text("\(section.credits)")
                        .font(.title3.bold()).foregroundColor(cardColor)
                    Text("Credits").font(.caption).foregroundColor(.secondary)
                }
                Divider().frame(height: 30)
                VStack {
                    Text("\(pendingCount)")
                        .font(.title3.bold()).foregroundColor(cardColor)
                    Text("Pending").font(.caption).foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .padding()
    }

    var tabSelector: some View {
        HStack(spacing: 0) {
            tabButton(title: "Grades", index: 0)
            tabButton(title: "Assignments", index: 1)
            tabButton(title: "Info", index: 2)
        }
        .background(Color(.systemGray6))
    }

    func tabButton(title: String, index: Int) -> some View {
        Button(action: { selectedTab = index }) {
            VStack(spacing: 0) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(selectedTab == index ? cardColor : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                Rectangle()
                    .fill(selectedTab == index ? cardColor : Color.clear)
                    .frame(height: 2)
            }
        }
    }

    // MARK: - Grades Tab
    var gradesTab: some View {
        VStack(spacing: 12) {
            gradeSection(title: "Midterm 1 — 30%", grades: midterm1, color: .blue)
            gradeSection(title: "Midterm 2 — 30%", grades: midterm2, color: .purple)
            gradeSection(title: "Final Exam — 40%", grades: finalGrades, color: .orange)
        }
        .padding()
    }

    func gradeSection(title: String, grades: [SupabaseGrade], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.bold()).foregroundColor(.white)
                .padding(.horizontal, 12).padding(.vertical, 4)
                .background(color).cornerRadius(8)

            if grades.isEmpty {
                Text("No grades yet")
                    .font(.caption).foregroundColor(.secondary)
                    .padding().frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6)).cornerRadius(12)
            } else {
                VStack(spacing: 0) {
                    ForEach(grades) { grade in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(grade.taskName ?? "").font(.subheadline)
                                Text(grade.gradeType ?? "")
                                    .font(.caption2).foregroundColor(.white)
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(color.opacity(0.8)).cornerRadius(4)
                            }
                            Spacer()
                            if (grade.score ?? 0) == 0 {
                                Text("N/D").font(.subheadline.bold()).foregroundColor(.secondary)
                            } else {
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(String(format: "%.0f / %.0f", grade.score ?? 0, grade.maxScore ?? 0))
                                        .font(.subheadline.bold()).foregroundColor(color)
                                    Text(String(format: "%.0f%%", ((grade.score ?? 0) / (grade.maxScore ?? 1)) * 100))
                                        .font(.caption).foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal).padding(.vertical, 12)
                        if grade.id != grades.last?.id { Divider().padding(.horizontal) }
                    }
                }
                .background(Color(.systemGray6)).cornerRadius(12)
            }
        }
    }

    // MARK: - Assignments Tab
    var assignmentsTab: some View {
        VStack(spacing: 12) {
            if sectionAssignments.isEmpty {
                Text("No assignments").foregroundColor(.secondary).padding()
            } else {
                ForEach(sectionAssignments) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.assignment.title).font(.subheadline.bold())
                            Text(item.assignment.midtermPeriod ?? "")
                                .font(.caption2.bold()).foregroundColor(.blue)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Color.blue.opacity(0.15)).cornerRadius(4)
                            Text(item.assignment.deadline ?? "")
                                .font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(item.status)
                            .font(.caption.bold()).foregroundColor(.white)
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(statusColor(item.status))
                            .cornerRadius(8)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }
        }
        .padding()
    }

    // MARK: - Info Tab
    var infoTab: some View {
        VStack(spacing: 12) {
            InfoRow(icon: "person.fill", label: "Professor", value: section.professorName, color: cardColor)
            InfoRow(icon: "mappin", label: "Room", value: section.room, color: cardColor)
            InfoRow(icon: "number", label: "Section", value: section.sectionCode, color: cardColor)
            InfoRow(icon: "calendar", label: "Semester", value: section.semester, color: cardColor)
            InfoRow(icon: "star.fill", label: "Credits", value: "\(section.credits)", color: cardColor)
            InfoRow(icon: "clock", label: "Schedule",
                    value: "\(section.startTime) - \(section.endTime)", color: cardColor)
        }
        .padding()
    }

    func loadData() {
        isLoading = true
        var loadedCount = 0

        SupabaseService.shared.getGrades(semester: section.semester) { result in
            if case .success(let data) = result { grades = data }
            loadedCount += 1
            if loadedCount >= 2 { isLoading = false }
        }

        SupabaseService.shared.getAssignments { result in
            if case .success(let data) = result { assignments = data }
            loadedCount += 1
            if loadedCount >= 2 { isLoading = false }
        }
    }

    func statusColor(_ status: String) -> Color {
        switch status {
        case "Submitted":   return .green
        case "In Progress": return .orange
        default:            return .red
        }
    }

    func colorFrom(_ name: String) -> Color {
        switch name {
        case "blue":   return .blue
        case "purple": return .purple
        case "orange": return .orange
        case "green":  return .green
        case "red":    return .red
        case "teal":   return .teal
        case "mint":   return .mint
        default:       return .blue
        }
    }
}

struct InfoRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon).foregroundColor(color).frame(width: 20)
            Text(label).foregroundColor(.secondary)
            Spacer()
            Text(value).bold()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
