import SwiftUI

public struct BulletinChecklistStep: Identifiable, Equatable {
    public let id: Int
    public let title: String
    public let completed: Bool
    public let ctaLabel: String
    public let onTap: () -> Void

    public init(id: Int, title: String, completed: Bool, ctaLabel: String, onTap: @escaping () -> Void) {
        self.id = id
        self.title = title
        self.completed = completed
        self.ctaLabel = ctaLabel
        self.onTap = onTap
    }

    public static func == (lhs: BulletinChecklistStep, rhs: BulletinChecklistStep) -> Bool {
        lhs.id == rhs.id && lhs.title == rhs.title && lhs.completed == rhs.completed && lhs.ctaLabel == rhs.ctaLabel
    }
}

/// Canonical Welcome / Patch Tuesday Rhythm Card using dual top & bottom fused corner notches
/// with translucent `1pt` interior dividers and zero outer double-border stacking.
public struct NotchBulletinCard: View {
    public let palette: BrandPalette
    public let statusLabel: String
    public let linkLabel: String
    public let headline: String
    public let bodyText: String
    public let checklistSteps: [BulletinChecklistStep]
    public let allComplete: Bool
    public let isSnoozed: Bool
    public let onTapRhythmInfo: () -> Void
    public let onSnoozeOrComplete: () -> Void
    public let onIgnore: () -> Void

    public init(
        palette: BrandPalette,
        statusLabel: String = "BULLETIN",
        linkLabel: String = "RHYTHM",
        headline: String,
        bodyText: String,
        checklistSteps: [BulletinChecklistStep],
        allComplete: Bool,
        isSnoozed: Bool = false,
        onTapRhythmInfo: @escaping () -> Void,
        onSnoozeOrComplete: @escaping () -> Void,
        onIgnore: @escaping () -> Void
    ) {
        self.palette = palette
        self.statusLabel = statusLabel
        self.linkLabel = linkLabel
        self.headline = headline
        self.bodyText = bodyText
        self.checklistSteps = checklistSteps
        self.allComplete = allComplete
        self.isSnoozed = isSnoozed
        self.onTapRhythmInfo = onTapRhythmInfo
        self.onSnoozeOrComplete = onSnoozeOrComplete
        self.onIgnore = onIgnore
    }

    public var body: some View {
        let dotColor = allComplete
            ? TuesdayTheme.ledColor(for: .ok, isStn: palette.isStn)
            : TuesdayTheme.ledCveRed
        let accentTint = allComplete
            ? TuesdayTheme.ledColor(for: .ok, isStn: palette.isStn)
            : palette.accent
        let borderTint = accentTint.opacity(0.42)

        VStack(alignment: .leading, spacing: 0) {
            // Top fused corner notches
            HStack(alignment: .top) {
                FusedCornerNotch(
                    corner: .topLeading,
                    fillColor: accentTint.opacity(0.14),
                    strokeColor: borderTint,
                    cornerRadius: TuesdayDimens.radiusCard
                ) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(dotColor)
                            .frame(width: 7, height: 7)
                        Text(statusLabel)
                            .font(.system(size: 11, weight: .heavy, design: .monospaced))
                            .foregroundColor(palette.textPrimary)
                    }
                }

                Spacer()

                FusedCornerNotch(
                    corner: .topTrailing,
                    fillColor: palette.elevated,
                    strokeColor: palette.border,
                    cornerRadius: TuesdayDimens.radiusCard,
                    action: onTapRhythmInfo
                ) {
                    HStack(spacing: 5) {
                        Text(linkLabel)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .kerning(1.2)
                            .foregroundColor(palette.accentText)
                        Image(systemName: "info.circle")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(palette.accentText)
                    }
                    .uiAction("clickRightNotch")
                }
                .uiAction("openReferenceGuideFromBulletin")
            }

            // Center unboxed reading flow (typography & hairline dividers only)
            VStack(alignment: .leading, spacing: 10) {
                Text(headline)
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundColor(palette.textPrimary)
                    .tracking(-0.2)

                Text(bodyText)
                    .font(.system(size: 14))
                    .foregroundColor(palette.textMuted)
                    .lineSpacing(4)

                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(checklistSteps.enumerated()), id: \.element.id) { index, step in
                        if index > 0 {
                            Rectangle()
                                .fill(palette.border.opacity(0.65))
                                .frame(height: 1)
                        }
                        HStack(spacing: 10) {
                            Image(systemName: step.completed ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(step.completed ? TuesdayTheme.ledColor(for: .ok, isStn: palette.isStn) : palette.textMuted)

                            Text(step.title)
                                .font(.system(size: 13.5, weight: step.completed ? .medium : .semibold))
                                .foregroundColor(step.completed ? palette.textMuted : palette.textPrimary)
                                .strikethrough(step.completed)

                            Spacer()

                            if !step.completed {
                                Button(action: step.onTap) {
                                    Text(step.ctaLabel)
                                        .font(.system(size: 11.5, weight: .bold))
                                        .foregroundColor(palette.accentText)
                                        .padding(.horizontal, 10)
                                        .frame(minHeight: 28)
                                        .background(palette.accent.opacity(0.14))
                                        .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusBadge))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 9)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            // Bottom fused action notches
            HStack {
                FusedCornerNotch(
                    corner: .bottomLeading,
                    fillColor: allComplete ? TuesdayTheme.ledColor(for: .ok, isStn: palette.isStn).opacity(0.14) : palette.elevated,
                    strokeColor: palette.border,
                    cornerRadius: TuesdayDimens.radiusCard,
                    action: onSnoozeOrComplete
                ) {
                    Text(allComplete ? "✓ Mark Complete" : (isSnoozed ? "Snoozed 24h" : "Snooze 24h"))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(allComplete ? TuesdayTheme.ledColor(for: .ok, isStn: palette.isStn) : palette.textPrimary)
                        .uiAction("clickLeftNotch")
                }
                .uiAction("primaryNotchAction")

                Spacer()

                FusedCornerNotch(
                    corner: .bottomTrailing,
                    fillColor: palette.elevated,
                    strokeColor: palette.border,
                    cornerRadius: TuesdayDimens.radiusCard,
                    action: onIgnore
                ) {
                    Text("Ignore")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(palette.textMuted)
                        .uiAction("secondaryNotchAction")
                }
                .uiAction("ignoreRhythmBulletin")
            }
        }
        .background(palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard))
        .overlay(
            RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard)
                .stroke(borderTint, lineWidth: 1)
        )
        .uiSlot("rhythm-reminder-panel")
        .uiComponent("NotchBulletinCard")
    }
}
