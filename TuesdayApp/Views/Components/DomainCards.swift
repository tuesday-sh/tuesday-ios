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
        VStack(spacing: 0) {
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
            .uiAction("openDiscordInvite")
        }
        .uiSlot("discord-community-card")
    }
}

/// Palette-aware condensed candlestick bar supporting both `TUESDAY_PRO` and `SURETHING_HOME` flavors
/// (matches Android `CondensedMiniCandleBar` in `DomainCards.kt`).
public struct CondensedMiniCandleBar: View {
    public let candle: OperationalCandle
    public let palette: BrandPalette
    public var showTodayMarker: Bool = false

    public init(candle: OperationalCandle, palette: BrandPalette, showTodayMarker: Bool = false) {
        self.candle = candle
        self.palette = palette
        self.showTodayMarker = showTodayMarker
    }

    public var body: some View {
        let isStn = palette.isStn
        let okColor = TuesdayTheme.ledColor(for: .ok, isStn: isStn)
        let cveColor = TuesdayTheme.ledColor(for: .cveKev, isStn: isStn)
        let eolColor = TuesdayTheme.ledColor(for: .eol, isStn: isStn)
        let overhangColor = TuesdayTheme.overhangColor(isStn: isStn)

        Canvas { context, size in
            let w = size.width
            let h = size.height
            let yCenter = h / 2
            let candleH: CGFloat = 6
            let cTop = yCenter - candleH / 2

            let xRel = CGFloat(candle.marketReleaseNorm) * w
            let xDeployStart = CGFloat(candle.deployStartNorm) * w
            let xDeployEnd = CGFloat(candle.deployEndNorm) * w
            let xEol = CGFloat(candle.vendorEolNorm) * w

            if xDeployStart > xRel {
                var wick = Path()
                wick.move(to: CGPoint(x: xRel, y: yCenter))
                wick.addLine(to: CGPoint(x: xDeployStart, y: yCenter))
                context.stroke(wick, with: .color(palette.textMuted), lineWidth: 1.2)
                context.fill(
                    Path(ellipseIn: CGRect(x: xRel - 1.8, y: yCenter - 1.8, width: 3.6, height: 3.6)),
                    with: .color(palette.textMuted)
                )
            }

            let xSupportedEnd = min(xDeployEnd, xEol)
            let bodyW = max(3, xSupportedEnd - xDeployStart)
            let bodyColor: Color = {
                if candle.presenceState != .active {
                    return TuesdayTheme.presenceColor(for: candle.presenceState, isStn: isStn)
                }
                if candle.hasCveOrRecall { return cveColor }
                if candle.isPastEol { return overhangColor }
                if candle.isEolNearing { return eolColor }
                return okColor
            }()

            let rect = CGRect(x: xDeployStart, y: cTop, width: bodyW, height: candleH)
            switch candle.presenceState {
            case .retired:
                context.fill(Path(rect), with: .color(bodyColor.opacity(0.15)))
                context.stroke(Path(rect), with: .color(bodyColor), lineWidth: 1.2)
            case .lost:
                context.fill(Path(rect), with: .color(bodyColor.opacity(0.12)))
                context.stroke(
                    Path(rect),
                    with: .color(bodyColor),
                    style: StrokeStyle(lineWidth: 1.2, dash: [4, 3])
                )
            case .stoppedWorking:
                context.fill(Path(rect), with: .color(bodyColor.opacity(0.18)))
                context.stroke(Path(rect), with: .color(bodyColor), lineWidth: 1.2)
                var slash = Path()
                slash.move(to: CGPoint(x: xDeployStart + 2, y: cTop + 1))
                slash.addLine(to: CGPoint(x: xDeployStart + bodyW - 2, y: cTop + candleH - 1))
                context.stroke(slash, with: .color(bodyColor), lineWidth: 1)
            case .active:
                if candle.isRetired {
                    context.fill(Path(rect), with: .color(bodyColor.opacity(0.15)))
                    context.stroke(Path(rect), with: .color(bodyColor), lineWidth: 1.2)
                } else {
                    context.fill(Path(rect), with: .color(bodyColor))
                }
            }

            if candle.isPastEol && xDeployEnd > xEol {
                let overW = max(3, xDeployEnd - xEol)
                var eolTick = Path()
                eolTick.move(to: CGPoint(x: xEol, y: cTop - 1))
                eolTick.addLine(to: CGPoint(x: xEol, y: cTop + candleH + 1))
                context.stroke(eolTick, with: .color(palette.textPrimary), lineWidth: 1.2)
                context.fill(Path(CGRect(x: xEol, y: cTop, width: overW, height: candleH)), with: .color(cveColor))
            }

            if !candle.isPastEol && xEol > xDeployEnd {
                let runwayColor = candle.isEolNearing ? eolColor : palette.textMuted
                var runway = Path()
                runway.move(to: CGPoint(x: xDeployEnd, y: yCenter))
                runway.addLine(to: CGPoint(x: xEol, y: yCenter))
                context.stroke(runway, with: .color(runwayColor), lineWidth: 1.2)
                context.fill(
                    Path(ellipseIn: CGRect(x: xEol - 1.8, y: yCenter - 1.8, width: 3.6, height: 3.6)),
                    with: .color(runwayColor)
                )
            }

            if showTodayMarker && !candle.isRetired {
                var todayLine = Path()
                todayLine.move(to: CGPoint(x: xDeployEnd, y: 0))
                todayLine.addLine(to: CGPoint(x: xDeployEnd, y: h))
                context.stroke(todayLine, with: .color(palette.textPrimary), lineWidth: 1.5)
                context.fill(
                    Path(ellipseIn: CGRect(x: xDeployEnd - 2.5, y: 0, width: 5, height: 5)),
                    with: .color(palette.textPrimary)
                )
            }
        }
        .frame(height: 14)
        .background(palette.chassisRecessed)
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .overlay(
            RoundedRectangle(cornerRadius: 3)
                .stroke(palette.border, lineWidth: 1)
        )
    }
}

/// Shared condensed candlestick lifecycle card used in `DeviceInspectorSheet` and `SwimlaneTimelineView`.
public struct CondensedCandlestickCard: View {
    public let candle: OperationalCandle
    public let palette: BrandPalette
    public var showHeader: Bool = true

    public init(candle: OperationalCandle, palette: BrandPalette, showHeader: Bool = true) {
        self.candle = candle
        self.palette = palette
        self.showHeader = showHeader
    }

    public var body: some View {
        let cveColor = TuesdayTheme.ledColor(for: .cveKev, isStn: palette.isStn)

        VStack(alignment: .leading, spacing: 7) {
            if showHeader {
                HStack {
                    Text("Timeline")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(palette.textPrimary)
                    Spacer()
                    HStack(spacing: 4) {
                        Circle()
                            .fill(palette.textPrimary)
                            .frame(width: 5, height: 5)
                        Text("Today")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(palette.textPrimary.opacity(0.85))
                    }
                }
            }

            CondensedMiniCandleBar(candle: candle, palette: palette, showTodayMarker: true)
                .frame(height: 16)

            HStack {
                Text("Released \(candle.releaseDateStr ?? candle.releaseLabel) • Active \(candle.deployDateStr ?? "Install")")
                    .font(.system(size: 11))
                    .foregroundColor(palette.textMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Spacer(minLength: 8)
                Text("EOL: \(candle.eolDateStr ?? candle.eolLabel)")
                    .font(.system(size: 11, weight: candle.isPastEol ? .bold : .regular))
                    .foregroundColor(candle.isPastEol ? cveColor : palette.textMuted)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.bg)
        .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
        .overlay(
            RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl)
                .stroke(palette.border, lineWidth: 1)
        )
    }
}
