import SwiftUI

/// Ported from SureThingNet's `HomeScreen` (`home_screen.dart`)
/// Adapted for Tuesday.sh package update telemetry and Home Assistant HACS integration.
public struct HomeView: View {
    @ObservedObject var repository: MockHacsTuesdayService
    @ObservedObject var networkMonitor: NetworkMonitorService

    @State private var expandedNodeIds: Set<String> = ["node-ubuntu-dev"]
    @State private var showHacsSheet: Bool = false

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
        NavigationStack {
            ZStack {
                TuesdayTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        fleetSummaryCard

                        nodesSectionHeader

                        if repository.nodes.isEmpty {
                            emptyStateCard
                        } else {
                            VStack(spacing: 12) {
                                ForEach(repository.nodes) { node in
                                    nodeCard(for: node)
                                }
                            }
                        }

                        hacsFooterSection
                    }
                    .padding(16)
                }
                .refreshable {
                    await repository.refreshTelemetry()
                    await networkMonitor.refreshSsid()
                }

                WifiWarningOverlay(
                    isVisible: shouldShowWifiOverlay,
                    hacsUrl: repository.hacsConfig.baseUrl,
                    onDisableLocalRequirement: {
                        var cfg = repository.hacsConfig
                        cfg.requireLocalWifi = false
                        repository.updateHacsConfig(cfg)
                        networkMonitor.simulateWifiDisconnected = false
                    }
                )
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(TuesdayTheme.appBar, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(TuesdayTheme.healthyGreen)
                                .frame(width: 28, height: 28)
                            Image(systemName: "shippingbox.and.arrow.backward.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.black)
                        }
                        Text("Tuesday.sh")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showHacsSheet = true
                    } label: {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(repository.hacsConfig.isConnected ? TuesdayTheme.hacsCyan : TuesdayTheme.criticalRed)
                                .frame(width: 7, height: 7)
                            Text("HACS")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(TuesdayTheme.hacsCyan)
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color(white: 0.75))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(TuesdayTheme.elevatedPill)
                        .clipShape(Capsule())
                    }
                    .accessibilityIdentifier("open_hacs_settings_button")
                }
            }
            .sheet(isPresented: $showHacsSheet) {
                HacsPairingSheet(
                    repository: repository,
                    networkMonitor: networkMonitor
                )
            }
        }
        .preferredColorScheme(.dark)
    }

    private var fleetSummaryCard: some View {
        let criticalNodes = repository.nodes.filter { $0.status == .critical }.count
        let warningNodes = repository.nodes.filter { $0.status == .warning }.count
        let totalPendingPackages = repository.nodes.reduce(0) { $0 + $1.pendingUpdates.count }

        let stateColor: Color = {
            if criticalNodes > 0 { return TuesdayTheme.criticalRed }
            if warningNodes > 0 { return TuesdayTheme.warningAmber }
            return TuesdayTheme.healthyGreen
        }()

        let stateTitle: String = {
            if criticalNodes > 0 {
                return "\(criticalNodes) Critical Security Alert\(criticalNodes == 1 ? "" : "s")"
            } else if warningNodes > 0 {
                return "\(warningNodes) Device\(warningNodes == 1 ? "" : "s") With Outdated Packages"
            } else {
                return "All Devices Up to Date"
            }
        }()

        let stateSubtitle: String = {
            if criticalNodes > 0 {
                return "\(totalPendingPackages) total package updates pending across HACS & Tuesday devices."
            } else if warningNodes > 0 {
                return "\(totalPendingPackages) non-critical package updates queued for Tuesday window."
            } else {
                return "Every monitored device passed active package update policies."
            }
        }()

        return VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: criticalNodes == 0 && warningNodes == 0 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(stateColor)

                VStack(alignment: .leading, spacing: 4) {
                    Text(stateTitle)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .accessibilityIdentifier("fleet_summary_title")

                    Text(stateSubtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(Color(white: 0.72))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }

            Divider().background(Color.white.opacity(0.12))

            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(TuesdayTheme.hacsCyan)
                    Text(repository.hacsConfig.instanceName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color(white: 0.72))
                }

                Spacer()

                HStack(spacing: 6) {
                    Image(systemName: "wifi")
                        .font(.system(size: 11))
                        .foregroundStyle(TuesdayTheme.healthyGreen)
                    Text(networkMonitor.currentSsid)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .accessibilityIdentifier("current_ssid_badge")
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(TuesdayTheme.elevatedPill)
                .clipShape(Capsule())
            }
        }
        .padding(20)
        .background(TuesdayTheme.cardSurface)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(stateColor.opacity(0.38), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var nodesSectionHeader: some View {
        HStack {
            Text("DEVICES (\(repository.nodes.count))")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color(white: 0.62))
                .tracking(1.0)
                .accessibilityIdentifier("devices_section_header")

            Spacer()

            NavigationLink {
                AddNodeView(repository: repository)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 13, weight: .bold))
                    Text("Add Device")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundStyle(TuesdayTheme.healthyGreen)
            }
            .accessibilityIdentifier("navigate_add_device_button")
        }
    }

    private var emptyStateCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "server.rack")
                .font(.system(size: 42))
                .foregroundStyle(Color(white: 0.45))
            Text("No Monitored Devices")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
            Text("Inventory your routers, IoT devices, Linux servers, or Home Assistant HACS nodes by photo or agent enrollment.")
                .font(.system(size: 13))
                .foregroundStyle(Color(white: 0.6))
                .multilineTextAlignment(.center)
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(TuesdayTheme.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func nodeCard(for node: MonitoredNode) -> some View {
        let statusColor = TuesdayTheme.color(for: node.status)
        let isExpanded = expandedNodeIds.contains(node.id)

        return VStack(alignment: .leading, spacing: 14) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if isExpanded {
                        expandedNodeIds.remove(node.id)
                    } else {
                        expandedNodeIds.insert(node.id)
                    }
                }
            } label: {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(node.hostname)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(.white)

                            Text(node.packageManager.rawValue.uppercased())
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundStyle(TuesdayTheme.hacsCyan)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(TuesdayTheme.hacsCyan.opacity(0.14))
                                .clipShape(RoundedRectangle(cornerRadius: 4))

                            if let invState = node.inventoryState, invState != .enrolled {
                                let invColor = invState == .verified ? TuesdayTheme.healthyGreen : TuesdayTheme.warningAmber
                                Text(invState.rawValue)
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundStyle(invColor)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(invColor.opacity(0.14))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                        }

                        Text(node.osDetails)
                            .font(.system(size: 12))
                            .foregroundStyle(Color(white: 0.68))
                            .multilineTextAlignment(.leading)

                        if let meta = node.discoveredMetadata {
                            HStack(spacing: 8) {
                                if let model = meta.modelNumber, !model.isEmpty {
                                    Text("Model: \(model)")
                                }
                                if let mac = meta.macAddress, !mac.isEmpty {
                                    Text("MAC: \(mac)")
                                }
                                if let sn = meta.serialNumber, !sn.isEmpty {
                                    Text("S/N: \(sn)")
                                }
                            }
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(Color(white: 0.58))
                        }
                    }

                    Spacer()

                    Text(node.status.displayTitle.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(statusColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusColor.opacity(0.14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(statusColor.opacity(0.45), lineWidth: 0.8)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("node_card_header_\(node.hostname)")

            Divider().background(Color.white.opacity(0.12))

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("HACS ENTITY ID")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color(white: 0.55))
                    Text(node.haEntityId)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Color(white: 0.82))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("OUTDATED PACKAGES")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color(white: 0.55))
                    Text(node.pendingUpdates.isEmpty ? "0 (Up to date)" : "\(node.pendingUpdates.count) update\(node.pendingUpdates.count == 1 ? "" : "s") available")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(node.pendingUpdates.isEmpty ? TuesdayTheme.healthyGreen : statusColor)
                }
            }

            CandleGraphView(score: node.healthScore)

            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Divider().background(Color.white.opacity(0.12))

                    if node.pendingUpdates.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(TuesdayTheme.healthyGreen)
                                .font(.system(size: 13))
                            Text("No pending \(node.packageManager.rawValue) updates reported by Tuesday agent.")
                                .font(.system(size: 12))
                                .foregroundStyle(Color(white: 0.72))
                        }
                        .padding(.vertical, 4)
                    } else {
                        ForEach(node.pendingUpdates) { pkg in
                            PackageDiffRow(update: pkg)
                        }
                    }

                    HStack(spacing: 10) {
                        Button {
                            Task {
                                await repository.triggerNodeCheckIn(nodeId: node.id)
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 11, weight: .bold))
                                Text("Poll HACS Agent")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(TuesdayTheme.elevatedPill)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .accessibilityIdentifier("poll_node_button_\(node.hostname)")

                        if !node.pendingUpdates.isEmpty {
                            Button {
                                Task {
                                    await repository.markNodeUpdatesApplied(nodeId: node.id)
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 11, weight: .bold))
                                    Text("Simulate Patch Run")
                                        .font(.system(size: 12, weight: .semibold))
                                }
                                .foregroundStyle(.black)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(TuesdayTheme.healthyGreen)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .accessibilityIdentifier("patch_node_button_\(node.hostname)")
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding(16)
        .background(TuesdayTheme.cardSurface)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    node.status == .healthy ? Color.white.opacity(0.08) : statusColor.opacity(0.35),
                    lineWidth: 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var hacsFooterSection: some View {
        VStack(spacing: 10) {
            Divider().background(Color.white.opacity(0.15))
                .padding(.vertical, 8)

            HStack(spacing: 8) {
                Image(systemName: "bolt.horizontal.circle.fill")
                    .foregroundStyle(TuesdayTheme.hacsCyan)
                Text("Synced with \(repository.hacsConfig.baseUrl)")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(Color(white: 0.65))
            }

            Text("Tuesday.sh • Calm Package Telemetry for Home Assistant & Linux Fleets")
                .font(.system(size: 11))
                .foregroundStyle(Color(white: 0.48))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}
