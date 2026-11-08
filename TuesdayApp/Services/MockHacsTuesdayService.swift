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
    @Published public var selectedPortStateFilter: PortLifecycleState? = nil
    @Published public var userNetworks: [NetworkSite] = MockHacsTuesdayService.defaultNetworks()
    @Published public var activeNetworkId: String = "skyway"
    @Published public var activeDeviceCount: Int = 12
    @Published public var isDeveloperMode: Bool = false
    @Published public var savedCorpusCount: Int = 2
    @Published public var hacsConfig: HacsConnectionConfig
    @Published public private(set) var isSyncing: Bool = false
    @Published public var entitlementTier: String = "free"

    public static func defaultNetworks() -> [NetworkSite] {
        return [
            NetworkSite(id: "skyway", name: "Skyway Lab", devicesCount: 12, role: "Primary Homelab"),
            NetworkSite(id: "main_home", name: "Main Home Wi-Fi", devicesCount: 7, role: "Residential"),
            NetworkSite(id: "orcas", name: "Orcas Island Cabin", devicesCount: 3, role: "Remote Site")
        ]
    }

    private let nodesCacheKey = "tuesday_mock_nodes_v1"
    private let configCacheKey = "tuesday_mock_hacs_config_v1"
    private let clientDeviceIdKey = "tuesday_ios_client_device_id_v1"
    private let entitlementTierKey = "tuesday_ios_entitlement_tier_v1"
    private let defaults: UserDefaults
    private let clientDeviceId: String

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let existingId = defaults.string(forKey: clientDeviceIdKey), !existingId.isEmpty {
            self.clientDeviceId = existingId
        } else {
            let generated = "ios-" + String(UUID().uuidString.prefix(8)).lowercased()
            defaults.set(generated, forKey: clientDeviceIdKey)
            self.clientDeviceId = generated
        }
        self.entitlementTier = defaults.string(forKey: entitlementTierKey) ?? "free"

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

    public func setZoneFilter(_ zone: TrustZone?) {
        selectedZoneFilter = zone
    }

    public func setPortStateFilter(_ state: PortLifecycleState?) {
        selectedPortStateFilter = state
    }

    public func selectNetwork(_ networkId: String) {
        guard let found = userNetworks.first(where: { $0.id == networkId }) else { return }
        activeNetworkId = found.id
        activeDeviceCount = found.devicesCount
    }

    public func createNetwork(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let newId = "net-\(Int(Date().timeIntervalSince1970))"
        let site = NetworkSite(id: newId, name: trimmed, devicesCount: 0, role: "New Location")
        userNetworks.append(site)
        activeNetworkId = newId
        activeDeviceCount = 0
    }

    public func renameActiveNetwork(_ newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        userNetworks = userNetworks.map { net in
            guard net.id == activeNetworkId else { return net }
            var copy = net
            copy.name = trimmed
            return copy
        }
    }

    public func toggleDeveloperMode(_ enabled: Bool) {
        isDeveloperMode = enabled
    }

    public func setSimulatedDeviceCount(_ count: Int) {
        let clamped = max(0, min(12, count))
        activeDeviceCount = clamped
        userNetworks = userNetworks.map { net in
            guard net.id == activeNetworkId else { return net }
            var copy = net
            copy.devicesCount = clamped
            return copy
        }
    }

    public func purgeGoldenCorpus() -> Int {
        let removed = savedCorpusCount
        savedCorpusCount = 0
        return removed
    }

    public func toggleMuteFeed(_ slug: String) {
        if mutedFeedSlugs.contains(slug) {
            mutedFeedSlugs.remove(slug)
        } else {
            mutedFeedSlugs.insert(slug)
        }
    }

    public func confirmProvisionalDeviceModel(_ chosenModel: String) {
        var targetId: String?
        rackDevices = rackDevices.map { dev in
            guard dev.confidenceTier == .provisionalGuess else { return dev }
            targetId = dev.id
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
        if let devId = targetId {
            syncInventoryPatchAsync(deviceId: devId, payload: ["confirmed_candidate_model": chosenModel])
        }
    }

    public func rejectProvisionalDeviceModel() {
        var targetId: String?
        rackDevices = rackDevices.map { dev in
            guard dev.confidenceTier == .provisionalGuess else { return dev }
            targetId = dev.id
            var copy = dev
            copy.confidenceTier = .opaqueUnknown
            copy.excludedPurlPrefixes.append("pkg:generic/ecobee/*")
            copy.proHeadline = "Ecobee Family Excluded • Use Plug & Tag Camera to Identify Exact Model"
            copy.stnHeadline = "Not an Ecobee • Snap a photo of the thermostat label to identify"
            return copy
        }
        if let devId = targetId {
            syncInventoryPatchAsync(
                deviceId: devId,
                payload: [
                    "confidence_tier": "opaque_unknown",
                    "add_excluded_purl_prefix": "pkg:generic/ecobee/*"
                ]
            )
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
        let nextPort = (rackDevices.map(\.portIndex).max() ?? 12) + 1
        let isGuessed = (inventoryState == .incompleteOrGuessed)
        let newRackDev = RackPortDevice(
            id: newNode.id,
            portIndex: min(nextPort, 128),
            portState: isGuessed ? .guessed : .ok,
            trustZone: .z3Iot,
            assetTag: "STN-NEW-\(nextPort)",
            shortLabel: String(hostname.prefix(12)),
            name: hostname,
            roomLocation: "Newly Enrolled",
            version: isGuessed ? "unverified" : "2026.10.1",
            targetVersion: "2026.10.1",
            lifecycleTier: isGuessed ? "Provisional Guess" : "Active",
            purls: ["pkg:generic/enrolled/\(hostname.lowercased())"],
            confidenceTier: isGuessed ? .provisionalGuess : .confirmed,
            candidateModels: isGuessed ? [discoveredMetadata?.modelNumber ?? "Generic IoT Node"] : [],
            excludedPurlPrefixes: [],
            proHeadline: osDetails,
            stnHeadline: osDetails,
            s0Identity: "STN-NEW-\(nextPort) • Newly Enrolled • Z3 IoT",
            s1Hardware: discoveredMetadata?.manufacturer ?? hostname,
            s2Software: osDetails,
            s3Lifecycle: isGuessed ? "Provisional Guess" : "Active Support",
            s4Advisories: "0 Active CVEs",
            s5Topology: "Z3 IoT",
            s6Remediation: isGuessed ? "Confirm exact model on Bulletins tab." : "No action required."
        )
        rackDevices.insert(newRackDev, at: 0)
        activeDeviceCount = min(128, activeDeviceCount + 1)
        syncInventoryCreateAsync(device: newRackDev, metadata: discoveredMetadata)

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
            syncInventoryPatchAsync(deviceId: nodeId, payload: ["mark_remediated": true])
        }
    }

    public func upgradeToProTier1(productId: String = "sh.tuesday.pro.tier1.annual") {
        entitlementTier = "pro_tier_1"
        defaults.set("pro_tier_1", forKey: entitlementTierKey)
        let base = hacsConfig.tuesdayApiBaseUrl.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let devId = clientDeviceId
        Task.detached {
            guard let url = URL(string: "\(base)/api/v1/billing/verify") else { return }
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.timeoutInterval = 10.0
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.setValue(devId, forHTTPHeaderField: "X-Tuesday-Device-ID")
            req.setValue("ios", forHTTPHeaderField: "X-Tuesday-Client-Platform")
            let body: [String: Any] = [
                "platform": "ios",
                "product_id": productId,
                "transaction_jws": "sk2_jws_\(UUID().uuidString)"
            ]
            req.httpBody = try? JSONSerialization.data(withJSONObject: body)
            _ = try? await URLSession.shared.data(for: req)
        }
    }

    private func syncInventoryCreateAsync(device: RackPortDevice, metadata: DiscoveredDeviceMetadata?) {
        let base = hacsConfig.tuesdayApiBaseUrl.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let devId = clientDeviceId
        let body: [String: Any] = [
            "id": device.id,
            "port_index": device.portIndex,
            "trust_zone": device.trustZone.rawValue,
            "port_state": device.portState.rawValue,
            "confidence_tier": device.confidenceTier.rawValue,
            "asset_tag": device.assetTag,
            "short_label": device.shortLabel,
            "name": device.name,
            "vendor": metadata?.manufacturer ?? "Generic",
            "model_number": metadata?.modelNumber ?? device.shortLabel,
            "room_location": device.roomLocation,
            "version": device.version,
            "target_version": device.targetVersion ?? device.version,
            "purls": device.purls
        ]
        Task.detached {
            guard let url = URL(string: "\(base)/api/v1/inventory") else { return }
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.timeoutInterval = 10.0
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.setValue(devId, forHTTPHeaderField: "X-Tuesday-Device-ID")
            req.setValue("ios", forHTTPHeaderField: "X-Tuesday-Client-Platform")
            req.httpBody = try? JSONSerialization.data(withJSONObject: body)
            _ = try? await URLSession.shared.data(for: req)
        }
    }

    private func syncInventoryPatchAsync(deviceId: String, payload: [String: Any]) {
        let base = hacsConfig.tuesdayApiBaseUrl.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let devId = clientDeviceId
        Task.detached {
            guard let url = URL(string: "\(base)/api/v1/inventory/\(deviceId)") else { return }
            var req = URLRequest(url: url)
            req.httpMethod = "PATCH"
            req.timeoutInterval = 10.0
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.setValue(devId, forHTTPHeaderField: "X-Tuesday-Device-ID")
            req.setValue("ios", forHTTPHeaderField: "X-Tuesday-Client-Platform")
            req.httpBody = try? JSONSerialization.data(withJSONObject: payload)
            _ = try? await URLSession.shared.data(for: req)
        }
    }

    public func updateHacsConfig(_ config: HacsConnectionConfig) {
        self.hacsConfig = config
        persistState()
    }

    public func recordCorpusAndScanNext() {
        self.savedCorpusCount += 1
        persistState()
    }

    public func resetDemoData() {
        self.hacsConfig = HacsConnectionConfig()
        self.nodes = Self.defaultSeedNodes()
        self.rackDevices = BulletinsAndInventoryEngine.defaultRackPortDevices()
        self.mutedFeedSlugs = ["lg-esphome-iot"]
        self.includeOkDevices = false
        self.selectedZoneFilter = nil
        self.selectedPortStateFilter = nil
        self.userNetworks = Self.defaultNetworks()
        self.activeNetworkId = "skyway"
        self.activeDeviceCount = 12
        self.isDeveloperMode = false
        self.savedCorpusCount = 2
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
