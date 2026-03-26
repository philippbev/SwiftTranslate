import SwiftUI

@available(macOS 26.0, *)
struct HistoryView: View {
    @Environment(AppState.self) private var state
    let onSelect: (HistoryEntry) -> Void

    var body: some View {
        VStack(spacing: 0) {
            if state.history.entries.isEmpty {
                ContentUnavailableView(L("history.empty"), systemImage: "clock")
                    .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(state.history.entries) { entry in
                            HistoryRowView(entry: entry, onSelect: onSelect)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                }
            }
        }
    }
}

@available(macOS 26.0, *)
private struct HistoryRowView: View {
    let entry: HistoryEntry
    let onSelect: (HistoryEntry) -> Void
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("\(entry.from.flag) → \(entry.to.flag)")
                .font(.caption2).foregroundStyle(.secondary)
            Text(entry.source).lineLimit(1)
            Text(entry.translation).lineLimit(1).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background {
            Color.clear
                .glassEffect(isHovered ? .regular : .clear,
                             in: RoundedRectangle(cornerRadius: 8))
        }
        .contentShape(RoundedRectangle(cornerRadius: 8))
        .onHover { isHovered = $0 }
        .onTapGesture { onSelect(entry) }
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(entry.source), \(entry.from.displayName) → \(entry.to.displayName), \(entry.translation)")
        .accessibilityHint(L("a11y.history.hint"))
        .accessibilityAddTraits(.isButton)
    }
}
