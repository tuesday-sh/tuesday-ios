import SwiftUI

/// Vector silhouette iconography mapped to the canonical `C1 → C8` SureThingNet Category Spine,
/// matching Android's `HardwareCategorySvgIcon` paths on a shared `24x24` coordinate grid.
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
            let sx = canvasSize.width / 24.0
            let sy = canvasSize.height / 24.0
            let style = StrokeStyle(lineWidth: 1.8 * sx, lineCap: .round, lineJoin: .round)

            switch category {
            case .C1_GATEWAY:
                let body = CGRect(x: 2 * sx, y: 7 * sy, width: 20 * sx, height: 10 * sy)
                context.stroke(Path(roundedRect: body, cornerRadius: 2 * sx), with: .color(tint), style: style)
                let led = CGRect(x: (6 - 1.3) * sx, y: (12 - 1.3) * sy, width: 2.6 * sx, height: 2.6 * sy)
                context.stroke(Path(ellipseIn: led), with: .color(tint), style: style)
                let ports = CGRect(x: 11 * sx, y: 10 * sy, width: 8 * sx, height: 4 * sy)
                context.stroke(Path(ports), with: .color(tint), style: style)

            case .C2_SWITCH:
                let rack = CGRect(x: 2 * sx, y: 6 * sy, width: 20 * sx, height: 12 * sy)
                context.stroke(Path(roundedRect: rack, cornerRadius: 2 * sx), with: .color(tint), style: style)
                let portStroke = StrokeStyle(lineWidth: 1.3 * sx, lineCap: .round, lineJoin: .round)
                for y in [8.8, 13.2] {
                    for x in [5.5, 10.5, 15.5] {
                        let port = CGRect(x: x * sx, y: y * sy, width: 2.6 * sx, height: 2.2 * sy)
                        context.stroke(Path(roundedRect: port, cornerRadius: 0.5 * sx), with: .color(tint), style: portStroke)
                    }
                }

            case .C3_AP:
                let outer = CGRect(x: (12 - 9) * sx, y: (12 - 9) * sy, width: 18 * sx, height: 18 * sy)
                context.stroke(Path(ellipseIn: outer), with: .color(tint), style: style)
                let inner = CGRect(x: (12 - 3.5) * sx, y: (12 - 3.5) * sy, width: 7 * sx, height: 7 * sy)
                context.stroke(Path(ellipseIn: inner), with: .color(tint), style: style)

            case .C4_SERVER:
                let topBay = CGRect(x: 3 * sx, y: 4 * sy, width: 18 * sx, height: 6 * sy)
                context.stroke(Path(roundedRect: topBay, cornerRadius: 1.5 * sx), with: .color(tint), style: style)
                let bottomBay = CGRect(x: 3 * sx, y: 14 * sy, width: 18 * sx, height: 6 * sy)
                context.stroke(Path(roundedRect: bottomBay, cornerRadius: 1.5 * sx), with: .color(tint), style: style)
                for cy in [7.0, 17.0] {
                    let dot = CGRect(x: (7 - 1.1) * sx, y: (cy - 1.1) * sy, width: 2.2 * sx, height: 2.2 * sy)
                    context.fill(Path(ellipseIn: dot), with: .color(tint))
                }

            case .C5_CAMERA:
                var prism = Path()
                prism.move(to: CGPoint(x: 14.5 * sx, y: 4 * sy))
                prism.addLine(to: CGPoint(x: 9.5 * sx, y: 4 * sy))
                prism.addLine(to: CGPoint(x: 7 * sx, y: 7 * sy))
                prism.addLine(to: CGPoint(x: 4 * sx, y: 7 * sy))
                prism.addLine(to: CGPoint(x: 4 * sx, y: 20 * sy))
                prism.addLine(to: CGPoint(x: 20 * sx, y: 20 * sy))
                prism.addLine(to: CGPoint(x: 20 * sx, y: 7 * sy))
                prism.addLine(to: CGPoint(x: 17 * sx, y: 7 * sy))
                prism.closeSubpath()
                context.stroke(prism, with: .color(tint), style: style)
                let lens = CGRect(x: (12 - 3.5) * sx, y: (13.5 - 3.5) * sy, width: 7 * sx, height: 7 * sy)
                context.stroke(Path(ellipseIn: lens), with: .color(tint), style: style)

            case .C6_IOT:
                let hub = CGRect(x: 4 * sx, y: 4 * sy, width: 16 * sx, height: 16 * sy)
                context.stroke(Path(roundedRect: hub, cornerRadius: 3 * sx), with: .color(tint), style: style)
                var plus = Path()
                plus.move(to: CGPoint(x: 9 * sx, y: 12 * sy))
                plus.addLine(to: CGPoint(x: 15 * sx, y: 12 * sy))
                plus.move(to: CGPoint(x: 12 * sx, y: 9 * sy))
                plus.addLine(to: CGPoint(x: 12 * sx, y: 15 * sy))
                context.stroke(plus, with: .color(tint), style: style)

            case .C7_CLIENT:
                let monitor = CGRect(x: 4 * sx, y: 4 * sy, width: 16 * sx, height: 11 * sy)
                context.stroke(Path(roundedRect: monitor, cornerRadius: 1.5 * sx), with: .color(tint), style: style)
                var stand = Path()
                stand.move(to: CGPoint(x: 2 * sx, y: 19 * sy))
                stand.addLine(to: CGPoint(x: 22 * sx, y: 19 * sy))
                stand.move(to: CGPoint(x: 9 * sx, y: 15 * sy))
                stand.addLine(to: CGPoint(x: 9 * sx, y: 19 * sy))
                stand.move(to: CGPoint(x: 15 * sx, y: 15 * sy))
                stand.addLine(to: CGPoint(x: 15 * sx, y: 19 * sy))
                context.stroke(stand, with: .color(tint), style: style)

            case .C8_GUEST:
                let head = CGRect(x: (12 - 4) * sx, y: (7.5 - 4) * sy, width: 8 * sx, height: 8 * sy)
                context.stroke(Path(ellipseIn: head), with: .color(tint), style: style)
                var shoulders = Path()
                shoulders.move(to: CGPoint(x: 5 * sx, y: 21 * sy))
                shoulders.addLine(to: CGPoint(x: 5 * sx, y: 18.5 * sy))
                shoulders.addCurve(
                    to: CGPoint(x: 9.5 * sx, y: 15 * sy),
                    control1: CGPoint(x: 5 * sx, y: 16 * sy),
                    control2: CGPoint(x: 7 * sx, y: 15 * sy)
                )
                shoulders.addLine(to: CGPoint(x: 14.5 * sx, y: 15 * sy))
                shoulders.addCurve(
                    to: CGPoint(x: 19 * sx, y: 18.5 * sy),
                    control1: CGPoint(x: 17 * sx, y: 15 * sy),
                    control2: CGPoint(x: 19 * sx, y: 16 * sy)
                )
                shoulders.addLine(to: CGPoint(x: 19 * sx, y: 21 * sy))
                context.stroke(shoulders, with: .color(tint), style: style)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
