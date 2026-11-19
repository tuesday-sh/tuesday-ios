import SwiftUI

public struct SingleNotchCard<TopEndHeader: View, Content: View>: View {
    public let palette: BrandPalette
    public let accentColor: Color
    public let notchLabel: String
    public var cardBorderColor: Color? = nil
    public var contentTopPadding: CGFloat = 40
    public var onClick: (() -> Void)? = nil
    @ViewBuilder public let topEndHeader: () -> TopEndHeader
    @ViewBuilder public let content: () -> Content

    public init(
        palette: BrandPalette,
        accentColor: Color,
        notchLabel: String,
        cardBorderColor: Color? = nil,
        contentTopPadding: CGFloat = 40,
        onClick: (() -> Void)? = nil,
        @ViewBuilder topEndHeader: @escaping () -> TopEndHeader = { EmptyView() },
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.palette = palette
        self.accentColor = accentColor
        self.notchLabel = notchLabel
        self.cardBorderColor = cardBorderColor
        self.contentTopPadding = contentTopPadding
        self.onClick = onClick
        self.topEndHeader = topEndHeader
        self.content = content
    }

    public var body: some View {
        let resolvedBorder = cardBorderColor ?? accentColor.opacity(0.38)
        let card = ZStack(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 8) {
                content()
            }
            .padding(.top, contentTopPadding)
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(alignment: .top, spacing: 8) {
                FusedCornerNotch(
                    corner: .topLeading,
                    fillColor: accentColor.opacity(0.14),
                    strokeColor: accentColor.opacity(0.38),
                    cornerRadius: TuesdayDimens.radiusCard
                ) {
                    Text(notchLabel)
                        .font(.system(size: 10.5, weight: .heavy, design: .monospaced))
                        .foregroundColor(accentColor)
                        .uiAction("clickLeftNotch")
                }

                Spacer(minLength: 4)

                HStack(spacing: 6) {
                    topEndHeader()
                }
                .padding(.top, 9)
                .padding(.trailing, 12)
            }
        }
        .background(palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard))
        .overlay(
            RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard)
                .stroke(resolvedBorder, lineWidth: 1)
        )

        if let onClick {
            Button(action: onClick) {
                card
            }
            .buttonStyle(.plain)
            .uiComponent("SingleNotchCard")
        } else {
            card
                .uiComponent("SingleNotchCard")
        }
    }
}
