import SwiftUI
import UIKit

/// Value-moment Notification Pre-Permission Primer shown right after the user enrolls
/// their first device (never on cold Day-0 launch).
public struct NotificationPrimerSheet: View {
    public let palette: BrandPalette
    public let appName: String
    public let deviceName: String?
    public let onEnableSelected: (Bool, Bool) -> Void
    public let onDismiss: () -> Void

    @State private var criticalEnabled = true
    @State private var patchTuesdayEnabled = true

    public init(
        palette: BrandPalette,
        appName: String,
        deviceName: String? = nil,
        onEnableSelected: @escaping (Bool, Bool) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.palette = palette
        self.appName = appName
        self.deviceName = deviceName
        self.onEnableSelected = onEnableSelected
        self.onDismiss = onDismiss
    }

    private var previewDevice: String {
        if let name = deviceName, !name.isEmpty { return name }
        return "UniFi Dream Machine Pro"
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Capsule()
                .fill(palette.border)
                .frame(width: 36, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.top, 6)

            Text(deviceName?.isEmpty == false ? "Filter advisories for \(previewDevice)?" : "Stay ahead of CVEs & Patch Tuesday")
                .font(.system(size: 18, weight: .heavy))
                .foregroundColor(palette.textPrimary)

            Text("\(appName) tracks manufacturer and security researcher notices from global feeds and filters only what applies to your network inventory.")
                .font(.system(size: 13))
                .foregroundColor(palette.textMuted)

            // Realistic Notification Preview Card
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(appName.uppercased()) • PREVIEW")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(palette.accent)
                    Spacer()
                    Text("now")
                        .font(.system(size: 10))
                        .foregroundColor(palette.textMuted)
                }
                Text("Critical firmware update for \(previewDevice)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(palette.textPrimary)
                Text("CVE-2026-4102 patched in latest firmware. Tap to review advisory.")
                    .font(.system(size: 12))
                    .foregroundColor(palette.textMuted)
            }
            .padding(12)
            .background(palette.surface)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(palette.border, lineWidth: 1))

            VStack(spacing: 8) {
                Toggle(isOn: $criticalEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Critical CVEs & safety recalls")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(palette.textPrimary)
                        Text("Immediate alerts for vulnerabilities matching your gear")
                            .font(.system(size: 11))
                            .foregroundColor(palette.textMuted)
                    }
                }
                .tint(palette.accent)
                .padding(10)
                .background(palette.surface)
                .cornerRadius(10)

                Toggle(isOn: $patchTuesdayEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Monthly Patch Tuesday rhythm")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(palette.textPrimary)
                        Text("2nd Tuesday 5-minute check-up & backup reminder")
                            .font(.system(size: 11))
                            .foregroundColor(palette.textMuted)
                    }
                }
                .tint(palette.accent)
                .padding(10)
                .background(palette.surface)
                .cornerRadius(10)
            }

            Text("Only alerts you choose. Never marketing spam.")
                .font(.system(size: 11))
                .foregroundColor(palette.textMuted)
                .frame(maxWidth: .infinity, alignment: .center)

            Button {
                onEnableSelected(criticalEnabled, patchTuesdayEnabled)
            } label: {
                Text("Enable Selected Alerts")
                    .font(.system(size: 14.5, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(palette.accent)
                    .cornerRadius(11)
            }

            Button {
                onDismiss()
            } label: {
                Text("Not now")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(palette.textMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(palette.border, lineWidth: 1))
            }

            Spacer(minLength: 0)
        }
        .padding(18)
        .background(palette.bg.ignoresSafeArea())
    }
}
