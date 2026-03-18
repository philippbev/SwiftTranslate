// In SaarlandViewModel.swift
func loadDataAsync() async {
    await Task.detached {
        guard let url = Bundle.main.url(forResource: "vergleichsobjekte", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([ComparisonObject].self, from: data)
        else {
            await MainActor.run { self.objects = [] }
            return
        }
        
        await MainActor.run {
            self.objects = decoded
            self.randomObject = decoded.randomElement()
        }
    }.value
}
