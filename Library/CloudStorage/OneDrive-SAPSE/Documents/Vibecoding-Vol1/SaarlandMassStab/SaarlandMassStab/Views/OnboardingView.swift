import SwiftUI

struct OnboardingView: View {
    @Binding var hasSeenOnboarding: Bool
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            emoji: "🌍",
            title: "Willkommen beim Saarland-Rechner",
            text: "Das Saarland hat 2.569 km² – und das ist DIE Maßeinheit für alles. Größer als ein Schuhkarton, kleiner als Bayern. Perfekt."
        ),
        OnboardingPage(
            emoji: "⚖️",
            title: "Alles in Saarland",
            text: "Fläche, Gewicht, Zeit, Geld – wir rechnen alles in Saarland um. Weil warum nicht?"
        ),
        OnboardingPage(
            emoji: "🧠",
            title: "Lerne, vergleiche, teile",
            text: "Löse Quizfragen, entdecke Zufallsfakten und teile dein Wissen. Haupsach gudd gess."
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(pages.indices, id: \.self) { index in
                    pageView(pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            bottomBar
                .padding(.bottom, 40)
                .padding(.horizontal, 24)
        }
        .background(Color(.systemGroupedBackground))
    }

    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 24) {
            Spacer()
            Text(page.emoji)
                .font(.system(size: 80))
            Text(page.title)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Text(page.text)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
            Spacer()
        }
    }

    private var bottomBar: some View {
        HStack {
            if currentPage < pages.count - 1 {
                Button("Überspringen") {
                    hasSeenOnboarding = true
                }
                .foregroundStyle(.secondary)
                Spacer()
                Button(action: { withAnimation { currentPage += 1 } }) {
                    HStack {
                        Text("Weiter")
                        Image(systemName: "chevron.right")
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.saarlandBlue)
                }
            } else {
                Spacer()
                Button(action: { hasSeenOnboarding = true }) {
                    Text("Los geht's!")
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.saarlandBlue)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                Spacer()
            }
        }
    }
}

private struct OnboardingPage {
    let emoji: String
    let title: String
    let text: String
}

#Preview {
    OnboardingView(hasSeenOnboarding: .constant(false))
}
