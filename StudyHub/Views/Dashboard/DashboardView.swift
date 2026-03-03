import SwiftUI

struct DashboardView: View {
    @AppStorage("dark_mode") var darkMode = false
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject private var session = UserSession.shared

    @State private var scheduleItems: [EnrolledSection] = []
    @State private var assignmentItems: [AssignmentWithStatus] = []
    @State private var profile: SupabaseProfile? = nil
    @State private var appeared = false
    @State private var isLoading = true
    @State private var loadedCount = 0
    @State private var hasLoaded = false
    

    var overdueCount: Int {
        assignmentItems.filter { item in
            guard let deadline = item.assignment.deadline,
                  let date = dateFrom(deadline) else { return false }
            return date < Date() && item.status != "Submitted"
        }.count
    }

    var upcomingAssignments: [AssignmentWithStatus] {
        assignmentItems
            .filter { item in
                guard let deadline = item.assignment.deadline,
                      let date = dateFrom(deadline) else { return false }
                return date >= Date() && item.status != "Submitted"
            }
            .sorted {
                let d1 = dateFrom($0.assignment.deadline ?? "") ?? Date.distantFuture
                let d2 = dateFrom($1.assignment.deadline ?? "") ?? Date.distantFuture
                return d1 < d2
            }
            .prefix(3).map { $0 }
    }

    var todayClasses: [EnrolledSection] {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return scheduleItems.filter { $0.days.contains(weekday) }
            .sorted { $0.startTime < $1.startTime }
    }

    var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12:  return "Good morning ☀️"
        case 12..<17: return "Good afternoon 👋"
        case 17..<22: return "Good evening 🌙"
        default:      return "Good night 😴"
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                if isLoading {
                    ProgressView().tint(.appAccent)
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 0) {
                            headerSection
                            statsSection
                            scheduleSection
                            deadlinesSection
                            Spacer().frame(height: 32)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear { if !hasLoaded { loadAll() } }
        }
        .preferredColorScheme(darkMode ? .dark : .light)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(greetingText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.appSecondary)
                Text(profile?.fullName ?? "Student")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.appPrimary)
            }
            Spacer()
            // Avatar
            Group {
                if let img = session.avatarImage {
                    Image(uiImage: img)
                        .resizable().scaledToFill()
                        .frame(width: 46, height: 46)
                        .clipShape(Circle())
                } else {
                    ZStack {
                        Circle().fill(Color.appAccent.opacity(0.12)).frame(width: 46, height: 46)
                        Text(String((profile?.fullName ?? "S").prefix(1)))
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.appAccent)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
        .padding(.bottom, 24)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : -16)
        .animation(.spring(response: 0.5).delay(0.05), value: appeared)
    }

    // MARK: - Stats

    private var statsSection: some View {
        HStack(spacing: 12) {
            DashStatCard(
                value: String(format: "%.2f", profile?.gpa ?? 0),
                label: "GPA",
                icon: "star.fill",
                color: .purple
            )
            DashStatCard(
                value: "\(scheduleItems.count)",
                label: "Courses",
                icon: "book.closed.fill",
                color: .blue
            )
            DashStatCard(
                value: "\(overdueCount)",
                label: "Overdue",
                icon: "exclamationmark.circle.fill",
                color: overdueCount > 0 ? .red : .green
            )
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 28)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .animation(.spring(response: 0.5).delay(0.1), value: appeared)
    }

    // MARK: - Schedule

    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Today's Schedule")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.appPrimary)
                Spacer()
                Text(todayName())
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.appAccent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.appAccent.opacity(0.1))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 20)

            if todayClasses.isEmpty {
                HStack(spacing: 14) {
                    Text("🎉").font(.system(size: 28))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("No classes today").font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.appPrimary)
                        Text("Enjoy your free time!").font(.system(size: 13))
                            .foregroundColor(.appSecondary)
                    }
                    Spacer()
                }
                .padding(16)
                .background(Color.appSurface)
                .cornerRadius(16)
                .padding(.horizontal, 20)
            } else {
                ForEach(Array(todayClasses.enumerated()), id: \.element.id) { i, lesson in
                    DashScheduleRow(lesson: lesson)
                        .padding(.horizontal, 20)
                        .opacity(appeared ? 1 : 0)
                        .offset(x: appeared ? 0 : 30)
                        .animation(.spring(response: 0.5).delay(0.15 + Double(i) * 0.06), value: appeared)
                }
            }
        }
        .padding(.bottom, 28)
    }

    // MARK: - Deadlines

    private var deadlinesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Upcoming Deadlines")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.appPrimary)
                Spacer()
                if !upcomingAssignments.isEmpty {
                    Text("\(upcomingAssignments.count) tasks")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.appSecondary)
                }
            }
            .padding(.horizontal, 20)

            if upcomingAssignments.isEmpty {
                HStack(spacing: 14) {
                    Text("✅").font(.system(size: 28))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("All caught up!").font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.appPrimary)
                        Text("No pending assignments").font(.system(size: 13))
                            .foregroundColor(.appSecondary)
                    }
                    Spacer()
                }
                .padding(16)
                .background(Color.appSurface)
                .cornerRadius(16)
                .padding(.horizontal, 20)
            } else {
                ForEach(Array(upcomingAssignments.enumerated()), id: \.element.id) { i, item in
                    DashDeadlineRow(item: item)
                        .padding(.horizontal, 20)
                        .opacity(appeared ? 1 : 0)
                        .offset(x: appeared ? 0 : 30)
                        .animation(.spring(response: 0.5).delay(0.2 + Double(i) * 0.06), value: appeared)
                }
            }
        }
    }

    // MARK: - Load

    func loadAll() {
        hasLoaded = true; isLoading = true; loadedCount = 0
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
            if self.isLoading { self.isLoading = false; self.appeared = true }
        }
        SupabaseService.shared.getProfile { result in
            if case .success(let d) = result { profile = d }
            checkDone()
        }
        SupabaseService.shared.getSchedule { result in
            if case .success(let d) = result { scheduleItems = d }
            checkDone()
        }
        SupabaseService.shared.getAssignments { result in
            if case .success(let d) = result { assignmentItems = d }
            checkDone()
        }
    }

    func checkDone() {
        loadedCount += 1
        if loadedCount >= 3 {
            isLoading = false
            withAnimation(.spring(response: 0.6)) { appeared = true }
        }
    }

    func todayName() -> String {
        let f = DateFormatter(); f.dateFormat = "EEEE, MMM d"
        return f.string(from: Date())
    }

    func dateFrom(_ s: String) -> Date? {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        return f.date(from: String(s.prefix(10)))
    }
}

// MARK: - Stat Card

struct DashStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(color)
            }
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.appPrimary)
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.appSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.appSurface)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.appBorder, lineWidth: 1)
        )
    }
}

// MARK: - Schedule Row

struct DashScheduleRow: View {
    let lesson: EnrolledSection

    var color: Color { AppColors.from(lesson.color) }

    var body: some View {
        HStack(spacing: 14) {
            Rectangle()
                .fill(color)
                .frame(width: 3)
                .cornerRadius(2)

            VStack(alignment: .leading, spacing: 3) {
                Text(lesson.subjectName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.appPrimary)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(lesson.room)
                    Text("·")
                    Text(lesson.professorName)
                }
                .font(.system(size: 12))
                .foregroundColor(.appSecondary)
                .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(lesson.startTime)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.appPrimary)
                Text(lesson.endTime)
                    .font(.system(size: 11))
                    .foregroundColor(.appSecondary)
            }
        }
        .padding(14)
        .background(Color.appSurface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Deadline Row

struct DashDeadlineRow: View {
    let item: AssignmentWithStatus

    var daysLeft: Int {
        guard let d = item.assignment.deadline,
              let date = { let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.date(from: String(d.prefix(10))) }()
        else { return 0 }
        return Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
    }

    var urgencyColor: Color {
        daysLeft <= 0 ? .red : daysLeft <= 3 ? .orange : .appSecondary
    }

    var statusColor: Color {
        switch item.status {
        case "Submitted": return .green
        case "In Progress": return .orange
        default: return .red
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                Text(item.assignment.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.appPrimary)
                    .lineLimit(1)
                Text(item.subjectName)
                    .font(.system(size: 12))
                    .foregroundColor(.appSecondary)
                HStack(spacing: 6) {
                    Text(item.assignment.midtermPeriod ?? "")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.appAccent)
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(Color.appAccent.opacity(0.1))
                        .cornerRadius(6)
                    Text(item.assignment.assignmentType ?? "")
                        .font(.system(size: 11))
                        .foregroundColor(.appSecondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text(daysLeft <= 0 ? "Overdue" : "\(daysLeft)d left")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(urgencyColor)
                Text(item.status)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(statusColor)
                    .cornerRadius(6)
            }
        }
        .padding(14)
        .background(Color.appSurface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.appBorder, lineWidth: 1)
        )
    }
}

// MARK: - Color helper (shared)
struct AppColors {
    static func from(_ name: String) -> Color {
        switch name {
        case "blue":   return .blue
        case "orange": return .orange
        case "purple": return .purple
        case "green":  return .green
        case "red":    return .red
        case "teal":   return .teal
        case "mint":   return .mint
        default:       return .blue
        }
    }
}
