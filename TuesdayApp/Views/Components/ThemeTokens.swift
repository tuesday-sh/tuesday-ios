import SwiftUI

public enum TuesdayTheme {
    public static let background = Color(red: 0x12 / 255.0, green: 0x12 / 255.0, blue: 0x12 / 255.0)
    public static let appBar = Color(red: 0x1A / 255.0, green: 0x1A / 255.0, blue: 0x1A / 255.0)
    public static let cardSurface = Color(red: 0x1E / 255.0, green: 0x1E / 255.0, blue: 0x1E / 255.0)
    public static let elevatedPill = Color(red: 0x2A / 255.0, green: 0x2A / 255.0, blue: 0x2A / 255.0)

    public static let healthyGreen = Color(red: 0x34 / 255.0, green: 0xC7 / 255.0, blue: 0x59 / 255.0)
    public static let warningAmber = Color(red: 0xFF / 255.0, green: 0x95 / 255.0, blue: 0x00 / 255.0)
    public static let criticalRed = Color(red: 0xFF / 255.0, green: 0x3B / 255.0, blue: 0x30 / 255.0)
    public static let hacsCyan = Color(red: 0x18 / 255.0, green: 0xBC / 255.0, blue: 0xF2 / 255.0)

    public static func color(for status: NodeHealthStatus) -> Color {
        switch status {
        case .healthy: return healthyGreen
        case .warning: return warningAmber
        case .critical: return criticalRed
        }
    }
}
