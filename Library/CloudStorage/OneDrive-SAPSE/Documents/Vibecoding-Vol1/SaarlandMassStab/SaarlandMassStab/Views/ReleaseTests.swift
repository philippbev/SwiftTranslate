import Testing
@testable import SaarlandMassApp

@Suite("Release Readiness Tests")
struct ReleaseTests {
    
    @Test("App lädt Daten erfolgreich")
    func dataLoading() async throws {
        let viewModel = SaarlandViewModel()
        await viewModel.loadDataAsync()
        
        #expect(viewModel.objects.count > 0, "Objekte müssen geladen werden")
        #expect(viewModel.randomObject != nil, "Zufälliges Objekt muss gesetzt sein")
    }
    
    @Test("Alle Kategorien verfügbar")
    func categoriesComplete() {
        #expect(Kategorie.allCases.count == 7, "Alle 7 Kategorien müssen verfügbar sein")
        
        for kategorie in Kategorie.allCases {
            #expect(!kategorie.emoji.isEmpty, "Kategorie \(kategorie) braucht Emoji")
            #expect(!kategorie.rawValue.isEmpty, "Kategorie braucht Namen")
        }
    }
    
    @Test("Share Image Rendering funktioniert")
    func shareImageRendering() async {
        let image = await renderShareImage(
            input: "Test Object", 
            result: "Das Saarland ist 2× größer als Test Object."
        )
        
        #expect(image != nil, "Share Image muss gerendert werden können")
    }
    
    @Test("Performance: Data Loading unter 2 Sekunden")
    func performanceTest() async throws {
        let startTime = Date()
        let viewModel = SaarlandViewModel()
        await viewModel.loadDataAsync()
        let duration = Date().timeIntervalSince(startTime)
        
        #expect(duration < 2.0, "Loading sollte unter 2 Sekunden dauern, war \(duration)s")
    }
}
