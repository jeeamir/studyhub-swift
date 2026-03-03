import SwiftUI

struct ScheduleView: View {
    @State private var sections: [EnrolledSection] = []
    @State private var isLoading = false
    @State private var selectedDay: Int = Calendar.current.component(.weekday, from: Date())

    let days = [(2, "MON"), (3, "TUE"), (4, "WED"), (5, "THU"), (6, "FRI")]

    var filteredSections: [EnrolledSection] {
        sections
            .filter { $0.days.contains(selectedDay) }
            .sorted { $0.startTime < $1.startTime }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                VStack(spacing: 0) {
                    HStack(spacing: 8) {
                        ForEach(days, id: \.0) { day, name in
                            Button(action: { selectedDay = day }) {
                                VStack(spacing: 4) {
                                    Text(name)
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(selectedDay == day ? .white : .secondary)
                                    Circle()
                                        .fill(selectedDay == day ? Color.white.opacity(0.4) : Color.clear)
                                        .frame(width: 4, height: 4)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedDay == day
                                              ? Color.blue
                                              : Color(.systemBackground))
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .background(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 2)

                    if isLoading {
                        Spacer()
                        ProgressView()
                        Spacer()
                    } else if filteredSections.isEmpty {
                        Spacer()
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.1))
                                    .frame(width: 80, height: 80)
                                Image(systemName: "sun.max.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(.yellow)
                            }
                            Text("No classes today")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("Enjoy your free time!")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            VStack(spacing: 0) {
                                ForEach(Array(filteredSections.enumerated()), id: \.element.id) { index, section in
                                    ScheduleCard(section: section, index: index)
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Schedule")
            .navigationBarTitleDisplayMode(.large)
            .onAppear { loadSchedule() }
        }
    }

    func loadSchedule() {
        isLoading = true
        SupabaseService.shared.getSchedule { result in
            isLoading = false
            if case .success(let data) = result { sections = data }
        }
    }
}

struct ScheduleCard: View {
    let section: EnrolledSection
    let index: Int

    var color: Color { colorFrom(section.color) }

    var body: some View {
        HStack(spacing: 0) {
        
            VStack(alignment: .trailing, spacing: 4) {
                Text(section.startTime)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.primary)
                Text(section.endTime)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .frame(width: 52)
            .padding(.trailing, 12)

            
            VStack(spacing: 0) {
                Circle()
                    .fill(color)
                    .frame(width: 10, height: 10)
                Rectangle()
                    .fill(color.opacity(0.3))
                    .frame(width: 2)
            }
            .padding(.trailing, 12)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(section.subjectName)
                        .font(.system(size: 15, weight: .semibold))
                        .lineLimit(1)
                    Spacer()
                    Text(section.sectionCode)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(color.opacity(0.12))
                        .cornerRadius(6)
                }

                HStack(spacing: 12) {
                    Label(section.room, systemImage: "mappin.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Label(section.professorName, systemImage: "person.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(14)
            .background(Color(.systemBackground))
            .cornerRadius(14)
            .shadow(color: color.opacity(0.15), radius: 8, x: 0, y: 4)
        }
        .padding(.bottom, 16)
    }

    func colorFrom(_ name: String) -> Color {
        switch name {
        case "blue": return .blue
        case "orange": return .orange
        case "purple": return .purple
        case "green": return .green
        case "red": return .red
        case "teal": return .teal
        case "mint": return .mint
        default: return .blue
        }
    }
}
