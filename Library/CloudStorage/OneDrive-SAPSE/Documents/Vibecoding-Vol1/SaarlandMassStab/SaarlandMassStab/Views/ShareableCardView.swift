import SwiftUI

/// Eine hübsche Karte die als Bild gerendert und geteilt werden kann
struct ShareableCardView: View {
    let input: String
    let result: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header mit bestehenden Farben
            ZStack(alignment: .bottomLeading) {
                LinearGradient(
                    colors: [Color.saarlandBlue, Color.saarlandBlueLight],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 120)

                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("SAARLAND RECHNER")
                            .font(.system(size: 10, weight: .semibold))
                            .tracking(2)
                            .foregroundStyle(.white.opacity(0.7))
                        Text("KI-Vergleich")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    Text("🗺️")
                        .font(.system(size: 52))
                }
                .padding(16)
            }

            // Body
            VStack(alignment: .leading, spacing: 12) {
                Text("\u{201E}\(input.prefix(80))\(input.count > 80 ? "..." : "")\u{201C}")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.saarlandBlue)
                    .padding(.top, 4)

                Text(result)
                    .font(.body)
                    .lineSpacing(4)
                    .foregroundStyle(.primary)
                    .lineLimit(3)

                Divider()

                HStack {
                    Image(systemName: "map.fill")
                        .foregroundStyle(Color.saarlandBlue)
                        .font(.caption)
                    Text("Das Saarland: 2.569,69 km²")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(ReleaseConfig.shareHashtag)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .fontWeight(.semibold)
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.15), radius: 16, x: 0, y: 6)
        .frame(width: 380, height: 280)
    }
}

@MainActor
func renderShareImage(input: String, result: String) -> UIImage? {
    let card = ShareableCardView(input: input, result: result)
        .padding(20)
        .background(Color(.systemGroupedBackground))
    
    let renderer = ImageRenderer(content: card)
    renderer.scale = UIScreen.main.scale
    renderer.isOpaque = false
    
    return renderer.uiImage?.optimizedForSharing()
}
// Performance-Optimierung für Bilder
extension UIImage {
    func optimizedForSharing() -> UIImage? {
        let maxDimension: CGFloat = 1200
        let scale = min(maxDimension/size.width, maxDimension/size.height, 1.0)
        
        if scale < 1.0 {
            let newSize = CGSize(width: size.width * scale, height: size.height * scale)
            
            UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
            defer { UIGraphicsEndImageContext() }
            
            draw(in: CGRect(origin: .zero, size: newSize))
            return UIGraphicsGetImageFromCurrentImageContext()
        }
        
        return self
    }
}

