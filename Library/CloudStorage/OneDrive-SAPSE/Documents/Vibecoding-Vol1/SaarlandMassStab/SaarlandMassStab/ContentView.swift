import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: SaarlandViewModel

    var body: some View {
        TabView {
            NavigationStack {
                CompareListView()
            }
            .tabItem {
                Label("Vergleiche", systemImage: "list.bullet.rectangle")
            }

            NavigationStack {
                RandomFactView()
            }
            .tabItem {
                Label("Zufallsfakt", systemImage: "star")
            }

            NavigationStack {
                QuizView()
            }
            .tabItem {
                Label("Quiz", systemImage: "questionmark.circle")
            }
        }
        .tint(.saarlandBlue)
    }
}

#Preview {
    ContentView()
        .environmentObject(SaarlandViewModel())
}
