import SwiftUI

public struct InboxItemNotchCard: View {
    public let palette: BrandPalette
    public let item: BulletinInboxView
    public var isCompleted: Bool = false
    public var onClick: () -> Void = {}
    public var onConfirmModel: (String) -> Void = { _ in }
    public var onRejectModel: () -> Void = {}

    @Environment(\.openURL) private var openURL

    public init(
        palette: BrandPalette,
        item: BulletinInboxView,
        isCompleted: Bool = false,
        onClick: @escaping () -> Void = {},
        onConfirmModel: @escaping (String) -> Void = { _ in },
        onRejectModel: @escaping () -> Void = {}
    ) {
        self.palette = palette
        self.item = item
        self.isCompleted = isCompleted
        self.onClick = onClick
        self.onConfirmModel = onConfirmModel
        self.onRejectModel = onRejectModel
    }

    public var body: some View {
        let accentColor: Color = {
            if isCompleted { return TuesdayTheme.ledColor(for: .ok, isStn: palette.isStn) }
            switch item.bulletinType.lowercased() {
            case "recall", "cisa_kev", "cve":
                return TuesdayTheme.ledColor(for: .cveKev, isStn: palette.isStn)
            case "eol":
                return TuesdayTheme.ledColor(for: .eol, isStn: palette.isStn)
            default:
                return TuesdayTheme.ledColor(for: .update, isStn: palette.isStn)
            }
        }()

        let notchText = isCompleted
            ? "✓ \(item.bulletinType.uppercased()) REMEDIATED"
            : item.bulletinType.uppercased()

        SingleNotchCard(
            palette: palette,
            accentColor: accentColor,
            notchLabel: notchText,
            cardBorderColor: isCompleted
                ? TuesdayTheme.ledColor(for: .ok, isStn: palette.isStn).opacity(0.4)
                : accentColor.opacity(0.35),
            contentTopPadding: 42,
            onClick: onClick,
            topEndHeader: {
                if isCompleted {
                    MonospaceBadge(
                        text: "✓ RESOLVED",
                        color: TuesdayTheme.ledColor(for: .ok, isStn: palette.isStn)
                    )
                } else if item.brokeThroughMute {
                    MonospaceBadge(
                        text: "🔕 High-Sev",
                        color: TuesdayTheme.ledColor(for: .eol, isStn: palette.isStn)
                    )
                }

                if item.matchedByGuess {
                    MonospaceBadge(text: "❓ Guess", color: palette.textMuted)
                }

                Text(item.publishedAt)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(palette.textMuted)
            },
            content: {
                Text(item.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(isCompleted ? palette.textPrimary.opacity(0.88) : palette.textPrimary)
                    .lineSpacing(3)

                Text(isCompleted ? "✓ Remediation applied. All associated devices are protected and marked OK." : item.body)
                    .font(.system(size: 13))
                    .fontWeight(isCompleted ? .semibold : .regular)
                    .foregroundColor(isCompleted ? TuesdayTheme.ledColor(for: .ok, isStn: palette.isStn) : palette.textMuted)
                    .lineSpacing(3)

                if let urlStr = item.sourceUrl, !urlStr.isEmpty, let url = URL(string: urlStr) {
                    Button(action: { openURL(url) }) {
                        Text("↗ View Original Notice")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(palette.accentText)
                            .padding(.horizontal, 8)
                            .frame(minHeight: 28)
                            .background(palette.elevated)
                            .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusBadge))
                            .overlay(
                                RoundedRectangle(cornerRadius: TuesdayDimens.radiusBadge)
                                    .stroke(palette.border, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 2)
                }

                if item.matchedByGuess, let firstCandidate = item.candidateModels.first {
                    CandidateDisambiguationStrip(
                        candidateModel: firstCandidate,
                        palette: palette,
                        onConfirmModel: onConfirmModel,
                        onRejectModel: onRejectModel
                    )
                    .padding(.top, 4)
                }
            }
        )
        .uiSlot("bulletin-inbox-item", state: "id=\(item.externalId);type=\(item.bulletinType);completed=\(isCompleted)")
    }
}
