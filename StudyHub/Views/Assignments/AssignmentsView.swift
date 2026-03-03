import SwiftUI

struct AssignmentsView: View {
    @AppStorage("dark_mode") var darkMode = false
    @State private var assignments: [AssignmentWithStatus] = []
    @State private var enrolledSections: [EnrolledSection] = []
    @State private var isLoading = false
    @State private var searchText = ""
    @State private var filterStatus: String? = nil
    @State private var showingAddSheet = false

    @State private var newTitle = ""
    @State private var newSectionId = ""
    @State private var newType = "Lab Work"
    @State private var newMidterm = "Midterm 1"
    @State private var newDesc = ""
    @State private var newDeadline = "2026-05-15"

    var filteredAssignments: [AssignmentWithStatus] {
        assignments
            .filter {
                (filterStatus == nil || $0.status == filterStatus) &&
                (searchText.isEmpty ||
                 $0.assignment.title.lowercased().contains(searchText.lowercased()) ||
                 $0.subjectName.lowercased().contains(searchText.lowercased()))
            }
            .sorted {
                let d1 = dateFrom($0.assignment.deadline ?? "") ?? Date.distantFuture
                let d2 = dateFrom($1.assignment.deadline ?? "") ?? Date.distantFuture
                return d1 < d2
            }
    }

    // Group by status for visual sections
    var overdueItems: [AssignmentWithStatus] {
        filteredAssignments.filter {
            guard let d = $0.assignment.deadline, let date = dateFrom(d) else { return false }
            return date < Date() && $0.status != "Submitted"
        }
    }

    var upcomingItems: [AssignmentWithStatus] {
        filteredAssignments.filter {
            guard let d = $0.assignment.deadline, let date = dateFrom(d) else { return false }
            return date >= Date() && $0.status != "Submitted"
        }
    }

    var submittedItems: [AssignmentWithStatus] {
        filteredAssignments.filter { $0.status == "Submitted" }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Filter tabs
                    filterTabBar

                    if isLoading {
                        Spacer()
                        ProgressView().tint(.appAccent)
                        Spacer()
                    } else if filteredAssignments.isEmpty {
                        Spacer()
                        VStack(spacing: 10) {
                            Image(systemName: "tray")
                                .font(.system(size: 40)).foregroundColor(.appTertiary)
                            Text(searchText.isEmpty ? "No assignments" : "No results")
                                .font(.system(size: 15)).foregroundColor(.appSecondary)
                        }
                        Spacer()
                    } else {
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 0) {
                                if !overdueItems.isEmpty && filterStatus == nil {
                                    assignmentSection(title: "Overdue", items: overdueItems, accent: .red)
                                }
                                if !upcomingItems.isEmpty && filterStatus == nil {
                                    assignmentSection(title: "Upcoming", items: upcomingItems, accent: .appAccent)
                                }
                                if !submittedItems.isEmpty && filterStatus == nil {
                                    assignmentSection(title: "Submitted", items: submittedItems, accent: .green)
                                }
                                if filterStatus != nil {
                                    assignmentSection(title: filterStatus!, items: filteredAssignments, accent: .appAccent)
                                }
                            }
                            .padding(.bottom, 32)
                        }
                    }
                }
            }
            .navigationTitle("Assignments")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search assignments")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.appAccent)
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) { addSheet }
            .onAppear { loadAll() }
        }
        .preferredColorScheme(darkMode ? .dark : .light)
    }

    // MARK: - Filter Tab Bar

    private var filterTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(label: "All", isSelected: filterStatus == nil) {
                    filterStatus = nil
                }
                FilterChip(label: "Not Started", isSelected: filterStatus == "Not Started") {
                    filterStatus = "Not Started"
                }
                FilterChip(label: "In Progress", isSelected: filterStatus == "In Progress") {
                    filterStatus = "In Progress"
                }
                FilterChip(label: "Submitted", isSelected: filterStatus == "Submitted") {
                    filterStatus = "Submitted"
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }

    // MARK: - Section builder

    private func assignmentSection(title: String, items: [AssignmentWithStatus], accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(accent)
                Text("\(items.count)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 20, height: 20)
                    .background(accent)
                    .clipShape(Circle())
            }
            .padding(.horizontal, 20)

            ForEach(items) { item in
                NavigationLink(destination: AssignmentDetailView(item: item)) {
                    AssignmentCard(item: item)
                        .padding(.horizontal, 20)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.top, 20)
    }

    // MARK: - Add Sheet

    var addSheet: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                Form {
                    Section("Assignment Info") {
                        TextField("Title", text: $newTitle)
                        Picker("Subject", selection: $newSectionId) {
                            ForEach(enrolledSections.filter { $0.semester == "Spring 2026" }) { s in
                                Text(s.subjectName).tag(s.sectionId)
                            }
                        }
                        Picker("Type", selection: $newType) {
                            ForEach(["Lab Work", "Homework", "Project", "Essay", "Quiz"], id: \.self) { Text($0) }
                        }
                        Picker("Midterm", selection: $newMidterm) {
                            ForEach(["Midterm 1", "Midterm 2", "Final Exam"], id: \.self) { Text($0) }
                        }
                        TextField("Deadline (2026-05-15)", text: $newDeadline)
                    }
                    Section("Description") {
                        TextField("Description (optional)", text: $newDesc, axis: .vertical).lineLimit(3...5)
                    }
                }
            }
            .navigationTitle("New Assignment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { showingAddSheet = false }.foregroundColor(.appAccent)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") { addAssignment() }
                        .bold().foregroundColor(.appAccent)
                        .disabled(newTitle.isEmpty || newSectionId.isEmpty)
                }
            }
        }
    }

    // MARK: - Logic (unchanged)

    func loadAll() {
        isLoading = true
        var count = 0
        SupabaseService.shared.getAssignments { result in
            if case .success(let data) = result { assignments = data }
            count += 1; if count >= 2 { isLoading = false }
        }
        SupabaseService.shared.getEnrolledSections(semester: "Spring 2026") { result in
            if case .success(let data) = result {
                enrolledSections = data
                if newSectionId.isEmpty { newSectionId = data.first?.sectionId ?? "" }
            }
            count += 1; if count >= 2 { isLoading = false }
        }
    }

    func addAssignment() {
        guard !newTitle.isEmpty, !newSectionId.isEmpty else { return }
        SupabaseService.shared.createAssignment(
            sectionId: newSectionId, title: newTitle, description: newDesc,
            type: newType, midterm: newMidterm, deadline: newDeadline, maxScore: 16.66
        ) { result in if case .success = result { loadAll() } }
        newTitle = ""; newDesc = ""; showingAddSheet = false
    }

    func dateFrom(_ s: String) -> Date? {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        return f.date(from: String(s.prefix(10)))
    }
}

// MARK: - Assignment Card

struct AssignmentCard: View {
    let item: AssignmentWithStatus

    var daysLeft: Int {
        guard let d = item.assignment.deadline,
              let date = { let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.date(from: String(d.prefix(10))) }()
        else { return 0 }
        return Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
    }

    var statusColor: Color {
        switch item.status {
        case "Submitted": return .green
        case "In Progress": return .orange
        default: return .red
        }
    }

    var urgencyColor: Color { daysLeft <= 0 ? .red : daysLeft <= 3 ? .orange : .appSecondary }

    var midtermColor: Color { item.assignment.midtermPeriod == "Midterm 1" ? .appAccent : .purple }

    var body: some View {
        HStack(spacing: 14) {
            // Left status stripe
            RoundedRectangle(cornerRadius: 2)
                .fill(statusColor)
                .frame(width: 3)

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
                        .foregroundColor(midtermColor)
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(midtermColor.opacity(0.1))
                        .cornerRadius(6)
                    Text(item.assignment.assignmentType ?? "")
                        .font(.system(size: 11))
                        .foregroundColor(.appSecondary)
                }
            }

            Spacer()

            Text(daysLeft <= 0 ? "Overdue" : "\(daysLeft)d")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(urgencyColor)
        }
        .padding(14)
        .background(Color.appSurface)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.appBorder, lineWidth: 1))
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(isSelected ? .white : .appSecondary)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(isSelected ? Color.appAccent : Color.appSurface)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(isSelected ? Color.clear : Color.appBorder, lineWidth: 1))
        }
    }
}

// MARK: - Assignment Detail View

struct AssignmentDetailView: View {
    let item: AssignmentWithStatus
    @State private var currentStatus: String = ""

    var midtermColor: Color {
        switch item.assignment.midtermPeriod {
        case "Midterm 1": return .appAccent
        case "Midterm 2": return .purple
        default:          return .orange
        }
    }

    var statusColor: Color {
        switch currentStatus {
        case "Submitted":   return .green
        case "In Progress": return .orange
        default:            return .red
        }
    }

    var daysLeft: Int {
        guard let deadline = item.assignment.deadline,
              let date = { let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
                  return f.date(from: String(deadline.prefix(10))) }()
        else { return 0 }
        return Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {

                // Header card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.subjectName)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.appSecondary)
                            Text(item.subjectCode)
                                .font(.system(size: 11))
                                .foregroundColor(.appTertiary)
                        }
                        Spacer()
                        Menu {
                            Button("Not Started") { updateStatus("Not Started") }
                            Button("In Progress") { updateStatus("In Progress") }
                            Button("Submitted")   { updateStatus("Submitted") }
                        } label: {
                            Text(currentStatus)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(statusColor)
                                .cornerRadius(8)
                        }
                    }

                    Text(item.assignment.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.appPrimary)

                    HStack(spacing: 8) {
                        Text(item.assignment.midtermPeriod ?? "")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(midtermColor)
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(midtermColor.opacity(0.1))
                            .cornerRadius(8)
                        Text(item.assignment.assignmentType ?? "")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.appSecondary)
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(Color.appSurface2)
                            .cornerRadius(8)
                    }
                }
                .padding(16)
                .background(Color.appSurface)
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appBorder, lineWidth: 1))
                .padding(.horizontal, 20)

                // Stats row
                HStack(spacing: 12) {
                    DetailStatCard(
                        icon: "calendar",
                        title: "Deadline",
                        value: String(item.assignment.deadline?.prefix(10) ?? "—"),
                        sub: daysLeft <= 0 ? "Overdue" : "\(daysLeft) days left",
                        color: daysLeft <= 1 ? .red : .appAccent
                    )
                    DetailStatCard(
                        icon: "star.fill",
                        title: "Max Score",
                        value: String(format: "%.0f pts", item.assignment.maxScore ?? 0),
                        sub: "Points",
                        color: .orange
                    )
                }
                .padding(.horizontal, 20)

                // Description
                VStack(alignment: .leading, spacing: 8) {
                    Text("DESCRIPTION")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.appTertiary)
                        .kerning(0.8)
                        .padding(.leading, 4)

                    Text(item.assignment.description?.isEmpty == false
                         ? item.assignment.description!
                         : "No description provided")
                        .font(.system(size: 15))
                        .foregroundColor(item.assignment.description?.isEmpty == false
                                         ? .appPrimary : .appSecondary)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.appSurface)
                        .cornerRadius(14)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.appBorder, lineWidth: 1))
                }
                .padding(.horizontal, 20)

                Spacer().frame(height: 32)
            }
            .padding(.top, 16)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle(item.assignment.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { currentStatus = item.status }
    }

    func updateStatus(_ status: String) {
        currentStatus = status
        SupabaseService.shared.updateAssignmentStatus(
            assignmentId: item.assignment.id, status: status) { _ in }
    }
}

// MARK: - Detail Stat Card

struct DetailStatCard: View {
    let icon: String
    let title: String
    let value: String
    let sub: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.appSecondary)
            }
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.appPrimary)
            Text(sub)
                .font(.system(size: 11))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.appSurface)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.appBorder, lineWidth: 1))
    }
}
