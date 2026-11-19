import SwiftUI

public enum TuesdayDimens {
    public static let radiusMicro: CGFloat = 4
    public static let radiusBadge: CGFloat = 6
    public static let radiusControl: CGFloat = 8
    public static let radiusCard: CGFloat = 10
    public static let radiusModalCard: CGFloat = 12
    public static let radiusDialog: CGFloat = 16

    public static let hitTargetMinWcag: CGFloat = 24
    public static let hitTargetCompact: CGFloat = 36
    public static let hitTargetStandard: CGFloat = 48

    public static let screenPaddingHorizontal: CGFloat = 12
    public static let cardPadding: CGFloat = 12
}

public struct BrandPalette {
    public let bg: Color
    public let surface: Color
    public let elevated: Color
    public let textPrimary: Color
    public let textMuted: Color
    public let border: Color
    public let accent: Color
    public let brandPrimary: Color
    public let borderStrong: Color
    public let chassisRecessed: Color
    public let accentText: Color
    public let isStn: Bool

    public init(
        bg: Color,
        surface: Color,
        elevated: Color,
        textPrimary: Color,
        textMuted: Color,
        border: Color,
        accent: Color,
        brandPrimary: Color? = nil,
        borderStrong: Color? = nil,
        chassisRecessed: Color? = nil,
        accentText: Color? = nil,
        isStn: Bool = false
    ) {
        self.bg = bg
        self.surface = surface
        self.elevated = elevated
        self.textPrimary = textPrimary
        self.textMuted = textMuted
        self.border = border
        self.accent = accent
        self.brandPrimary = brandPrimary ?? accent
        self.borderStrong = borderStrong ?? border
        self.chassisRecessed = chassisRecessed ?? bg
        self.accentText = accentText ?? accent
        self.isStn = isStn
    }
}

public enum TuesdayTheme {
    // Preset A: Tuesday.sh Brand Orange & Carbon Rack (STN-Pro)
    public static let background = Color(red: 0x11 / 255.0, green: 0x12 / 255.0, blue: 0x15 / 255.0) // #111215
    public static let appBar = Color(red: 0x18 / 255.0, green: 0x1A / 255.0, blue: 0x1F / 255.0)     // #181A1F
    public static let cardSurface = Color(red: 0x18 / 255.0, green: 0x1A / 255.0, blue: 0x1F / 255.0) // #181A1F
    public static let elevatedPill = Color(red: 0x20 / 255.0, green: 0x23 / 255.0, blue: 0x2A / 255.0) // #20232A
    public static let proChassisRecessed = Color(red: 0x0D / 255.0, green: 0x0F / 255.0, blue: 0x14 / 255.0) // #0D0F14
    public static let proBorder = Color(red: 0x24 / 255.0, green: 0x27 / 255.0, blue: 0x30 / 255.0)    // #242730
    public static let proBorderStrong = Color(red: 0x2E / 255.0, green: 0x32 / 255.0, blue: 0x3E / 255.0) // #2E323E
    public static let proTextPrimary = Color(red: 0xF3 / 255.0, green: 0xF4 / 255.0, blue: 0xF6 / 255.0) // #F3F4F6
    public static let proTextSecondary = Color(red: 0x8E / 255.0, green: 0x95 / 255.0, blue: 0xA2 / 255.0) // #8E95A2

    public static let proBrandPrimary = Color(red: 0xE5 / 255.0, green: 0x78 / 255.0, blue: 0x19 / 255.0) // #E57819
    public static let proAccent = Color(red: 0xE8 / 255.0, green: 0x77 / 255.0, blue: 0x2E / 255.0)       // #E8772E

    // Canonical 6-State LED Colors
    public static let ledOkGreen = Color(red: 0x2E / 255.0, green: 0xBD / 255.0, blue: 0x6B / 255.0)      // #2EBD6B
    public static let ledCveRed = Color(red: 0xEF / 255.0, green: 0x44 / 255.0, blue: 0x44 / 255.0)       // #EF4444
    public static let ledEolAmber = Color(red: 0xF5 / 255.0, green: 0x9E / 255.0, blue: 0x0B / 255.0)     // #F59E0B
    public static let ledGuessedGrey = Color(red: 0x8E / 255.0, green: 0x95 / 255.0, blue: 0xA2 / 255.0)  // #8E95A2
    public static let ledUpdateBlue = Color(red: 0x3B / 255.0, green: 0x82 / 255.0, blue: 0xF6 / 255.0)   // #3B82F6
    public static let ledUnassignedPro = Color(red: 0x1B / 255.0, green: 0x1E / 255.0, blue: 0x26 / 255.0) // #1B1E26
    public static let ledUnassignedStn = Color(red: 0xE2 / 255.0, green: 0xE8 / 255.0, blue: 0xF0 / 255.0) // #E2E8F0

    // Preset A: Daylight Home (SureThingNet STN-Home)
    public static let stnBgCanvas = Color(red: 0xF1 / 255.0, green: 0xF5 / 255.0, blue: 0xF9 / 255.0)     // #F1F5F9
    public static let stnBgSurface = Color(red: 0xFF / 255.0, green: 0xFF / 255.0, blue: 0xFF / 255.0)    // #FFFFFF
    public static let stnBgElevated = Color(red: 0xF8 / 255.0, green: 0xFA / 255.0, blue: 0xFC / 255.0)   // #F8FAFC
    public static let stnBorder = Color(red: 0xE2 / 255.0, green: 0xE8 / 255.0, blue: 0xF0 / 255.0)       // #E2E8F0
    public static let stnBorderStrong = Color(red: 0xCB / 255.0, green: 0xD5 / 255.0, blue: 0xE1 / 255.0) // #CBD5E1
    public static let stnTextPrimary = Color(red: 0x0F / 255.0, green: 0x17 / 255.0, blue: 0x2A / 255.0)  // #0F172A
    public static let stnTextSecondary = Color(red: 0x47 / 255.0, green: 0x55 / 255.0, blue: 0x69 / 255.0) // #475569
    public static let stnAccentPrimary = Color(red: 0x02 / 255.0, green: 0x84 / 255.0, blue: 0xC7 / 255.0) // #0284C7
    public static let stnAccentText = Color(red: 0x03 / 255.0, green: 0x69 / 255.0, blue: 0xA1 / 255.0)    // #0369A1 (>=4.5:1 AA on #FFFFFF)
    public static let stnAccentHealthy = Color(red: 0x05 / 255.0, green: 0x96 / 255.0, blue: 0x69 / 255.0) // #059669
    public static let stnDangerRed = Color(red: 0xDC / 255.0, green: 0x26 / 255.0, blue: 0x26 / 255.0)     // #DC2626
    public static let stnWarningAmber = Color(red: 0xD9 / 255.0, green: 0x77 / 255.0, blue: 0x06 / 255.0)  // #D97706
    public static let stnGuessedSlate = Color(red: 0x64 / 255.0, green: 0x74 / 255.0, blue: 0x8B / 255.0)  // #64748B

    // Post-EOL active overhang crimson/rose
    public static let overhangRosePro = Color(red: 0xE1 / 255.0, green: 0x1D / 255.0, blue: 0x48 / 255.0) // #E11D48
    public static let overhangRoseStn = Color(red: 0xBE / 255.0, green: 0x12 / 255.0, blue: 0x3C / 255.0) // #BE123C

    public static let healthyGreen = ledOkGreen
    public static let warningAmber = ledEolAmber
    public static let criticalRed = ledCveRed
    public static let hacsCyan = proAccent

    public static func brandFont(size: CGFloat) -> Font {
        Font.custom("IBMPlexSans-SemiBold", size: size)
    }

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
                accent: proAccent,
                brandPrimary: proBrandPrimary,
                borderStrong: proBorderStrong,
                chassisRecessed: proChassisRecessed,
                accentText: proAccent,
                isStn: false
            )
        case .sureThingHome:
            return BrandPalette(
                bg: stnBgCanvas,
                surface: stnBgSurface,
                elevated: stnBgElevated,
                textPrimary: stnTextPrimary,
                textMuted: stnTextSecondary,
                border: stnBorder,
                accent: stnAccentPrimary,
                brandPrimary: stnAccentPrimary,
                borderStrong: stnBorderStrong,
                chassisRecessed: stnBgCanvas,
                accentText: stnAccentText,
                isStn: true
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

    public static func zoneColor(for zone: TrustZone, isStn: Bool = false) -> Color {
        switch zone {
        case .z0Core: return isStn ? Color(hex: "0891B2") : Color(hex: "06B6D4")
        case .z1Trusted: return isStn ? Color(hex: "0284C7") : Color(hex: "38BDF8")
        case .z2Lab: return isStn ? Color(hex: "7C3AED") : Color(hex: "A78BFA")
        case .z3Iot: return isStn ? Color(hex: "D97706") : Color(hex: "F59E0B")
        case .z4Guest: return isStn ? Color(hex: "64748B") : Color(hex: "94A3B8")
        }
    }

    public static func presenceColor(for state: DevicePresenceState, isStn: Bool = false) -> Color {
        switch state {
        case .active: return ledColor(for: .ok, isStn: isStn)
        case .retired: return isStn ? stnGuessedSlate : ledGuessedGrey
        case .lost: return isStn ? Color(hex: "9333EA") : Color(hex: "C084FC")
        case .stoppedWorking: return ledColor(for: .cveKev, isStn: isStn)
        }
    }

    public static func overhangColor(isStn: Bool = false) -> Color {
        isStn ? overhangRoseStn : overhangRosePro
    }

    public static func color(for status: NodeHealthStatus) -> Color {
        switch status {
        case .healthy: return ledOkGreen
        case .warning: return ledEolAmber
        case .critical: return ledCveRed
        }
    }
}

public struct TuesdayCalendarHeartIcon: View {
    public let tint: Color
    public let size: CGFloat

    public init(tint: Color = TuesdayTheme.proAccent, size: CGFloat = 20) {
        self.tint = tint
        self.size = size
    }

    public var body: some View {
        Canvas { context, sz in
            let s = min(sz.width, sz.height) / 24.0
            let boxRect = CGRect(x: 3 * s, y: 4 * s, width: 18 * s, height: 18 * s)
            var calendarPath = Path()
            calendarPath.addRoundedRect(in: boxRect, cornerSize: CGSize(width: 2.2 * s, height: 2.2 * s))
            calendarPath.move(to: CGPoint(x: 16 * s, y: 2 * s))
            calendarPath.addLine(to: CGPoint(x: 16 * s, y: 6 * s))
            calendarPath.move(to: CGPoint(x: 8 * s, y: 2 * s))
            calendarPath.addLine(to: CGPoint(x: 8 * s, y: 6 * s))
            calendarPath.move(to: CGPoint(x: 3 * s, y: 10 * s))
            calendarPath.addLine(to: CGPoint(x: 21 * s, y: 10 * s))

            context.stroke(
                calendarPath,
                with: .color(tint),
                style: StrokeStyle(lineWidth: 1.9 * s, lineCap: .round, lineJoin: .round)
            )

            var heartPath = Path()
            heartPath.move(to: CGPoint(x: 12 * s, y: 18.8 * s))
            heartPath.addCurve(
                to: CGPoint(x: 8.6 * s, y: 14.3 * s),
                control1: CGPoint(x: 9.8 * s, y: 17.5 * s),
                control2: CGPoint(x: 8.6 * s, y: 16.0 * s)
            )
            heartPath.addCurve(
                to: CGPoint(x: 12 * s, y: 13.7 * s),
                control1: CGPoint(x: 8.6 * s, y: 13.0 * s),
                control2: CGPoint(x: 10.7 * s, y: 12.6 * s)
            )
            heartPath.addCurve(
                to: CGPoint(x: 15.4 * s, y: 14.3 * s),
                control1: CGPoint(x: 13.3 * s, y: 12.6 * s),
                control2: CGPoint(x: 15.4 * s, y: 13.0 * s)
            )
            heartPath.addCurve(
                to: CGPoint(x: 12 * s, y: 18.8 * s),
                control1: CGPoint(x: 15.4 * s, y: 16.0 * s),
                control2: CGPoint(x: 14.2 * s, y: 17.5 * s)
            )
            heartPath.closeSubpath()

            context.fill(heartPath, with: .color(tint))
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

public extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
