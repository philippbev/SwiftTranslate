import SwiftUI

@main
struct SaarlandMassApp: App {
    @StateObject private var viewModel = SaarlandViewModel()
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .fullScreenCover(isPresented: .constant(!hasSeenOnboarding)) {
                    OnboardingView(hasSeenOnboarding: $hasSeenOnboarding)
                }
                .onAppear {
                    viewModel.requestReviewIfAppropriate()
                }
        }
    }
}
