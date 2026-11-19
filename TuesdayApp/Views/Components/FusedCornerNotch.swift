import SwiftUI

/// Corner notch positions fused flush to the inside edge of a parent card's 1pt outer border.
/// Renders ONLY interior dividing strokes and curves (never an outer perimeter border) and
/// insets translucent background fills by `1pt` so outer alpha borders never stack/darken.
public enum FusedNotchCorner: Sendable {
    case topLeading
    case topTrailing
    case bottomLeading
    case bottomTrailing
}

public struct FusedCornerNotch<Content: View>: View {
    public let corner: FusedNotchCorner
    public let fillColor: Color
    public let strokeColor: Color
    public var cornerRadius: CGFloat = 10
    public var lineWidth: CGFloat = 1
    public var action: (() -> Void)? = nil
    @ViewBuilder public let content: () -> Content

    public init(
        corner: FusedNotchCorner,
        fillColor: Color,
        strokeColor: Color,
        cornerRadius: CGFloat = 10,
        lineWidth: CGFloat = 1,
        action: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.corner = corner
        self.fillColor = fillColor
        self.strokeColor = strokeColor
        self.cornerRadius = cornerRadius
        self.lineWidth = lineWidth
        self.action = action
        self.content = content
    }

    public var body: some View {
        let baseContent = content()
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                FusedNotchFillShape(corner: corner, cornerRadius: cornerRadius)
                    .fill(fillColor)
                    .padding(insetPaddingEdges, 1)
            )
            .overlay(
                FusedNotchInteriorDividerShape(corner: corner, cornerRadius: cornerRadius)
                    .stroke(strokeColor, lineWidth: lineWidth)
            )

        if let action {
            Button(action: action) {
                baseContent
            }
            .buttonStyle(.plain)
        } else {
            baseContent
        }
    }

    private var insetPaddingEdges: Edge.Set {
        switch corner {
        case .topLeading: return [.top, .leading]
        case .topTrailing: return [.top, .trailing]
        case .bottomLeading: return [.bottom, .leading]
        case .bottomTrailing: return [.bottom, .trailing]
        }
    }
}

private struct FusedNotchFillShape: Shape {
    let corner: FusedNotchCorner
    let cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        let r = min(cornerRadius, min(rect.width, rect.height) * 0.45)
        var path = Path()
        switch corner {
        case .topLeading:
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX - r, y: rect.maxY),
                control: CGPoint(x: rect.maxX, y: rect.maxY)
            )
            path.closeSubpath()

        case .topTrailing:
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX + r, y: rect.maxY))
            path.addQuadCurve(
                to: CGPoint(x: rect.minX, y: rect.maxY - r),
                control: CGPoint(x: rect.minX, y: rect.maxY)
            )
            path.closeSubpath()

        case .bottomLeading:
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX, y: rect.minY + r),
                control: CGPoint(x: rect.maxX, y: rect.minY)
            )
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()

        case .bottomTrailing:
            path.move(to: CGPoint(x: rect.minX, y: rect.minY + r))
            path.addQuadCurve(
                to: CGPoint(x: rect.minX + r, y: rect.minY),
                control: CGPoint(x: rect.minX, y: rect.minY)
            )
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        }
        return path
    }
}

private struct FusedNotchInteriorDividerShape: Shape {
    let corner: FusedNotchCorner
    let cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        let r = min(cornerRadius, min(rect.width, rect.height) * 0.45)
        var path = Path()
        switch corner {
        case .topLeading:
            path.move(to: CGPoint(x: rect.minX + 1, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX - r, y: rect.maxY))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX, y: rect.maxY - r),
                control: CGPoint(x: rect.maxX, y: rect.maxY)
            )
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + 1))

        case .topTrailing:
            path.move(to: CGPoint(x: rect.minX, y: rect.minY + 1))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - r))
            path.addQuadCurve(
                to: CGPoint(x: rect.minX + r, y: rect.maxY),
                control: CGPoint(x: rect.minX, y: rect.maxY)
            )
            path.addLine(to: CGPoint(x: rect.maxX - 1, y: rect.maxY))

        case .bottomLeading:
            path.move(to: CGPoint(x: rect.minX + 1, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX, y: rect.minY + r),
                control: CGPoint(x: rect.maxX, y: rect.minY)
            )
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - 1))

        case .bottomTrailing:
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY - 1))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
            path.addQuadCurve(
                to: CGPoint(x: rect.minX + r, y: rect.minY),
                control: CGPoint(x: rect.minX, y: rect.minY)
            )
            path.addLine(to: CGPoint(x: rect.maxX - 1, y: rect.minY))
        }
        return path
    }
}
