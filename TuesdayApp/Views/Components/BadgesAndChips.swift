import SwiftUI

public struct MonospaceBadge: View {
    public let text: String
    public let color: Color
    public var borderAlpha: Double = 0.4

    public init(text: String, color: Color, borderAlpha: Double = 0.4) {
        self.text = text
        self.color = color
        self.borderAlpha = borderAlpha
    }

    public var body: some View {
        Text(text)
            .font(.system(size: 10.5, weight: .bold, design: .monospaced))
            .foregroundColor(color)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(color.opacity(0.14))
            .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusBadge))
            .overlay(
                RoundedRectangle(cornerRadius: TuesdayDimens.radiusBadge)
                    .stroke(color.opacity(borderAlpha), lineWidth: borderAlpha > 0 ? 1 : 0)
            )
    }
}

public struct SelectableFilterChip: View {
    public let label: String
    public let selected: Bool
    public let palette: BrandPalette
    public var tintColor: Color? = nil
    public let action: () -> Void

    public init(
        label: String,
        selected: Bool,
        palette: BrandPalette,
        tintColor: Color? = nil,
        action: @escaping () -> Void
    ) {
        self.label = label
        self.selected = selected
        self.palette = palette
        self.tintColor = tintColor
        self.action = action
    }

    public var body: some View {
        let activeColor = tintColor ?? palette.accentText
        Button(action: action) {
            Text(label)
                .font(.system(size: 11.5, weight: selected ? .bold : .semibold))
                .foregroundColor(selected ? activeColor : palette.textMuted)
                .padding(.horizontal, 10)
                .frame(minHeight: 30)
                .background(selected ? activeColor.opacity(0.14) : palette.elevated)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(selected ? activeColor.opacity(0.7) : palette.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

public struct RiskMeterDots: View {
    public let state: PortLifecycleState
    public let palette: BrandPalette

    public init(state: PortLifecycleState, palette: BrandPalette) {
        self.state = state
        self.palette = palette
    }

    public var body: some View {
        let litCount: Int = {
            switch state {
            case .cveKev, .eol: return 3
            case .guessed, .update: return 2
            case .ok: return 1
            case .unassigned: return 0
            }
        }()
        let tint = TuesdayTheme.ledColor(for: state, isStn: palette.isStn)
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { idx in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(idx < litCount ? tint : palette.border)
                    .frame(width: 4, height: CGFloat(6 + idx * 3))
            }
        }
        .accessibilityHidden(true)
    }
}

public struct CandidateDisambiguationStrip: View {
    public let candidateModel: String
    public let palette: BrandPalette
    public let onConfirmModel: (String) -> Void
    public let onRejectModel: () -> Void

    public init(
        candidateModel: String,
        palette: BrandPalette,
        onConfirmModel: @escaping (String) -> Void,
        onRejectModel: @escaping () -> Void
    ) {
        self.candidateModel = candidateModel
        self.palette = palette
        self.onConfirmModel = onConfirmModel
        self.onRejectModel = onRejectModel
    }

    public var body: some View {
        HStack(spacing: 8) {
            Button(action: { onConfirmModel(candidateModel) }) {
                Text("✓ Yes, \(candidateModel)")
                    .font(.system(size: 11.5, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .frame(minHeight: 32)
                    .background(TuesdayTheme.ledColor(for: .ok, isStn: palette.isStn))
                    .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusBadge))
            }
            .buttonStyle(.plain)
            .uiAction("confirmGuessedModel")

            Button(action: onRejectModel) {
                Text("✕ No")
                    .font(.system(size: 11.5, weight: .bold))
                    .foregroundColor(palette.textPrimary)
                    .padding(.horizontal, 10)
                    .frame(minHeight: 32)
                    .background(palette.elevated)
                    .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusBadge))
                    .overlay(RoundedRectangle(cornerRadius: TuesdayDimens.radiusBadge).stroke(palette.border, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .uiAction("rejectGuessedModel")
        }
    }
}
