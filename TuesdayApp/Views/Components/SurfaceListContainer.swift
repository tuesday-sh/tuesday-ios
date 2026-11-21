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
            let closeBtn = Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(palette.textPrimary)
                    .frame(width: TuesdayDimens.hitTargetCompact, height: TuesdayDimens.hitTargetCompact)
                    .background(palette.surface)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(palette.border, lineWidth: 1))
            }
            .buttonStyle(.plain)

            if closeActionName == "closeTier1UpgradeModal" {
                closeBtn.uiAction("closeTier1UpgradeModal")
            } else {
                closeBtn.uiAction(closeActionName)
            }

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

/// Canonical unboxed section heading (`SectionHeading.kt`) — 14pt bold primary text, single line.
public struct SectionHeading: View {
    public let text: String
    public let palette: BrandPalette

    public init(text: String, palette: BrandPalette) {
        self.text = text
        self.palette = palette
    }

    public var body: some View {
        Text(text)
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(palette.textPrimary)
            .lineLimit(1)
    }
}

/// Full-width dimmed scrim dialog with a top-trailing `36pt` circular close button
/// above arbitrary card content (matches Android `DetailModalDialog`).
public struct DetailModalDialog<Content: View>: View {
    public let palette: BrandPalette
    public var closeActionName: String? = nil
    public let onDismiss: () -> Void
    @ViewBuilder public let content: () -> Content

    public init(
        palette: BrandPalette,
        closeActionName: String? = nil,
        onDismiss: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.palette = palette
        self.closeActionName = closeActionName
        self.onDismiss = onDismiss
        self.content = content
    }

    public var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            ScrollView {
                VStack(alignment: .trailing, spacing: 8) {
                    closeButton
                    content()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 24)
            }
            .scrollIndicators(.hidden)
        }
    }

    @ViewBuilder
    private var closeButton: some View {
        let button = Button(action: onDismiss) {
            Image(systemName: "xmark")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(palette.textPrimary)
                .frame(width: TuesdayDimens.hitTargetCompact, height: TuesdayDimens.hitTargetCompact)
                .background(palette.surface)
                .clipShape(Circle())
                .overlay(Circle().stroke(palette.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Close")

        if let closeActionName {
            button.uiAction(closeActionName)
        } else {
            button
        }
    }
}

public enum ListSectionLayoutStyle {
    case cardStack
    case surfaceGrouped
}

public struct TuesdayListEmptyBanner: View {
    public let message: String
    public let palette: BrandPalette

    public init(message: String, palette: BrandPalette) {
        self.message = message
        self.palette = palette
    }

    public var body: some View {
        Text(message)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(palette.textMuted)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(14)
            .background(palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
            .overlay(
                RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl)
                    .stroke(palette.border, lineWidth: 1)
            )
    }
}

private struct IndexedSectionItem<Item, ID: Hashable>: Identifiable {
    let index: Int
    let item: Item
    let id: ID
}

/// Unified section primitive backing DeviceListSection, HardwareLifecyclesSection,
/// and MatchedFeedsSection across Home, Timeline, and Bulletins.
public struct TuesdayListSection<
    Item,
    ID: Hashable,
    HeaderTrailing: View,
    ItemContent: View,
    EmptyContent: View,
    FooterContent: View
>: View {
    public let palette: BrandPalette
    public let items: [Item]
    public let id: KeyPath<Item, ID>
    public var layoutStyle: ListSectionLayoutStyle
    public var itemSpacing: CGFloat
    public var sectionSpacing: CGFloat
    public var title: String?
    public var showHeader: Bool
    public var showHeaderTrailing: Bool
    public var showEmpty: Bool
    public var showFooter: Bool
    @ViewBuilder public let headerTrailing: () -> HeaderTrailing
    @ViewBuilder public let itemContent: (Item) -> ItemContent
    @ViewBuilder public let emptyContent: () -> EmptyContent
    @ViewBuilder public let footerContent: () -> FooterContent

    public init(
        palette: BrandPalette,
        items: [Item],
        id: KeyPath<Item, ID>,
        layoutStyle: ListSectionLayoutStyle = .cardStack,
        itemSpacing: CGFloat = 8,
        sectionSpacing: CGFloat = 8,
        title: String? = nil,
        showHeader: Bool = true,
        showHeaderTrailing: Bool = true,
        showEmpty: Bool = true,
        @ViewBuilder headerTrailing: @escaping () -> HeaderTrailing,
        @ViewBuilder itemContent: @escaping (Item) -> ItemContent,
        @ViewBuilder emptyContent: @escaping () -> EmptyContent,
        showFooter: Bool = true,
        @ViewBuilder footerContent: @escaping () -> FooterContent
    ) {
        self.palette = palette
        self.items = items
        self.id = id
        self.layoutStyle = layoutStyle
        self.itemSpacing = itemSpacing
        self.sectionSpacing = sectionSpacing
        self.title = title
        self.showHeader = showHeader
        self.showHeaderTrailing = showHeaderTrailing
        self.showEmpty = showEmpty
        self.showFooter = showFooter
        self.headerTrailing = headerTrailing
        self.itemContent = itemContent
        self.emptyContent = emptyContent
        self.footerContent = footerContent
    }

    @ViewBuilder
    private var headerRow: some View {
        HStack(spacing: 8) {
            if let title {
                SectionHeading(text: title, palette: palette)
            }

            Spacer(minLength: 4)

            if showHeaderTrailing {
                HStack(spacing: 8) {
                    headerTrailing()
                }
            }
        }
        .uiSlot("list-section-header")
    }

    public var body: some View {
        let indexed = items.enumerated().map { idx, element in
            IndexedSectionItem(index: idx, item: element, id: element[keyPath: id])
        }

        VStack(alignment: .leading, spacing: sectionSpacing) {
            if showHeader && (title != nil || showHeaderTrailing) {
                headerRow
            }

            if items.isEmpty {
                if showEmpty {
                    emptyContent()
                }
            } else if layoutStyle == .surfaceGrouped {
                SurfaceListContainer(palette: palette) {
                    ForEach(indexed) { entry in
                        itemContent(entry.item)
                        if entry.index < indexed.count - 1 {
                            SurfaceListDivider(palette: palette)
                        }
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: itemSpacing) {
                    ForEach(indexed) { entry in
                        itemContent(entry.item)
                    }
                }
            }

            if showFooter {
                footerContent()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

public extension TuesdayListSection where FooterContent == EmptyView {
    init(
        palette: BrandPalette,
        items: [Item],
        id: KeyPath<Item, ID>,
        layoutStyle: ListSectionLayoutStyle = .cardStack,
        itemSpacing: CGFloat = 8,
        sectionSpacing: CGFloat = 8,
        title: String? = nil,
        showHeader: Bool = true,
        showHeaderTrailing: Bool = true,
        showEmpty: Bool = true,
        @ViewBuilder headerTrailing: @escaping () -> HeaderTrailing,
        @ViewBuilder itemContent: @escaping (Item) -> ItemContent,
        @ViewBuilder emptyContent: @escaping () -> EmptyContent
    ) {
        self.init(
            palette: palette,
            items: items,
            id: id,
            layoutStyle: layoutStyle,
            itemSpacing: itemSpacing,
            sectionSpacing: sectionSpacing,
            title: title,
            showHeader: showHeader,
            showHeaderTrailing: showHeaderTrailing,
            showEmpty: showEmpty,
            headerTrailing: headerTrailing,
            itemContent: itemContent,
            emptyContent: emptyContent,
            showFooter: false,
            footerContent: { EmptyView() }
        )
    }
}
