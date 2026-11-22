import SwiftUI

public struct PreferenceToggleRow: View {
    public let title: String
    public let description: String
    @Binding public var isOn: Bool
    public let palette: BrandPalette
    public var badgeText: String? = nil
    public var badgeColor: Color? = nil
    public var tintColor: Color? = nil
    public var actionName: String = "togglePreference"

    public init(
        title: String,
        description: String,
        isOn: Binding<Bool>,
        palette: BrandPalette,
        badgeText: String? = nil,
        badgeColor: Color? = nil,
        tintColor: Color? = nil,
        actionName: String = "togglePreference"
    ) {
        self.title = title
        self.description = description
        self._isOn = isOn
        self.palette = palette
        self.badgeText = badgeText
        self.badgeColor = badgeColor
        self.tintColor = tintColor
        self.actionName = actionName
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundColor(palette.textPrimary)
                    if let badgeText, !badgeText.isEmpty {
                        MonospaceBadge(text: badgeText, color: badgeColor ?? palette.accentText)
                    }
                }
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(palette.textMuted)
                    .lineSpacing(2)
            }
            Spacer()
            let prefToggle = Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(tintColor ?? palette.accent)
            switch actionName {
            case "toggleShowStateFilterStrip":
                prefToggle.uiAction("toggleShowStateFilterStrip")
            case "toggleShowZoneFilterStrip":
                prefToggle.uiAction("toggleShowZoneFilterStrip")
            case "toggleVisionDebugMode":
                prefToggle.uiAction("toggleVisionDebugMode")
            case "toggleDiagnosticsMode":
                prefToggle.uiAction("toggleDiagnosticsMode")
            case "toggleDeveloperMode":
                prefToggle.uiAction("toggleDeveloperMode")
            case "toggleMonthlyReminders":
                prefToggle.uiAction("toggleMonthlyReminders")
            case "toggleReminderCategory":
                prefToggle.uiAction("toggleReminderCategory")
            default:
                prefToggle.uiAction(actionName)
            }
        }
    }
}

public struct TuesdayTextField: View {
    @Binding public var text: String
    public let label: String
    public var placeholder: String = ""
    public let palette: BrandPalette

    public init(text: Binding<String>, label: String, placeholder: String = "", palette: BrandPalette) {
        self._text = text
        self.label = label
        self.placeholder = placeholder
        self.palette = palette
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundColor(palette.textMuted)
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 13.5))
                .foregroundColor(palette.textPrimary)
                .padding(.horizontal, 10)
                .padding(.vertical, 9)
                .background(palette.bg)
                .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
                .overlay(
                    RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl)
                        .stroke(palette.borderStrong, lineWidth: 1)
                )
        }
    }
}

public struct RemovableAttachmentChip: View {
    public let label: String
    public let palette: BrandPalette
    public var accentColor: Color? = nil
    public let onRemove: () -> Void

    public init(label: String, palette: BrandPalette, accentColor: Color? = nil, onRemove: @escaping () -> Void) {
        self.label = label
        self.palette = palette
        self.accentColor = accentColor
        self.onRemove = onRemove
    }

    public var body: some View {
        let tint = accentColor ?? palette.accent
        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(palette.textPrimary)
                .lineLimit(1)

            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(palette.textMuted)
                    .frame(width: 24, height: 24)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, 10)
        .padding(.trailing, 4)
        .padding(.vertical, 3)
        .background(tint.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
        .overlay(
            RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl)
                .stroke(tint.opacity(0.5), lineWidth: 1)
        )
    }
}

public struct PlanOfferSelector: View {
    public let plans: [SubscriptionPlanOffer]
    public let selectedProductId: String
    public let palette: BrandPalette
    public let onSelectPlan: (String) -> Void

    public init(
        plans: [SubscriptionPlanOffer],
        selectedProductId: String,
        palette: BrandPalette,
        onSelectPlan: @escaping (String) -> Void
    ) {
        self.plans = plans
        self.selectedProductId = selectedProductId
        self.palette = palette
        self.onSelectPlan = onSelectPlan
    }

    public var body: some View {
        HStack(spacing: 8) {
            ForEach(plans) { offer in
                let isSelected = (offer.productId == selectedProductId)
                Button(action: { onSelectPlan(offer.productId) }) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(offer.title)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(palette.textPrimary)
                            Spacer()
                            if let badge = offer.badge {
                                Text(badge)
                                    .font(.system(size: 9.5, weight: .heavy, design: .monospaced))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(palette.accent)
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                        }
                        HStack(alignment: .firstTextBaseline, spacing: 3) {
                            Text(offer.formattedPrice)
                                .font(.system(size: 17, weight: .heavy))
                                .foregroundColor(isSelected ? palette.accentText : palette.textPrimary)
                            Text(offer.periodLabel)
                                .font(.system(size: 11))
                                .foregroundColor(palette.textMuted)
                        }
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(isSelected ? palette.accent.opacity(0.12) : palette.elevated)
                    .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
                    .overlay(
                        RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl)
                            .stroke(isSelected ? palette.accent : palette.border, lineWidth: isSelected ? 1.5 : 1)
                    )
                }
                .buttonStyle(.plain)
                .uiAction("selectTier1Plan")
            }
        }
    }
}

public struct SubscriptionLegalDisclosure: View {
    public let palette: BrandPalette

    public init(palette: BrandPalette) {
        self.palette = palette
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Subscriptions auto-renew via Apple App Store unless canceled at least 24 hours before the end of the current period. Manage or cancel anytime in Settings → Apple Account → Subscriptions.")
                .font(.system(size: 11))
                .foregroundColor(palette.textMuted)
                .lineSpacing(2)

            HStack(spacing: 12) {
                if let termsUrl = URL(string: "https://tuesday.sh/terms") {
                    Link("Terms of Use", destination: termsUrl)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(palette.accentText)
                }
                Text("•")
                    .font(.system(size: 11))
                    .foregroundColor(palette.textMuted)
                if let privacyUrl = URL(string: "https://tuesday.sh/privacy") {
                    Link("Privacy Policy", destination: privacyUrl)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(palette.accentText)
                }
            }
        }
    }
}

public struct SegmentedTabRow: View {
    public let options: [String]
    public let selectedIndex: Int
    public let onSelect: (Int) -> Void
    public let palette: BrandPalette
    public var actionName: String = "switchEnrollmentMode"

    public init(
        options: [String],
        selectedIndex: Int,
        onSelect: @escaping (Int) -> Void,
        palette: BrandPalette,
        actionName: String = "switchEnrollmentMode"
    ) {
        self.options = options
        self.selectedIndex = selectedIndex
        self.onSelect = onSelect
        self.palette = palette
        self.actionName = actionName
    }

    public var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(options.enumerated()), id: \.offset) { idx, title in
                let isSelected = (idx == selectedIndex)
                let tabButton = Button(action: { onSelect(idx) }) {
                    Text(title)
                        .font(.system(size: 13, weight: isSelected ? .bold : .semibold))
                        .foregroundColor(isSelected ? palette.textPrimary : palette.textMuted)
                        .frame(maxWidth: .infinity, minHeight: 34)
                        .background(isSelected ? palette.surface : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusBadge))
                        .overlay(
                            RoundedRectangle(cornerRadius: TuesdayDimens.radiusBadge)
                                .stroke(isSelected ? palette.borderStrong : Color.clear, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)

                if actionName == "switchEnrollmentMode" {
                    tabButton.uiAction("switchEnrollmentMode")
                } else {
                    tabButton.uiAction(actionName)
                }
            }
        }
        .padding(3)
        .background(palette.elevated)
        .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
        .overlay(
            RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl)
                .stroke(palette.border, lineWidth: 1)
        )
    }
}
