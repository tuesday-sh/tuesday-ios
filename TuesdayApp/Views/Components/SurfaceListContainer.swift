import SwiftUI

public struct SurfaceListContainer<Content: View>: View {
    public let palette: BrandPalette
    @ViewBuilder public let content: () -> Content

    public init(palette: BrandPalette, @ViewBuilder content: @escaping () -> Content) {
        self.palette = palette
        self.content = content
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard))
        .overlay(
            RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard)
                .stroke(palette.border, lineWidth: 1)
        )
    }
}

public struct SurfaceListDivider: View {
    public let palette: BrandPalette

    public init(palette: BrandPalette) {
        self.palette = palette
    }

    public var body: some View {
        Rectangle()
            .fill(palette.border.opacity(0.6))
            .frame(height: 1)
    }
}

public struct TuesdayListRow<Leading: View, Subtitle: View, Trailing: View>: View {
    public let palette: BrandPalette
    public let title: String
    public var minHeight: CGFloat = 44
    public var titleLineLimit: Int? = 1
    public var onClick: (() -> Void)? = nil
    @ViewBuilder public let leading: () -> Leading
    @ViewBuilder public let subtitle: () -> Subtitle
    @ViewBuilder public let trailing: () -> Trailing

    public init(
        palette: BrandPalette,
        title: String,
        minHeight: CGFloat = 44,
        titleLineLimit: Int? = 1,
        onClick: (() -> Void)? = nil,
        @ViewBuilder leading: @escaping () -> Leading = { EmptyView() },
        @ViewBuilder subtitle: @escaping () -> Subtitle = { EmptyView() },
        @ViewBuilder trailing: @escaping () -> Trailing = {
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
        }
    ) {
        self.palette = palette
        self.title = title
        self.minHeight = minHeight
        self.titleLineLimit = titleLineLimit
        self.onClick = onClick
        self.leading = leading
        self.subtitle = subtitle
        self.trailing = trailing
    }

    public var body: some View {
        let rowBody = HStack(spacing: 10) {
            leading()

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundColor(palette.textPrimary)
                    .lineLimit(titleLineLimit)
                subtitle()
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            trailing()
                .foregroundColor(palette.textMuted)
        }
        .frame(minHeight: minHeight)
        .padding(.horizontal, TuesdayDimens.cardPadding)
        .padding(.vertical, 10)
        .contentShape(Rectangle())

        if let onClick {
            Button(action: onClick) {
                rowBody
            }
            .buttonStyle(.plain)
        } else {
            rowBody
        }
    }
}

public struct StatusListRow<Subtitle: View>: View {
    public let palette: BrandPalette
    public let dotColor: Color
    public let title: String
    public let onClick: () -> Void
    @ViewBuilder public let subtitle: () -> Subtitle

    public init(
        palette: BrandPalette,
        dotColor: Color,
        title: String,
        onClick: @escaping () -> Void,
        @ViewBuilder subtitle: @escaping () -> Subtitle
    ) {
        self.palette = palette
        self.dotColor = dotColor
        self.title = title
        self.onClick = onClick
        self.subtitle = subtitle
    }

    public var body: some View {
        TuesdayListRow(
            palette: palette,
            title: title,
            onClick: onClick,
            leading: {
                Circle()
                    .fill(dotColor)
                    .frame(width: 8, height: 8)
            },
            subtitle: subtitle
        )
    }
}

public struct TuesdayModalCard<Leading: View, HeaderTrailing: View, Content: View>: View {
    public let palette: BrandPalette
    public let title: String
    public var subtitle: String? = nil
    public var borderColor: Color? = nil
    public var componentName: String = "TuesdayModalCard"
    public var closeActionName: String = "closeModal"
    public let onDismiss: () -> Void
    @ViewBuilder public let leading: () -> Leading
    @ViewBuilder public let headerTrailing: () -> HeaderTrailing
    @ViewBuilder public let content: () -> Content

    public init(
        palette: BrandPalette,
        title: String,
        subtitle: String? = nil,
        borderColor: Color? = nil,
        componentName: String = "TuesdayModalCard",
        closeActionName: String = "closeModal",
        onDismiss: @escaping () -> Void,
        @ViewBuilder leading: @escaping () -> Leading = { EmptyView() },
        @ViewBuilder headerTrailing: @escaping () -> HeaderTrailing = { EmptyView() },
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.palette = palette
        self.title = title
        self.subtitle = subtitle
        self.borderColor = borderColor
        self.componentName = componentName
        self.closeActionName = closeActionName
        self.onDismiss = onDismiss
        self.leading = leading
        self.headerTrailing = headerTrailing
        self.content = content
    }

    public var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(palette.textPrimary)
                    .frame(width: TuesdayDimens.hitTargetCompact, height: TuesdayDimens.hitTargetCompact)
                    .background(palette.surface)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(palette.border, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .uiAction(closeActionName)

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    leading()
                    Text(title)
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundColor(palette.textPrimary)
                        .lineLimit(2)
                    Spacer()
                    headerTrailing()
                }

                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 12.5))
                        .foregroundColor(palette.textMuted)
                }

                content()
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusModalCard))
            .overlay(
                RoundedRectangle(cornerRadius: TuesdayDimens.radiusModalCard)
                    .stroke(borderColor ?? palette.border, lineWidth: 1)
            )
            .uiComponent(componentName)
        }
        .padding(.horizontal, 16)
    }
}
