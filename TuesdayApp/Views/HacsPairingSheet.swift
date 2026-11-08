import SwiftUI

public struct HacsPairingSheet: View {
    @ObservedObject var repository: MockHacsTuesdayService
    @ObservedObject var networkMonitor: NetworkMonitorService
    @Environment(\.dismiss) private var dismiss

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

                        VStack(spacing: 12) {
                            Text("Home Assistant sync coming soon.")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)

                            Text("Native integration for Home Assistant and HACS is currently in development.")
                                .font(.system(size: 13))
                                .foregroundStyle(Color(white: 0.65))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 36)
                        .padding(.horizontal, 20)
                        .background(TuesdayTheme.cardSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        Button {
                            dismiss()
                        } label: {
                            Text("Close")
                                .font(.system(size: 15, weight: .bold))
                                .uiAction("saveHacsConfig")
                                .foregroundStyle(TuesdayTheme.hacsCyan)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(TuesdayTheme.hacsCyan.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .accessibilityIdentifier("hacs_close_action_button")
                    }
                    .padding(20)
                }
                .uiComponent("HacsSettingsSheet")
            }
            .navigationTitle("Home Assistant Integration")
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
                Text("Home Assistant Integration")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                Text("Tuesday.sh Bridge")
                    .font(.system(size: 12))
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
        .uiSlot("hacs-bridge-header")
    }
}
