import SwiftUI

@available(macOS 15.0, *)
struct HistoryView: View {
    @Environment(AppState.self) private var state
    let onSelect: (HistoryEntry) -> Void

    var body: some View {
        VStack(spacing: 0) {
            if state.history.entries.isEmpty {
                ContentUnavailableView(L("history.empty"), systemImage: "clock")
                    .frame(maxHeight: .infinity)
            } else {
                List(state.history.entries) { entry in
                    VStack(alignment: .leading, spacing: 3) {
                        Text("\(entry.from.flag) → \(entry.to.flag)")
                            .font(.caption2).foregroundStyle(.secondary)
                        Text(entry.source).lineLimit(1)
                        Text(entry.translation).lineLimit(1).foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { onSelect(entry) }
                }
                .listStyle(.plain)
            }
        }
    }
}
