import SwiftUI

public struct BulletinChecklistStep: Identifiable, Equatable {
    public let id: String
    public let num: String
    public let title: String
    public let description: String
    public let linkText: String
    public let isDone: Bool
    public let onClick: () -> Void

    public init(
        id: String,
        num: String,
        title: String,
        description: String,
        linkText: String,
        isDone: Bool = false,
        onClick: @escaping () -> Void
    ) {
        self.id = id
        self.num = num
        self.title = title
        self.description = description
        self.linkText = linkText
        self.isDone = isDone
        self.onClick = onClick
    }

    public static func == (lhs: BulletinChecklistStep, rhs: BulletinChecklistStep) -> Bool {
        lhs.id == rhs.id &&
            lhs.num == rhs.num &&
            lhs.title == rhs.title &&
            lhs.description == rhs.description &&
            lhs.linkText == rhs.linkText &&
            lhs.isDone == rhs.isDone
    }
}

/// Canonical 4-corner Fused Notch Bulletin Card backed by [FusedCornerNotch] and [FusedBottomDualNotchBar].
public struct NotchBulletinCard: View {
    public let palette: BrandPalette
    public let title: String
    public let description: String
    public var leftNotchLabel: String = "BULLETIN"
    public var leftNotchDotColor: Color = TuesdayTheme.ledCveRed
    public var onLeftNotchClick: () -> Void = {}
    public var rightNotchLabel: String = "CHECK-UP"
    public var onRightNotchClick: () -> Void = {}
    public var steps: [BulletinChecklistStep] = []
    public var allStepsDone: Bool = false
    public var primaryActionLabel: String = "Snooze 24h"
    public var completeActionLabel: String = "Mark Complete"
    public var secondaryActionLabel: String = "Ignore"
    public var onPrimaryAction: () -> Void = {}
    public var onSecondaryAction: () -> Void = {}

    public init(
        palette: BrandPalette,
        title: String,
        description: String,
        leftNotchLabel: String = "BULLETIN",
        leftNotchDotColor: Color = TuesdayTheme.ledCveRed,
        onLeftNotchClick: @escaping () -> Void = {},
        rightNotchLabel: String = "CHECK-UP",
        onRightNotchClick: @escaping () -> Void = {},
        steps: [BulletinChecklistStep] = [],
        allStepsDone: Bool = false,
        primaryActionLabel: String = "Snooze 24h",
        completeActionLabel: String = "Mark Complete",
        secondaryActionLabel: String = "Ignore",
        onPrimaryAction: @escaping () -> Void = {},
        onSecondaryAction: @escaping () -> Void = {}
    ) {
        self.palette = palette
        self.title = title
        self.description = description
        self.leftNotchLabel = leftNotchLabel
        self.leftNotchDotColor = leftNotchDotColor
        self.onLeftNotchClick = onLeftNotchClick
        self.rightNotchLabel = rightNotchLabel
        self.onRightNotchClick = onRightNotchClick
        self.steps = steps
        self.allStepsDone = allStepsDone
        self.primaryActionLabel = primaryActionLabel
        self.completeActionLabel = completeActionLabel
        self.secondaryActionLabel = secondaryActionLabel
        self.onPrimaryAction = onPrimaryAction
        self.onSecondaryAction = onSecondaryAction
    }

    public var body: some View {
        let okGreen = TuesdayTheme.ledColor(for: .ok, isStn: palette.isStn)
        let borderColor = allStepsDone ? okGreen.opacity(0.45) : palette.accent.opacity(0.45)
        let accentStroke = palette.accent.opacity(0.45)

        VStack(alignment: .leading, spacing: 0) {
            // Top fused corner notches
            HStack(alignment: .top) {
                FusedCornerNotch(
                    corner: .topLeading,
                    fillColor: palette.accent.opacity(0.12),
                    strokeColor: accentStroke,
                    cornerRadius: 8,
                    action: onLeftNotchClick
                ) {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(leftNotchDotColor)
                            .frame(width: 7, height: 7)
                        Text(leftNotchLabel)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .kerning(0.5)
                            .foregroundColor(palette.accentText)
                    }
                }
                .uiAction("clickLeftNotch")

                Spacer()

                FusedCornerNotch(
                    corner: .topTrailing,
                    fillColor: palette.accent.opacity(0.12),
                    strokeColor: accentStroke,
                    cornerRadius: 8,
                    action: onRightNotchClick
                ) {
                    HStack(spacing: 5) {
                        Text(rightNotchLabel)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .kerning(1.2)
                            .foregroundColor(palette.accentText)
                        Image(systemName: "info.circle")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(palette.accentText)
                    }
                }
                .uiAction("clickRightNotch")
            }

            // Center unboxed reading flow (typography & hairline dividers only)
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(palette.textPrimary)
                    .tracking(-0.2)

                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(palette.textMuted)
                    .lineSpacing(3.5)

                ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                    Rectangle()
                        .fill(palette.border.opacity(0.5))
                        .frame(height: 0.6)
                        .padding(.top, index == 0 ? 2 : 0)

                    HStack(alignment: .top, spacing: 9) {
                        ZStack {
                            Circle()
                                .fill(step.isDone ? okGreen : palette.elevated)
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Circle().stroke(step.isDone ? okGreen : palette.border, lineWidth: 1)
                                )
                            Text(step.isDone ? "✓" : step.num)
                                .font(.system(size: step.isDone ? 12 : 11, weight: .bold))
                                .foregroundColor(step.isDone ? .white : palette.textPrimary)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            HStack(alignment: .center) {
                                Text(step.title)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(palette.textPrimary)
                                Spacer(minLength: 6)
                                Button(action: step.onClick) {
                                    Text(step.linkText)
                                        .font(.system(size: 11.5, weight: .bold, design: .monospaced))
                                        .foregroundColor(step.isDone ? okGreen : palette.accentText)
                                        .padding(.leading, 6)
                                        .padding(.vertical, 3)
                                        .frame(minHeight: 24)
                                }
                                .buttonStyle(.plain)
                            }
                            Text(step.description)
                                .font(.system(size: 12))
                                .foregroundColor(palette.textMuted)
                                .lineSpacing(3)
                        }
                    }
                    .padding(.vertical, 3.5)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 14)
            .uiSlot("rhythm-reminder-panel")

            // Full-width lower fused dual notch bar
            FusedBottomDualNotchBar(
                primaryBackground: allStepsDone ? okGreen.opacity(0.22) : palette.accent.opacity(0.18),
                primaryStrokeColor: allStepsDone ? okGreen.opacity(0.55) : accentStroke,
                onPrimaryClick: onPrimaryAction,
                secondaryBackground: palette.accent.opacity(0.05),
                secondaryStrokeColor: accentStroke,
                onSecondaryClick: onSecondaryAction,
                primaryContent: {
                    if allStepsDone {
                        Text("✓")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(okGreen)
                        Text(completeActionLabel)
                            .font(.system(size: 13.5, weight: .bold))
                            .tracking(-0.1)
                            .foregroundColor(okGreen)
                    } else {
                        Image(systemName: "clock")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(palette.accent)
                        Text(primaryActionLabel)
                            .font(.system(size: 13.5, weight: .bold))
                            .tracking(-0.1)
                            .foregroundColor(palette.accentText)
                    }
                },
                secondaryContent: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(palette.textMuted)
                    Text(secondaryActionLabel)
                        .font(.system(size: 13.5, weight: .medium))
                        .tracking(-0.1)
                        .foregroundColor(palette.textMuted)
                }
            )
        }
        .background(palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard))
        .overlay(
            RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard)
                .stroke(borderColor, lineWidth: 1)
        )
        .uiComponent("NotchBulletinCard")
    }
}
