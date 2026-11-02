import Foundation
import Combine

@MainActor
public final class MockHacsTuesdayService: TuesdayRepositoryProtocol {
    @Published public private(set) var nodes: [MonitoredNode] = []
    @Published public var rackDevices: [RackPortDevice] = BulletinsAndInventoryEngine.defaultRackPortDevices()
    @Published public var brandFlavor: AppBrandFlavor = .tuesdayPro
    @Published public var mutedFeedSlugs: Set<String> = ["lg-esphome-iot"]
    @Published public var includeOkDevices: Bool = false
    @Published public var selectedZoneFilter: TrustZone? = nil
    @Published public var hacsConfig: HacsConnectionConfig
    @Published public private(set) var isSyncing: Bool = false

    private let nodesCacheKey = "tuesday_mock_nodes_v1"
    private let configCacheKey = "tuesday_mock_hacs_config_v1"
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if let data = defaults.data(forKey: configCacheKey),
           let decoded = try? JSONDecoder().decode(HacsConnectionConfig.self, from: data) {
            self.hacsConfig = decoded
        } else {
            self.hacsConfig = HacsConnectionConfig()
        }

        if let data = defaults.data(forKey: nodesCacheKey),
           let decoded = try? JSONDecoder().decode([MonitoredNode].self, from: data),
           !decoded.isEmpty {
            self.nodes = decoded
        } else {
            self.nodes = Self.defaultSeedNodes()
            persistState()
        }
    }

    public func toggleBrandFlavor() {
        brandFlavor = (brandFlavor == .tuesdayPro) ? .sureThingHome : .tuesdayPro
    }

    public func toggleIncludeOkDevices() {
        includeOkDevices.toggle()
    }

    public func toggleMuteFeed(_ slug: String) {
        if mutedFeedSlugs.contains(slug) {
            mutedFeedSlugs.remove(slug)
        } else {
            mutedFeedSlugs.insert(slug)
        }
    }

    public func confirmProvisionalDeviceModel(_ chosenModel: String) {
        rackDevices = rackDevices.map { dev in
            guard dev.confidenceTier == .provisionalGuess else { return dev }
            var copy = dev
            copy.confidenceTier = .confirmed
            copy.portState = .cveKev
            copy.name = "Hallway Ecobee \(chosenModel)"
            copy.version = "4.8.7.210"
            copy.targetVersion = "4.8.7.220"
            copy.lifecycleTier = "Active"
            copy.purls = ["pkg:generic/ecobee/smart-thermostat@4.8.7.210"]
            copy.proHeadline = "Confirmed (\(chosenModel)): CVE-2026-88901 HomeKit Pairing Fix (4.8.7.220)"
            copy.stnHeadline = "Confirmed (\(chosenModel)): Update thermostat firmware to 4.8.7.220"
            return copy
        }
    }

    public func rejectProvisionalDeviceModel() {
        rackDevices = rackDevices.map { dev in
            guard dev.confidenceTier == .provisionalGuess else { return dev }
            var copy = dev
            copy.confidenceTier = .opaqueUnknown
            copy.excludedPurlPrefixes.append("pkg:generic/ecobee/*")
            copy.proHeadline = "Ecobee Family Excluded • Use Plug & Tag Camera to Identify Exact Model"
            copy.stnHeadline = "Not an Ecobee • Snap a photo of the thermostat label to identify"
            return copy
        }
    }

    public static func defaultSeedNodes(now: Date = Date()) -> [MonitoredNode] {
        return [
            MonitoredNode(
                id: "node-ubuntu-dev",
                hostname: "ubuntu-dev",
                osDetails: "Ubuntu 24.04.1 LTS (Linux 6.8.0-45 x86_64)",
                agentVersion: "0.2.1",
                packageManager: .apt,
                haEntityId: "sensor.tuesday_ubuntu_dev",
                lastCheckIn: now.addingTimeInterval(-12 * 60),
                pendingUpdates: [
                    PackageUpdate(
                        name: "openssl",
                        currentVersion: "3.0.13-1",
                        availableVersion: "3.0.13-4",
                        isSecurityCritical: true,
                        advisoryNote: "CVE-2026-4102 High Severity TLS Fix"
                    ),
                    PackageUpdate(
                        name: "openssh-server",
                        currentVersion: "9.6p1-3",
                        availableVersion: "9.6p1-5",
                        isSecurityCritical: true,
                        advisoryNote: "USN-6891-1 sshd auth hardening"
                    ),
                    PackageUpdate(
                        name: "docker-ce",
                        currentVersion: "27.1.1-1",
                        availableVersion: "27.3.1-1"
                    ),
                    PackageUpdate(
                        name: "jq",
                        currentVersion: "1.7-1",
                        availableVersion: "1.7.1-1"
                    )
                ],
                healthScore: 34.0,
                referenceDate: now
            ),
            MonitoredNode(
                id: "node-homeassistant",
                hostname: "homeassistant.local",
                osDetails: "Home Assistant OS 14.2 (Tuesday HACS Add-on)",
                agentVersion: "0.4.2-hacs",
                packageManager: .hacs,
                haEntityId: "sensor.tuesday_homeassistant",
                lastCheckIn: now.addingTimeInterval(-3 * 60),
                pendingUpdates: [
                    PackageUpdate(
                        name: "hacs/tuesday-server",
                        currentVersion: "0.4.1",
                        availableVersion: "0.4.2"
                    ),
                    PackageUpdate(
                        name: "esphome",
                        currentVersion: "2026.9.1",
                        availableVersion: "2026.10.0"
                    )
                ],
                healthScore: 78.0,
                referenceDate: now
            ),
            MonitoredNode(
                id: "node-lml",
                hostname: "lml.local",
                osDetails: "Unraid NAS 6.12.14 (Docker & APK)",
                agentVersion: "0.2.1",
                packageManager: .docker,
                haEntityId: "sensor.tuesday_lml",
                lastCheckIn: now.addingTimeInterval(-38 * 60),
                pendingUpdates: [
                    PackageUpdate(
                        name: "couchdb",
                        currentVersion: "3.3.3",
                        availableVersion: "3.4.1"
                    ),
                    PackageUpdate(
                        name: "traefik",
                        currentVersion: "v3.1.2",
                        availableVersion: "v3.1.6"
                    ),
                    PackageUpdate(
                        name: "tailscale",
                        currentVersion: "1.72.1",
                        availableVersion: "1.76.1"
                    )
                ],
                healthScore: 68.0,
                referenceDate: now
            ),
            MonitoredNode(
                id: "node-aaronpro18",
                hostname: "aaronpro18",
                osDetails: "macOS Sequoia 15.7.9 (Darwin 24.6.0 x86_64)",
                agentVersion: "0.2.1",
                packageManager: .brew,
                haEntityId: "sensor.tuesday_aaronpro18",
                lastCheckIn: now.addingTimeInterval(-5 * 60),
                pendingUpdates: [],
                healthScore: 100.0,
                referenceDate: now
            )
        ]
    }

    public func refreshTelemetry() async {
        isSyncing = true
        try? await Task.sleep(nanoseconds: 250_000_000)
        let now = Date()
        hacsConfig.lastSyncedAt = now
        nodes = nodes.map { node in
            var copy = node
            copy.lastCheckIn = now
            return copy
        }
        isSyncing = false
        persistState()
    }

    public func enrollNode(
        hostname: String,
        osDetails: String,
        packageManager: PackageManagerType,
        agentToken: String,
        inventoryState: InventoryConfidenceState? = .enrolled,
        discoveredMetadata: DiscoveredDeviceMetadata? = nil
    ) async {
        isSyncing = true
        try? await Task.sleep(nanoseconds: 200_000_000)
        let now = Date()
        let sampleUpdates: [PackageUpdate]
        if inventoryState == .incompleteOrGuessed {
            sampleUpdates = [
                PackageUpdate(
                    name: "firmware/inventory-audit",
                    currentVersion: "unverified",
                    availableVersion: "verify-model",
                    isSecurityCritical: false,
                    advisoryNote: "Incomplete/guessed inventory record — confirm model/MAC when convenient"
                )
            ]
        } else {
            sampleUpdates = [
                PackageUpdate(
                    name: packageManager == .brew ? "git" : (packageManager == .firmware ? "vendor-firmware" : "ca-certificates"),
                    currentVersion: "2026.01.1",
                    availableVersion: "2026.10.1"
                )
            ]
        }
        let initialScore: Double = inventoryState == .incompleteOrGuessed ? 64.0 : 84.0
        let newNode = MonitoredNode(
            hostname: hostname,
            osDetails: osDetails,
            agentVersion: "0.2.1",
            packageManager: packageManager,
            lastCheckIn: now,
            pendingUpdates: sampleUpdates,
            healthScore: initialScore,
            inventoryState: inventoryState,
            discoveredMetadata: discoveredMetadata,
            referenceDate: now
        )
        nodes.insert(newNode, at: 0)
        hacsConfig.lastSyncedAt = now
        isSyncing = false
        persistState()
    }

    public func triggerNodeCheckIn(nodeId: String) async {
        guard let index = nodes.firstIndex(where: { $0.id == nodeId }) else { return }
        let now = Date()
        var updated = nodes[index]
        updated.lastCheckIn = now
        nodes[index] = updated
        hacsConfig.lastSyncedAt = now
        persistState()
    }

    public func markNodeUpdatesApplied(nodeId: String) async {
        if let index = nodes.firstIndex(where: { $0.id == nodeId }) {
            let now = Date()
            let current = nodes[index]
            nodes[index] = MonitoredNode(
                id: current.id,
                hostname: current.hostname,
                osDetails: current.osDetails,
                agentVersion: current.agentVersion,
                packageManager: current.packageManager,
                haEntityId: current.haEntityId,
                lastCheckIn: now,
                pendingUpdates: [],
                healthScore: 100.0,
                inventoryState: current.inventoryState,
                discoveredMetadata: current.discoveredMetadata,
                referenceDate: now
            )
            hacsConfig.lastSyncedAt = now
            persistState()
        }
        if let rackIndex = rackDevices.firstIndex(where: { $0.id == nodeId }) {
            rackDevices[rackIndex].portState = .ok
            rackDevices[rackIndex].version = rackDevices[rackIndex].targetVersion ?? rackDevices[rackIndex].version
            rackDevices[rackIndex].proHeadline = "Patched & Verified OK • 0 Active Advisories"
            rackDevices[rackIndex].stnHeadline = "Everything OK • Latest software installed"
        }
    }

    public func updateHacsConfig(_ config: HacsConnectionConfig) {
        self.hacsConfig = config
        persistState()
    }

    public func resetDemoData() {
        self.hacsConfig = HacsConnectionConfig()
        self.nodes = Self.defaultSeedNodes()
        self.rackDevices = BulletinsAndInventoryEngine.defaultRackPortDevices()
        self.mutedFeedSlugs = ["lg-esphome-iot"]
        self.includeOkDevices = false
        self.selectedZoneFilter = nil
        persistState()
    }

    private func persistState() {
        if let encodedNodes = try? JSONEncoder().encode(nodes) {
            defaults.set(encodedNodes, forKey: nodesCacheKey)
        }
        if let encodedConfig = try? JSONEncoder().encode(hacsConfig) {
            defaults.set(encodedConfig, forKey: configCacheKey)
        }
    }
}
