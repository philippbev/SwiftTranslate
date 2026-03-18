import SwiftUI
import UIKit

struct KIVergleichView: View {
    @StateObject private var kiViewModel = KIVergleichViewModel()
    @FocusState private var isInputFocused: Bool

    private let loadingMessages = [
        "Das Saarland denkt nach…",
        "Geograf im Einsatz…",
        "Flächen werden verglichen…",
        "Saarbrücken wird konsultiert…",
        "KI rechnet fleißig…"
    ]
    @State private var loadingMessageIndex = 0
    @State private var loadingTimer: Timer? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Unavailability banner
                if case .unavailable(let reason) = kiViewModel.modelState {
                    unavailabilityBanner(reason: reason)
                }

                // Input card
                inputCard

                // Result / Loading / Empty state
                if kiViewModel.isLoading {
                    loadingCard
                } else if let result = kiViewModel.result {
                    resultCard(result: result)
                        .transition(.scale(scale: 0.95).combined(with: .opacity))
                        .onChange(of: kiViewModel.result) { _, new in
                            if new != nil {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            }
                        }
                } else {
                    placeholderCard
                }

                // History
                if !kiViewModel.history.isEmpty && kiViewModel.result == nil {
                    historySection
                }

                Spacer(minLength: 20)
            }
            .padding()
        }
        .navigationTitle("Freier Vergleich")
        .navigationBarTitleDisplayMode(.large)
        .background(Color(.systemGroupedBackground))
        .onTapGesture { isInputFocused = false }
    }

    // MARK: - Subviews

    private func unavailabilityBanner(reason: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(Color.saarlandBlue)
                .font(.subheadline)
            VStack(alignment: .leading, spacing: 2) {
                Text("Regelbasierter Modus aktiv")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                Text("Apple Intelligence nicht verfügbar – die App rechnet selbst. Funktioniert trotzdem!")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.saarlandBlue.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.saarlandBlue.opacity(0.2), lineWidth: 1))
    }

    private var inputCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Was soll ich vergleichen?", systemImage: "sparkles")
                .font(.headline)

            TextField("z.B. mein Fiat Panda 4x4, die Chinesische Mauer, eine Pizza…", text: $kiViewModel.inputText, axis: .vertical)
                .lineLimit(1...3)
                .focused($isInputFocused)
                .padding()
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .font(.body)
                .onChange(of: kiViewModel.inputText) { _, new in
                    if new.count > 200 {
                        kiViewModel.inputText = String(new.prefix(200))
                    }
                }

            HStack {
                Text("\(kiViewModel.inputText.count)/200")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer()
                Button {
                    isInputFocused = false
                    loadingMessageIndex = Int.random(in: 0..<loadingMessages.count)
                    startLoadingTimer()
                    Task { await kiViewModel.generateComparison() }
                } label: {
                    Label("Saarland vergleichen!", systemImage: "magnifyingglass")
                        .font(.headline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(kiViewModel.inputText.trimmingCharacters(in: .whitespaces).isEmpty
                                    ? Color.secondary : Color.saarlandBlue)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                .disabled(kiViewModel.inputText.trimmingCharacters(in: .whitespaces).isEmpty || kiViewModel.isLoading)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var loadingCard: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.4)
                .tint(Color.saarlandBlue)
            Text(loadingMessages[loadingMessageIndex % loadingMessages.count])
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .animation(.easeInOut, value: loadingMessageIndex)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onDisappear { loadingTimer?.invalidate() }
    }

    private func resultCard(result: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Gradient header
            ZStack(alignment: .bottomLeading) {
                LinearGradient(
                    colors: [Color.saarlandBlue, Color.saarlandBlueLight],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 100)

                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("KI-Vergleich", systemImage: "magnifyingglass")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                        Text("\u{201E}\(kiViewModel.inputText.trimmingCharacters(in: .whitespaces).prefix(40))\(kiViewModel.inputText.count > 40 ? "..." : "")\u{201C}")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }
                    Spacer()
                    Text("🗺️")
                        .font(.system(size: 44))
                }
                .padding()
            }

            // Result text
            VStack(alignment: .leading, spacing: 16) {
                Text(result)
                    .font(.body)
                    .lineSpacing(5)
                    .padding(.top, 4)

                Divider()

                HStack(spacing: 12) {
                    // Nochmal button
                    Button {
                        startLoadingTimer()
                        Task { await kiViewModel.generateComparison() }
                    } label: {
                        Label("Nochmal", systemImage: "arrow.clockwise")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.saarlandBlue.opacity(0.1))
                            .foregroundStyle(Color.saarlandBlue)
                            .clipShape(Capsule())
                    }

                    // Share button — rendert eine schöne Karte als Bild
                    if let image = renderShareImage(input: kiViewModel.inputText, result: result) {
                        ShareLink(item: Image(uiImage: image),
                                  preview: SharePreview("\u{201E}\(kiViewModel.inputText)\u{201C} vs. Saarland",
                                                        image: Image(uiImage: image))) {
                            Label("Teilen", systemImage: "square.and.arrow.up")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color(.tertiarySystemGroupedBackground))
                                .foregroundStyle(.primary)
                                .clipShape(Capsule())
                        }
                    }

                    Spacer()

                    // New comparison button
                    Button {
                        withAnimation { kiViewModel.reset() }
                        isInputFocused = true
                    } label: {
                        Image(systemName: "plus.circle")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
    }

    private var placeholderCard: some View {
        VStack(spacing: 16) {
            Text("🗺️")
                .font(.system(size: 56))
            Text("Gib irgendetwas ein –\ndas Saarland vergleicht es.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            VStack(alignment: .leading, spacing: 8) {
                Text("Beispiele:")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.tertiary)
                ForEach(["mein Fiat Panda 4x4", "die Chinesische Mauer", "eine Pizzaschachtel", "alle Haare auf meinem Kopf", "der Vatikan"], id: \.self) { example in
                    Button {
                        kiViewModel.inputText = example
                        isInputFocused = false
                    } label: {
                        Text("→ \(example)")
                            .font(.caption)
                            .foregroundStyle(Color.saarlandBlue)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.tertiarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - History

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Letzte Vergleiche", systemImage: "clock")
                    .font(.headline)
                Spacer()
                Button("Alle löschen") {
                    withAnimation { kiViewModel.history.removeAll() }
                    UserDefaults.standard.removeObject(forKey: "ki_history_v1")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            ForEach(kiViewModel.history) { entry in
                Button {
                    withAnimation {
                        kiViewModel.restoreFromHistory(entry)
                        isInputFocused = false
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundStyle(Color.saarlandBlue.opacity(0.7))
                            .font(.caption)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.input)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            Text(entry.result)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(10)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Helpers

    private func startLoadingTimer() {
        loadingTimer?.invalidate()
        loadingTimer = Timer.scheduledTimer(withTimeInterval: 1.8, repeats: true) { _ in
            Task { @MainActor in
                loadingMessageIndex = (loadingMessageIndex + 1) % loadingMessages.count
            }
        }
    }
}

#Preview {
    NavigationStack {
        KIVergleichView()
    }
}
