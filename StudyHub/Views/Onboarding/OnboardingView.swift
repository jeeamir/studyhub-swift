import SwiftUI

struct OnboardingView: View {
    @Binding var needsOnboarding: Bool
    @AppStorage("dark_mode") var darkMode = false

    @State private var currentStep = 0
    @State private var selectedMajor = ""
    @State private var selectedYear = 1
    @State private var isLoading = false

    var university: String {
        UserDefaults.standard.string(forKey: "detected_university") ?? ""
    }

    let majors = [
        "Computer Science", "Data Science", "Digital Engineering",
        "Business Analytics", "Finance", "Marketing",
        "Accounting", "Law", "Economics", "Management",
        "Information Systems", "Cybersecurity", "Mathematics"
    ]

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress bar — 2 шага
                HStack(spacing: 6) {
                    ForEach(0..<2) { i in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(i <= currentStep ? Color.appAccent : Color.appBorder)
                            .frame(height: 4)
                            .animation(.spring(response: 0.4), value: currentStep)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .padding(.bottom, 32)

                if !university.isEmpty {
                    HStack(spacing: 10) {
                        Image(systemName: "building.columns.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.appAccent)
                        Text(university)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.appAccent)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.appAccent.opacity(0.08))
                    .cornerRadius(20)
                    .padding(.bottom, 24)
                }
                

                if currentStep == 0 { majorStep }
                else { yearStep }

                Spacer()

                VStack(spacing: 12) {
                    Button(action: nextStep) {
                        HStack(spacing: 8) {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text(currentStep == 1 ? "Get Started 🚀" : "Continue")
                                    .font(.system(size: 16, weight: .semibold))
                                if currentStep == 0 {
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(canProceed ? Color.appAccent : Color.appTertiary)
                        .cornerRadius(14)
                    }
                    .disabled(!canProceed || isLoading)

                    Text("Step \(currentStep + 1) of 2")
                        .font(.system(size: 12))
                        .foregroundColor(.appTertiary)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(darkMode ? .dark : .light)
    }

    // MARK: - Major Step

    private var majorStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Your Major 📚")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.appPrimary)
                Text("What are you studying?")
                    .font(.system(size: 15))
                    .foregroundColor(.appSecondary)
            }
            .padding(.horizontal, 24)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 8) {
                    ForEach(majors, id: \.self) { major in
                        Button(action: { selectedMajor = major }) {
                            HStack {
                                Text(major)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.appPrimary)
                                Spacer()
                                if selectedMajor == major {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.appAccent)
                                }
                            }
                            .padding(14)
                            .background(Color.appSurface)
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(
                                        selectedMajor == major ? Color.appAccent : Color.appBorder,
                                        lineWidth: selectedMajor == major ? 1.5 : 1
                                    )
                            )
                        }
                        .padding(.horizontal, 24)
                    }
                }
                .padding(.bottom, 16)
            }
        }
    }

    // MARK: - Year Step

    private var yearStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Your Year 📅")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.appPrimary)
                Text("Which year are you in?")
                    .font(.system(size: 15))
                    .foregroundColor(.appSecondary)
            }
            .padding(.horizontal, 24)

            VStack(spacing: 8) {
                ForEach(1...4, id: \.self) { year in
                    Button(action: { selectedYear = year }) {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(selectedYear == year
                                          ? Color.appAccent.opacity(0.12)
                                          : Color.appSurface2)
                                    .frame(width: 40, height: 40)
                                Text("\(year)")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(selectedYear == year ? .appAccent : .appSecondary)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Year \(year)")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.appPrimary)
                                Text(yearSubtitle(year))
                                    .font(.system(size: 13))
                                    .foregroundColor(.appSecondary)
                            }
                            Spacer()
                            if selectedYear == year {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.appAccent)
                            }
                        }
                        .padding(14)
                        .background(Color.appSurface)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(
                                    selectedYear == year ? Color.appAccent : Color.appBorder,
                                    lineWidth: selectedYear == year ? 1.5 : 1
                                )
                        )
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
    }

    // MARK: - Logic

    private var canProceed: Bool {
        currentStep == 0 ? !selectedMajor.isEmpty : true
    }

    private func nextStep() {
        if currentStep < 1 {
            withAnimation(.spring(response: 0.4)) { currentStep += 1 }
        } else {
            saveAndFinish()
        }
    }

    private func saveAndFinish() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            SupabaseService.shared.updateProfile(
                major: self.selectedMajor,
                year: self.selectedYear,
                university: self.university
            ) { _ in
                DispatchQueue.main.async {
                    self.isLoading = false
                    UserDefaults.standard.set(false, forKey: "needs_onboarding")
                    self.needsOnboarding = false
                }
            }
        }
    }

    private func yearSubtitle(_ year: Int) -> String {
        switch year {
        case 1: return "Freshman — just getting started"
        case 2: return "Sophomore — finding your path"
        case 3: return "Junior — deep in the work"
        case 4: return "Senior — almost there!"
        default: return ""
        }
    }
}
