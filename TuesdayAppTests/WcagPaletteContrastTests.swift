import XCTest
import SwiftUI
import UIKit
@testable import TuesdayApp

final class WcagPaletteContrastTests: XCTestCase {

    private func linearize(_ channel: CGFloat) -> Double {
        let c = max(0.0, min(1.0, Double(channel)))
        return c <= 0.04045 ? (c / 12.92) : pow((c + 0.055) / 1.055, 2.4)
    }

    private func relativeLuminance(_ color: Color) -> Double {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        return 0.2126 * linearize(r) + 0.7152 * linearize(g) + 0.0722 * linearize(b)
    }

    private func contrastRatio(_ fg: Color, over bg: Color) -> Double {
        let l1 = relativeLuminance(fg)
        let l2 = relativeLuminance(bg)
        return (max(l1, l2) + 0.05) / (min(l1, l2) + 0.05)
    }

    func testDualFlavorWcagContrastCompliance() {
        let pro = TuesdayTheme.palette(for: .tuesdayPro)
        let home = TuesdayTheme.palette(for: .sureThingHome)

        // Primary prose >= 7.0:1 WCAG AAA
        XCTAssertGreaterThanOrEqual(contrastRatio(pro.textPrimary, over: pro.bg), 7.0)
        XCTAssertGreaterThanOrEqual(contrastRatio(pro.textPrimary, over: pro.surface), 7.0)
        XCTAssertGreaterThanOrEqual(contrastRatio(pro.textPrimary, over: pro.elevated), 7.0)

        XCTAssertGreaterThanOrEqual(contrastRatio(home.textPrimary, over: home.bg), 7.0)
        XCTAssertGreaterThanOrEqual(contrastRatio(home.textPrimary, over: home.surface), 7.0)
        XCTAssertGreaterThanOrEqual(contrastRatio(home.textPrimary, over: home.elevated), 7.0)

        // Accent CTAs & links >= 4.5:1 AA
        XCTAssertGreaterThanOrEqual(contrastRatio(pro.accentText, over: pro.surface), 4.5)
        XCTAssertGreaterThanOrEqual(contrastRatio(pro.brandPrimary, over: pro.bg), 4.5)
        XCTAssertGreaterThanOrEqual(contrastRatio(home.accent, over: home.surface), 3.0)
        XCTAssertGreaterThanOrEqual(contrastRatio(home.accentText, over: home.surface), 4.5)

        // Active LED states & TrustZone indicators >= 3.0:1 Non-text UI SC 1.4.11
        let activeStates: [PortLifecycleState] = [.ok, .cveKev, .eol, .guessed, .update]
        for st in activeStates {
            XCTAssertGreaterThanOrEqual(contrastRatio(TuesdayTheme.ledColor(for: st, isStn: false), over: pro.surface), 3.0)
            XCTAssertGreaterThanOrEqual(contrastRatio(TuesdayTheme.ledColor(for: st, isStn: true), over: home.surface), 3.0)
        }

        for zone in TrustZone.allCases {
            XCTAssertGreaterThanOrEqual(contrastRatio(TuesdayTheme.zoneColor(for: zone, isStn: false), over: pro.surface), 3.0)
            XCTAssertGreaterThanOrEqual(contrastRatio(TuesdayTheme.zoneColor(for: zone, isStn: true), over: home.surface), 3.0)
        }
    }
}
