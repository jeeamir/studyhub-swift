import SwiftUI

struct SubjectsView: View {
    @AppStorage("dark_mode") var darkMode = false
    @State private var sections: [EnrolledSection] = []
    @State private var isLoading = false
    @State private var selectedSemester = "Spring 2026"

    let semesters = ["Spring 2026", "Fall 2025", "Spring 2025", "Fall 2024", "Fall 2023"]

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Semester pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(semesters, id: \.self) { sem in
                                Button(action: { selectedSemester = sem; loadSections() }) {
                                    Text(sem)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(selectedSemester == sem ? .white : .appSecondary)
                                        .padding(.horizontal, 16).padding(.vertical, 8)
                                        .background(
                                            selectedSemester == sem
                                            ? Color.appAccent
                                            : Color.appSurface
                                        )
                                        .clipShape(Capsule())
                                        .overlay(
                                            Capsule().stroke(
                                                selectedSemester == sem ? Color.clear : Color.appBorder,
                                                lineWidth: 1
                                            )
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }

                    if isLoading {
                        Spacer()
                        ProgressView().tint(.appAccent)
                        Spacer()
                    } else if sections.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "book.closed")
                                .font(.system(size: 40)).foregroundColor(.appTertiary)
                            Text("No subjects for this semester")
                                .font(.system(size: 15)).foregroundColor(.appSecondary)
                        }
                        Spacer()
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVGrid(
                                columns: [GridItem(.flexible()), GridItem(.flexible())],
                                spacing: 14
                            ) {
                                ForEach(sections) { section in
                                    NavigationLink(destination: SectionDetailView(section: section)) {
                                        SubjectCard(section: section)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 32)
                        }
                    }
                }
            }
            .navigationTitle("Subjects")
            .navigationBarTitleDisplayMode(.large)
            .onAppear { loadSections() }
        }
        .preferredColorScheme(darkMode ? .dark : .light)
    }

    func loadSections() {
        isLoading = true
        SupabaseService.shared.getEnrolledSections(semester: selectedSemester) { result in
            isLoading = false
            if case .success(let data) = result { sections = data }
        }
    }
}

struct SubjectCard: View {
    let section: EnrolledSection
    var color: Color { AppColors.from(section.color) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top color band
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(color.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Text(String(section.subjectName.prefix(1)))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(color)
                }
                Spacer()
                Text("\(section.credits) cr")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(color)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(color.opacity(0.12))
                    .cornerRadius(8)
            }
            .padding(.bottom, 12)

            Text(section.subjectName)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.appPrimary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 4)

            Text(section.professorName)
                .font(.system(size: 12))
                .foregroundColor(.appSecondary)
                .lineLimit(1)
                .padding(.bottom, 2)

            HStack(spacing: 4) {
                Image(systemName: "mappin").font(.system(size: 10))
                Text(section.room).font(.system(size: 11))
            }
            .foregroundColor(.appTertiary)
            .padding(.bottom, 10)

            Text(section.sectionCode)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(color)
                .padding(.horizontal, 7).padding(.vertical, 3)
                .background(color.opacity(0.1))
                .cornerRadius(6)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appSurface)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.appBorder, lineWidth: 1)
        )
    }
}
