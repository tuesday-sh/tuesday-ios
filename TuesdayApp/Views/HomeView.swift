import SwiftUI

public enum MainNavigationTab: String, CaseIterable, Identifiable {
    case status
    case bulletins
    case timeline
    case checkup
    case account

    public var id: String { rawValue }

    public func label(for flavor: AppBrandFlavor) -> String {
        switch (self, flavor) {
        case (.status, .tuesdayPro): return "My Net"
        case (.status, .sureThingHome): return "Home Grid"
        case (.bulletins, _): return "Bulletins"
        case (.timeline, .tuesdayPro): return "Timeline"
        case (.timeline, .sureThingHome): return "Lifespan"
        case (.checkup, _): return "Check-Up"
        case (.account, _): return "Settings"
        }
    }

    public var systemIcon: String {
        switch self {
        case .status: return "square.grid.2x2.fill"
        case .bulletins: return "bell.badge.fill"
        case .timeline: return "chart.bar.xaxis"
        case .checkup: return "checkmark.shield.fill"
        case .account: return "gearshape.fill"
        }
    }
}

public struct HomeView: View {
    @ObservedObject var repository: MockHacsTuesdayService
    @ObservedObject var networkMonitor: NetworkMonitorService
    var notificationManager: TuesdayNotificationManager?
    var storeKitManager: TuesdayStoreKitManager?
    @Binding var pendingDeepLink: DeepLinkDestination?
    @State private var showNotificationPrimer = false
    @State private var primerDeviceName: String? = nil

    public init(
        repository: MockHacsTuesdayService,
        networkMonitor: NetworkMonitorService,
        notificationManager: TuesdayNotificationManager? = nil,
        storeKitManager: TuesdayStoreKitManager? = nil,
        pendingDeepLink: Binding<DeepLinkDestination?> = .constant(nil)
    ) {
        self.repository = repository
        self.networkMonitor = networkMonitor
        self.notificationManager = notificationManager
        self.storeKitManager = storeKitManager
        self._pendingDeepLink = pendingDeepLink
    }

    @State private var activeTab: MainNavigationTab = .status
    @State private var inspectedDevice: RackPortDevice? = nil
    @State private var editingDevice: RackPortDevice? = nil
    @State private var showingHacsSheet = false
    private struct AddDeviceSheetRequest: Identifiable {
        let id = UUID()
        let mode: String?
        let synth: String?
        let query: String?
        let clues: String?
        let autoSearch: Bool
    }

    @State private var addDeviceRequest: AddDeviceSheetRequest? = nil

    @State private var showingNetworkPicker = false
    @State private var showingTier1Upgrade = false
    @State private var showingReferenceGuide = false
    @State private var showingProComingSoonModal = false
    @State private var timelineInitialModal: String? = nil

    @State private var settingsExpandNetwork = false
    @State private var settingsExpandPlan = false

    public var body: some View {
        let palette = TuesdayTheme.palette(for: repository.brandFlavor)
        let isStn = (repository.brandFlavor == .sureThingHome)
        let activeNetwork = repository.userNetworks.first(where: { $0.id == repository.activeNetworkId })
            ?? NetworkSite(id: "net-default", name: "My Network", devicesCount: 0, role: "Primary Site")

        let visibleDevices = repository.visibleRackDevices
        let bulletinsPayload = BulletinsAndInventoryEngine.assembleBulletins(
            flavor: repository.brandFlavor,
            devices: visibleDevices,
            mutedFeedSlugs: repository.mutedFeedSlugs,
            completedBulletinIds: repository.completedBulletinIds
        )
        let showBulletinAttentionDot = !repository.bulletinDismissed &&
            !repository.bulletinMuted &&
            !repository.bulletinSnoozed &&
            (visibleDevices.isEmpty || !repository.remindersEnabled || !repository.dispatchSubscribed)
        let showsWifiBanner = repository.hacsConfig.requireLocalWifi && !networkMonitor.isWifiConnected

        ZStack {
            VStack(spacing: 0) {
                topAppBar(palette: palette, isStn: isStn, activeNetwork: activeNetwork)

                TabView(selection: $activeTab) {
                NavigationStack {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            InventoryCardView(
                                flavor: repository.brandFlavor,
                                palette: palette,
                                devices: visibleDevices,
                                zoneFilter: repository.selectedZoneFilter,
                                portStateFilter: repository.selectedPortStateFilter,
                                includeOkDevices: repository.includeOkDevices,
                                showStateFilterStrip: repository.showStateFilterStrip,
                                showZoneFilterStrip: repository.showZoneFilterStrip,
                                onSelectZoneFilter: { repository.setZoneFilter($0) },
                                onTogglePortStateFilter: { repository.setPortStateFilter($0) },
                                onToggleIncludeOk: { repository.toggleIncludeOkDevices() },
                                onInspectDevice: { dev in inspectedDevice = dev },
                                onAddDeviceWithClues: { clues in
                                    openAddDeviceWizard(mode: nil, synth: nil, query: nil, clues: clues, autoSearch: false)
                                },
                                onSeedDemoFleet: {
                                    repository.enableDemoMode()
                                    repository.setSimulatedDeviceCount(12)
                                },
                                onOpenReferenceGuide: { showingReferenceGuide = true }
                            )
                        }
                        .padding(.horizontal, TuesdayDimens.screenPaddingHorizontal)
                        .padding(.vertical, 12)
                    }
                    .background(palette.bg.ignoresSafeArea())
                }
                .tag(MainNavigationTab.status)
                .onChange(of: visibleDevices.count) { oldCount, newCount in
                    if oldCount == 0 && newCount > 0 && notificationManager?.authorizationStatus == .notDetermined {
                        primerDeviceName = visibleDevices.first?.name
                        showNotificationPrimer = true
                    }
                }
                .sheet(isPresented: $showNotificationPrimer) {
                    NotificationPrimerSheet(
                        palette: palette,
                        appName: isStn ? "SureThingNet" : "Tuesday.sh",
                        deviceName: primerDeviceName,
                        onEnableSelected: { _, patchTuesdayEnabled in
                            showNotificationPrimer = false
                            Task {
                                if let mgr = notificationManager, await mgr.requestAuthorizationIfNeeded() {
                                    await MainActor.run {
                                        UIApplication.shared.registerForRemoteNotifications()
                                        repository.setRemindersEnabled(patchTuesdayEnabled)
                                    }
                                }
                            }
                        },
                        onDismiss: { showNotificationPrimer = false }
                    )
                    .presentationDetents([.medium, .large])
                }

                BulletinsView(
                    repository: repository,
                    palette: palette,
                    payload: bulletinsPayload,
                    notificationManager: notificationManager ?? .shared,
                    onTapAddDevice: { openAddDeviceWizard() },
                    onTapReferenceGuide: { showingReferenceGuide = true },
                    onOpenFeedsSettings: { activeTab = .account },
                    onInspectDevice: { targetId in
                        if let dev = visibleDevices.first(where: { $0.id == targetId }) ?? visibleDevices.first {
                            inspectedDevice = dev
                        }
                    },
                    onNavigateToCheckUp: { activeTab = .checkup }
                )
                .tag(MainNavigationTab.bulletins)

                SwimlaneTimelineView(
                    devices: visibleDevices,
                    attestations: repository.attestations,
                    flavor: repository.brandFlavor,
                    palette: palette,
                    initialModal: timelineInitialModal,
                    onConsumeInitialModal: { timelineInitialModal = nil },
                    onOpenReferenceGuide: { showingReferenceGuide = true },
                    onInspectDevice: { inspectedDevice = $0 },
                    onRecordAttestation: { devId, type, presence, date, notes in
                        repository.recordAttestation(
                            deviceId: devId,
                            type: type,
                            presenceState: presence,
                            auditDate: date,
                            notes: notes
                        )
                    },
                    onRecordBatchAttestation: { ids, date, sessionId, notes in
                        repository.recordBatchAttestation(
                            deviceIds: ids,
                            auditDate: date,
                            sessionId: sessionId,
                            notes: notes
                        )
                    }
                )
                .tag(MainNavigationTab.timeline)

                SeasonalCheckupView(
                    devices: visibleDevices,
                    bulletins: bulletinsPayload.inbox,
                    flavor: repository.brandFlavor,
                    palette: palette,
                    welcomeComplete: repository.welcomeCompleted || repository.bulletinDismissed,
                    onOpenReferenceGuide: { showingReferenceGuide = true }
                )
                .tag(MainNavigationTab.checkup)

                AccountSettingsView(
                    repository: repository,
                    storeKitManager: storeKitManager,
                    notificationManager: notificationManager ?? .shared,
                    palette: palette,
                    initialExpandNetwork: settingsExpandNetwork,
                    initialExpandPlan: settingsExpandPlan,
                    onOpenReferenceGuide: { showingReferenceGuide = true },
                    onOpenUpgradeModal: { showingTier1Upgrade = true },
                    onSwitchToFleetTab: { activeTab = .status }
                )
                .tag(MainNavigationTab.account)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .uiSlot("content-area")

            bottomNavigationBar(
                palette: palette,
                unreadBulletinsCount: bulletinsPayload.inbox.count,
                showBulletinAttentionDot: showBulletinAttentionDot
            )
        }
            WifiWarningOverlay(
                isVisible: showsWifiBanner,
                hacsUrl: repository.hacsConfig.baseUrl,
                onDisableLocalRequirement: {
                    var cfg = repository.hacsConfig
                    cfg.requireLocalWifi = false
                    repository.updateHacsConfig(cfg)
                }
            )
        }
        .background(palette.bg.ignoresSafeArea())
        .preferredColorScheme(isStn ? .light : .dark)
        .overlay {
            if showingProComingSoonModal {
                proComingSoonOverlay(palette: palette)
            } else if showingTier1Upgrade, let store = storeKitManager {
                Tier1UpgradeModalView(
                    palette: palette,
                    storeKitManager: store,
                    onDismiss: { showingTier1Upgrade = false }
                )
            }
        }
        .sheet(isPresented: $showingNetworkPicker) {
            SetupNetworkModalView(
                palette: palette,
                networks: repository.userNetworks,
                activeNetworkId: repository.activeNetworkId,
                entitlementTier: repository.entitlementTier,
                onSelectNetwork: { repository.selectNetwork($0) },
                onCreateNetwork: { repository.createNetwork($0) },
                onOpenUpgrade: {
                    showingNetworkPicker = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        showingTier1Upgrade = true
                    }
                },
                onOpenNetworkSettings: {
                    showingNetworkPicker = false
                    settingsExpandNetwork = true
                    activeTab = .account
                },
                onDismiss: { showingNetworkPicker = false }
            )
        }
        .sheet(isPresented: $showingHacsSheet) {
            HacsPairingSheet(
                repository: repository,
                palette: palette,
                onOpenUpgrade: {
                    showingHacsSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        showingTier1Upgrade = true
                    }
                },
                onOpenNetworkPicker: {
                    showingHacsSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        showingNetworkPicker = true
                    }
                },
                onDismiss: { showingHacsSheet = false }
            )
        }
        .sheet(item: $inspectedDevice) { dev in
            DeviceInspectorSheet(
                device: dev,
                flavor: repository.brandFlavor,
                palette: palette,
                onDismiss: { inspectedDevice = nil },
                onEditDevice: { toEdit in
                    inspectedDevice = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        editingDevice = toEdit
                    }
                },
                onApplyPatch: {
                    repository.markDeviceRemediated(id: dev.id)
                    inspectedDevice = nil
                }
            )
        }
        .sheet(item: $editingDevice) { dev in
            EditDeviceView(
                device: dev,
                palette: palette,
                isStn: isStn,
                onSave: { newName, newShortLabel, newCat, newZone, newRoom, newVer, newSerial, newMac in
                    repository.updateDeviceDetails(
                        id: dev.id,
                        name: newName,
                        shortLabel: newShortLabel,
                        category: newCat,
                        trustZone: newZone,
                        roomLocation: newRoom,
                        version: newVer,
                        serialNumber: newSerial,
                        macAddress: newMac
                    )
                    editingDevice = nil
                },
                onDelete: { id in
                    repository.deleteDevice(id: id)
                    editingDevice = nil
                },
                onCancel: { editingDevice = nil }
            )
        }
        .sheet(item: $addDeviceRequest) { req in
            AddNodeView(
                repository: repository,
                palette: palette,
                initialMode: req.mode,
                initialSynthPreset: req.synth,
                initialQuery: req.query,
                initialCluesCsv: req.clues,
                autoSearch: req.autoSearch,
                onOpenUpgrade: {
                    addDeviceRequest = nil
                    showingTier1Upgrade = true
                }
            )
        }
        .sheet(isPresented: $showingReferenceGuide) {
            ReferenceGuideModalSheet(flavor: repository.brandFlavor, palette: palette)
        }
        .onAppear {
            if let link = pendingDeepLink {
                handleDeepLink(link)
                pendingDeepLink = nil
            }
        }
        .onChange(of: pendingDeepLink) { _, newValue in
            if let link = newValue {
                handleDeepLink(link)
                pendingDeepLink = nil
            }
        }
    }

    private func topAppBar(palette: BrandPalette, isStn: Bool, activeNetwork: NetworkSite) -> some View {
        HStack(spacing: 8) {
            HStack(spacing: 8) {
                TuesdayCalendarHeartIcon(tint: TuesdayTheme.proAccent, size: 20)
                    .uiSlot("brand-mark")

                Text(isStn ? "SureThing" : "tuesday.sh")
                    .font(TuesdayTheme.brandFont(size: 16.5))
                    .foregroundColor(palette.textPrimary)
                    .lineLimit(1)
                    .uiSlot("brand-title")

                Button(action: { showingProComingSoonModal = true }) {
                    Text(repository.brandFlavor.badge)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(palette.accentText)
                        .padding(.horizontal, 9)
                        .frame(minHeight: 30)
                        .background(palette.elevated)
                        .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
                        .uiSlot("brand-badge")
                }
                .buttonStyle(.plain)
                .uiAction("toggleBrandFlavor")
            }
            .uiSlot("brand-identity")

            Spacer(minLength: 4)

            HStack(spacing: 6) {
                Button(action: { showingNetworkPicker = true }) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(palette.textMuted.opacity(0.75))
                            .frame(width: 6, height: 6)
                        Text(activeNetwork.name.isEmpty ? "My Network" : activeNetwork.name)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(palette.textPrimary)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 10)
                    .frame(minHeight: 34)
                    .background(palette.elevated)
                    .clipShape(Capsule())
                    .uiSlot("network-switcher-pill")
                }
                .buttonStyle(.plain)
                .uiAction("openNetworkPicker")

                Button(action: { showingHacsSheet = true }) {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(repository.hacsConfig.isConnected ? TuesdayTheme.ledColor(for: .ok, isStn: isStn) : palette.textMuted)
                            .frame(width: 6, height: 6)
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(palette.textPrimary)
                    }
                    .padding(.horizontal, 10)
                    .frame(minHeight: 34)
                    .background(palette.elevated)
                    .clipShape(Capsule())
                    .uiSlot("hacs-menu-pill")
                }
                .buttonStyle(.plain)
                .uiAction("openHacsSettings")
            }
            .uiSlot("scope-actions")
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 46)
        .background(palette.surface)
        .overlay(alignment: .bottom) {
            Rectangle().fill(palette.border).frame(height: 1)
        }
        .uiComponent("TopAppBar")
    }

    private func bottomNavigationBar(
        palette: BrandPalette,
        unreadBulletinsCount: Int,
        showBulletinAttentionDot: Bool
    ) -> some View {
        HStack(spacing: 0) {
            ForEach(MainNavigationTab.allCases) { tab in
                let isSelected = (activeTab == tab)
                let label = tab.label(for: repository.brandFlavor)
                Button(action: { activeTab = tab }) {
                    VStack(spacing: 3) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: tab.systemIcon)
                                .font(.system(size: 17, weight: isSelected ? .bold : .medium))

                            if tab == .bulletins {
                                if unreadBulletinsCount > 0 {
                                    Text("\(unreadBulletinsCount)")
                                        .font(.system(size: 9, weight: .heavy))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 4)
                                        .frame(minWidth: 14, minHeight: 14)
                                        .background(TuesdayTheme.ledCveRed)
                                        .clipShape(Capsule())
                                        .offset(x: 9, y: -4)
                                        .uiSlot("bulletins-badge")
                                } else if showBulletinAttentionDot {
                                    Circle()
                                        .fill(TuesdayTheme.ledCveRed)
                                        .frame(width: 6, height: 6)
                                        .offset(x: 6, y: -2)
                                        .uiSlot("bulletins-badge")
                                }
                            }
                        }

                        Text(label)
                            .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                            .lineLimit(1)
                    }
                    .foregroundColor(isSelected ? palette.accentText : palette.textMuted)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .uiAction("switchTab")
                }
                .buttonStyle(.plain)
                .accessibilityLabel(label)
                .uiSlot("nav-tab-\(tab.rawValue)")
            }
        }
        .padding(.horizontal, 4)
        .padding(.top, 4)
        .background(palette.surface)
        .overlay(alignment: .top) {
            Rectangle().fill(palette.border).frame(height: 1)
        }
        .uiComponent("BottomNavigationBar", state: "activeTab=\(activeTab.rawValue)")
    }

    private func proComingSoonOverlay(palette: BrandPalette) -> some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea().onTapGesture {
                showingProComingSoonModal = false
            }

            TuesdayModalCard(
                palette: palette,
                title: "Tuesday.sh Pro",
                subtitle: "Tuesday.sh tracks hardware lifecycles, firmware advisories, and seasonal check-ups across your home and homelab networks.",
                componentName: "ProComingSoonModal",
                closeActionName: "closeProComingSoon",
                onDismiss: { showingProComingSoonModal = false },
                leading: { TuesdayCalendarHeartIcon(tint: palette.accent, size: 18) },
                headerTrailing: {
                    MonospaceBadge(text: "PRO", color: palette.accent)
                },
                content: {
                    SurfaceListContainer(palette: palette) {
                        TuesdayListRow(
                            palette: palette,
                            title: "Plain-English Security & Recall Advisories",
                            subtitle: {
                                Text("Tracks manufacturer and security researcher notices from global feeds and filters only the CVEs, firmware updates, recalls, and End-of-Life alerts that match your inventory.")
                                    .font(.system(size: 12))
                                    .foregroundColor(palette.textMuted)
                                    .lineSpacing(2)
                            },
                            trailing: {
                                MonospaceBadge(text: "LIVE", color: TuesdayTheme.ledOkGreen)
                            }
                        )
                        SurfaceListDivider(palette: palette)
                        TuesdayListRow(
                            palette: palette,
                            title: "Seasonal Check-Ups & Printable Summaries",
                            subtitle: {
                                Text("Run guided seasonal check-ups and share a clean plain-text or printable network check-up report with a partner or household helper.")
                                    .font(.system(size: 12))
                                    .foregroundColor(palette.textMuted)
                                    .lineSpacing(2)
                            },
                            trailing: {
                                MonospaceBadge(text: "LIVE", color: TuesdayTheme.ledOkGreen)
                            }
                        )
                        SurfaceListDivider(palette: palette)
                        TuesdayListRow(
                            palette: palette,
                            title: "Multi-Site Homelab & Remote Care",
                            onClick: {
                                showingProComingSoonModal = false
                                showingNetworkPicker = true
                            },
                            subtitle: {
                                Text("Free accounts include 1 primary network (up to 15 devices) and 1 demo sandbox. Upgrade to Pro Tier 1 to track up to 128 devices per site and unlock unlimited network locations.")
                                    .font(.system(size: 12))
                                    .foregroundColor(palette.textMuted)
                                    .lineSpacing(2)
                            },
                            trailing: {
                                MonospaceBadge(text: "PRO", color: palette.accent)
                            }
                        )
                    }

                    Button(action: { showingProComingSoonModal = false }) {
                        Text("Got It")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 42)
                            .background(palette.accent)
                            .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
                    }
                    .buttonStyle(.plain)
                }
            )
        }
    }

    private func openAddDeviceWizard(
        mode: String? = nil,
        synth: String? = nil,
        query: String? = nil,
        clues: String? = nil,
        autoSearch: Bool = false
    ) {
        if EntitlementGatePolicy.requiresUpgradeForNewDevice(
            tier: repository.entitlementTier,
            activeNetworkId: repository.activeNetworkId,
            currentDeviceCount: repository.visibleRackDevices.count
        ) {
            showingTier1Upgrade = true
            return
        }
        addDeviceRequest = AddDeviceSheetRequest(
            mode: mode,
            synth: synth,
            query: query,
            clues: clues,
            autoSearch: autoSearch
        )
    }

    private func dismissPresentedSheets() {
        addDeviceRequest = nil
        showingHacsSheet = false
        showingNetworkPicker = false
        showingTier1Upgrade = false
        showingReferenceGuide = false
        showingProComingSoonModal = false
        inspectedDevice = nil
        editingDevice = nil
    }

    private func handleDeepLink(_ destination: DeepLinkDestination) {
        switch destination {
        case .tab(let tabSlug):
            dismissPresentedSheets()
            switch tabSlug {
            case "bulletins": activeTab = .bulletins
            case "timeline": activeTab = .timeline
            case "checkup": activeTab = .checkup
            case "account": activeTab = .account
            case "account-dev":
                repository.toggleDeveloperMode(true)
                activeTab = .account
            default: activeTab = .status
            }

        case .device(let deviceId):
            dismissPresentedSheets()
            if let dev = repository.rackDevices.first(where: { $0.id.caseInsensitiveCompare(deviceId) == .orderedSame }) {
                inspectedDevice = dev
            }

        case .addDevice(let mode, let synthPreset, let clueQuery, let cluesCsv, let autoSearch):
            dismissPresentedSheets()
            openAddDeviceWizard(mode: mode, synth: synthPreset, query: clueQuery, clues: cluesCsv, autoSearch: autoSearch)

        case .hacsSettings:
            dismissPresentedSheets()
            showingHacsSheet = true

        case .networkPicker:
            dismissPresentedSheets()
            showingNetworkPicker = true

        case .upgradePrompt(let source, let sku):
            dismissPresentedSheets()
            if let sku { storeKitManager?.selectPlan(sku) }
            if source == "account" {
                settingsExpandPlan = true
                activeTab = .account
            } else {
                showingTier1Upgrade = true
            }

        case .referenceGuide:
            dismissPresentedSheets()
            showingReferenceGuide = true

        case .seedFleet(let count):
            dismissPresentedSheets()
            if count > 0 {
                repository.enableDemoMode()
            }
            repository.setSimulatedDeviceCount(count)
            activeTab = .status

        case .toggleFlavor:
            repository.toggleBrandFlavor()

        case .setFlavor(let flavor):
            repository.setBrandFlavor(flavor)

        case .resetDemo:
            dismissPresentedSheets()
            repository.resetDemoData()
            activeTab = .status

        case .timelineAction(let scenario, let modal):
            dismissPresentedSheets()
            if scenario == "zombie" {
                repository.enableDemoMode()
                repository.setSimulatedDeviceCount(12)
            }
            timelineInitialModal = modal
            activeTab = .timeline

        case .triggerMockPatchTuesday:
            repository.triggerMockPatchTuesdayCycle()
            activeTab = .bulletins

        case .setApiEndpoint(let url):
            repository.setTuesdayApiBaseUrl(url)

        case .visionDebug(let enabled):
            repository.toggleDeveloperMode(true)
            repository.toggleVisionDebugMode(enabled)
        }
    }
}

public struct RiskMeterView: View {
    public let portState: PortLifecycleState
    public var body: some View {
        RiskMeterDots(state: portState, palette: TuesdayTheme.palette(for: .tuesdayPro))
    }
}
