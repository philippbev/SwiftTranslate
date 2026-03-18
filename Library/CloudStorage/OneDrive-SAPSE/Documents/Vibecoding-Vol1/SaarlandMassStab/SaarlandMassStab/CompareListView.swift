// In CompareListView.swift - nutze ScrollViewReader für bessere Performance
struct CompareListView: View {
    @EnvironmentObject var viewModel: SaarlandViewModel
    @State private var scrollProxy: ScrollViewReader.ScrollProxy?
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: []) {
                    // ... existing content ...
                }
                .onAppear { scrollProxy = proxy }
            }
        }
        .refreshable {
            await viewModel.loadDataAsync()
        }
    }
}
