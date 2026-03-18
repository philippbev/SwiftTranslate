import SwiftUI
import UIKit

struct CompareListView: View {
    @EnvironmentObject var viewModel: SaarlandViewModel
    @StateObject private var kiViewModel = KIVergleichViewModel()
    @FocusState private var isKIFocused: Bool

    private let loadingMessages = [
        "Das Saarland denkt nach…",
        "Geograf im Einsatz…",
        "Flächen werden verglichen…",
        "Saarbrücken wird konsultiert…",
        "Rechnet fleißig…"
    ]
    @State private var loadingMessageIndex = 0
    @State private var loadingTimer: Timer? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // ── Hero: Saarland-Rechner ──────────────────────────
                saarlandRechnerHero
                    .padding(.horizontal)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                // ── Vergleichsliste ─────────────────────────────────
                vergleichsListeSection
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Saarland Rechner")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $viewModel.searchText, prompt: "Vergleichsobjekt suchen…")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    ForEach(SortOrder.allCases, id: \.self) { order in
                        Button {
                            viewModel.sortOrder = order
                        } label: {
                            if viewModel.sortOrder == order {
                                Label(order.rawValue, systemImage: "checkmark")
                            } else {
                                Text(order.rawValue)
                            }
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                }
            }
        }
    }

    // MARK: - Hero Section

    private var saarlandRechnerHero: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Title row
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.saarlandBlue)
                        .frame(width: 40, height: 40)
                    Image(systemName: "sparkles")
                        .foregroundStyle(.white)
                        .font(.system(size: 18, weight: .semibold))
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("Saarland-Rechner")
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("Vergleiche alles mit dem Saarland")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            // Input field
            HStack(spacing: 10) {
                TextField("z.B. Fiat Panda, Chinesische Mauer, Vatikan…", text: $kiViewModel.inputText, axis: .vertical)
                    .lineLimit(1...3)
                    .focused($isKIFocused)
                    .font(.body)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .onChange(of: kiViewModel.inputText) { _, new in
                        if new.count > 200 { kiViewModel.inputText = String(new.prefix(200)) }
                    }

                if !kiViewModel.inputText.isEmpty {
                    Button {
                        kiViewModel.inputText = ""
                        isKIFocused = true
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Color(.tertiaryLabel))
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    isKIFocused = false
                    loadingMessageIndex = Int.random(in: 0..<loadingMessages.count)
                    startLoadingTimer()
                    Task { await kiViewModel.generateComparison() }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(kiViewModel.inputText.trimmingCharacters(in: .whitespaces).isEmpty
                                  ? Color(.tertiarySystemGroupedBackground)
                                  : Color.saarlandBlue)
                            .frame(width: 48, height: 48)
                        Image(systemName: "arrow.up")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(kiViewModel.inputText.trimmingCharacters(in: .whitespaces).isEmpty
                                             ? Color(.tertiaryLabel) : .white)
                    }
                }
                .disabled(kiViewModel.inputText.trimmingCharacters(in: .whitespaces).isEmpty || kiViewModel.isLoading)
                .animation(.easeInOut(duration: 0.15), value: kiViewModel.inputText.isEmpty)
            }

            // Example chips (shown when no input and no result)
            if kiViewModel.inputText.isEmpty && kiViewModel.result == nil && !kiViewModel.isLoading {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(["🚗 Fiat Panda", "🏯 Chinesische Mauer", "🍕 Pizzaschachtel", "🇻🇦 Vatikan", "🏝️ Mallorca"], id: \.self) { example in
                            Button {
                                let clean = example.components(separatedBy: " ").dropFirst().joined(separator: " ")
                                kiViewModel.inputText = clean
                            } label: {
                                Text(example)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color(.tertiarySystemGroupedBackground))
                                    .foregroundStyle(.primary)
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(Color(.separator), lineWidth: 0.5))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            // Loading state
            if kiViewModel.isLoading {
                HStack(spacing: 10) {
                    ProgressView().tint(Color.saarlandBlue)
                    Text(loadingMessages[loadingMessageIndex % loadingMessages.count])
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.vertical, 4)
                .onDisappear { loadingTimer?.invalidate() }
            }

            // Result
            if let result = kiViewModel.result {
                Divider()

                VStack(alignment: .leading, spacing: 10) {
                    // Input label
                    HStack(spacing: 6) {
                        Text("\u{201E}\(kiViewModel.inputText.trimmingCharacters(in: .whitespaces))\u{201C}")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.saarlandBlue)
                            .lineLimit(1)
                        Spacer()
                    }

                    Text(result)
                        .font(.body)
                        .lineSpacing(4)
                        .onChange(of: kiViewModel.result) { _, new in
                            if new != nil {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            }
                        }

                    HStack(spacing: 8) {
                        Button {
                            startLoadingTimer()
                            Task { await kiViewModel.generateComparison() }
                        } label: {
                            Label("Nochmal", systemImage: "arrow.clockwise")
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.saarlandBlue.opacity(0.1))
                                .foregroundStyle(Color.saarlandBlue)
                                .clipShape(Capsule())
                        }

                        if let image = renderShareImage(input: kiViewModel.inputText, result: result) {
                            ShareLink(
                                item: Image(uiImage: image),
                                preview: SharePreview("\u{201E}\(kiViewModel.inputText)\u{201C} vs. Saarland",
                                                      image: Image(uiImage: image))
                            ) {
                                Label("Teilen", systemImage: "square.and.arrow.up")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color(.tertiarySystemGroupedBackground))
                                    .foregroundStyle(.primary)
                                    .clipShape(Capsule())
                            }
                        }

                        Spacer()

                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) { kiViewModel.reset() }
                            isKIFocused = true
                        } label: {
                            Label("Neu", systemImage: "plus.circle")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Unavailability note (subtle)
            if case .unavailable(let reason) = kiViewModel.modelState {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.caption2)
                    Text("Regelbasiert · \(reason)")
                        .font(.caption2)
                        .lineLimit(1)
                }
                .foregroundStyle(Color(.tertiaryLabel))
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.caption2)
                    Text("Apple Intelligence aktiv")
                        .font(.caption2)
                }
                .foregroundStyle(Color.saarlandBlue.opacity(0.6))
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: kiViewModel.result)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: kiViewModel.isLoading)
    }

    // MARK: - Vergleichsliste Section

    private var vergleichsListeSection: some View {
        VStack(spacing: 0) {
            // Section header
            HStack {
                Text("Vergleichsobjekte")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                Text("\(viewModel.filteredObjects.count) Objekte")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.top, 20)
            .padding(.bottom, 10)

            // Category filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(title: "Alle", emoji: "🗺️", isSelected: viewModel.selectedKategorie == nil && !viewModel.showFavoritesOnly) {
                        viewModel.selectedKategorie = nil
                        viewModel.showFavoritesOnly = false
                    }
                    FilterChip(title: "Favoriten", emoji: "❤️", isSelected: viewModel.showFavoritesOnly) {
                        viewModel.showFavoritesOnly.toggle()
                    }
                    ForEach(Kategorie.allCases, id: \.self) { kat in
                        FilterChip(
                            title: kat.rawValue,
                            emoji: kat.emoji,
                            isSelected: viewModel.selectedKategorie == kat
                        ) {
                            viewModel.selectedKategorie = (viewModel.selectedKategorie == kat) ? nil : kat
                            viewModel.showFavoritesOnly = false
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 10)
            }

            // List content
            if viewModel.filteredObjects.isEmpty {
                ContentUnavailableView(
                    "Keine Ergebnisse",
                    systemImage: "magnifyingglass",
                    description: Text("Versuche einen anderen Suchbegriff oder Filter.")
                )
                .padding(.top, 40)
            } else {
                LazyVStack(spacing: 0, pinnedViews: []) {
                    let groups: [(Kategorie, [ComparisonObject])] = viewModel.selectedKategorie != nil || viewModel.showFavoritesOnly || !viewModel.searchText.isEmpty
                        ? [(Kategorie.flaeche, viewModel.filteredObjects)]  // flat list
                        : viewModel.groupedObjects

                    let isFlat = viewModel.selectedKategorie != nil || viewModel.showFavoritesOnly || !viewModel.searchText.isEmpty

                    ForEach(groups, id: \.0) { kat, items in
                        VStack(spacing: 0) {
                            if !isFlat {
                                HStack(spacing: 6) {
                                    Image(systemName: sectionIcon(kat))
                                        .font(.caption)
                                        .foregroundStyle(Color.saarlandBlue)
                                    Text(kat.rawValue)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(Color.saarlandBlue)
                                    Spacer()
                                }
                                .padding(.horizontal)
                                .padding(.top, 8)
                                .padding(.bottom, 4)
                            }

                            VStack(spacing: 0) {
                                ForEach(items) { obj in
                                    NavigationLink(destination: DetailView(object: obj)) {
                                        CompareRowView(object: obj)
                                            .padding(.horizontal)
                                    }
                                    .buttonStyle(.plain)
                                    if obj.id != items.last?.id {
                                        Divider().padding(.leading, 68)
                                    }
                                }
                            }
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .padding(.horizontal)
                            .padding(.bottom, 4)
                        }
                    }
                }
                .padding(.bottom, 20)
            }
        }
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

    private func sectionIcon(_ kat: Kategorie) -> String {
        switch kat {
        case .flaeche: return "map"
        case .gewicht: return "scalemass.fill"
        case .zeit: return "clock"
        case .geld: return "eurosign.circle"
        case .laenge: return "ruler"
        case .anzahl: return "number.circle"
        case .volumen: return "drop"
        }
    }
}

// MARK: - Supporting Views

struct FilterChip: View {
    let title: String
    let emoji: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(emoji).font(.caption)
                Text(title)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? Color.saarlandBlue : Color(.tertiarySystemBackground))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(isSelected ? Color.clear : Color(.separator), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

struct CompareRowView: View {
    @EnvironmentObject var viewModel: SaarlandViewModel
    let object: ComparisonObject

    var body: some View {
        HStack(spacing: 12) {
            Text(object.emoji)
                .font(.title2)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(object.name)
                    .font(.body)
                    .fontWeight(.medium)
                HStack(spacing: 4) {
                    Text(object.kategorieEnum.emoji)
                        .font(.caption2)
                    Text(object.kategorie)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            RatioBadge(ratio: viewModel.ratio(for: object), viewModel: viewModel)

            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    viewModel.toggleFavorite(object)
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            } label: {
                Image(systemName: viewModel.isFavorite(object) ? "heart.fill" : "heart")
                    .foregroundStyle(viewModel.isFavorite(object) ? .red : Color(.tertiaryLabel))
                    .font(.body)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 10)
    }
}

struct RatioBadge: View {
    let ratio: Double
    let viewModel: SaarlandViewModel

    var body: some View {
        let text = ratio < 1
            ? "÷\(viewModel.formatRatio(1.0/ratio))"
            : "×\(viewModel.formatRatio(ratio))"

        Text(text)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(ratio < 1 ? Color.orange.opacity(0.15) : Color.saarlandBlue.opacity(0.15))
            .foregroundStyle(ratio < 1 ? .orange : Color.saarlandBlue)
            .clipShape(Capsule())
    }
}

#Preview {
    NavigationStack {
        CompareListView()
    }
    .environmentObject(SaarlandViewModel())
}
