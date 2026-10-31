import SwiftUI

public struct HacsPairingSheet: View {
    @ObservedObject var repository: MockHacsTuesdayService
    @ObservedObject var networkMonitor: NetworkMonitorService
    @Environment(\.dismiss) private var dismiss

    @State private var instanceName: String = ""
    @State private var baseUrl: String = ""
    @State private var apiToken: String = ""
    @State private var requireLocalWifi: Bool = false
    @State private var isConnected: Bool = true
    @State private var showScannedBanner: Bool = false

    public init(
        repository: MockHacsTuesdayService,
        networkMonitor: NetworkMonitorService
    ) {
        self.repository = repository
        self.networkMonitor = networkMonitor
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                TuesdayTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        headerBanner

                        if showScannedBanner {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(TuesdayTheme.healthyGreen)
                                Text("Paired with Home Assistant HACS QR payload")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(TuesdayTheme.healthyGreen.opacity(0.16))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }

                        formField(
                            label: "INSTANCE NAME",
                            text: $instanceName,
                            placeholder: "Home Assistant (HACS)",
                            identifier: "hacs_instance_name_field"
                        )

                        formField(
                            label: "HOME ASSISTANT / TUESDAY SERVER URL",
                            text: $baseUrl,
                            placeholder: "http://homeassistant.local:8123",
                            identifier: "hacs_base_url_field"
                        )

                        formField(
                            label: "HACS / TUESDAY API TOKEN",
                            text: $apiToken,
                            placeholder: "tuesday_hacs_live_...",
                            identifier: "hacs_api_token_field"
                        )

                        Button {
                            instanceName = "Home Assistant OS (lml HACS)"
                            baseUrl = "http://homeassistant.local:8123/api/tuesday"
                            apiToken = "tuesday_hacs_qr_\(Int.random(in: 1000...9999))"
                            isConnected = true
                            showScannedBanner = true
                        } label: {
                            HStack {
                                Image(systemName: "qrcode.viewfinder")
                                    .font(.system(size: 16, weight: .bold))
                                Text("Scan Home Assistant HACS Pairing QR")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .foregroundStyle(TuesdayTheme.hacsCyan)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(TuesdayTheme.hacsCyan.opacity(0.14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(TuesdayTheme.hacsCyan.opacity(0.45), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .accessibilityIdentifier("hacs_scan_qr_button")

                        VStack(spacing: 14) {
                            Toggle(isOn: $requireLocalWifi) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Require Local Wi-Fi (LAN Guard)")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.white)
                                    Text("Blocks dashboard with Wi-Fi overlay if disconnected from LAN")
                                        .font(.system(size: 11))
                                        .foregroundStyle(Color(white: 0.65))
                                }
                            }
                            .tint(TuesdayTheme.healthyGreen)
                            .accessibilityIdentifier("hacs_require_wifi_toggle")

                            Divider().background(Color.white.opacity(0.12))

                            Toggle(isOn: $networkMonitor.simulateWifiDisconnected) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Simulate Wi-Fi Disconnected")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.white)
                                    Text("Test the SureThingNet Wi-Fi warning overlay on Simulator")
                                        .font(.system(size: 11))
                                        .foregroundStyle(Color(white: 0.65))
                                }
                            }
                            .tint(TuesdayTheme.warningAmber)
                            .accessibilityIdentifier("hacs_simulate_wifi_off_toggle")
                        }
                        .padding(16)
                        .background(TuesdayTheme.cardSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        Button {
                            var updated = repository.hacsConfig
                            updated.instanceName = instanceName.trimmingCharacters(in: .whitespacesAndNewlines)
                            updated.baseUrl = baseUrl.trimmingCharacters(in: .whitespacesAndNewlines)
                            updated.apiToken = apiToken.trimmingCharacters(in: .whitespacesAndNewlines)
                            updated.requireLocalWifi = requireLocalWifi
                            updated.isConnected = isConnected
                            updated.lastSyncedAt = Date()
                            repository.updateHacsConfig(updated)
                            dismiss()
                        } label: {
                            Text("Save HACS Integration Settings")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(TuesdayTheme.healthyGreen)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .accessibilityIdentifier("hacs_save_button")

                        Button {
                            repository.resetDemoData()
                            networkMonitor.simulateWifiDisconnected = false
                            dismiss()
                        } label: {
                            Text("Reset Demo Fleet Data")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color(white: 0.72))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                        }
                        .accessibilityIdentifier("hacs_reset_demo_button")
                    }
                    .padding(20)
                }
            }
            .navigationTitle("HACS Integration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundStyle(Color(white: 0.78))
                    .accessibilityIdentifier("hacs_close_button")
                }
            }
            .onAppear {
                instanceName = repository.hacsConfig.instanceName
                baseUrl = repository.hacsConfig.baseUrl
                apiToken = repository.hacsConfig.apiToken
                requireLocalWifi = repository.hacsConfig.requireLocalWifi
                isConnected = repository.hacsConfig.isConnected
            }
        }
        .preferredColorScheme(.dark)
    }

    private var headerBanner: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(TuesdayTheme.hacsCyan.opacity(0.18))
                    .frame(width: 48, height: 48)
                Image(systemName: "house.and.flag.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(TuesdayTheme.hacsCyan)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Tuesday.sh HACS Bridge")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                Text("Component v\(repository.hacsConfig.hacsComponentVersion) • Server v\(repository.hacsConfig.tuesdayServerVersion)")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(TuesdayTheme.hacsCyan)
            }
            Spacer()
        }
        .padding(16)
        .background(TuesdayTheme.cardSurface)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(TuesdayTheme.hacsCyan.opacity(0.35), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func formField(
        label: String,
        text: Binding<String>,
        placeholder: String,
        identifier: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color(white: 0.65))
                .tracking(0.5)

            TextField(placeholder, text: text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.system(size: 14, design: .monospaced))
                .foregroundStyle(.white)
                .padding(14)
                .background(TuesdayTheme.cardSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .accessibilityIdentifier(identifier)
        }
    }
}
