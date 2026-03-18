// In DetailView.swift - Memory-effiziente Chart-Darstellung
struct ProportionDiagram: View {
    let ratio: Double
    let objectName: String
    let objectEmoji: String
    
    var body: some View {
        Canvas { context, size in
            // Canvas ist memory-effizienter für komplexe Zeichnungen
            drawProportions(context: context, size: size)
        }
        .drawingGroup() // GPU-Optimierung
    }
    
    private func drawProportions(context: GraphicsContext, size: CGSize) {
        // Zeichne die Proportionen direkt
    }
}
