import SwiftUI

public struct BulletinPreferencesDialog: View {
    public let palette: BrandPalette
    public let onDismiss: () -> Void
    public let onConfirmMute: () -> Void
    public let onConfirmIgnoreUntilNextMonth: () -> Void

    public init(
        palette: BrandPalette,
        onDismiss: @escaping () -> Void,
        onConfirmMute: @escaping () -> Void,
        onConfirmIgnoreUntilNextMonth: @escaping () -> Void
    ) {
        self.palette = palette
        self.onDismiss = onDismiss
        self.onConfirmMute = onConfirmMute
        self.onConfirmIgnoreUntilNextMonth = onConfirmIgnoreUntilNextMonth
    }

    public var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            TuesdayModalCard(
                palette: palette,
                title: "Bulletin Preferences",
                componentName: "BulletinPreferencesDialog",
                closeActionName: "closeBulletinPreferences",
                onDismiss: onDismiss,
                leading: {
                    Text("⚙️").font(.system(size: 16))
                },
                content: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Do you want to mute Patch Tuesday monthly rhythm?")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(palette.textPrimary)
                            .lineSpacing(3)
                        Text("Muting turns off all routine updates and monthly checklist reminders for this rhythm. Critical CVEs and hardware recalls will still be delivered.")
                            .font(.system(size: 12.5))
                            .foregroundColor(palette.textMuted)
                            .lineSpacing(3)
                    }

                    VStack(spacing: 10) {
                        Button(action: onConfirmMute) {
                            Text("🔕 Mute")
                                .font(.system(size: 13.5, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, minHeight: 42)
                                .background(palette.accent)
                                .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard))
                        }
                        .buttonStyle(.plain)
                        .uiAction("confirmMuteBulletinRhythm")

                        Button(action: onConfirmIgnoreUntilNextMonth) {
                            Text("Ignore until next month")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(palette.textPrimary)
                                .frame(maxWidth: .infinity, minHeight: 42)
                                .background(palette.elevated)
                                .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard))
                                .overlay(
                                    RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard)
                                        .stroke(palette.borderStrong, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                        .uiAction("confirmIgnoreUntilNextMonth")
                    }
                }
            )
        }
        .uiComponent("BulletinPreferencesDialog")
    }
}
