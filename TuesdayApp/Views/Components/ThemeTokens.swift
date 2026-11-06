import SwiftUI

public struct BrandPalette {
    public let bg: Color
    public let surface: Color
    public let elevated: Color
    public let textPrimary: Color
    public let textMuted: Color
    public let border: Color
    public let accent: Color
}

/// Official Tuesday.sh Brand Orange & Carbon Rack (`v1.2.0`) + SureThingNet Daylight Home Tokens (`design-tokens.json`)
///
/// Hex Token Manifest (Audited by `check-ui-parity.mjs` D4):
/// - pro.bgCanvas: #111215
/// - pro.bgSurface: #181A1F
/// - pro.bgElevated: #20232A
/// - pro.borderHairline: #242730
/// - pro.textPrimary: #F3F4F6
/// - pro.textSecondary: #8E95A2
/// - pro.brandPrimary: #E57819
/// - pro.accentPrimary: #E8772E
/// - pro.accentUpdate: #3B82F6
/// - pro.accentHealthy: #2EBD6B
/// - pro.accentWarning: #F59E0B
/// - pro.accentDanger: #EF4444
/// - led.unassignedPro: #1B1E26
/// - stn.bgCanvas: #F1F5F9
/// - stn.bgSurface: #FFFFFF
/// - stn.bgElevated: #F8FAFC
/// - stn.borderHairline / led.unassignedStn: #E2E8F0
/// - stn.textPrimary: #0F172A
/// - stn.textSecondary: #475569
/// - stn.accentPrimary: #0284C7
/// - stn.accentHealthy: #059669
public enum TuesdayTheme {
    // Preset A: Tuesday.sh Brand Orange & Carbon Rack (STN-Pro)
    public static let background = Color(red: 0x11 / 255.0, green: 0x12 / 255.0, blue: 0x15 / 255.0) // #111215
    public static let appBar = Color(red: 0x18 / 255.0, green: 0x1A / 255.0, blue: 0x1F / 255.0)     // #181A1F
    public static let cardSurface = Color(red: 0x18 / 255.0, green: 0x1A / 255.0, blue: 0x1F / 255.0) // #181A1F
    public static let elevatedPill = Color(red: 0x20 / 255.0, green: 0x23 / 255.0, blue: 0x2A / 255.0) // #20232A
    public static let proBorder = Color(red: 0x24 / 255.0, green: 0x27 / 255.0, blue: 0x30 / 255.0)    // #242730
    public static let proTextPrimary = Color(red: 0xF3 / 255.0, green: 0xF4 / 255.0, blue: 0xF6 / 255.0) // #F3F4F6
    public static let proTextSecondary = Color(red: 0x8E / 255.0, green: 0x95 / 255.0, blue: 0xA2 / 255.0) // #8E95A2

    // Tuesday.sh Official Brand Orange Tokens
    public static let proBrandPrimary = Color(red: 0xE5 / 255.0, green: 0x78 / 255.0, blue: 0x19 / 255.0) // #E57819 (0xFFE57819)
    public static let proAccent = Color(red: 0xE8 / 255.0, green: 0x77 / 255.0, blue: 0x2E / 255.0)       // #E8772E (0xFFE8772E)

    // Canonical 6-State LED Colors (Pro & STN-Home)
    public static let ledOkGreen = Color(red: 0x2E / 255.0, green: 0xBD / 255.0, blue: 0x6B / 255.0)      // #2EBD6B
    public static let ledCveRed = Color(red: 0xEF / 255.0, green: 0x44 / 255.0, blue: 0x44 / 255.0)       // #EF4444
    public static let ledEolAmber = Color(red: 0xF5 / 255.0, green: 0x9E / 255.0, blue: 0x0B / 255.0)     // #F59E0B
    public static let ledGuessedGrey = Color(red: 0x8E / 255.0, green: 0x95 / 255.0, blue: 0xA2 / 255.0)  // #8E95A2
    public static let ledUpdateBlue = Color(red: 0x3B / 255.0, green: 0x82 / 255.0, blue: 0xF6 / 255.0)   // #3B82F6
    public static let ledUnassignedPro = Color(red: 0x1B / 255.0, green: 0x1E / 255.0, blue: 0x26 / 255.0) // #1B1E26
    public static let ledUnassignedStn = Color(red: 0xE2 / 255.0, green: 0xE8 / 255.0, blue: 0xF0 / 255.0) // #E2E8F0

    // SureThingNet Daylight Home Tokens
    public static let stnBgCanvas = Color(red: 0xF1 / 255.0, green: 0xF5 / 255.0, blue: 0xF9 / 255.0)     // #F1F5F9
    public static let stnBgSurface = Color(red: 0xFF / 255.0, green: 0xFF / 255.0, blue: 0xFF / 255.0)    // #FFFFFF
    public static let stnBgElevated = Color(red: 0xF8 / 255.0, green: 0xFA / 255.0, blue: 0xFC / 255.0)   // #F8FAFC
    public static let stnBorder = Color(red: 0xE2 / 255.0, green: 0xE8 / 255.0, blue: 0xF0 / 255.0)       // #E2E8F0
    public static let stnTextPrimary = Color(red: 0x0F / 255.0, green: 0x17 / 255.0, blue: 0x2A / 255.0)  // #0F172A
    public static let stnTextSecondary = Color(red: 0x47 / 255.0, green: 0x55 / 255.0, blue: 0x69 / 255.0) // #475569
    public static let stnAccentPrimary = Color(red: 0x02 / 255.0, green: 0x84 / 255.0, blue: 0xC7 / 255.0) // #0284C7
    public static let stnAccentHealthy = Color(red: 0x05 / 255.0, green: 0x96 / 255.0, blue: 0x69 / 255.0) // #059669
    public static let stnDangerRed = Color(red: 0xDC / 255.0, green: 0x26 / 255.0, blue: 0x26 / 255.0)     // #DC2626
    public static let stnWarningAmber = Color(red: 0xD9 / 255.0, green: 0x77 / 255.0, blue: 0x06 / 255.0)  // #D97706
    public static let stnGuessedSlate = Color(red: 0x64 / 255.0, green: 0x74 / 255.0, blue: 0x8B / 255.0)  // #64748B

    public static let healthyGreen = ledOkGreen
    public static let warningAmber = ledEolAmber
    public static let criticalRed = ledCveRed
    public static let hacsCyan = proAccent

    public static func palette(for flavor: AppBrandFlavor) -> BrandPalette {
        switch flavor {
        case .tuesdayPro:
            return BrandPalette(
                bg: background,
                surface: cardSurface,
                elevated: elevatedPill,
                textPrimary: proTextPrimary,
                textMuted: proTextSecondary,
                border: proBorder,
                accent: proAccent
            )
        case .sureThingHome:
            return BrandPalette(
                bg: stnBgCanvas,
                surface: stnBgSurface,
                elevated: stnBgElevated,
                textPrimary: stnTextPrimary,
                textMuted: stnTextSecondary,
                border: stnBorder,
                accent: stnAccentPrimary
            )
        }
    }

    public static func ledColor(for state: PortLifecycleState, isStn: Bool = false) -> Color {
        switch state {
        case .ok: return isStn ? stnAccentHealthy : ledOkGreen
        case .cveKev: return isStn ? stnDangerRed : ledCveRed
        case .eol: return isStn ? stnWarningAmber : ledEolAmber
        case .guessed: return isStn ? stnGuessedSlate : ledGuessedGrey
        case .update: return isStn ? stnAccentPrimary : ledUpdateBlue
        case .unassigned: return isStn ? ledUnassignedStn : ledUnassignedPro
        }
    }

    public static func color(for status: NodeHealthStatus) -> Color {
        switch status {
        case .healthy: return healthyGreen
        case .warning: return warningAmber
        case .critical: return criticalRed
        }
    }
}

/// Official Tuesday.sh Calendar-Heart Vector Icon (`ic_tuesday_mark` / `tuesday-mark-color.svg`)
public struct TuesdayCalendarHeartIcon: View {
    public let tint: Color
    public let size: CGFloat

    public init(tint: Color = TuesdayTheme.proAccent, size: CGFloat = 20) {
        self.tint = tint
        self.size = size
    }

    public var body: some View {
        Canvas { ctx, canvasSize in
            let sx = canvasSize.width / 24.0
            let sy = canvasSize.height / 24.0

            // Calendar rounded chassis
            let rect = CGRect(x: 3.0 * sx, y: 4.5 * sy, width: 18.0 * sx, height: 16.5 * sy)
            let chassis = Path(roundedRect: rect, cornerRadius: 3.2 * sx)
            ctx.stroke(chassis, with: .color(tint), lineWidth: 2.0 * sx)

            // Calendar top binding rings
            var rings = Path()
            rings.move(to: CGPoint(x: 8.0 * sx, y: 2.5 * sy))
            rings.addLine(to: CGPoint(x: 8.0 * sx, y: 6.5 * sy))
            rings.move(to: CGPoint(x: 16.0 * sx, y: 2.5 * sy))
            rings.addLine(to: CGPoint(x: 16.0 * sx, y: 6.5 * sy))
            ctx.stroke(rings, with: .color(tint), style: StrokeStyle(lineWidth: 2.0 * sx, lineCap: .round))

            // Center heart glyph
            var heart = Path()
            heart.move(to: CGPoint(x: 12.0 * sx, y: 17.2 * sy))
            heart.addCurve(
                to: CGPoint(x: 7.5 * sx, y: 11.8 * sy),
                control1: CGPoint(x: 9.2 * sx, y: 15.2 * sy),
                control2: CGPoint(x: 7.5 * sx, y: 13.6 * sy)
            )
            heart.addCurve(
                to: CGPoint(x: 12.0 * sx, y: 10.6 * sy),
                control1: CGPoint(x: 7.5 * sx, y: 9.8 * sy),
                control2: CGPoint(x: 10.4 * sx, y: 9.4 * sy)
            )
            heart.addCurve(
                to: CGPoint(x: 16.5 * sx, y: 11.8 * sy),
                control1: CGPoint(x: 13.6 * sx, y: 9.4 * sy),
                control2: CGPoint(x: 16.5 * sx, y: 9.8 * sy)
            )
            heart.addCurve(
                to: CGPoint(x: 12.0 * sx, y: 17.2 * sy),
                control1: CGPoint(x: 16.5 * sx, y: 13.6 * sy),
                control2: CGPoint(x: 14.8 * sx, y: 15.2 * sy)
            )
            heart.closeSubpath()
            ctx.fill(heart, with: .color(tint))
        }
        .frame(width: size, height: size)
    }
}
