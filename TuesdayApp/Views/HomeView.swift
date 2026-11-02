import SwiftUI

public enum MainNavigationTab: String, CaseIterable {
    case status
    case bulletins
    case timeline
    case checkup
    case plugAndTag

    public func label(for flavor: AppBrandFlavor) -> String {
        let isStn = (flavor == .sureThingHome)
        switch self {
        case .status: return isStn ? "Home" : "Status"
        case .bulletins: return "Bulletins"
        case .timeline: return isStn ? "Lifespan" : "Timeline"
        case .checkup: return isStn ? "Checkup" : "Q4 Tune-Up"
        case .plugAndTag: return isStn ? "Add Device" : "Plug & Tag"
        }
    }

    public var systemIcon: String {
        switch self {
        case .status: return "square.grid.4x3.fill"
        case .bulletins: return "bell.badge.fill"
        case .timeline: return "chart.bar.xaxis"
        case .checkup: return "checklist"
        case .plugAndTag: return "camera.viewfinder"
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

        let ledSlots = BulletinsAndInventoryEngine.build128LedMatrix(
            devices: repository.rackDevices,
            zoneFilter: repository.selectedZoneFilter
        )
        let actionDevices = BulletinsAndInventoryEngine.filterActionFirstDevices(
            devices: repository.rackDevices,
            includeOk: repository.includeOkDevices,
            zoneFilter: repository.selectedZoneFilter
        )
        let bulletinsPayload = BulletinsAndInventoryEngine.assembleBulletins(
            flavor: repository.brandFlavor,
            devices: repository.rackDevices,
            mutedFeedSlugs: repository.mutedFeedSlugs
        )

        NavigationStack {
            ZStack {
                palette.bg.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Main Tab Content
                    Group {
                        switch activeTab {
                        case .status:
                            statusMatrixAndActionList(
                                palette: palette,
                                isStn: isStn,
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
                                onRejectModel: { repository.rejectProvisionalDeviceModel() }
                            )
                        case .timeline:
                            timelineView(palette: palette, isStn: isStn)
                        case .checkup:
                            checkupView(palette: palette, isStn: isStn)
                        case .plugAndTag:
                            EmptyView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    // 5-Item Custom Bottom Navigation Bar
                    HStack(spacing: 0) {
                        ForEach(MainNavigationTab.allCases, id: \.self) { tab in
                            let selected = (activeTab == tab)
                            Button(action: {
                                if tab == .plugAndTag {
                                    showAddNodeView = true
                                } else {
                                    activeTab = tab
                                }
                            }) {
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
                        }
                    }
                    .background(palette.surface)
                    .overlay(
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(palette.border),
                        alignment: .top
                    )
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
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(palette.accent)
                                .frame(width: 24, height: 24)
                            Image(systemName: "shippingbox.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                        }
                        Text(repository.brandFlavor.title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(palette.textPrimary)

                        Button(action: { repository.toggleBrandFlavor() }) {
                            Text(repository.brandFlavor.badge)
                                .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                                .foregroundColor(palette.accent)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(palette.elevated)
                                .cornerRadius(5)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("brand_flavor_toggle_button")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showHacsSheet = true }) {
                        HStack(spacing: 5) {
                            Circle()
                                .fill(repository.hacsConfig.isConnected ? TuesdayTheme.ledOkGreen : TuesdayTheme.ledCveRed)
                                .frame(width: 7, height: 7)
                            Text("HACS")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(palette.accent)
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(palette.elevated)
                        .clipShape(Capsule())
                    }
                    .accessibilityIdentifier("hacs_settings_pill_button")
                }
            }
            .navigationDestination(isPresented: $showAddNodeView) {
                AddNodeView(repository: repository)
            }
            .sheet(item: $inspectedDevice) { device in
                deviceInspectorSheet(device: device, palette: palette)
            }
            .sheet(isPresented: $showHacsSheet) {
                HacsPairingSheet(
                    repository: repository,
                    networkMonitor: networkMonitor
                )
            }
        }
    }

    @ViewBuilder
    private func statusMatrixAndActionList(
        palette: BrandPalette,
        isStn: Bool,
        ledSlots: [LedSlot],
        actionDevices: [RackPortDevice]
    ) -> some View {
        let okCount = ledSlots.filter { $0.state == .ok }.count
        let cveCount = ledSlots.filter { $0.state == .cveKev }.count
        let eolCount = ledSlots.filter { $0.state == .eol }.count
        let guessedCount = ledSlots.filter { $0.state == .guessed }.count
        let updateCount = ledSlots.filter { $0.state == .update }.count

        let gridColumns = Array(repeating: GridItem(.flexible(), spacing: 3), count: 16)

        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // 1. 128-LED At-a-Glance Status Matrix Card
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(isStn ? "HOME DEVICE STATUS MATRIX (\(ledSlots.count) NODES)" : "AT-A-GLANCE STATUS MATRIX (\(ledSlots.count) LEDS • Z0→Z4)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(palette.textPrimary)
                        Spacer()
                        Text("\(okCount) OK • \(ledSlots.count - okCount) Action")
                            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                            .foregroundColor(palette.accent)
                    }

                    // Legend
                    HStack {
                        ledLegendDot("OK (\(okCount))", TuesdayTheme.ledOkGreen, palette)
                        Spacer()
                        ledLegendDot("CVE (\(cveCount))", TuesdayTheme.ledCveRed, palette)
                        Spacer()
                        ledLegendDot("EOL (\(eolCount))", TuesdayTheme.ledEolAmber, palette)
                        Spacer()
                        ledLegendDot("Guess (\(guessedCount))", TuesdayTheme.ledGuessedGrey, palette)
                        Spacer()
                        ledLegendDot("Upd (\(updateCount))", TuesdayTheme.ledUpdateBlue, palette)
                    }

                    // 16x8 LED Matrix (zero text inside LED squares)
                    LazyVGrid(columns: gridColumns, spacing: 3) {
                        ForEach(ledSlots) { slot in
                            let color = TuesdayTheme.ledColor(for: slot.state)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(color.opacity(slot.state == .ok ? 0.78 : 1.0))
                                .aspectRatio(1.0, contentMode: .fit)
                                .onTapGesture {
                                    if let devId = slot.deviceId,
                                       let found = repository.rackDevices.first(where: { $0.id == devId }) {
                                        inspectedDevice = found
                                    }
                                }
                        }
                    }
                    .padding(6)
                    .background(Color(red: 0x07 / 255.0, green: 0x0A / 255.0, blue: 0x0F / 255.0))
                    .cornerRadius(6)

                    // Zone Filter Pills
                    HStack(spacing: 5) {
                        zonePill(label: "All (128)", selected: repository.selectedZoneFilter == nil, palette: palette) {
                            repository.selectedZoneFilter = nil
                        }
                        ForEach([TrustZone.z0Core, .z1Trusted, .z2Lab, .z3Iot], id: \.self) { zone in
                            zonePill(label: zone.shortCode, selected: repository.selectedZoneFilter == zone, palette: palette) {
                                repository.selectedZoneFilter = zone
                            }
                        }
                    }
                }
                .padding(10)
                .background(palette.surface)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(palette.border, lineWidth: 1)
                )

                // 2. Action-First Device List Header + Show OK Toggle
                HStack {
                    Text(repository.includeOkDevices ? "ALL NAMED DEVICES (\(actionDevices.count))" : "NEEDS ATTENTION (\(actionDevices.count) NON-GREEN)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(palette.textMuted)
                    Spacer()
                    Button(action: { repository.toggleIncludeOkDevices() }) {
                        Text(repository.includeOkDevices ? "Hide OK Devices" : "Show OK Devices (+119)")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(palette.accent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(palette.elevated)
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("toggle_show_ok_devices_button")
                }

                // 3. Action-First Device Rows
                ForEach(actionDevices) { dev in
                    let stateColor = TuesdayTheme.ledColor(for: dev.portState)
                    Button(action: { inspectedDevice = dev }) {
                        HStack(spacing: 10) {
                            Text(String(format: "#%02d", dev.portIndex))
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(stateColor)
                                .frame(width: 34, height: 34)
                                .background(stateColor.opacity(0.16))
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(stateColor, lineWidth: 1)
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(dev.name)
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(palette.textPrimary)
                                    Spacer()
                                    Text("\(dev.trustZone.shortCode) • \(dev.version)")
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(palette.textMuted)
                                }
                                Text(isStn ? dev.stnHeadline : dev.proHeadline)
                                    .font(.system(size: 10))
                                    .foregroundColor(stateColor)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                        .padding(10)
                        .background(palette.surface)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(palette.border, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
        }
    }

    @ViewBuilder
    private func timelineView(palette: BrandPalette, isStn: Bool) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(repository.rackDevices) { dev in
                    let stateColor = TuesdayTheme.ledColor(for: dev.portState)
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text(String(format: "#%02d %@", dev.portIndex, dev.name))
                                .font(.system(size: 11.5, weight: .bold))
                                .foregroundColor(palette.textPrimary)
                            Spacer()
                            Text("\(dev.trustZone.shortCode) • \(dev.lifecycleTier)")
                                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                                .foregroundColor(stateColor)
                        }
                        Text(dev.s3Lifecycle)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(palette.textMuted)
                    }
                    .padding(10)
                    .background(palette.surface)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(palette.border, lineWidth: 1))
                }
            }
            .padding(12)
        }
    }

    @ViewBuilder
    private func checkupView(palette: BrandPalette, isStn: Bool) -> some View {
        let nonGreen = repository.rackDevices.filter { $0.portState != .ok }
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(nonGreen) { dev in
                    let stateColor = TuesdayTheme.ledColor(for: dev.portState)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(String(format: "Port #%02d • %@", dev.portIndex, dev.name))
                                .font(.system(size: 11.5, weight: .bold))
                                .foregroundColor(palette.textPrimary)
                            Spacer()
                            Text(isStn ? dev.portState.stnLabel : dev.portState.proLabel)
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(stateColor)
                        }
                        Text(dev.s6Remediation)
                            .font(.system(size: 10.5))
                            .foregroundColor(palette.textMuted)
                    }
                    .padding(10)
                    .background(palette.surface)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(palette.border, lineWidth: 1))
                }
            }
            .padding(12)
        }
    }

    @ViewBuilder
    private func deviceInspectorSheet(device: RackPortDevice, palette: BrandPalette) -> some View {
        let stateColor = TuesdayTheme.ledColor(for: device.portState)
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(format: "PORT #%02d • %@", device.portIndex, device.assetTag))
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(stateColor)
                        Text(device.name)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(palette.textPrimary)
                    }
                    Spacer()
                    Button("Close") { inspectedDevice = nil }
                        .foregroundColor(palette.accent)
                }

                CandleGraphView(
                    score: device.portState == .ok ? 98.0 : (device.portState == .update ? 82.0 : 40.0),
                    status: device.portState == .ok ? .healthy : (device.portState == .cveKev ? .critical : .warning)
                )

                inspectorRow("S0 Identity", device.s0Identity, palette)
                inspectorRow("S1 Hardware", device.s1Hardware, palette)
                inspectorRow("S2 Software (PURL)", device.s2Software, palette)
                inspectorRow("S3 Lifecycle", device.s3Lifecycle, palette)
                inspectorRow("S4 Advisories", device.s4Advisories, palette)
                inspectorRow("S5 Topology", device.s5Topology, palette)
                inspectorRow("S6 Remediation", device.s6Remediation, palette)

                if device.portState != .ok {
                    Button(action: {
                        Task {
                            await repository.markNodeUpdatesApplied(nodeId: device.id)
                            inspectedDevice = nil
                        }
                    }) {
                        Text("Mark Remediation Complete (Set Port OK)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(TuesdayTheme.ledOkGreen)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
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
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 7, height: 7)
            Text(label)
                .font(.system(size: 8.5, design: .monospaced))
                .foregroundColor(palette.textMuted)
        }
    }

    private func zonePill(label: String, selected: Bool, palette: BrandPalette, action: @escaping () -> Void) -> some View {
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
    }
}
