import SwiftUI

/// Vector silhouette iconography mapped to the canonical `C1 → C8` SureThingNet Category Spine.
public struct HardwareCategoryIcon: View {
    public let category: StnHardwareCategory
    public let tint: Color
    public var size: CGFloat = 20

    public init(category: StnHardwareCategory, tint: Color, size: CGFloat = 20) {
        self.category = category
        self.tint = tint
        self.size = size
    }

    public var body: some View {
        Canvas { context, canvasSize in
            let w = canvasSize.width
            let h = canvasSize.height
            let strokeWidth = max(1.4, min(w, h) * 0.085)
            let style = StrokeStyle(lineWidth: strokeWidth, lineCap: .round, lineJoin: .round)

            switch category {
            case .C1_GATEWAY:
                // Perimeter Router / Gateway chassis + dual antennas + status LED dots
                let chassis = CGRect(x: w * 0.12, y: h * 0.50, width: w * 0.76, height: h * 0.34)
                let path = Path(roundedRect: chassis, cornerRadius: w * 0.08)
                context.stroke(path, with: .color(tint), style: style)

                var antennas = Path()
                antennas.move(to: CGPoint(x: w * 0.28, y: h * 0.50))
                antennas.addLine(to: CGPoint(x: w * 0.28, y: h * 0.16))
                antennas.move(to: CGPoint(x: w * 0.72, y: h * 0.50))
                antennas.addLine(to: CGPoint(x: w * 0.72, y: h * 0.16))
                context.stroke(antennas, with: .color(tint), style: style)

                let ledR = strokeWidth * 0.75
                for px in [0.28, 0.44, 0.60] {
                    let dot = CGRect(x: w * px - ledR, y: h * 0.67 - ledR, width: ledR * 2, height: ledR * 2)
                    context.fill(Path(ellipseIn: dot), with: .color(tint))
                }

            case .C2_SWITCH:
                // 1U Rack Switch with port bays & SFP uplink pair
                let rack = CGRect(x: w * 0.08, y: h * 0.30, width: w * 0.84, height: h * 0.40)
                context.stroke(Path(roundedRect: rack, cornerRadius: w * 0.08), with: .color(tint), style: style)

                for i in 0..<4 {
                    let bx = w * (0.17 + CGFloat(i) * 0.13)
                    let port = CGRect(x: bx, y: h * 0.43, width: w * 0.08, height: h * 0.14)
                    context.fill(Path(roundedRect: port, cornerRadius: 1), with: .color(tint))
                }
                let sfp = CGRect(x: w * 0.74, y: h * 0.42, width: w * 0.10, height: h * 0.16)
                context.stroke(Path(roundedRect: sfp, cornerRadius: 1), with: .color(tint), lineWidth: strokeWidth * 0.8)

            case .C3_AP:
                // Ceiling Access Point disc + concentric RF arcs
                let disc = CGRect(x: w * 0.18, y: h * 0.56, width: w * 0.64, height: h * 0.26)
                context.stroke(Path(roundedRect: disc, cornerRadius: h * 0.13), with: .color(tint), style: style)

                let center = CGPoint(x: w * 0.50, y: h * 0.52)
                for mult in [0.18, 0.34] {
                    var arc = Path()
                    arc.addArc(
                        center: center,
                        radius: w * mult,
                        startAngle: .degrees(215),
                        endAngle: .degrees(325),
                        clockwise: false
                    )
                    context.stroke(arc, with: .color(tint), style: style)
                }

            case .C4_SERVER:
                // Compute / NAS 3-bay tower & drive LEDs
                let outer = CGRect(x: w * 0.18, y: h * 0.12, width: w * 0.64, height: h * 0.76)
                context.stroke(Path(roundedRect: outer, cornerRadius: w * 0.09), with: .color(tint), style: style)
                for row in 0..<3 {
                    let y = h * (0.24 + CGFloat(row) * 0.20)
                    let tray = CGRect(x: w * 0.27, y: y, width: w * 0.46, height: h * 0.11)
                    context.stroke(Path(roundedRect: tray, cornerRadius: 1.5), with: .color(tint), lineWidth: strokeWidth * 0.8)
                }

            case .C5_CAMERA:
                // Vision / Smart Camera dome & optic ring
                let sphere = CGRect(x: w * 0.16, y: h * 0.18, width: w * 0.68, height: h * 0.64)
                context.stroke(Path(ellipseIn: sphere), with: .color(tint), style: style)
                let lens = CGRect(x: w * 0.36, y: h * 0.36, width: w * 0.28, height: w * 0.28)
                context.fill(Path(ellipseIn: lens), with: .color(tint))

            case .C6_IOT:
                // Smart Home Hub / Controller + connected mesh nodes
                let hub = CGRect(x: w * 0.26, y: h * 0.28, width: w * 0.48, height: h * 0.44)
                context.stroke(Path(roundedRect: hub, cornerRadius: w * 0.12), with: .color(tint), style: style)
                let dotSize = strokeWidth * 1.4
                let pts = [
                    CGPoint(x: w * 0.50, y: h * 0.14),
                    CGPoint(x: w * 0.14, y: h * 0.50),
                    CGPoint(x: w * 0.86, y: h * 0.50),
                    CGPoint(x: w * 0.50, y: h * 0.86)
                ]
                for pt in pts {
                    let r = CGRect(x: pt.x - dotSize * 0.5, y: pt.y - dotSize * 0.5, width: dotSize, height: dotSize)
                    context.fill(Path(ellipseIn: r), with: .color(tint))
                }

            case .C7_CLIENT:
                // Workstation / Laptop screen + deck
                let screen = CGRect(x: w * 0.18, y: h * 0.20, width: w * 0.64, height: h * 0.46)
                context.stroke(Path(roundedRect: screen, cornerRadius: w * 0.06), with: .color(tint), style: style)
                var base = Path()
                base.move(to: CGPoint(x: w * 0.08, y: h * 0.76))
                base.addLine(to: CGPoint(x: w * 0.92, y: h * 0.76))
                context.stroke(base, with: .color(tint), style: style)

            case .C8_GUEST:
                // Display / Media / Human perimeter screen with pedestal
                let tv = CGRect(x: w * 0.12, y: h * 0.20, width: w * 0.76, height: h * 0.48)
                context.stroke(Path(roundedRect: tv, cornerRadius: w * 0.06), with: .color(tint), style: style)
                var stand = Path()
                stand.move(to: CGPoint(x: w * 0.50, y: h * 0.68))
                stand.addLine(to: CGPoint(x: w * 0.50, y: h * 0.82))
                stand.move(to: CGPoint(x: w * 0.30, y: h * 0.82))
                stand.addLine(to: CGPoint(x: w * 0.70, y: h * 0.82))
                context.stroke(stand, with: .color(tint), style: style)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
