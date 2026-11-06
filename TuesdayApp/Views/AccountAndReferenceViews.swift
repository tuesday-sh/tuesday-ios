import SwiftUI

public struct AccountSettingsView: View {
    public let flavor: AppBrandFlavor
    public let palette: BrandPalette
    public let networkLocationName: String
    public let activeDeviceCount: Int
    public let isDeveloperMode: Bool
    public let entitlementTier: String
    public let savedCorpusCount: Int
    public let onUpgradeProTier1: () -> Void
    public let onSaveNetworkName: (String) -> Void
    public let onToggleDeveloperMode: (Bool) -> Void
    public let onSetSimulatedDeviceCount: (Int) -> Void
    public let onPurgeGoldenCorpus: () -> Int
    public let onOpenIntakeFlow: () -> Void
    public let onSwitchToFleetTab: () -> Void

    @State private var draftName: String = ""
    @State private var purgeFeedback: String? = nil

    public var body: some View {
        let isStn = (flavor == .sureThingHome)

        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 14) {
                    // Header
                    HStack {
                        Text(isStn ? "Account & Home Settings" : "Account & Network Settings")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(palette.textPrimary)
                        Spacer()
                        Text(isStn ? "Protected" : "STN-Pro")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(TuesdayTheme.ledOkGreen)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(TuesdayTheme.ledOkGreen.opacity(0.14))
                            .cornerRadius(6)
                    }
                    .uiSlot("account-header")

                    // Network / Location Name Field
                    VStack(alignment: .leading, spacing: 6) {
                        Text(isStn ? "HOME / NETWORK NAME" : "NETWORK / LOCATION NAME")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(palette.textMuted)

                        HStack(spacing: 8) {
                            TextField("Network Name", text: $draftName)
                                .textInputAutocapitalization(.words)
                                .autocorrectionDisabled()
                                .font(.system(size: 13))
                                .foregroundColor(palette.textPrimary)
                                .padding(10)
                                .background(palette.bg)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(palette.border, lineWidth: 1)
                                )

                            Button(action: { onSaveNetworkName(draftName) }) {
                                Text("Save")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(palette.accent)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                            .uiAction("saveNetworkName")
                        }

                        Text(
                            isStn
                                ? "Used on your home health dashboard and family safety notifications."
                                : "Displayed in the console header and synced to Quarterly Audit exports."
                        )
                        .font(.system(size: 10.5))
                        .foregroundColor(palette.textMuted)
                    }
                    .uiSlot("location-name-editor")

                    // Profile Summary Box
                    VStack(spacing: 8) {
                        accountSummaryRow(
                            label: isStn ? "Home Location" : "Profile Tier",
                            value: isStn ? networkLocationName : "\(networkLocationName) • STN-Pro",
                            valueColor: palette.textPrimary
                        )
                        accountSummaryRow(
                            label: isStn ? "Protected Devices" : "Tracked Ports",
                            value: isStn ? "\(activeDeviceCount) Protected" : "\(activeDeviceCount) Active (128 Cap)",
                            valueColor: TuesdayTheme.ledOkGreen
                        )
                        accountSummaryRow(
                            label: isStn ? "Protection Status" : "Cloud Sync",
                            value: isStn ? "Active 24/7 Monitoring" : "Connected • Zero-Knowledge",
                            valueColor: TuesdayTheme.ledOkGreen
                        )
                        accountSummaryRow(
                            label: "Entitlement Tier",
                            value: entitlementTier == "pro_tier_1" ? "Pro Tier 1 (<=128 Active)" : "Standard Free Tier",
                            valueColor: entitlementTier == "pro_tier_1" ? TuesdayTheme.ledOkGreen : palette.accent
                        )
                    }
                    .padding(12)
                    .background(palette.bg)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(palette.border, lineWidth: 1)
                    )
                    .uiSlot("account-profile-summary")

                    if !isStn && entitlementTier != "pro_tier_1" {
                        Button(action: onUpgradeProTier1) {
                            Text("⚡ Upgrade to Tuesday Pro Tier 1 (StoreKit 2 • <=128 Ports)")
                                .font(.system(size: 11.5, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(palette.accent)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                        .uiAction("upgradeProTier1")
                    }

                    // Developer Mode Toggle & In-App Inventory State Tester
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 6) {
                                    Text("🛠️ Developer Mode")
                                        .font(.system(size: 12.5, weight: .bold))
                                        .foregroundColor(palette.textPrimary)
                                    Text(isStn ? "LAB" : "INTERNAL")
                                        .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                                        .foregroundColor(palette.accent)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 1)
                                        .background(palette.accent.opacity(0.16))
                                        .cornerRadius(4)
                                }
                                Text(
                                    isStn
                                        ? "Test different household device scales and prototype states."
                                        : "Enables in-app state controls & diagnostic testing tools."
                                )
                                .font(.system(size: 10.5))
                                .foregroundColor(palette.textMuted)
                            }
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { isDeveloperMode },
                                set: { onToggleDeveloperMode($0) }
                            ))
                            .labelsHidden()
                            .tint(palette.accent)
                            .uiAction("toggleDeveloperMode")
                        }

                        if isDeveloperMode {
                            Divider().background(palette.accent.opacity(0.2))

                            Text(isStn ? "SIMULATE HOUSEHOLD SIZE:" : "QUICK STATE SIMULATION:")
                                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                                .foregroundColor(palette.textMuted)

                            HStack(spacing: 8) {
                                devStateSimButton(label: "🔄 Reset (Day 0)", isSelected: activeDeviceCount == 0) {
                                    onSetSimulatedDeviceCount(0)
                                    onSwitchToFleetTab()
                                }
                                devStateSimButton(label: "🌱 Pea (1)", isSelected: activeDeviceCount == 1) {
                                    onSetSimulatedDeviceCount(1)
                                    onSwitchToFleetTab()
                                }
                            }

                            HStack(spacing: 8) {
                                devStateSimButton(label: "🪴 Garden (7)", isSelected: activeDeviceCount == 7) {
                                    onSetSimulatedDeviceCount(7)
                                    onSwitchToFleetTab()
                                }
                                devStateSimButton(label: "🌲 Forest (12)", isSelected: activeDeviceCount == 12) {
                                    onSetSimulatedDeviceCount(12)
                                    onSwitchToFleetTab()
                                }
                            }

                            if !isStn {
                                Button(action: {
                                    onSetSimulatedDeviceCount(12)
                                    onSwitchToFleetTab()
                                }) {
                                    Text("📦 Load Full Pro View Mock")
                                        .font(.system(size: 11.5, weight: .bold))
                                        .foregroundColor(palette.accent)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(palette.accent.opacity(0.18))
                                        .cornerRadius(6)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(palette.accent, lineWidth: 1)
                                        )
                                }
                                .buttonStyle(.plain)
                            }

                            Button(action: {
                                let removed = onPurgeGoldenCorpus()
                                purgeFeedback = "Purged \(removed) capture session(s) & gallery exports"
                            }) {
                                Text(purgeFeedback ?? "🗑️ Purge Golden Corpus Captures (\(savedCorpusCount) Saved)")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(TuesdayTheme.ledCveRed)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(TuesdayTheme.ledCveRed.opacity(0.14))
                                    .cornerRadius(6)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(TuesdayTheme.ledCveRed.opacity(0.55), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                            .uiAction("purgeGoldenCorpus")
                        }
                    }
                    .padding(12)
                    .background(palette.accent.opacity(0.08))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(palette.accent.opacity(0.28), lineWidth: 1)
                    )
                    .uiSlot("developer-mode-card")

                    // Open Camera Intake Flow Button
                    Button(action: onOpenIntakeFlow) {
                        Text(isStn ? "+ Name New Device with Camera" : "+ Open Intake / Camera Clues Flow")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(palette.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(palette.elevated)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(palette.border, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .uiAction("openAddDevice")
                }
                .padding(16)
                .background(palette.surface)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(palette.border, lineWidth: 1)
                )
                .uiComponent("AccountSettingsCard")
            }
            .padding(14)
        }
        .onAppear {
            draftName = networkLocationName
        }
        .onChange(of: networkLocationName) { _, newValue in
            draftName = newValue
        }
    }

    private func accountSummaryRow(label: String, value: String, valueColor: Color) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(palette.textMuted)
            Spacer()
            Text(value)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(valueColor)
        }
    }

    private func devStateSimButton(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 10.5, weight: .bold))
                .foregroundColor(isSelected ? palette.accent : palette.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .padding(.horizontal, 6)
                .background(isSelected ? palette.accent.opacity(0.2) : palette.surface)
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(isSelected ? palette.accent : palette.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .uiAction("setSimulatedDeviceCount")
    }
}

public struct NetworkPickerModalSheet: View {
    public let networks: [NetworkSite]
    public let activeNetworkId: String
    public let palette: BrandPalette
    public let onSelectNetwork: (String) -> Void
    public let onCreateNetwork: (String) -> Void
    public let onDismiss: () -> Void

    @State private var newNetworkName: String = ""

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Text("NETWORKS")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(palette.accent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(palette.accent.opacity(0.14))
                        .cornerRadius(4)
                    Text("Switch Site / Location")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(palette.textPrimary)
                }
                Spacer()
                Button(action: onDismiss) {
                    Text("✕")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(palette.textMuted)
                }
                .buttonStyle(.plain)
                .uiAction("closeNetworkPicker")
            }

            Text("Your account manages multiple physical locations and homelab installations.")
                .font(.system(size: 11.5))
                .foregroundColor(palette.textMuted)

            VStack(spacing: 8) {
                ForEach(networks) { net in
                    let isActive = (net.id == activeNetworkId)
                    Button(action: {
                        onSelectNetwork(net.id)
                        onDismiss()
                    }) {
                        HStack {
                            HStack(spacing: 9) {
                                Circle()
                                    .fill(isActive ? TuesdayTheme.ledOkGreen : palette.textMuted)
                                    .frame(width: 8, height: 8)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(net.name)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(palette.textPrimary)
                                    Text("\(net.role) • \(net.devicesCount) devices")
                                        .font(.system(size: 10))
                                        .foregroundColor(palette.textMuted)
                                }
                            }
                            Spacer()
                            Text(isActive ? "✓ Active" : "Switch →")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(isActive ? TuesdayTheme.ledOkGreen : palette.textMuted)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(isActive ? palette.accent.opacity(0.12) : palette.elevated)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(isActive ? palette.accent : palette.border, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .uiAction("selectNetwork")
                }
            }
            .uiSlot("network-picker-list")

            VStack(alignment: .leading, spacing: 8) {
                Text("+ ADD ANOTHER NETWORK")
                    .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                    .foregroundColor(palette.textMuted)

                HStack(spacing: 8) {
                    TextField("e.g. Vacation Cabin, Office Rack", text: $newNetworkName)
                        .font(.system(size: 11.5))
                        .foregroundColor(palette.textPrimary)
                        .padding(9)
                        .background(palette.surface)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(palette.border, lineWidth: 1)
                        )

                    Button(action: {
                        let trimmed = newNetworkName.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        onCreateNetwork(trimmed)
                        newNetworkName = ""
                        onDismiss()
                    }) {
                        Text("Create")
                            .font(.system(size: 11.5, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .background(palette.accent)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    .uiAction("createNetwork")
                }
            }
            .padding(10)
            .background(palette.bg)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(palette.border, lineWidth: 1)
            )
            .uiSlot("create-network-form")

            Spacer()
        }
        .padding(16)
        .background(palette.surface.ignoresSafeArea())
        .uiComponent("NetworkPickerModal")
    }
}

public struct ReferenceGuideModalSheet: View {
    public let flavor: AppBrandFlavor
    public let palette: BrandPalette
    public let onDismiss: () -> Void

    public var body: some View {
        let isStn = (flavor == .sureThingHome)

        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Text("REFERENCE GUIDE")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(palette.accent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(palette.accent.opacity(0.14))
                        .cornerRadius(4)
                    Text("SureThingNet Standard & Ordinal Spine")
                        .font(.system(size: 11.5, weight: .bold))
                        .foregroundColor(palette.textPrimary)
                }
                Spacer()
                Button(action: onDismiss) {
                    Text("✕")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(palette.textMuted)
                }
                .buttonStyle(.plain)
                .uiAction("closeReferenceGuide")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(palette.bg)

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("SureThingNet Standard Categories (Scale C)")
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundColor(palette.textPrimary)

                    Text("The 8 semantic hardware categories (C1 → C8) that govern our faceplate port strip, inventory classification, and progressive disclosure model.")
                        .font(.system(size: 11.5))
                        .foregroundColor(palette.textMuted)

                    ForEach(StnHardwareCategory.allCases, id: \.code) { cat in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(isStn ? cat.stnLabel : cat.proLabel)
                                    .font(.system(size: 11.5, weight: .bold))
                                    .foregroundColor(palette.textPrimary)
                                Spacer()
                                Text("\(cat.code) • \(cat.osiLayer)")
                                    .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                                    .foregroundColor(palette.accent)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(palette.accent.opacity(0.14))
                                    .cornerRadius(4)
                            }
                            Text(cat.description)
                                .font(.system(size: 10))
                                .foregroundColor(palette.textMuted)
                            Text(cat.examples)
                                .font(.system(size: 8.5, design: .monospaced))
                                .foregroundColor(palette.accent)
                        }
                        .padding(9)
                        .background(palette.elevated)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(palette.border, lineWidth: 1)
                        )
                    }

                    Divider().background(palette.border)

                    Text("📐 Industry-Standard Ordinal Scales (S0→S6 • Z0→Z5 • R1→R3)")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundColor(palette.textPrimary)

                    Text(" 🌐 The OSI 7+1 Layer Reference Model (L1–L8)")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundColor(palette.textPrimary)

                    Button(action: onDismiss) {
                        Text("Done Reading")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(palette.accent)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
            }
        }
        .background(palette.surface.ignoresSafeArea())
        .uiComponent("ReferenceGuideModal")
    }
}
