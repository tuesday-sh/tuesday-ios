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
        let activeSite = networks.first(where: { $0.id == activeNetworkId }) ?? networks.first
        let gatedForNewSite = EntitlementGatePolicy.requiresUpgradeForNewSite(tier: entitlementTier, networks: networks)

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if let activeSite {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("CURRENT SITE")
                                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                                .foregroundColor(palette.textMuted)
                            HStack {
                                Text("\(activeSite.emoji) \(activeSite.name)")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(palette.textPrimary)
                                Spacer()
                                MonospaceBadge(text: "\(activeSite.devicesCount) devices", color: palette.accentText)
                            }
                            Button(action: onOpenNetworkSettings) {
                                Text("Rename or Configure Current Site →")
                                    .font(.system(size: 12.5, weight: .bold))
                                    .foregroundColor(palette.accentText)
                            }
                            .buttonStyle(.plain)
                            .uiAction("openNetworkSettings")
                        }
                        .padding(12)
                        .background(palette.surface)
                        .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard))
                        .overlay(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard).stroke(palette.border, lineWidth: 1))
                        .uiSlot("current-network-widget")
                    }

                    SurfaceListContainer(palette: palette) {
                        ForEach(Array(networks.enumerated()), id: \.element.id) { idx, site in
                            if idx > 0 { SurfaceListDivider(palette: palette) }
                            TuesdayListRow(
                                palette: palette,
                                title: "\(site.emoji) \(site.name)",
                                onClick: {
                                    onSelectNetwork(site.id)
                                    onDismiss()
                                },
                                leading: {
                                    Image(systemName: site.id == activeNetworkId ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(site.id == activeNetworkId ? palette.accent : palette.textMuted)
                                        .uiAction("selectNetwork")
                                },
                                subtitle: {
                                    Text("\(site.role) • \(site.devicesCount) device(s)")
                                        .font(.system(size: 11.5))
                                        .foregroundColor(palette.textMuted)
                                }
                            )
                        }
                    }
                    .uiSlot("available-networks-list")
                    .uiSlot("network-picker-list")

                    VStack(alignment: .leading, spacing: 10) {
                        Text(gatedForNewSite ? "ADD SECOND SITE (PRO TIER 1)" : "ADD ADDITIONAL SITE")
                            .font(.system(size: 11, weight: .heavy, design: .monospaced))
                            .foregroundColor(palette.textMuted)

                        if gatedForNewSite {
                            Text("Free includes 1 primary site. Upgrade to Pro Tier 1 to manage multiple family homes, vacation cabins, or lab sites.")
                                .font(.system(size: 12.5))
                                .foregroundColor(palette.textMuted)
                                .lineSpacing(3)

                            Button(action: onOpenUpgrade) {
                                Text("Unlock Multi-Site with Pro Tier 1")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, minHeight: 44)
                                    .background(palette.accent)
                                    .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
                            }
                            .buttonStyle(.plain)
                            .uiAction("openSetupNetworkModal")
                        } else {
                            TuesdayTextField(text: $newSiteName, label: "New Site Name", placeholder: "e.g. Mom's House", palette: palette)
                            Button(action: {
                                onCreateNetwork(newSiteName)
                                newSiteName = ""
                                onDismiss()
                            }) {
                                Text("Create Site")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, minHeight: 44)
                                    .background(palette.accent)
                                    .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
                            }
                            .buttonStyle(.plain)
                            .disabled(newSiteName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .uiAction("createNetwork")
                        }
                    }
                    .padding(12)
                    .background(palette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard))
                    .overlay(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard).stroke(palette.border, lineWidth: 1))
                }
                .padding(14)
            }
            .background(palette.bg.ignoresSafeArea())
            .navigationTitle("Network Sites")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done", action: onDismiss)
                        .foregroundColor(palette.accentText)
                        .uiAction("closeNetworkPicker")
                }
            }
        }
        .uiComponent("SetupNetworkModal")
        .uiComponent("NetworkPickerModal")
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

            TuesdayModalCard(
                palette: palette,
                title: "Tuesday.sh Pro Tier 1",
                subtitle: "Unlimited physical sites, family site delegation, and priority multi-site cloud backup sync.",
                borderColor: palette.accent.opacity(0.5),
                componentName: "Tier1UpgradeModal",
                closeActionName: "closeTier1UpgradeModal",
                onDismiss: onDismiss,
                leading: {
                    MondayBadgeMark(palette: palette)
                },
                content: {
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
                            Text(storeKitManager.isPurchasing ? "Confirming in App Store..." : "Subscribe Now")
                                .font(.system(size: 15, weight: .bold))
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
            .uiSlot("tier1-upgrade-card")
            .uiComponent("Tier1UpgradeModal")
            .overlay(alignment: .topTrailing) {
                Button("") { onDismiss() }
                    .frame(width: 0, height: 0)
                    .hidden()
                    .uiAction("closeTier1UpgradeModal")
            }
        }
    }
}

private struct MondayBadgeMark: View {
    let palette: BrandPalette
    var body: some View {
        TuesdayCalendarHeartIcon(tint: palette.accent, size: 20)
    }
}
