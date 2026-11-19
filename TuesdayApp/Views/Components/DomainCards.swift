import SwiftUI

public struct LegalAndSupportCard: View {
    public let palette: BrandPalette
    @Environment(\.openURL) private var openURL

    public init(palette: BrandPalette) {
        self.palette = palette
    }

    public var body: some View {
        SurfaceListContainer(palette: palette) {
            TuesdayListRow(
                palette: palette,
                title: "Privacy Policy",
                onClick: { if let u = URL(string: "https://tuesday.sh/privacy") { openURL(u) } },
                leading: { Image(systemName: "hand.raised.fill").foregroundColor(palette.accentText) },
                subtitle: {
                    Text("Zero photo retention • sovereign local storage")
                        .font(.system(size: 11.5))
                        .foregroundColor(palette.textMuted)
                }
            )
            SurfaceListDivider(palette: palette)
            TuesdayListRow(
                palette: palette,
                title: "Terms of Service",
                onClick: { if let u = URL(string: "https://tuesday.sh/terms") { openURL(u) } },
                leading: { Image(systemName: "doc.text.fill").foregroundColor(palette.accentText) },
                subtitle: {
                    Text("Packablock LLC / Tuesday.sh commercial terms")
                        .font(.system(size: 11.5))
                        .foregroundColor(palette.textMuted)
                }
            )
            SurfaceListDivider(palette: palette)
            TuesdayListRow(
                palette: palette,
                title: "Support & Help Center",
                onClick: { if let u = URL(string: "https://tuesday.sh/support") { openURL(u) } },
                leading: { Image(systemName: "lifepreserver.fill").foregroundColor(palette.accentText) },
                subtitle: {
                    Text("tuesday.sh/support • support@packablock.com")
                        .font(.system(size: 11.5))
                        .foregroundColor(palette.textMuted)
                }
            )
        }
        .uiSlot("legal-support-card")
    }
}

public struct DiscordCommunityCard: View {
    public let palette: BrandPalette
    @Environment(\.openURL) private var openURL

    public init(palette: BrandPalette) {
        self.palette = palette
    }

    public var body: some View {
        Button(action: {
            if let url = URL(string: "https://discord.gg/2KEYJARecD") {
                openURL(url)
            }
        }) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl)
                    .fill(Color(hex: "5865F2").opacity(0.18))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .foregroundColor(Color(hex: "5865F2"))
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text("Join the Tuesday.sh Discord")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(palette.textPrimary)
                    Text("Share router findings, request new SKUs & join Patch Tuesday live check-ins.")
                        .font(.system(size: 12))
                        .foregroundColor(palette.textMuted)
                        .lineSpacing(2)
                }
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(palette.accentText)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard))
            .overlay(
                RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard)
                    .stroke(palette.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .uiSlot("discord-community-card")
        .uiAction("openDiscordInvite")
    }
}
