import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Home", systemImage: "house.fill") }

            SubjectsView()
                .tabItem { Label("Subjects", systemImage: "book.fill") }

            AssignmentsView()
                .tabItem { Label("Tasks", systemImage: "checklist") }

            GradesView()
                .tabItem { Label("Grades", systemImage: "chart.bar.fill") }

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.fill") }
            
            
        }
    }
}
