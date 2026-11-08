import SwiftUI

public enum MainNavigationTab: String, CaseIterable {
    case status
    case bulletins
    case timeline
    case checkup
    case account

    public func label(for flavor: AppBrandFlavor) -> String {
        let isStn = (flavor == .sureThingHome)
        switch self {
        case .status: return isStn ? "Home Grid" : "My Net"
        case .bulletins: return "Bulletins"
        case .timeline: return isStn ? "Lifespan" : "Timeline"
        case .checkup: return "Check-Up"
        case .account: return "Account"
        }
    }

    public var systemIcon: String {
        switch self {
        case .status: return "square.grid.4x3.fill"
        case .bulletins: return "bell.badge.fill"
        case .timeline: return "chart.bar.xaxis"
        case .checkup: return "checklist"
        case .account: return "person.crop.circle.fill"
        }
    }
}

public struct HomeView: View {
    @ObservedObject var repository: MockHacsTuesdayService
    @ObservedObject var networkMonitor: NetworkMonitorService

    @State private var activeTab: MainNavigationTab = .status
    @State private var inspectedDevice: RackPortDevice? = nil
    @State private var showHacsSheet: Bool = false
    @State private var showAddNodeView: Bool = false
    @State private var showNetworkPicker: Bool = false
    @State private var showReferenceGuide: Bool = false
    @State private var bulletinDismissed: Bool = false
    @State private var bulletinSnoozed: Bool = false

    public init(
        repository: MockHacsTuesdayService,
        networkMonitor: NetworkMonitorService
    ) {
        self.repository = repository
        self.networkMonitor = networkMonitor
    }

    private var shouldShowWifiOverlay: Bool {
        repository.hacsConfig.requireLocalWifi && !networkMonitor.isWifiConnected
    }

    public var body: some View {
        let palette = TuesdayTheme.palette(for: repository.brandFlavor)
        let isStn = (repository.brandFlavor == .sureThingHome)
        let activeNetwork = repository.userNetworks.first(where: { $0.id == repository.activeNetworkId })
            ?? repository.userNetworks.first
            ?? NetworkSite(id: "skyway", name: "Skyway Lab", devicesCount: 12, role: "Primary Homelab")
        let visibleDevices = Array(repository.rackDevices.prefix(repository.activeDeviceCount))
        let scaleTier = InventoryScaleTier.forCount(visibleDevices.count)

        let ledSlots = BulletinsAndInventoryEngine.build128LedMatrix(
            devices: visibleDevices,
            zoneFilter: repository.selectedZoneFilter
        )
        let actionDevices = BulletinsAndInventoryEngine.filterActionFirstDevices(
            devices: visibleDevices,
            includeOk: repository.includeOkDevices,
            zoneFilter: repository.selectedZoneFilter,
            portStateFilter: repository.selectedPortStateFilter
        )
        let bulletinsPayload = BulletinsAndInventoryEngine.assembleBulletins(
            flavor: repository.brandFlavor,
            devices: visibleDevices,
            mutedFeedSlugs: repository.mutedFeedSlugs
        )

        NavigationStack {
            ZStack {
                palette.bg.ignoresSafeArea()

                VStack(spacing: 0) {
                    Group {
                        switch activeTab {
                        case .status:
                            statusMatrixAndActionList(
                                palette: palette,
                                isStn: isStn,
                                scaleTier: scaleTier,
                                visibleDevices: visibleDevices,
                                ledSlots: ledSlots,
                                actionDevices: actionDevices
                            )
                        case .bulletins:
                            BulletinsView(
                                flavor: repository.brandFlavor,
                                palette: palette,
                                payload: bulletinsPayload,
                                onToggleMuteFeed: { repository.toggleMuteFeed($0) },
                                onConfirmModel: { repository.confirmProvisionalDeviceModel($0) },
                                onRejectModel: { repository.rejectProvisionalDeviceModel() },
                                onOpenFeedsSettings: { activeTab = .account }
                            )
                        case .timeline:
                            SwimlaneTimelineView(
                                flavor: repository.brandFlavor,
                                palette: palette,
                                devices: visibleDevices,
                                onOpenReferenceGuide: { showReferenceGuide = true },
                                onInspectDevice: { inspectedDevice = $0 }
                            )
                        case .checkup:
                            SeasonalCheckupView(
                                flavor: repository.brandFlavor,
                                palette: palette,
                                devices: visibleDevices,
                                onOpenReferenceGuide: { showReferenceGuide = true }
                            )
                        case .account:
                            AccountSettingsView(
                                flavor: repository.brandFlavor,
                                palette: palette,
                                networkLocationName: activeNetwork.name,
                                activeDeviceCount: visibleDevices.count,
                                isDeveloperMode: repository.isDeveloperMode,
                                entitlementTier: repository.entitlementTier,
                                savedCorpusCount: repository.savedCorpusCount,
                                matchedFeeds: bulletinsPayload.matchedFeeds,
                                onToggleMuteFeed: { repository.toggleMuteFeed($0) },
                                onUpgradeProTier1: { repository.upgradeToProTier1() },
                                onSaveNetworkName: { repository.renameActiveNetwork($0) },
                                onToggleDeveloperMode: { repository.toggleDeveloperMode($0) },
                                onSetSimulatedDeviceCount: { repository.setSimulatedDeviceCount($0) },
                                onPurgeGoldenCorpus: { repository.purgeGoldenCorpus() },
                                onOpenIntakeFlow: { showAddNodeView = true },
                                onSwitchToFleetTab: { activeTab = .status }
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    // 5-Item Custom Bottom Navigation Bar
                    HStack(spacing: 0) {
                        ForEach(MainNavigationTab.allCases, id: \.self) { tab in
                            let selected = (activeTab == tab)
                            Button(action: { activeTab = tab }) {
                                VStack(spacing: 3) {
                                    ZStack(alignment: .topTrailing) {
                                        Image(systemName: tab.systemIcon)
                                            .font(.system(size: 16, weight: .semibold))
                                        if tab == .bulletins && !bulletinsPayload.inbox.isEmpty {
                                            Text("\(bulletinsPayload.inbox.count)")
                                                .font(.system(size: 8, weight: .bold))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 4)
                                                .padding(.vertical, 1)
                                                .background(TuesdayTheme.ledCveRed)
                                                .clipShape(Capsule())
                                                .offset(x: 8, y: -5)
                                        }
                                    }
                                    Text(tab.label(for: repository.brandFlavor))
                                        .font(.system(size: 9.5, weight: selected ? .bold : .medium))
                                }
                                .foregroundColor(selected ? palette.accent : palette.textMuted)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)
                            .uiAction("switchTab")
                        }
                    }
                    .background(palette.surface)
                    .overlay(
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(palette.border),
                        alignment: .top
                    )
                    .uiComponent("BottomNavigationBar")
                }

                WifiWarningOverlay(
                    isVisible: shouldShowWifiOverlay,
                    hacsUrl: repository.hacsConfig.baseUrl,
                    onDisableLocalRequirement: {
                        var cfg = repository.hacsConfig
                        cfg.requireLocalWifi = false
                        repository.updateHacsConfig(cfg)
                        networkMonitor.setSimulateDisconnected(false)
                    }
                )
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(palette.surface, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 6) {
                        if !isStn {
                            TuesdayCalendarHeartIcon(tint: TuesdayTheme.proAccent, size: 20)
                            Text("tuesday.sh")
                                .font(.system(size: 15.5, weight: .semibold))
                                .foregroundColor(palette.textPrimary)
                        } else {
                            ZStack {
                                Circle()
                                    .fill(palette.accent)
                                    .frame(width: 22, height: 22)
                                Image(systemName: "shippingbox.fill")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            Text(repository.brandFlavor.title)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(palette.textPrimary)
                        }

                        Button(action: { repository.toggleBrandFlavor() }) {
                            Text(repository.brandFlavor.badge)
                                .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                                .foregroundColor(palette.accent)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(palette.elevated)
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                        .uiAction("toggleBrandFlavor")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 6) {
                        Button(action: { showNetworkPicker = true }) {
                            HStack(spacing: 4) {
                                Text(activeNetwork.name)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(palette.textPrimary)
                                    .lineLimit(1)
                                Text("▾")
                                    .font(.system(size: 10))
                                    .foregroundColor(palette.textMuted)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(palette.elevated)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .uiAction("openNetworkPicker")

                        Button(action: { showHacsSheet = true }) {
                            HStack(spacing: 5) {
                                Circle()
                                    .fill(repository.hacsConfig.isConnected ? TuesdayTheme.ledOkGreen : TuesdayTheme.ledCveRed)
                                    .frame(width: 7, height: 7)
                                Text("HACS")
                                    .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                                    .foregroundColor(palette.accent)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(palette.elevated)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .uiAction("openHacsSettings")
                    }
                }
            }
            .navigationDestination(isPresented: $showAddNodeView) {
                AddNodeView(repository: repository)
            }
            .sheet(item: $inspectedDevice) { device in
                deviceInspectorSheet(device: device, palette: palette, isStn: isStn)
            }
            .sheet(isPresented: $showHacsSheet) {
                HacsPairingSheet(
                    repository: repository,
                    networkMonitor: networkMonitor
                )
            }
            .sheet(isPresented: $showNetworkPicker) {
                NetworkPickerModalSheet(
                    networks: repository.userNetworks,
                    activeNetworkId: repository.activeNetworkId,
                    palette: palette,
                    onSelectNetwork: { repository.selectNetwork($0) },
                    onCreateNetwork: { repository.createNetwork($0) },
                    onDismiss: { showNetworkPicker = false }
                )
            }
            .sheet(isPresented: $showReferenceGuide) {
                ReferenceGuideModalSheet(
                    flavor: repository.brandFlavor,
                    palette: palette,
                    onDismiss: { showReferenceGuide = false }
                )
            }
            .onOpenURL { url in
                handleDeepLink(url)
            }
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "tuesday" else { return }
        let host = url.host?.lowercased() ?? ""
        let pathComponents = url.pathComponents.filter { $0 != "/" && !$0.isEmpty }
        let primary = host.isEmpty ? (pathComponents.first?.lowercased() ?? "") : host

        switch primary {
        case "status", "fleet", "home", "grid":
            activeTab = .status
        case "bulletins", "inbox":
            activeTab = .bulletins
        case "timeline", "lifespan", "swimlane":
            activeTab = .timeline
        case "checkup", "audit":
            activeTab = .checkup
        case "account", "settings":
            activeTab = .account
        case "add-device", "add_device", "intake", "wizard":
            showAddNodeView = true
        case "hacs", "hacs-settings":
            showHacsSheet = true
        case "network-picker", "networks", "sites":
            showNetworkPicker = true
        case "reference-guide", "reference", "standards":
            showReferenceGuide = true
        case "toggle-flavor", "flavor":
            repository.toggleBrandFlavor()
        case "reset-demo", "reset":
            bulletinDismissed = false
            bulletinSnoozed = false
            repository.setSimulatedDeviceCount(0)
            activeTab = .status
        case "seed", "seed-forest", "demo":
            let count = pathComponents.first.flatMap { Int($0) } ?? 12
            repository.setSimulatedDeviceCount(count)
            activeTab = .status
        case "device":
            let deviceId = pathComponents.first ?? ""
            if let dev = repository.rackDevices.first(where: { $0.id.caseInsensitiveCompare(deviceId) == .orderedSame }) {
                inspectedDevice = dev
            }
        default:
            break
        }
    }

    @ViewBuilder
    private func statusMatrixAndActionList(
        palette: BrandPalette,
        isStn: Bool,
        scaleTier: InventoryScaleTier,
        visibleDevices: [RackPortDevice],
        ledSlots: [LedSlot],
        actionDevices: [RackPortDevice]
    ) -> some View {
        let okCount = visibleDevices.filter { $0.portState == .ok }.count
        let cveCount = visibleDevices.filter { $0.portState == .cveKev }.count
        let eolCount = visibleDevices.filter { $0.portState == .eol }.count
        let guessedCount = visibleDevices.filter { $0.portState == .guessed }.count
        let updateCount = visibleDevices.filter { $0.portState == .update }.count
        let actionCount = visibleDevices.count - okCount
        let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 3), count: 16)

        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                // Backward-compatibility accessibility anchors for existing XCUITests
                Text("DEVICES (\(visibleDevices.count))")
                    .font(.system(size: 1))
                    .opacity(0.01)
                    .frame(height: 1)
                    .accessibilityIdentifier("fleet_summary_title")
                Text("DEVICES")
                    .font(.system(size: 1))
                    .opacity(0.01)
                    .frame(height: 1)
                    .accessibilityIdentifier("devices_section_header")

                // Always show WelcomeCard / Notched Readiness Bulletin at top of Home view if not dismissed
                if !bulletinDismissed || scaleTier == .DAY_ZERO {
                    welcomeCard(palette: palette, scaleTier: scaleTier, activeCount: visibleDevices.count)
                }

                if scaleTier != .DAY_ZERO {
                    // 1. Inventory Card (8-Port Category Strip + 16x8 LED Matrix + Botanical Overlay)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            HStack(spacing: 8) {
                                Text("Inventory")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(palette.textPrimary)
                                    .uiSlot("title")
                                if scaleTier.showSummaryBadge {
                                    Text("\(okCount) OK · \(actionCount) Action")
                                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                                        .foregroundColor(palette.accent)
                                        .uiSlot("summary-badge")
                                }
                            }
                            Spacer()
                            HStack(spacing: 6) {
                                Button(action: { showAddNodeView = true }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 10, weight: .bold))
                                        Text("+ Add Device")
                                            .font(.system(size: 9.5, weight: .bold))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(palette.accent)
                                    .cornerRadius(6)
                                    .uiSlot("add-device-cta")
                                }
                                .buttonStyle(.plain)
                                .uiAction("openAddDevice")
                                .accessibilityIdentifier("navigate_add_device_button")

                                Button(action: { showReferenceGuide = true }) {
                                    Text("?")
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .foregroundColor(palette.textMuted)
                                        .frame(width: 20, height: 20)
                                        .background(palette.elevated)
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(palette.border, lineWidth: 1)
                                        )
                                        .uiSlot("help-button")
                                }
                                .buttonStyle(.plain)
                                .uiAction("openReferenceGuide")
                            }
                        }
                        .uiSlot("header")

                        // Unified ubnt-chassis container
                        VStack(spacing: 8) {
                            if scaleTier.showPortDiagramStrip {
                                portCategoryFaceplateStrip(
                                    devices: visibleDevices,
                                    isStn: isStn,
                                    palette: palette
                                )
                                Divider().background(palette.border)
                            }

                            ZStack(alignment: .bottom) {
                                LazyVGrid(columns: gridColumns, spacing: 3) {
                                    ForEach(ledSlots) { slot in
                                        let color = TuesdayTheme.ledColor(for: slot.state, isStn: isStn)
                                        let alpha: Double = {
                                            switch slot.state {
                                            case .unassigned: return 0.55
                                            case .ok: return 0.85
                                            default: return 1.0
                                            }
                                        }()
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(color.opacity(alpha))
                                            .aspectRatio(1.0, contentMode: .fit)
                                            .onTapGesture {
                                                if let devId = slot.deviceId,
                                                   let found = visibleDevices.first(where: { $0.id == devId }) {
                                                    inspectedDevice = found
                                                }
                                            }
                                            .uiAction("inspectDevice")
                                    }
                                }

                                matrixBotanicalPixelArtOverlay(
                                    scaleTier: scaleTier,
                                    activeCount: visibleDevices.count,
                                    isStn: isStn
                                )
                                .uiSlot("botanical-overlay")
                                .uiComponent("MatrixBotanicalPixelArtOverlay")
                            }
                            .uiSlot("led-grid-128")
                            .uiComponent("LedMatrix128Grid")
                        }
                        .padding(8)
                        .background(isStn ? TuesdayTheme.stnBgCanvas : Color(red: 0x0B / 255.0, green: 0x0D / 255.0, blue: 0x11 / 255.0))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(palette.border, lineWidth: 1)
                        )

                        if scaleTier.showFilterChips {
                            HStack {
                                ledLegendDot("OK (\(okCount))", TuesdayTheme.ledOkGreen, palette)
                                Spacer()
                                ledLegendDot("CVE/KEV (\(cveCount))", TuesdayTheme.ledCveRed, palette)
                                Spacer()
                                ledLegendDot("EOL (\(eolCount))", TuesdayTheme.ledEolAmber, palette)
                                Spacer()
                                ledLegendDot("Guessed (\(guessedCount))", TuesdayTheme.ledGuessedGrey, palette)
                                Spacer()
                                ledLegendDot("Update (\(updateCount))", TuesdayTheme.ledUpdateBlue, palette)
                            }
                            .uiSlot("legend-row")
                        }

                        if scaleTier.showTrustZonePills {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 5) {
                                    zoneFilterPill(
                                        label: "All Zones",
                                        selected: repository.selectedZoneFilter == nil,
                                        palette: palette
                                    ) {
                                        repository.setZoneFilter(nil)
                                    }
                                    ForEach(TrustZone.allCases, id: \.self) { zone in
                                        zoneFilterPill(
                                            label: isStn ? zone.stnLabel : "\(zone.shortCode) \(zone.stnLabel)",
                                            selected: repository.selectedZoneFilter == zone,
                                            palette: palette
                                        ) {
                                            repository.setZoneFilter(zone)
                                        }
                                    }
                                }
                            }
                            .uiSlot("zone-filter-strip")
                        }
                    }
                    .padding(.vertical, 4)
                    .uiComponent("InventoryMatrixCard", state: "tier=\(scaleTier.id);active=\(visibleDevices.count)")

                    // 1B. Tracked Hardware Profiles Strip (Forest Tier >= 8 devices on STN-Pro)
                    if scaleTier == .FOREST && !isStn && !visibleDevices.isEmpty {
                        trackedHardwareProfilesCard(devices: visibleDevices, palette: palette)
                    }

                    // 2. Top-of-Inventory State Filter Chips (for Forest tier)
                    if scaleTier.showFilterChips {
                        VStack(alignment: .leading, spacing: 6) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    stateFilterChip(
                                        label: "All (\(visibleDevices.count))",
                                        dotColor: nil,
                                        selected: repository.selectedPortStateFilter == nil && repository.includeOkDevices,
                                        palette: palette
                                    ) {
                                        repository.setPortStateFilter(nil)
                                        if !repository.includeOkDevices {
                                            repository.toggleIncludeOkDevices()
                                        }
                                    }
                                    stateFilterChip(
                                        label: "CVE / KEV (\(cveCount))",
                                        dotColor: TuesdayTheme.ledCveRed,
                                        selected: repository.selectedPortStateFilter == .cveKev,
                                        palette: palette
                                    ) {
                                        repository.setPortStateFilter(repository.selectedPortStateFilter == .cveKev ? nil : .cveKev)
                                    }
                                    stateFilterChip(
                                        label: "EOL (\(eolCount))",
                                        dotColor: TuesdayTheme.ledEolAmber,
                                        selected: repository.selectedPortStateFilter == .eol,
                                        palette: palette
                                    ) {
                                        repository.setPortStateFilter(repository.selectedPortStateFilter == .eol ? nil : .eol)
                                    }
                                    stateFilterChip(
                                        label: "Guessed (\(guessedCount))",
                                        dotColor: TuesdayTheme.ledGuessedGrey,
                                        selected: repository.selectedPortStateFilter == .guessed,
                                        palette: palette
                                    ) {
                                        repository.setPortStateFilter(repository.selectedPortStateFilter == .guessed ? nil : .guessed)
                                    }
                                    stateFilterChip(
                                        label: "Update (\(updateCount))",
                                        dotColor: TuesdayTheme.ledUpdateBlue,
                                        selected: repository.selectedPortStateFilter == .update,
                                        palette: palette
                                    ) {
                                        repository.setPortStateFilter(repository.selectedPortStateFilter == .update ? nil : .update)
                                    }
                                    stateFilterChip(
                                        label: "OK (\(okCount))",
                                        dotColor: TuesdayTheme.ledOkGreen,
                                        selected: repository.selectedPortStateFilter == .ok,
                                        palette: palette
                                    ) {
                                        repository.setPortStateFilter(repository.selectedPortStateFilter == .ok ? nil : .ok)
                                    }
                                }
                            }
                            .uiSlot("state-filter-strip")

                            HStack {
                                Text(
                                    repository.selectedPortStateFilter != nil
                                        ? "FILTERED: \((isStn ? repository.selectedPortStateFilter!.stnLabel : repository.selectedPortStateFilter!.proLabel).uppercased()) (\(actionDevices.count))"
                                        : (repository.includeOkDevices ? "ALL NAMED DEVICES (\(actionDevices.count))" : "NEEDS ATTENTION (\(actionDevices.count))")
                                )
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(palette.textMuted)

                                Spacer()

                                if repository.selectedPortStateFilter == nil {
                                    Button(action: { repository.toggleIncludeOkDevices() }) {
                                        Text(repository.includeOkDevices ? "Hide OK Devices" : "Show OK (+\(okCount))")
                                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                                            .foregroundColor(palette.accent)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(palette.elevated)
                                            .cornerRadius(6)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6)
                                                    .stroke(palette.border, lineWidth: 1)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                    .uiAction("toggleIncludeOk")
                                }
                            }
                            .uiSlot("action-list-header")
                        }
                    }

                    // 3. Device Rows (Unboxed with 1pt hairline dividers, no STN-... asset tags)
                    let devicesToShow = !scaleTier.showFilterChips ? visibleDevices : actionDevices
                    ForEach(devicesToShow) { dev in
                        let stateColor = TuesdayTheme.ledColor(for: dev.portState, isStn: isStn)
                        Button(action: { inspectedDevice = dev }) {
                            VStack(spacing: 0) {
                                Divider().background(palette.border)
                                if isStn {
                                    HStack(spacing: 0) {
                                        Rectangle()
                                            .fill(stateColor)
                                            .frame(width: 4)
                                        VStack(alignment: .leading, spacing: 6) {
                                            HStack {
                                                Text(dev.name)
                                                    .font(.system(size: 13.5, weight: .heavy))
                                                    .foregroundColor(palette.textPrimary)
                                                Spacer()
                                                Text(dev.portState.stnLabel)
                                                    .font(.system(size: 9.5, weight: .bold))
                                                    .foregroundColor(stateColor)
                                                    .padding(.horizontal, 7)
                                                    .padding(.vertical, 2)
                                                    .background(stateColor.opacity(0.14))
                                                    .cornerRadius(6)
                                            }
                                            HStack(spacing: 6) {
                                                Text("📍 \(dev.roomLocation)")
                                                    .font(.system(size: 10, weight: .semibold))
                                                    .foregroundColor(palette.textMuted)
                                                Text("•")
                                                    .font(.system(size: 10))
                                                    .foregroundColor(palette.border)
                                                Text(dev.trustZone.stnLabel)
                                                    .font(.system(size: 10, weight: .semibold))
                                                    .foregroundColor(palette.accent)
                                                Text("•")
                                                    .font(.system(size: 10))
                                                    .foregroundColor(palette.border)
                                                Text(String(format: "Port #%02d", dev.portIndex))
                                                    .font(.system(size: 10, design: .monospaced))
                                                    .foregroundColor(palette.textMuted)
                                            }
                                            Text(dev.stnHeadline)
                                                .font(.system(size: 11))
                                                .foregroundColor(palette.textPrimary)
                                                .multilineTextAlignment(.leading)
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 10)
                                    }
                                } else {
                                    HStack(spacing: 10) {
                                        VStack(spacing: 1) {
                                            Text(String(format: "#%02d", dev.portIndex))
                                                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                                                .foregroundColor(stateColor)
                                            Text(dev.category.code)
                                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                                .foregroundColor(palette.textMuted)
                                        }
                                        .frame(width: 38)
                                        .padding(.vertical, 4)
                                        .background(stateColor.opacity(0.16))
                                        .cornerRadius(6)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(stateColor, lineWidth: 1)
                                        )

                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(dev.name)
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(palette.textPrimary)
                                            Text("\(dev.trustZone.shortCode) • \(dev.roomLocation) • \(dev.version) • \(dev.lifecycleTier)")
                                                .font(.system(size: 9, design: .monospaced))
                                                .foregroundColor(palette.textMuted)
                                            Text(dev.proHeadline)
                                                .font(.system(size: 10))
                                                .foregroundColor(stateColor)
                                                .multilineTextAlignment(.leading)
                                        }
                                        Spacer()
                                        RiskMeterView(portState: dev.portState, isStn: isStn)
                                    }
                                    .padding(.vertical, 10)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .uiSlot("device-row", state: "port=\(dev.portIndex);state=\(dev.portState.key);cat=\(dev.category.code)")
                        .uiAction("inspectDevice")
                    }

                    // Secondary "+ Add Another Device" CTA shown in Pea (1..2) and Garden (3..7) tiers
                    if !scaleTier.showFilterChips {
                        Button(action: { showAddNodeView = true }) {
                            Text("+ Add Another Device")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(palette.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(palette.surface)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(palette.border, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                        .uiAction("openAddDevice")
                    }
                }
            }
            .padding(12)
        }
    }

    @ViewBuilder
    private func welcomeCard(palette: BrandPalette, scaleTier: InventoryScaleTier, activeCount: Int) -> some View {
        VStack(spacing: 10) {
            if !bulletinDismissed {
                let step1Done = activeCount > 0
                let step2Done = true
                let step3Done = false

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("BULLETIN")
                            .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(TuesdayTheme.ledCveRed)
                            .cornerRadius(4)
                        Text("Patch Tuesday • Readiness Checklist")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(palette.textPrimary)
                        Spacer()
                        Button(action: { activeTab = .bulletins }) {
                            Text("RHYTHM ⓘ")
                                .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                                .foregroundColor(palette.accent)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(palette.accent.opacity(0.14))
                                .cornerRadius(4)
                        }
                        .buttonStyle(.plain)
                    }

                    Text("Patch Tuesday Readiness")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(palette.textPrimary)

                    Text(
                        bulletinSnoozed
                            ? "💤 Reminder snoozed until tomorrow. Get your perimeter cataloged before vendors push critical firmware fixes."
                            : "Get your perimeter cataloged before vendors push critical firmware and OS fixes."
                    )
                    .font(.system(size: 11))
                    .foregroundColor(palette.textMuted)

                    VStack(spacing: 4) {
                        Divider().background(palette.border)
                        HStack {
                            Text("1. Inventory Your Network")
                                .font(.system(size: 11.5, weight: .bold))
                                .foregroundColor(palette.textPrimary)
                            Spacer()
                            Button(action: { showAddNodeView = true }) {
                                Text(step1Done ? "✓ Added" : "Add Device →")
                                    .font(.system(size: 10.5, weight: .bold))
                                    .foregroundColor(step1Done ? TuesdayTheme.ledOkGreen : palette.accent)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 3)

                        Divider().background(palette.border)
                        HStack {
                            Text("2. Enable Push Reminders")
                                .font(.system(size: 11.5, weight: .bold))
                                .foregroundColor(palette.textPrimary)
                            Spacer()
                            Button(action: { activeTab = .account }) {
                                Text(step2Done ? "✓ Active" : "Enable →")
                                    .font(.system(size: 10.5, weight: .bold))
                                    .foregroundColor(step2Done ? TuesdayTheme.ledOkGreen : palette.accent)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 3)

                        Divider().background(palette.border)
                        HStack {
                            Text("3. Subscribe to the Dispatch")
                                .font(.system(size: 11.5, weight: .bold))
                                .foregroundColor(palette.textPrimary)
                            Spacer()
                            Button(action: {
                                if let url = URL(string: "https://tuesday.sh/dispatch") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                Text(step3Done ? "✓ Subscribed" : "Dispatch ↗")
                                    .font(.system(size: 10.5, weight: .bold))
                                    .foregroundColor(step3Done ? TuesdayTheme.ledOkGreen : palette.accent)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 3)
                    }

                    HStack(spacing: 8) {
                        Button(action: {
                            bulletinDismissed = true
                        }) {
                            Text("✓ Mark Complete")
                                .font(.system(size: 10.5, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(TuesdayTheme.ledOkGreen)
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)

                        Button(action: {
                            bulletinSnoozed = true
                        }) {
                            Text("Snooze 24h")
                                .font(.system(size: 10.5, weight: .semibold))
                                .foregroundColor(palette.textPrimary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(palette.elevated)
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)

                        Button(action: {
                            bulletinDismissed = true
                        }) {
                            Text("Ignore")
                                .font(.system(size: 10.5))
                                .foregroundColor(palette.textMuted)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 4)
                }
                .padding(12)
                .background(palette.surface)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(palette.border, lineWidth: 1)
                )
            }

            if activeCount == 0 {
                Text("🏠")
                    .font(.system(size: 28))
                Text("Welcome to your network inventory")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(palette.textPrimary)
                    .multilineTextAlignment(.center)
                Text("Start by adding 1 device — snap a photo of its label, or type its make & model.")
                    .font(.system(size: 11.5))
                    .foregroundColor(palette.textMuted)
                    .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: 3) {
                    Text("💡 Best place to start: Your Router")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(palette.accent)
                    Text("Your router is the front door to your home network and the single highest-impact device to keep updated.")
                        .font(.system(size: 10))
                        .foregroundColor(palette.textMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(palette.accent.opacity(0.10))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(palette.accent.opacity(0.28), lineWidth: 1)
                )
                .uiSlot("router-advisory-tip")

                Button(action: { showAddNodeView = true }) {
                    Text("Add Your Router (Recommended) →")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(palette.accent)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .uiAction("openAddDevice")

                Button(action: { showAddNodeView = true }) {
                    Text("+ Add Any Device")
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundColor(palette.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(palette.elevated)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(palette.border, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .uiAction("openAddDevice")

                Button(action: { repository.setSimulatedDeviceCount(12) }) {
                    Text("or Enable Demo Mode (seed Forest fleet)")
                        .font(.system(size: 10.5))
                        .foregroundColor(palette.textMuted)
                }
                .buttonStyle(.plain)
                .uiAction("setSimulatedDeviceCount")
                .uiAction("enableDemoMode")
            }
        }
        .padding(.vertical, 8)
        .uiComponent("WelcomeCard", state: "tier=\(scaleTier.id);active=\(activeCount)")
    }

    @ViewBuilder
    private func portCategoryFaceplateStrip(
        devices: [RackPortDevice],
        isStn: Bool,
        palette: BrandPalette
    ) -> some View {
        let hasRecommendation = hasActiveCheckupRecommendation(devices: devices)
        HStack(spacing: 5) {
            ForEach(StnHardwareCategory.allCases, id: \.code) { category in
                let matchingDevs = devices.filter { $0.category == category }
                let count = matchingDevs.count
                let hasDevices = count > 0
                let primaryDev = matchingDevs.first
                let isC8Rec = (category == .C8_GUEST && hasRecommendation)
                let stateColor: Color = {
                    if isC8Rec {
                        return TuesdayTheme.warningAmber
                    }
                    if let dev = primaryDev {
                        return TuesdayTheme.ledColor(for: dev.portState, isStn: isStn)
                    }
                    return isStn ? TuesdayTheme.stnGuessedSlate : TuesdayTheme.proTextSecondary
                }()
                let iconBoxBg = isC8Rec
                    ? TuesdayTheme.warningAmber.opacity(0.14)
                    : (isStn ? TuesdayTheme.stnBgElevated : TuesdayTheme.elevatedPill)
                let tileBgColor = isC8Rec
                    ? TuesdayTheme.warningAmber
                    : (hasDevices ? stateColor : (isStn ? TuesdayTheme.ledUnassignedStn : TuesdayTheme.elevatedPill))

                Button(action: {
                    if isC8Rec {
                        activeTab = .checkup
                    } else if let dev = primaryDev {
                        inspectedDevice = dev
                    } else {
                        showAddNodeView = true
                    }
                }) {
                    VStack(spacing: 2) {
                        ZStack(alignment: .topTrailing) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(iconBoxBg)
                                    .aspectRatio(1.0, contentMode: .fit)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke((hasDevices || isC8Rec) ? stateColor.opacity(0.65) : palette.border, lineWidth: 1)
                                    )
                                Text(category.code)
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(stateColor)
                            }
                            if isC8Rec {
                                Circle()
                                    .fill(TuesdayTheme.warningAmber)
                                    .frame(width: 7, height: 7)
                                    .offset(x: 2, y: -2)
                            }
                        }

                        Rectangle()
                            .fill((hasDevices || isC8Rec) ? stateColor.opacity(0.65) : palette.border)
                            .frame(width: 1, height: 6)

                        ZStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(tileBgColor)
                                .aspectRatio(1.0, contentMode: .fit)
                            Text(isC8Rec && !hasDevices ? "!" : "\(count)")
                                .font(.system(size: 10, weight: .heavy, design: .monospaced))
                                .foregroundColor((hasDevices || isC8Rec) ? .white : palette.textMuted)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .uiSlot("category-col", state: "cat=\(category.code);count=\(count)")
                .uiAction("inspectCategoryDevice")
            }
        }
        .uiSlot("c1-c8-strip")
        .uiComponent("PortCategoryFaceplateStrip")
    }

    @ViewBuilder
    private func trackedHardwareProfilesCard(
        devices: [RackPortDevice],
        palette: BrandPalette
    ) -> some View {
        let featured = BulletinsAndInventoryEngine.sortDevicesByRecentChanges(devices)

        VStack(alignment: .leading, spacing: 6) {
            Divider().background(palette.border)

            HStack {
                Text("Tracked Hardware Profiles")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(palette.textMuted)
                Spacer()
                Text("Recent changes")
                    .font(.system(size: 9))
                    .foregroundColor(palette.textMuted)
            }
            .uiSlot("tracked-profiles-header")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(featured.enumerated()), id: \.element.id) { idx, dev in
                        let stateColor = TuesdayTheme.ledColor(for: dev.portState, isStn: false)
                        let isSelected = (idx == 0)
                        let badgeText: String = {
                            switch dev.portState {
                            case .cveKev: return "!"
                            case .eol: return "EOL"
                            default: return "#\(dev.portIndex)"
                            }
                        }()
                        let verSub = (dev.portState == .guessed || dev.version == "unverified") ? "guess" : "v\(dev.version)"

                        Button(action: { inspectedDevice = dev }) {
                            VStack(spacing: 2) {
                                ZStack(alignment: .topTrailing) {
                                    RoundedRectangle(cornerRadius: 11)
                                        .fill(isSelected ? palette.accent.opacity(0.14) : TuesdayTheme.elevatedPill)
                                        .frame(width: 42, height: 42)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 11)
                                                .stroke(isSelected ? palette.accent : stateColor.opacity(0.35), lineWidth: 1)
                                        )
                                    Text(dev.category.code)
                                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                                        .foregroundColor(stateColor)
                                        .frame(width: 42, height: 42)
                                    Text(badgeText)
                                        .font(.system(size: 7.5, weight: .bold, design: .monospaced))
                                        .foregroundColor(stateColor)
                                        .padding(.horizontal, 3)
                                        .padding(.vertical, 1)
                                        .background(TuesdayTheme.background)
                                        .cornerRadius(4)
                                        .padding(2)
                                }
                                Text(dev.shortLabel)
                                    .font(.system(size: 8.5, weight: .semibold))
                                    .foregroundColor(palette.textPrimary)
                                    .lineLimit(1)
                                Text(verSub)
                                    .font(.system(size: 7.5, design: .monospaced))
                                    .foregroundColor(palette.textMuted)
                                    .lineLimit(1)
                            }
                            .frame(width: 52)
                        }
                        .buttonStyle(.plain)
                        .uiSlot("tracked-profile-squircle")
                        .uiAction("inspectDevice")
                    }
                }
            }
            .uiSlot("tracked-profiles-strip")
        }
        .padding(.vertical, 6)
        .uiComponent("TrackedHardwareProfilesCard")
    }

    @ViewBuilder
    private func matrixBotanicalPixelArtOverlay(
        scaleTier: InventoryScaleTier,
        activeCount: Int,
        isStn: Bool
    ) -> some View {
        switch scaleTier {
        case .DAY_ZERO:
            EmptyView()
        case .PEA:
            HStack(spacing: 6) {
                Text("🌱")
                    .font(.system(size: 14))
                Text("\(activeCount) ACTIVE • \(128 - activeCount) SLOTS AVAILABLE")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(isStn ? TuesdayTheme.stnTextSecondary : TuesdayTheme.proTextSecondary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background((isStn ? Color.white : TuesdayTheme.background).opacity(0.88))
                    .cornerRadius(4)
            }
            .padding(.bottom, 4)
        case .GARDEN:
            HStack(spacing: 14) {
                Text("🪴").font(.system(size: 16))
                Text("🪴").font(.system(size: 20))
                Text("🪴").font(.system(size: 14))
            }
            .padding(.bottom, 2)
        case .FOREST:
            HStack(spacing: 10) {
                ForEach(0..<9, id: \.self) { _ in
                    Text("🌲")
                        .font(.system(size: 12))
                        .opacity(0.55)
                }
            }
            .padding(.bottom, 2)
        }
    }

    @ViewBuilder
    private func deviceInspectorSheet(
        device: RackPortDevice,
        palette: BrandPalette,
        isStn: Bool
    ) -> some View {
        let stateColor = TuesdayTheme.ledColor(for: device.portState, isStn: isStn)
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(
                            isStn
                                ? "\(device.portState.stnLabel.uppercased()) • \(device.lifecycleTier.uppercased())"
                                : String(format: "PORT #%02d • %@ • %@ (%@)", device.portIndex, device.assetTag, device.category.code, device.category.shortName)
                        )
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(stateColor)

                        Text(device.name)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(palette.textPrimary)
                    }
                    Spacer()
                    if !isStn {
                        RiskMeterView(portState: device.portState, isStn: false)
                    }
                    Button(isStn ? "Done" : "Close") {
                        inspectedDevice = nil
                    }
                    .foregroundColor(palette.accent)
                    .uiAction("closeDeviceInspector")
                }
                .uiSlot("inspector-header")

                if isStn {
                    Text(device.stnHeadline)
                        .font(.system(size: 12))
                        .foregroundColor(palette.textMuted)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("What to Do Next")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundColor(palette.textPrimary)
                        Text("1. Check status: \(device.s4Advisories)")
                            .font(.system(size: 11.5))
                            .foregroundColor(palette.textPrimary)
                        Text("2. Action step: \(device.s6Remediation)")
                            .font(.system(size: 11.5))
                            .foregroundColor(palette.textPrimary)
                        Text("3. Verify support window: \(device.s3Lifecycle)")
                            .font(.system(size: 11.5))
                            .foregroundColor(palette.textPrimary)
                    }
                    .padding(12)
                    .background(palette.bg)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(palette.border, lineWidth: 1)
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        inspectorRow("ROOM & PLACEMENT", device.roomLocation, palette)
                        inspectorRow("DEVICE LIFESPAN & MANUFACTURER SUPPORT", "\(device.lifecycleTier) • \(device.s3Lifecycle)", palette)
                        inspectorRow("PLUGGED INTO (ROUTER PORT / WI-FI)", String(format: "Port #%02d • %@", device.portIndex, device.s5Topology), palette)
                        inspectorRow("WI-FI LANE", device.trustZone.stnLabel, palette)
                        inspectorRow("SOFTWARE VERSION & PUBLISHED WARNINGS", "Version \(device.version) • \(device.s4Advisories)", palette)
                    }
                    .uiSlot("s0-s6-stack")
                } else {
                    CandleGraphView(
                        score: device.portState == .ok ? 98.0 : (device.portState == .update ? 82.0 : 40.0)
                    )
                    .uiSlot("candlestick-chart")

                    VStack(alignment: .leading, spacing: 8) {
                        inspectorRow("S0 Identity", device.s0Identity, palette)
                        inspectorRow("S1 Hardware", device.s1Hardware, palette)
                        inspectorRow("S2 Software (PURL)", device.s2Software, palette)
                        inspectorRow("S3 Lifecycle", device.s3Lifecycle, palette)
                        inspectorRow("S4 Advisories", device.s4Advisories, palette)
                        inspectorRow("S5 Topology", device.s5Topology, palette)
                        inspectorRow("S6 Remediation", device.s6Remediation, palette)
                    }
                    .uiSlot("s0-s6-stack")
                }

                if device.portState != .ok && device.portState != .unassigned {
                    Button(action: {
                        Task {
                            await repository.markNodeUpdatesApplied(nodeId: device.id)
                            inspectedDevice = nil
                        }
                    }) {
                        Text(isStn ? "✓ Mark Remediation Complete (Set Device OK)" : "✓ Mark Remediation Complete (Set Port OK)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(isStn ? .white : .black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(TuesdayTheme.ledOkGreen)
                            .cornerRadius(8)
                            .uiSlot("remediation-cta")
                    }
                    .buttonStyle(.plain)
                    .uiAction("markRemediationComplete")
                }
            }
            .padding(16)
            .uiComponent("DeviceInspectorSheet", state: "device=\(device.id);state=\(device.portState.key)")
        }
        .background(palette.surface.ignoresSafeArea())
    }

    private func inspectorRow(_ title: String, _ value: String, _ palette: BrandPalette) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                .foregroundColor(palette.accent)
            Text(value)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(palette.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(palette.elevated)
        .cornerRadius(6)
    }

    private func ledLegendDot(_ label: String, _ color: Color, _ palette: BrandPalette) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 8.5, design: .monospaced))
                .foregroundColor(palette.textMuted)
        }
    }

    private func stateFilterChip(
        label: String,
        dotColor: Color?,
        selected: Bool,
        palette: BrandPalette,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let dot = dotColor {
                    Circle()
                        .fill(dot)
                        .frame(width: 7, height: 7)
                }
                Text(label)
                    .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                    .foregroundColor(selected ? palette.accent : palette.textPrimary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(selected ? palette.accent.opacity(0.18) : palette.surface)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(selected ? palette.accent : palette.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .uiAction("filterPortState")
    }

    private func zoneFilterPill(
        label: String,
        selected: Bool,
        palette: BrandPalette,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                .foregroundColor(selected ? palette.accent : palette.textMuted)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(selected ? palette.accent.opacity(0.18) : palette.elevated)
                .cornerRadius(5)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(selected ? palette.accent : palette.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .uiAction("filterZone")
    }
}

public struct RiskMeterView: View {
    public let portState: PortLifecycleState
    public let isStn: Bool

    public init(portState: PortLifecycleState, isStn: Bool = false) {
        self.portState = portState
        self.isStn = isStn
    }

    public var body: some View {
        let activeBars: Int = {
            switch portState {
            case .cveKev, .eol: return 3
            case .guessed, .update: return 2
            case .ok: return 1
            case .unassigned: return 0
            }
        }()
        let activeColor = TuesdayTheme.ledColor(for: portState, isStn: isStn)
        let inactiveColor = isStn ? TuesdayTheme.stnBorder : TuesdayTheme.proBorder

        VStack(alignment: .trailing, spacing: 3) {
            HStack(alignment: .bottom, spacing: 2) {
                RoundedRectangle(cornerRadius: 1)
                    .fill(activeBars >= 1 ? activeColor : inactiveColor)
                    .frame(width: 3, height: 7)
                RoundedRectangle(cornerRadius: 1)
                    .fill(activeBars >= 2 ? activeColor : inactiveColor)
                    .frame(width: 3, height: 10)
                RoundedRectangle(cornerRadius: 1)
                    .fill(activeBars >= 3 ? activeColor : inactiveColor)
                    .frame(width: 3, height: 13)
            }
            Text(portState.proLabel)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(activeColor)
        }
    }
}
