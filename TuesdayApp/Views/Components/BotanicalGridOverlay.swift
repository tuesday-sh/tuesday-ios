import SwiftUI

/// Subtle botanical pixel-art backdrop rendered inside the 16×8 inventory LED matrix
/// matching Android's `BotanicalGridOverlay` scale progression (`Day-0 -> Pea -> Garden -> Forest`).
public struct BotanicalGridOverlay: View {
    public let scaleTier: InventoryScaleTier
    public let deviceCount: Int
    public let palette: BrandPalette

    public init(scaleTier: InventoryScaleTier, deviceCount: Int, palette: BrandPalette) {
        self.scaleTier = scaleTier
        self.deviceCount = deviceCount
        self.palette = palette
    }

    public var body: some View {
        ZStack {
            Canvas { context, size in
                let cols = 16
                let rows = 8
                let cellW = size.width / CGFloat(cols)
                let cellH = size.height / CGFloat(rows)
                let green = TuesdayTheme.ledColor(for: .ok, isStn: palette.isStn)

                let coords: [(Int, Int)] = {
                    switch scaleTier {
                    case .DAY_ZERO:
                        return [(7, 5), (8, 5), (7, 6), (8, 6)]
                    case .PEA:
                        return [(7, 3), (8, 3), (6, 4), (9, 4), (7, 4), (8, 5), (7, 6), (8, 6)]
                    case .GARDEN:
                        return [
                            (7, 2), (8, 2), (6, 3), (9, 3), (7, 4), (8, 4),
                            (6, 5), (9, 5), (7, 6), (8, 6), (6, 6), (9, 6)
                        ]
                    case .FOREST:
                        return [
                            (3, 2), (3, 3), (2, 4), (3, 4), (4, 4), (3, 5), (3, 6),
                            (8, 1), (7, 2), (8, 2), (9, 2), (6, 3), (8, 3), (10, 3),
                            (8, 4), (8, 5), (8, 6),
                            (13, 2), (12, 3), (13, 3), (14, 3), (13, 4), (13, 5), (13, 6)
                        ]
                    }
                }()

                for (cx, cy) in coords {
                    let rect = CGRect(
                        x: CGFloat(cx) * cellW + 2,
                        y: CGFloat(cy) * cellH + 2,
                        width: max(3, cellW - 4),
                        height: max(3, cellH - 4)
                    )
                    context.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(green.opacity(deviceCount == 0 ? 0.16 : 0.11)))
                }
            }

            if deviceCount == 0 {
                Text("0/128 Slots Populated")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(palette.textMuted)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(palette.elevated.opacity(0.92))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(palette.border, lineWidth: 1))
                    .uiSlot("inventory-empty-pill")
            }
        }
        .uiComponent("BotanicalGridOverlay")
    }
}
