import SwiftUI

public struct AccountSettingsView: View {
    public let flavor: AppBrandFlavor
    public let palette: BrandPalette
    public let networkLocationName: String
    public let activeDeviceCount: Int
    public let isDeveloperMode: Bool
    public let entitlementTier: String
    public let savedCorpusCount: Int
    public let matchedFeeds: [MatchedFeedView]
    public let onToggleMuteFeed: (String) -> Void
    public let onUpgradeProTier1: () -> Void
    public let onSaveNetworkName: (String) -> Void
    public let onToggleDeveloperMode: (Bool) -> Void
    public let onSetSimulatedDeviceCount: (Int) -> Void
    public let onPurgeGoldenCorpus: () -> Int
    public let onOpenIntakeFlow: () -> Void
    public let onSwitchToFleetTab: () -> Void

    @State private var draftName: String = ""
    @State private var purgeFeedback: String? = nil

    // Accordion Expansion States
    @State private var isNetworkOpen: Bool = false
    @State private var isDevModeOpen: Bool = false
    @State private var isRemindersOpen: Bool = false
    @State private var isFeedsOpen: Bool = false

    // Reminders state
    @State private var reminderHighSeverity: Bool = false
    @State private var reminderMonthlyRhythm: Bool = true
    @State private var reminderQuarterlyCheckup: Bool = true
    @State private var reminderRoutineFirmware: Bool = true
    @State private var reminderLifecycleEol: Bool = true

    public init(
        flavor: AppBrandFlavor,
        palette: BrandPalette,
        networkLocationName: String,
        activeDeviceCount: Int,
        isDeveloperMode: Bool,
        entitlementTier: String,
        savedCorpusCount: Int,
        matchedFeeds: [MatchedFeedView] = [],
        onToggleMuteFeed: @escaping (String) -> Void = { _ in },
        onUpgradeProTier1: @escaping () -> Void,
        onSaveNetworkName: @escaping (String) -> Void,
        onToggleDeveloperMode: @escaping (Bool) -> Void,
        onSetSimulatedDeviceCount: @escaping (Int) -> Void,
        onPurgeGoldenCorpus: @escaping () -> Int,
        onOpenIntakeFlow: @escaping () -> Void = {},
        onSwitchToFleetTab: @escaping () -> Void
    ) {
        self.flavor = flavor
        self.palette = palette
        self.networkLocationName = networkLocationName
        self.activeDeviceCount = activeDeviceCount
        self.isDeveloperMode = isDeveloperMode
        self.entitlementTier = entitlementTier
        self.savedCorpusCount = savedCorpusCount
        self.matchedFeeds = matchedFeeds
        self.onToggleMuteFeed = onToggleMuteFeed
        self.onUpgradeProTier1 = onUpgradeProTier1
        self.onSaveNetworkName = onSaveNetworkName
        self.onToggleDeveloperMode = onToggleDeveloperMode
        self.onSetSimulatedDeviceCount = onSetSimulatedDeviceCount
        self.onPurgeGoldenCorpus = onPurgeGoldenCorpus
        self.onOpenIntakeFlow = onOpenIntakeFlow
        self.onSwitchToFleetTab = onSwitchToFleetTab
    }

    private var activeRemindersCount: Int {
        [reminderHighSeverity, reminderMonthlyRhythm, reminderQuarterlyCheckup, reminderRoutineFirmware, reminderLifecycleEol].filter { $0 }.count
    }

    private var activeFeedsCount: Int {
        matchedFeeds.filter { !$0.isMuted }.count
    }

    private var mutedFeedsCount: Int {
        matchedFeeds.filter { $0.isMuted }.count
    }

    public var body: some View {
        let isStn = (flavor == .sureThingHome)

        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 10) {
                    // Header (Unboxed)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Settings & Preferences")
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundColor(palette.textPrimary)
                        Text("Configure network profiles, alert reminder preferences, matched firmware feeds, and developer diagnostics.")
                            .font(.system(size: 12))
                            .foregroundColor(palette.textMuted)
                            .lineSpacing(2)
                    }
                    .padding(.vertical, 4)
                    .uiSlot("account-header")

                    // UNBOXED ACCORDION LIST
                    VStack(spacing: 0) {
                        // 1. Network
                        VStack(spacing: 0) {
                            Button(action: { isNetworkOpen.toggle() }) {
                                HStack(spacing: 10) {
                                    Text("🌐")
                                        .font(.system(size: 16))
                                    Text("Network")
                                        .font(.system(size: 13.5, weight: .bold))
                                        .foregroundColor(palette.textPrimary)
                                    if !networkLocationName.isEmpty {
                                        Text(networkLocationName)
                                            .font(.system(size: 11, design: .monospaced))
                                            .foregroundColor(palette.accent)
                                    }
                                    Spacer()
                                    Text(isNetworkOpen ? "▾" : "›")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(palette.textMuted)
                                }
                                .padding(.vertical, 14)
                                .padding(.horizontal, 4)
                            }
                            .buttonStyle(.plain)

                            if isNetworkOpen {
                                VStack(alignment: .leading, spacing: 10) {
                                    // Retained slot for parity contract
                                    EmptyView()
                                        .uiSlot("account-profile-summary")

                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(isStn ? "HOME NETWORK NAME" : "LOCATION / NETWORK NAME")
                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                            .foregroundColor(palette.textMuted)

                                        HStack(spacing: 8) {
                                            TextField(
                                                isStn ? "e.g. Our House, Main Home Wi-Fi" : "e.g. Primary Homelab, Main Rack",
                                                text: $draftName
                                            )
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
                                    }
                                    .uiSlot("location-name-editor")
                                }
                                .padding(.horizontal, 4)
                                .padding(.bottom, 16)
                            }
                            Divider().background(palette.border.opacity(0.5))
                        }

                        // 2. Developer Mode
                        VStack(spacing: 0) {
                            Button(action: { isDevModeOpen.toggle() }) {
                                HStack(spacing: 10) {
                                    Text("🛠️")
                                        .font(.system(size: 16))
                                    Text("Developer Mode")
                                        .font(.system(size: 13.5, weight: .bold))
                                        .foregroundColor(palette.textPrimary)
                                    Spacer()
                                    Text(isDevModeOpen ? "▾" : "›")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(palette.textMuted)
                                }
                                .padding(.vertical, 14)
                                .padding(.horizontal, 4)
                            }
                            .buttonStyle(.plain)

                            if isDevModeOpen {
                                VStack(alignment: .leading, spacing: 10) {
                                    VStack(alignment: .leading, spacing: 10) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(isStn ? "Household Scale Tester" : "State Simulator")
                                                    .font(.system(size: 12, weight: .bold))
                                                    .foregroundColor(palette.textPrimary)
                                                Text(isStn ? "Test different household device scales and prototype states." : "Enables in-app state controls & diagnostic testing tools.")
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

                                            Text("INVENTORY SEEDS:")
                                                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                                                .foregroundColor(palette.textMuted)

                                            HStack(spacing: 8) {
                                                devStateSimButton(label: "🔄 Reset (0)", isSelected: activeDeviceCount == 0) {
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

                                            Button(action: {
                                                let removed = onPurgeGoldenCorpus()
                                                purgeFeedback = "Purged \(removed) capture session(s)"
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
                                    .background(palette.accent.opacity(0.06))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(palette.accent.opacity(0.22), lineWidth: 1)
                                    )
                                    .uiSlot("developer-mode-card")
                                }
                                .padding(.horizontal, 4)
                                .padding(.bottom, 16)
                            }
                            Divider().background(palette.border.opacity(0.5))
                        }

                        // 3. Reminders
                        VStack(spacing: 0) {
                            Button(action: { isRemindersOpen.toggle() }) {
                                HStack(spacing: 10) {
                                    Text("🔔")
                                        .font(.system(size: 16))
                                    Text("Reminders")
                                        .font(.system(size: 13.5, weight: .bold))
                                        .foregroundColor(palette.textPrimary)
                                    Text("\(activeRemindersCount) of 5 Active")
                                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                        .foregroundColor(TuesdayTheme.ledOkGreen)
                                    Spacer()
                                    Text(isRemindersOpen ? "▾" : "›")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(palette.textMuted)
                                }
                                .padding(.vertical, 14)
                                .padding(.horizontal, 4)
                            }
                            .buttonStyle(.plain)

                            if isRemindersOpen {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(
                                        isStn
                                            ? "Choose which notifications ring your phone. Turning off a reminder keeps security bulletins visible inside the app without noisy alerts."
                                            : "Configure generalized notification channels. Disabling a category stops push alerts while preserving in-app inbox items."
                                    )
                                    .font(.system(size: 11.5))
                                    .foregroundColor(palette.textMuted)
                                    .lineSpacing(2)

                                    reminderToggleRow(
                                        title: "High Severity Alerts (CVEs & Recalls)",
                                        desc: "Critical vulnerabilities, active CISA KEV disclosures, and physical recalls. (In-app always if disabled).",
                                        isCritical: true,
                                        isOn: $reminderHighSeverity
                                    )
                                    reminderToggleRow(
                                        title: "Monthly Rhythm (Patch Tuesday)",
                                        desc: "Prep checklists and release day drop digests scheduled for the second Tuesday of each month.",
                                        isCritical: false,
                                        isOn: $reminderMonthlyRhythm
                                    )
                                    reminderToggleRow(
                                        title: "Quarterly Physical Audit & Checkup",
                                        desc: "Quarterly reminders to inspect physical patch cabling, port labels, and admin credential hygiene.",
                                        isCritical: false,
                                        isOn: $reminderQuarterlyCheckup
                                    )
                                    reminderToggleRow(
                                        title: "Routine Firmware & Maintenance",
                                        desc: "General manufacturer software improvements, minor patches, and feature updates.",
                                        isCritical: false,
                                        isOn: $reminderRoutineFirmware
                                    )
                                    reminderToggleRow(
                                        title: "Lifespan & Hardware Retirement (EOL)",
                                        desc: "Early warning notices before vendor security support and firmware patch commitments expire.",
                                        isCritical: false,
                                        isOn: $reminderLifecycleEol
                                    )
                                }
                                .padding(.horizontal, 4)
                                .padding(.bottom, 16)
                            }
                            Divider().background(palette.border.opacity(0.5))
                        }

                        // 4. Feeds
                        VStack(spacing: 0) {
                            Button(action: { isFeedsOpen.toggle() }) {
                                HStack(spacing: 10) {
                                    Text("📡")
                                        .font(.system(size: 16))
                                    Text("Feeds")
                                        .font(.system(size: 13.5, weight: .bold))
                                        .foregroundColor(palette.textPrimary)
                                    Text("\(activeFeedsCount) Active • \(mutedFeedsCount) Muted")
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(palette.textMuted)
                                    Spacer()
                                    Text(isFeedsOpen ? "▾" : "›")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(palette.textMuted)
                                }
                                .padding(.vertical, 14)
                                .padding(.horizontal, 4)
                            }
                            .buttonStyle(.plain)

                            if isFeedsOpen {
                                VStack(alignment: .leading, spacing: 8) {
                                    // High Severity Guardrail Box
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("⚠️ High Severity Guardrail Policy")
                                            .font(.system(size: 11.5, weight: .bold))
                                            .foregroundColor(TuesdayTheme.ledCveRed)
                                        Text("High Severity bulletins (CISA KEV disclosures and physical recalls) cannot be muted. You can snooze them or disable push reminders so they only show in-app.")
                                            .font(.system(size: 11))
                                            .foregroundColor(palette.textMuted)
                                            .lineSpacing(2)
                                    }
                                    .padding(10)
                                    .background(TuesdayTheme.ledCveRed.opacity(0.08))
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(TuesdayTheme.ledCveRed.opacity(0.3), lineWidth: 1)
                                    )

                                    Text(isStn ? "MATCHED HOME DEVICE FEEDS:" : "MATCHED HARDWARE FEEDS:")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .foregroundColor(palette.textMuted)

                                    if matchedFeeds.isEmpty {
                                        Text("No feeds matched yet. Add devices to activate security feeds.")
                                            .font(.system(size: 11))
                                            .foregroundColor(palette.textMuted)
                                            .padding(.vertical, 4)
                                    } else {
                                        ForEach(matchedFeeds) { feed in
                                            HStack {
                                                VStack(alignment: .leading, spacing: 2) {
                                                    HStack(spacing: 6) {
                                                        Text(feed.isMuted ? "🔕" : "📡")
                                                            .font(.system(size: 11))
                                                        Text(feed.name)
                                                            .font(.system(size: 11.5, weight: .bold))
                                                            .foregroundColor(palette.textPrimary)
                                                    }
                                                    Text(feed.matchedPorts.joined(separator: ", "))
                                                        .font(.system(size: 10, design: .monospaced))
                                                        .foregroundColor(palette.textMuted)
                                                }
                                                Spacer()
                                                Button(action: { onToggleMuteFeed(feed.slug) }) {
                                                    Text(feed.isMuted ? "Muted" : "Mute")
                                                        .font(.system(size: 10.5, weight: .bold))
                                                        .foregroundColor(feed.isMuted ? palette.textPrimary : palette.accent)
                                                        .padding(.horizontal, 10)
                                                        .padding(.vertical, 4)
                                                        .background(feed.isMuted ? palette.border : palette.elevated)
                                                        .cornerRadius(6)
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 6)
                                                                .stroke(feed.isMuted ? palette.textMuted : palette.accent, lineWidth: 1)
                                                        )
                                                }
                                                .buttonStyle(.plain)
                                            }
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 8)
                                            .background(palette.elevated)
                                            .cornerRadius(6)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .stroke(palette.border, lineWidth: 1)
                                            )
                                        }
                                    }
                                }
                                .padding(.horizontal, 4)
                                .padding(.bottom, 16)
                            }
                            Divider().background(palette.border.opacity(0.5))
                        }
                    }
                }
                .padding(.vertical, 4)
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

    private func reminderToggleRow(
        title: String,
        desc: String,
        isCritical: Bool,
        isOn: Binding<Bool>
    ) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(palette.textPrimary)
                    if isCritical {
                        Text("IN-APP ALWAYS")
                            .font(.system(size: 8.5, weight: .bold))
                            .foregroundColor(TuesdayTheme.ledCveRed)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(TuesdayTheme.ledCveRed.opacity(0.14))
                            .cornerRadius(4)
                    }
                }
                Text(desc)
                    .font(.system(size: 10.5))
                    .foregroundColor(palette.textMuted)
                    .lineSpacing(2)
            }
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(TuesdayTheme.ledOkGreen)
        }
        .padding(10)
        .background(palette.elevated)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(palette.border, lineWidth: 1)
        )
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
