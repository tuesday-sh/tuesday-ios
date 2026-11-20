import SwiftUI

public struct SingleNotchCard<TopEndHeader: View, Content: View>: View {
    public let palette: BrandPalette
    public let accentColor: Color
    public let notchLabel: String
    public var notchDotColor: Color? = nil
    public var cardBorderColor: Color? = nil
    public var contentTopPadding: CGFloat = 42
    public var onNotchClick: () -> Void = {}
    public var onClick: (() -> Void)? = nil
    @ViewBuilder public let topEndHeader: () -> TopEndHeader
    @ViewBuilder public let content: () -> Content

    public init(
        palette: BrandPalette,
        accentColor: Color,
        notchLabel: String,
        notchDotColor: Color? = nil,
        cardBorderColor: Color? = nil,
        contentTopPadding: CGFloat = 42,
        onNotchClick: @escaping () -> Void = {},
        onClick: (() -> Void)? = nil,
        @ViewBuilder topEndHeader: @escaping () -> TopEndHeader = { EmptyView() },
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.palette = palette
        self.accentColor = accentColor
        self.notchLabel = notchLabel
        self.notchDotColor = notchDotColor
        self.cardBorderColor = cardBorderColor
        self.contentTopPadding = contentTopPadding
        self.onNotchClick = onNotchClick
        self.onClick = onClick
        self.topEndHeader = topEndHeader
        self.content = content
    }

    public var body: some View {
        let resolvedBorder = cardBorderColor ?? accentColor.opacity(0.35)
        let card = ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 5) {
                content()
            }
            .padding(.top, contentTopPadding)
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(alignment: .top, spacing: 8) {
                FusedCornerNotch(
                    corner: .topLeading,
                    fillColor: accentColor.opacity(0.12),
                    strokeColor: resolvedBorder,
                    cornerRadius: 8,
                    action: onNotchClick
                ) {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(notchDotColor ?? accentColor)
                            .frame(width: 7, height: 7)
                        Text(notchLabel)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .kerning(0.5)
                            .foregroundColor(accentColor)
                    }
                }
                .uiAction("clickLeftNotch")

                Spacer(minLength: 4)

                HStack(spacing: 6) {
                    topEndHeader()
                }
                .padding(.top, 7)
                .padding(.trailing, 12)
            }
        }
        .background(palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard))
        .overlay(
            RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard)
                .stroke(resolvedBorder, lineWidth: 1)
        )
        .uiComponent("SingleNotchCard")

        if let onClick {
            Button(action: onClick) {
                card
            }
            .buttonStyle(.plain)
        } else {
            VStack(spacing: 0) {
                card
            }
        }
    }
}
