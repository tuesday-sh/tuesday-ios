import SwiftUI

/// Ported from SureThingNet's `WifiWarningOverlay` (`wifi_warning_overlay.dart`)
public struct WifiWarningOverlay: View {
    public let isVisible: Bool
    public let hacsUrl: String
    public let onDisableLocalRequirement: () -> Void

    @State private var pulseScale: CGFloat = 0.92

    public init(
        isVisible: Bool,
        hacsUrl: String,
        onDisableLocalRequirement: @escaping () -> Void
    ) {
        self.isVisible = isVisible
        self.hacsUrl = hacsUrl
        self.onDisableLocalRequirement = onDisableLocalRequirement
    }

    public var body: some View {
        if isVisible {
            ZStack {
                Color.black.opacity(0.92)
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(TuesdayTheme.warningAmber.opacity(0.15))
                            .frame(width: 112, height: 112)
                            .overlay(
                                Circle()
                                    .stroke(TuesdayTheme.warningAmber.opacity(0.45), lineWidth: 2)
                            )
                            .scaleEffect(pulseScale)

                        Image(systemName: "wifi.exclamationmark")
                            .font(.system(size: 46, weight: .bold))
                            .foregroundStyle(TuesdayTheme.warningAmber)
                    }
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                            pulseScale = 1.12
                        }
                    }

                    Text("Local Wi-Fi Required")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)

                    Text("Tuesday.sh is configured to poll your Home Assistant HACS endpoint (\(hacsUrl)) over your local LAN. Connect to Wi-Fi or switch to remote proxy mode.")
                        .font(.system(size: 15))
                        .foregroundStyle(Color(white: 0.72))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 24)

                    Button(action: onDisableLocalRequirement) {
                        Text("Continue in Cached / Remote Mode")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(TuesdayTheme.warningAmber)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .accessibilityIdentifier("wifi_overlay_bypass_button")
                }
                .padding(24)
            }
            .accessibilityIdentifier("wifi_warning_overlay")
        }
    }
}
