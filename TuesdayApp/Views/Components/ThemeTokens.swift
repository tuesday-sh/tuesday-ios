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

public enum TuesdayTheme {
    // Preset A: Anodized Rack (Tuesday.sh STN-Pro)
    public static let background = Color(red: 0x0B / 255.0, green: 0x0F / 255.0, blue: 0x17 / 255.0)
    public static let appBar = Color(red: 0x12 / 255.0, green: 0x18 / 255.0, blue: 0x24 / 255.0)
    public static let cardSurface = Color(red: 0x12 / 255.0, green: 0x18 / 255.0, blue: 0x24 / 255.0)
    public static let elevatedPill = Color(red: 0x19 / 255.0, green: 0x22 / 255.0, blue: 0x31 / 255.0)

    // Canonical 5-State LED Colors
    public static let ledOkGreen = Color(red: 0x10 / 255.0, green: 0xB9 / 255.0, blue: 0x81 / 255.0)
    public static let ledCveRed = Color(red: 0xF4 / 255.0, green: 0x3F / 255.0, blue: 0x5E / 255.0)
    public static let ledEolAmber = Color(red: 0xF5 / 255.0, green: 0x9E / 255.0, blue: 0x0B / 255.0)
    public static let ledGuessedGrey = Color(red: 0x64 / 255.0, green: 0x74 / 255.0, blue: 0x8B / 255.0)
    public static let ledUpdateBlue = Color(red: 0x38 / 255.0, green: 0xBD / 255.0, blue: 0xF8 / 255.0)

    public static let healthyGreen = ledOkGreen
    public static let warningAmber = ledEolAmber
    public static let criticalRed = ledCveRed
    public static let hacsCyan = Color(red: 0x06 / 255.0, green: 0xB6 / 255.0, blue: 0xD4 / 255.0)

    public static func palette(for flavor: AppBrandFlavor) -> BrandPalette {
        switch flavor {
        case .tuesdayPro:
            return BrandPalette(
                bg: background,
                surface: cardSurface,
                elevated: elevatedPill,
                textPrimary: Color(red: 0xF8 / 255.0, green: 0xFA / 255.0, blue: 0xFC / 255.0),
                textMuted: Color(red: 0x94 / 255.0, green: 0xA3 / 255.0, blue: 0xB8 / 255.0),
                border: Color(red: 0x26 / 255.0, green: 0x33 / 255.0, blue: 0x4A / 255.0),
                accent: hacsCyan
            )
        case .sureThingHome:
            return BrandPalette(
                bg: Color(red: 0xF1 / 255.0, green: 0xF5 / 255.0, blue: 0xF9 / 255.0),
                surface: Color.white,
                elevated: Color(red: 0xE2 / 255.0, green: 0xE8 / 255.0, blue: 0xF0 / 255.0),
                textPrimary: Color(red: 0x0F / 255.0, green: 0x17 / 255.0, blue: 0x2A / 255.0),
                textMuted: Color(red: 0x33 / 255.0, green: 0x41 / 255.0, blue: 0x55 / 255.0),
                border: Color(red: 0xCB / 255.0, green: 0xD5 / 255.0, blue: 0xE1 / 255.0),
                accent: Color(red: 0x02 / 255.0, green: 0x84 / 255.0, blue: 0xC7 / 255.0)
            )
        }
    }

    public static func ledColor(for state: PortLifecycleState) -> Color {
        switch state {
        case .ok: return ledOkGreen
        case .cveKev: return ledCveRed
        case .eol: return ledEolAmber
        case .guessed: return ledGuessedGrey
        case .update: return ledUpdateBlue
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
