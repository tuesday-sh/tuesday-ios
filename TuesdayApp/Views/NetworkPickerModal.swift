import SwiftUI

public struct SetupNetworkModalView: View {
    public let palette: BrandPalette
    public let networks: [NetworkSite]
    public let activeNetworkId: String
    public let entitlementTier: String
    public let onSelectNetwork: (String) -> Void
    public let onCreateNetwork: (String) -> Void
    public let onOpenUpgrade: () -> Void
    public let onOpenNetworkSettings: () -> Void
    public let onDismiss: () -> Void

    @State private var showSetupModal: Bool = false
    @State private var setupFlowIndex: Int = 0
    @State private var newSiteName: String = ""

    public init(
        palette: BrandPalette,
        networks: [NetworkSite],
        activeNetworkId: String,
        entitlementTier: String,
        onSelectNetwork: @escaping (String) -> Void,
        onCreateNetwork: @escaping (String) -> Void,
        onOpenUpgrade: @escaping () -> Void,
        onOpenNetworkSettings: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.palette = palette
        self.networks = networks
        self.activeNetworkId = activeNetworkId
        self.entitlementTier = entitlementTier
        self.onSelectNetwork = onSelectNetwork
        self.onCreateNetwork = onCreateNetwork
        self.onOpenUpgrade = onOpenUpgrade
        self.onOpenNetworkSettings = onOpenNetworkSettings
        self.onDismiss = onDismiss
    }

    public var body: some View {
        if showSetupModal {
            setupNetworkContent
                .uiComponent("SetupNetworkModal")
        } else {
            networkPickerContent
                .uiComponent("NetworkPickerModal")
        }
    }

    private var networkPickerContent: some View {
        let activeSite = networks.first(where: { $0.id == activeNetworkId }) ?? networks.first
        let availableNetworks = networks.filter { $0.id != activeNetworkId }
        let canAddNetwork = EntitlementGatePolicy.canCreateAdditionalNetwork(tier: entitlementTier, networks: networks)

        return NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if let activeSite {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(TuesdayTheme.ledOkGreen)
                                        .frame(width: 8, height: 8)
                                    Text("CURRENT NETWORK")
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .tracking(0.5)
                                        .foregroundColor(palette.accentText)
                                }
                                Spacer()
                                Button(action: onOpenNetworkSettings) {
                                    Image(systemName: "gearshape.fill")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(palette.textPrimary)
                                        .frame(width: TuesdayDimens.hitTargetCompact, height: TuesdayDimens.hitTargetCompact)
                                }
                                .buttonStyle(.plain)
                                .uiAction("openNetworkSettings")
                            }

                            HStack(alignment: .bottom) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(activeSite.name.isEmpty ? "My Network" : activeSite.name)
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(palette.textPrimary)
                                    Text(activeSite.role)
                                        .font(.system(size: 12))
                                        .foregroundColor(palette.textMuted)
                                }
                                Spacer()
                                MonospaceBadge(text: "\(activeSite.devicesCount) devices", color: palette.textPrimary)
                            }
                        }
                        .padding(14)
                        .background(palette.accent.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusModalCard))
                        .overlay(
                            RoundedRectangle(cornerRadius: TuesdayDimens.radiusModalCard)
                                .stroke(palette.accent.opacity(0.6), lineWidth: 1)
                        )
                        .uiSlot("current-network-widget")
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        if !availableNetworks.isEmpty {
                            Text("SWITCH TO NETWORK")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .tracking(0.5)
                                .foregroundColor(palette.textMuted)

                            ForEach(availableNetworks) { site in
                                Button(action: {
                                    onSelectNetwork(site.id)
                                    onDismiss()
                                }) {
                                    HStack {
                                        HStack(spacing: 10) {
                                            Circle()
                                                .fill(palette.textMuted.opacity(0.5))
                                                .frame(width: 7, height: 7)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(site.name.isEmpty ? "My Network" : site.name)
                                                    .font(.system(size: 13, weight: .semibold))
                                                    .foregroundColor(palette.textPrimary)
                                                Text("\(site.role) • \(site.devicesCount) devices")
                                                    .font(.system(size: 11))
                                                    .foregroundColor(palette.textMuted)
                                            }
                                        }
                                        Spacer()
                                        HStack(spacing: 4) {
                                            Text("Switch")
                                                .font(.system(size: 11.5, weight: .bold))
                                                .foregroundColor(palette.accentText)
                                            Image(systemName: "arrow.right")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(palette.accentText)
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(palette.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard)
                                            .stroke(palette.border, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                                .uiAction("selectNetwork")
                            }
                        }
                    }
                    .uiSlot("available-networks-list")

                    Button(action: {
                        if canAddNetwork {
                            showSetupModal = true
                        } else {
                            onOpenUpgrade()
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .bold))
                            Text(canAddNetwork ? "Add a network" : "Add a network (Multi-Site)")
                                .font(.system(size: 13.5, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(palette.accent)
                        .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard))
                    }
                    .buttonStyle(.plain)
                    .uiAction("openSetupNetworkModal")
                }
                .padding(14)
            }
            .background(palette.bg.ignoresSafeArea())
            .navigationTitle("Networks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done", action: onDismiss)
                        .foregroundColor(palette.accentText)
                        .uiAction("closeNetworkPicker")
                }
            }
        }
    }

    private var setupNetworkContent: some View {
        let trimmedName = newSiteName.trimmingCharacters(in: .whitespacesAndNewlines)
        return NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    SegmentedTabRow(
                        options: ["New", "Join"],
                        selectedIndex: setupFlowIndex,
                        onSelect: { setupFlowIndex = $0 },
                        palette: palette,
                        actionName: "switchSetupFlow"
                    )

                    if setupFlowIndex == 0 {
                        Text("Create a new isolated site or installation profile for your hardware rack.")
                            .font(.system(size: 12.5))
                            .foregroundColor(palette.textMuted)
                            .lineSpacing(3)

                        TuesdayTextField(
                            text: $newSiteName,
                            label: "Network Name",
                            placeholder: "e.g. Vacation Cabin, Office Rack",
                            palette: palette
                        )

                        Button(action: {
                            guard !trimmedName.isEmpty else { return }
                            onCreateNetwork(trimmedName)
                            newSiteName = ""
                            showSetupModal = false
                            onDismiss()
                        }) {
                            Text("Create Network & Join")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(trimmedName.isEmpty ? palette.borderStrong : palette.accent)
                                .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard))
                        }
                        .buttonStyle(.plain)
                        .disabled(trimmedName.isEmpty)
                    } else {
                        VStack(spacing: 8) {
                            Text("Import an Existing Network")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(palette.textPrimary)
                            Text("To load a network inventory exported from another device, open Account → Backup & Restore and import a saved JSON backup file.")
                                .font(.system(size: 12))
                                .foregroundColor(palette.textMuted)
                                .lineSpacing(3)
                                .multilineTextAlignment(.center)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity)
                        .background(palette.surface)
                        .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard))
                        .overlay(
                            RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard)
                                .stroke(palette.border, lineWidth: 1)
                        )
                    }
                }
                .padding(14)
            }
            .background(palette.bg.ignoresSafeArea())
            .navigationTitle("Setup a network")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Back") { showSetupModal = false }
                        .foregroundColor(palette.accentText)
                }
            }
        }
    }
}

public struct Tier1UpgradeModalView: View {
    public let palette: BrandPalette
    @ObservedObject public var storeKitManager: TuesdayStoreKitManager
    public let onDismiss: () -> Void

    public init(
        palette: BrandPalette,
        storeKitManager: TuesdayStoreKitManager,
        onDismiss: @escaping () -> Void
    ) {
        self.palette = palette
        self.storeKitManager = storeKitManager
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            VStack(spacing: 0) {
                TuesdayModalCard(
                    palette: palette,
                    title: "Tuesday.sh Pro — Founding Member",
                    subtitle: "Built at SURF Incubator in Seattle. Free includes 1 primary site, 15 devices, and 15 AI photo scans. Lock in Founding Member pricing for the full Tier 1 suite:",
                    borderColor: palette.accent.opacity(0.6),
                    componentName: "TuesdayModalCard",
                    closeActionName: "closeTier1UpgradeModal",
                    onDismiss: onDismiss,
                    leading: {
                        MondayBadgeMark(palette: palette)
                    },
                    content: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("✓ Up to 128 devices/site & unlimited network locations")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(palette.textPrimary)
                            Text("✓ Unlimited AI photo hardware identification (15 free)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(palette.textPrimary)
                            Text("✓ Printable PDF, CSV & Markdown rack dossier exports")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(palette.textPrimary)
                            Text("✓ Multi-year EOL forecast, audit log & Ask Claude briefs")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(palette.textPrimary)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(palette.elevated)
                        .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard))
                        .overlay(
                            RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard)
                                .stroke(palette.border, lineWidth: 1)
                        )
                        .uiSlot("tier1-upgrade-card")

                        PlanOfferSelector(
                            plans: storeKitManager.plans,
                            selectedProductId: storeKitManager.selectedProductId,
                            palette: palette,
                            onSelectPlan: { storeKitManager.selectPlan($0) }
                        )

                        Button(action: {
                            Task {
                                let ok = await storeKitManager.purchase(productId: storeKitManager.selectedProductId)
                                if ok { onDismiss() }
                            }
                        }) {
                            HStack {
                                if storeKitManager.isPurchasing {
                                    ProgressView().tint(.white)
                                }
                                Text(storeKitManager.isPurchasing ? "Confirming in App Store..." : "Upgrade & Continue")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity, minHeight: 46)
                            .background(palette.accent)
                            .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
                        }
                        .buttonStyle(.plain)
                        .disabled(storeKitManager.isPurchasing || storeKitManager.isRestoring)
                        .uiAction("confirmTier1Upgrade")

                        Button(action: {
                            Task { await storeKitManager.restorePurchases() }
                        }) {
                            Text(storeKitManager.isRestoring ? "Restoring..." : "Restore Purchases")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(palette.accentText)
                                .frame(maxWidth: .infinity, minHeight: 36)
                        }
                        .buttonStyle(.plain)
                        .disabled(storeKitManager.isPurchasing || storeKitManager.isRestoring)
                        .uiAction("restorePurchases")

                        if let status = storeKitManager.statusMessage, !status.isEmpty {
                            Text(status)
                                .font(.system(size: 11.5, design: .monospaced))
                                .foregroundColor(palette.textPrimary)
                        }

                        SubscriptionLegalDisclosure(palette: palette)
                    }
                )
            }
            .uiComponent("Tier1UpgradeModal")
        }
    }
}

private struct MondayBadgeMark: View {
    let palette: BrandPalette
    var body: some View {
        TuesdayCalendarHeartIcon(tint: palette.accent, size: 20)
    }
}
