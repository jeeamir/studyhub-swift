import SwiftUI
import PhotosUI

struct ProfileView: View {
    @AppStorage("dark_mode") var darkMode = false
    @State private var profile: SupabaseProfile? = nil
    @State private var isLoading = true
    @State private var enrolledCount = 0
    @ObservedObject private var session = UserSession.shared
    @State private var showImagePicker = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                if isLoading {
                    ProgressView().tint(.appAccent)
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            profileHeader
                            statsRow
                            Spacer().frame(height: 24)
                            infoSections
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear { loadAll() }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $session.avatarImage)
            }
        }
        .preferredColorScheme(darkMode ? .dark : .light)
    }

    // MARK: - Header

    private var profileHeader: some View {
        VStack(spacing: 14) {
            // Avatar with edit button
            ZStack(alignment: .bottomTrailing) {
                Button(action: { showImagePicker = true }) {
                    Group {
                        if let img = session.avatarImage {
                            Image(uiImage: img)
                                .resizable().scaledToFill()
                        } else {
                            ZStack {
                                Circle().fill(Color.appAccent.opacity(0.12))
                                Text(String((profile?.fullName ?? "S").prefix(1)))
                                    .font(.system(size: 30, weight: .semibold))
                                    .foregroundColor(.appAccent)
                            }
                        }
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.appBorder, lineWidth: 2))
                }

                // Edit badge
                ZStack {
                    Circle().fill(Color.appAccent).frame(width: 26, height: 26)
                    Image(systemName: "camera.fill")
                        .font(.system(size: 11)).foregroundColor(.white)
                }
                .offset(x: 2, y: 2)
            }

            VStack(spacing: 5) {
                Text(profile?.fullName ?? "Student")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.appPrimary)
                Text(profile?.major ?? "Digital Engineering")
                    .font(.system(size: 14))
                    .foregroundColor(.appSecondary)
                HStack(spacing: 6) {
                    Text("Year \(profile?.year ?? 1)")
                    Text("·")
                    Text(profile?.university ?? "University")
                }
                .font(.system(size: 12))
                .foregroundColor(.appTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
        .padding(.bottom, 24)
    }

    // MARK: - Stats

    private var statsRow: some View {
        HStack(spacing: 10) {
            ProfileStatPill(value: String(format: "%.2f", profile?.gpa ?? 0), label: "GPA", color: .appAccent)
            ProfileStatPill(value: "Year \(profile?.year ?? 1)", label: "Level", color: .purple)
            ProfileStatPill(value: "\(enrolledCount)", label: "Courses", color: .blue)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Sections

    private var infoSections: some View {
        VStack(spacing: 8) {
            ProfileSection(title: "Academic") {
                ProfileRow(icon: "graduationcap", label: "Major", value: profile?.major ?? "—")
                ProfileRowDivider()
                ProfileRow(icon: "star", label: "GPA", value: String(format: "%.2f / 4.0", profile?.gpa ?? 0))
                ProfileRowDivider()
                ProfileRow(icon: "calendar", label: "Year", value: "Year \(profile?.year ?? 1)")
            }

            ProfileSection(title: "Contact") {
                ProfileRow(icon: "envelope", label: "Email", value: profile?.email ?? "—")
                ProfileRowDivider()
                ProfileRow(icon: "phone", label: "Phone", value: profile?.phone ?? "—")
            }

            ProfileSection(title: "Preferences") {
                HStack(spacing: 14) {
                    Image(systemName: "moon")
                        .font(.system(size: 15)).foregroundColor(.appSecondary).frame(width: 20)
                    Text("Dark Mode")
                        .font(.system(size: 15)).foregroundColor(.appPrimary)
                    Spacer()
                    Toggle("", isOn: $darkMode).labelsHidden().tint(.appAccent)
                }
                .padding(.horizontal, 16).padding(.vertical, 14)
            }

            Button(action: { AuthService.shared.signOut() }) {
                Text("Sign Out")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.appSurface)
                    .cornerRadius(14)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.red.opacity(0.2), lineWidth: 1))
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .padding(.horizontal, 20)
    }

    func loadAll() {
        isLoading = true; var count = 0
        SupabaseService.shared.getProfile { result in
            if case .success(let p) = result { profile = p }
            count += 1; if count >= 2 { isLoading = false }
        }
        SupabaseService.shared.getEnrolledSections(semester: "Spring 2026") { result in
            if case .success(let d) = result { enrolledCount = d.count }
            count += 1; if count >= 2 { isLoading = false }
        }
    }
}

// MARK: - Profile Components

struct ProfileStatPill: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.system(size: 16, weight: .bold)).foregroundColor(color)
            Text(label).font(.system(size: 11)).foregroundColor(.appSecondary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 14)
        .background(Color.appSurface).cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appBorder, lineWidth: 1))
    }
}

struct ProfileSection<Content: View>: View {
    let title: String
    let content: Content
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title; self.content = content()
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold)).foregroundColor(.appTertiary)
                .kerning(0.8).padding(.bottom, 8).padding(.leading, 4)
            VStack(spacing: 0) { content }
                .background(Color.appSurface).cornerRadius(14)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.appBorder, lineWidth: 1))
        }
        .padding(.bottom, 8)
    }
}

struct ProfileRow: View {
    let icon: String; let label: String; let value: String
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.system(size: 14)).foregroundColor(.appSecondary).frame(width: 20)
            Text(label).font(.system(size: 15)).foregroundColor(.appSecondary)
            Spacer()
            Text(value).font(.system(size: 14, weight: .medium)).foregroundColor(.appPrimary).lineLimit(1)
        }
        .padding(.horizontal, 16).padding(.vertical, 13)
    }
}

struct ProfileRowDivider: View {
    var body: some View {
        Rectangle().fill(Color.appBorder).frame(height: 1).padding(.leading, 50)
    }
}

// MARK: - Image Picker (UIKit bridge for multimedia requirement)

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                UserSession.shared.saveAvatar(image)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
