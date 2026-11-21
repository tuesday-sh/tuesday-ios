import SwiftUI

/// Monochrome PNW botanical pixel-art backdrop rendered inside the 16×8 inventory LED matrix,
/// matching Android's `BotanicalGridOverlay` progression (`Day 0 -> Pea -> Garden -> Forest`).
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
        let fgColor = palette.textMuted

        return ZStack {
            Group {
                switch scaleTier {
                case .DAY_ZERO:
                    ZStack {
                        VStack(spacing: 0) {
                            Spacer(minLength: 0)
                            PixelArtMountainHorizon(
                                color: fgColor.opacity(palette.isStn ? 0.35 : 0.38)
                            )
                            .frame(height: 48)
                        }

                        Text("Inventory Empty")
                            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                            .foregroundColor(palette.textMuted)
                            .lineLimit(1)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(palette.elevated)
                            .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusBadge))
                            .overlay(
                                RoundedRectangle(cornerRadius: TuesdayDimens.radiusBadge)
                                    .stroke(palette.border, lineWidth: 1)
                            )
                            .uiSlot("inventory-empty-pill")
                    }

                case .PEA:
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                        PixelArtSprout(color: fgColor.opacity(0.85), size: 32)
                            .padding(.bottom, 4)
                    }
                    .frame(maxWidth: .infinity)

                case .GARDEN:
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                        HStack(alignment: .bottom, spacing: 16) {
                            PixelArtPineTree(color: fgColor.opacity(0.75), width: 24, height: 34)
                            PixelArtPineTree(color: fgColor.opacity(0.75), width: 30, height: 42)
                            PixelArtPineTree(color: fgColor.opacity(0.75), width: 20, height: 28)
                        }
                        .padding(.bottom, 2)
                    }
                    .frame(maxWidth: .infinity)

                case .FOREST:
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                        HStack(alignment: .bottom, spacing: 0) {
                            ForEach(0..<9, id: \.self) { idx in
                                let isTall = (idx % 2 == 0)
                                Spacer(minLength: 0)
                                PixelArtPineTree(
                                    color: fgColor.opacity(0.45),
                                    width: isTall ? 22 : 18,
                                    height: isTall ? 32 : 26
                                )
                                Spacer(minLength: 0)
                            }
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .allowsHitTesting(false)
            .uiSlot("botanical-overlay")
        }
        .uiComponent("BotanicalGridOverlay")
    }
}

/// 16x16 pixel-art sprout silhouette for the Pea (`1-2` devices) tier.
private struct PixelArtSprout: View {
    let color: Color
    let size: CGFloat

    var body: some View {
        Canvas { context, sz in
            let px = sz.width / 16.0
            let py = sz.height / 16.0
            let cells: [(Int, Int, Int, Int)] = [
                // Left leaf
                (2, 3, 3, 1), (1, 4, 5, 1), (1, 5, 5, 1), (2, 6, 4, 1), (4, 7, 2, 1),
                // Right leaf
                (10, 1, 3, 1), (9, 2, 5, 1), (9, 3, 6, 1), (9, 4, 5, 1), (8, 5, 4, 1), (8, 6, 2, 1),
                // Stem & soil mound
                (6, 7, 3, 1), (7, 8, 2, 4), (6, 12, 3, 1), (5, 13, 5, 1), (3, 14, 9, 1), (4, 15, 7, 1)
            ]
            for (x, y, w, h) in cells {
                let rect = CGRect(x: CGFloat(x) * px, y: CGFloat(y) * py, width: CGFloat(w) * px, height: CGFloat(h) * py)
                context.fill(Path(rect), with: .color(color))
            }
        }
        .frame(width: size, height: size)
    }
}

/// 64-column stepped Cascade/Rainier silhouette shown in the Day 0 empty grid.
private struct PixelArtMountainHorizon: View {
    let color: Color

    var body: some View {
        Canvas { context, sz in
            let w = sz.width
            let h = sz.height
            let cols = 64
            let colW = w / CGFloat(cols)

            var bgPath = Path()
            bgPath.move(to: CGPoint(x: 0, y: h))
            bgPath.addLine(to: CGPoint(x: 0, y: h * 0.55))
            bgPath.addLine(to: CGPoint(x: w * 0.22, y: h * 0.35))
            bgPath.addLine(to: CGPoint(x: w * 0.38, y: h * 0.52))
            bgPath.addLine(to: CGPoint(x: w * 0.72, y: h * 0.22))
            bgPath.addLine(to: CGPoint(x: w * 0.88, y: h * 0.42))
            bgPath.addLine(to: CGPoint(x: w, y: h * 0.38))
            bgPath.addLine(to: CGPoint(x: w, y: h))
            bgPath.closeSubpath()
            context.fill(bgPath, with: .color(color.opacity(0.45)))

            for i in 0..<cols {
                let fracX = CGFloat(i) / CGFloat(cols)
                let elev: CGFloat
                if fracX >= 0.15 && fracX <= 0.45 {
                    elev = (1.0 - abs(fracX - 0.30) / 0.15) * 0.55
                } else if fracX >= 0.52 && fracX <= 0.84 {
                    elev = (1.0 - abs(fracX - 0.68) / 0.16) * 0.82
                } else {
                    elev = 0.15
                }
                let stepY = h - elev * h
                let bar = CGRect(x: CGFloat(i) * colW, y: stepY, width: colW + 0.5, height: h - stepY)
                context.fill(Path(bar), with: .color(color))
            }
        }
        .frame(maxWidth: .infinity)
    }
}

/// 16x22 pixel-art evergreen pine tree used in Garden and Forest tiers.
private struct PixelArtPineTree: View {
    let color: Color
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        Canvas { context, sz in
            let px = sz.width / 16.0
            let py = sz.height / 22.0
            let tiers: [(Int, Int, Int, Int)] = [
                (7, 0, 2, 2),
                (6, 2, 4, 2),
                (5, 4, 6, 2),
                (6, 6, 4, 2),
                (4, 8, 8, 2),
                (3, 10, 10, 2),
                (5, 12, 6, 2),
                (2, 14, 12, 2),
                (1, 16, 14, 2),
                (7, 18, 2, 4)
            ]
            for (x, y, w, h) in tiers {
                let rect = CGRect(x: CGFloat(x) * px, y: CGFloat(y) * py, width: CGFloat(w) * px, height: CGFloat(h) * py)
                context.fill(Path(rect), with: .color(color))
            }
        }
        .frame(width: width, height: height)
    }
}
