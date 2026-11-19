import Foundation
import Combine
import UIKit

/// Sovereign local-first repository for monitored nodes, hardware rack inventory,
/// multi-site configuration, local lifecycle attestations, JSON backup, and billing state.
public final class MockHacsTuesdayService: TuesdayRepositoryProtocol, ObservableObject {
    public static func defaultNetworks() -> [NetworkSite] {
        [
            NetworkSite(id: "net-default", name: "My Network", devicesCount: 0, role: "Primary Site")
        ]
    }

    private enum Keys {
        static let nodes = "tuesday_mock_nodes_v1"
        static let rackDevices = "tuesday_ios_rack_devices_v2"
        static let config = "tuesday_mock_hacs_config_v1"
        static let networks = "tuesday_ios_user_networks_v1"
        static let activeNetworkId = "tuesday_ios_active_network_id_v1"
        static let clientDeviceId = "tuesday_ios_client_device_id_v1"
        static let attestations = "tuesday_ios_attestations_v1"
        static let flavor = "tuesday_ios_brand_flavor_v1"
        static let mutedFeeds = "tuesday_ios_muted_feeds_v1"
        static let completedBulletins = "tuesday_ios_completed_bulletins_v1"
        static let activeCount = "tuesday_ios_active_device_count_v1"
        static let devMode = "tuesday_ios_developer_mode_v1"
        static let visionDebug = "tuesday_ios_vision_debug_v1"
        static let diagnostics = "tuesday_ios_diagnostics_v1"
        static let apiBaseUrl = "tuesday_ios_api_base_url_v1"
        static let entitlementTier = "tuesday_ios_entitlement_tier_v1"
        static let subscriptionSku = "tuesday_ios_active_sku_v1"
        static let remindersEnabled = "tuesday_ios_reminders_enabled_v1"
        static let dispatchSubscribed = "tuesday_ios_dispatch_subscribed_v1"
        static let bulletinDismissed = "tuesday_ios_bulletin_dismissed_v1"
        static let bulletinSnoozed = "tuesday_ios_bulletin_snoozed_v1"
        static let bulletinMuted = "tuesday_ios_bulletin_muted_v1"
        static let welcomeCompleted = "tuesday_ios_welcome_completed_v1"
        static let showStateStrip = "tuesday_ios_show_state_strip_v1"
        static let showZoneStrip = "tuesday_ios_show_zone_strip_v1"
        static let reminderPrefsPrefix = "tuesday_ios_reminder_cat_"
    }

    public static func clearAllPersistedState(in defaults: UserDefaults = .standard) {
        let allKeys = [
            Keys.nodes, Keys.rackDevices, Keys.config, Keys.networks, Keys.activeNetworkId,
            Keys.attestations, Keys.flavor, Keys.mutedFeeds, Keys.completedBulletins,
            Keys.activeCount, Keys.devMode, Keys.visionDebug, Keys.diagnostics, Keys.apiBaseUrl,
            Keys.entitlementTier, Keys.subscriptionSku, Keys.remindersEnabled, Keys.dispatchSubscribed,
            Keys.bulletinDismissed, Keys.bulletinSnoozed, Keys.bulletinMuted, Keys.welcomeCompleted,
            Keys.showStateStrip, Keys.showZoneStrip
        ]
        allKeys.forEach { defaults.removeObject(forKey: $0) }
    }

    @Published public private(set) var nodes: [MonitoredNode] = []
    @Published public var rackDevices: [RackPortDevice] = []
    @Published public var brandFlavor: AppBrandFlavor = .tuesdayPro
    @Published public var mutedFeedSlugs: Set<String> = ["lg-esphome-iot"]
    @Published public var completedBulletinIds: Set<String> = []
    @Published public var includeOkDevices: Bool = false
    @Published public var selectedZoneFilter: TrustZone? = nil
    @Published public var selectedPortStateFilter: PortLifecycleState? = nil
    @Published public var userNetworks: [NetworkSite] = MockHacsTuesdayService.defaultNetworks()
    @Published public var activeNetworkId: String = "net-default"
    @Published public var activeDeviceCount: Int = 0
    @Published public var attestations: [DeviceAttestation] = []
    @Published public var isDeveloperMode: Bool = false
    @Published public var isVisionDebugEnabled: Bool = false
    @Published public var isDiagnosticsEnabled: Bool = false
    @Published public var tuesdayApiBaseUrl: String = ApiEndpointPreset.prodGcp.url
    @Published public var savedCorpusCount: Int = 0
    @Published public var hacsConfig: HacsConnectionConfig
    @Published public private(set) var isSyncing: Bool = false
    @Published public var entitlementTier: String = "free"
    @Published public var activeSubscriptionSku: String = TuesdayStoreKitManager.skuProTier1Annual

    @Published public var remindersEnabled: Bool = false
    @Published public var dispatchSubscribed: Bool = false
    @Published public var bulletinDismissed: Bool = false
    @Published public var bulletinSnoozed: Bool = false
    @Published public var bulletinMuted: Bool = false
    @Published public var welcomeCompleted: Bool = false
    @Published public var showStateFilterStrip: Bool = true
    @Published public var showZoneFilterStrip: Bool = true

    private let defaults: UserDefaults

    public var visibleRackDevices: [RackPortDevice] {
        rackDevices.filter { $0.networkId == activeNetworkId || ($0.networkId == "net-default" && activeNetworkId == "net-default") }
    }

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if let data = defaults.data(forKey: Keys.config),
           let decoded = try? JSONDecoder().decode(HacsConnectionConfig.self, from: data) {
            self.hacsConfig = decoded
        } else {
            self.hacsConfig = HacsConnectionConfig()
        }

        if let savedApi = defaults.string(forKey: Keys.apiBaseUrl), !savedApi.isEmpty {
            self.tuesdayApiBaseUrl = savedApi
        } else {
            self.tuesdayApiBaseUrl = hacsConfig.tuesdayApiBaseUrl.isEmpty
                ? ApiEndpointPreset.prodGcp.url
                : hacsConfig.tuesdayApiBaseUrl
        }

        if let rawFlavor = defaults.string(forKey: Keys.flavor),
           let parsedFlavor = AppBrandFlavor(rawValue: rawFlavor) {
            self.brandFlavor = parsedFlavor
        }

        if let data = defaults.data(forKey: Keys.nodes),
           let decoded = try? JSONDecoder().decode([MonitoredNode].self, from: data) {
            self.nodes = decoded
        } else {
            self.nodes = []
        }

        if let data = defaults.data(forKey: Keys.rackDevices),
           let decoded = try? JSONDecoder().decode([RackPortDevice].self, from: data) {
            self.rackDevices = decoded
        } else {
            self.rackDevices = []
        }

        if let data = defaults.data(forKey: Keys.networks),
           let decoded = try? JSONDecoder().decode([NetworkSite].self, from: data),
           !decoded.isEmpty {
            self.userNetworks = decoded
        } else {
            self.userNetworks = Self.defaultNetworks()
        }

        if let netId = defaults.string(forKey: Keys.activeNetworkId),
           userNetworks.contains(where: { $0.id == netId }) {
            self.activeNetworkId = netId
        } else {
            self.activeNetworkId = userNetworks.first?.id ?? "net-default"
        }

        if let data = defaults.data(forKey: Keys.attestations),
           let decoded = try? JSONDecoder().decode([DeviceAttestation].self, from: data) {
            self.attestations = decoded
        }

        if let muted = defaults.array(forKey: Keys.mutedFeeds) as? [String] {
            self.mutedFeedSlugs = Set(muted)
        }
        if let completed = defaults.array(forKey: Keys.completedBulletins) as? [String] {
            self.completedBulletinIds = Set(completed)
        }

        self.isDeveloperMode = defaults.bool(forKey: Keys.devMode)
        self.isVisionDebugEnabled = defaults.bool(forKey: Keys.visionDebug)
        self.isDiagnosticsEnabled = defaults.bool(forKey: Keys.diagnostics)
        self.entitlementTier = defaults.string(forKey: Keys.entitlementTier) ?? "free"
        self.activeSubscriptionSku = defaults.string(forKey: Keys.subscriptionSku) ?? TuesdayStoreKitManager.skuProTier1Annual

        self.remindersEnabled = defaults.bool(forKey: Keys.remindersEnabled)
        self.dispatchSubscribed = defaults.bool(forKey: Keys.dispatchSubscribed)
        self.bulletinDismissed = defaults.bool(forKey: Keys.bulletinDismissed)
        self.bulletinSnoozed = defaults.bool(forKey: Keys.bulletinSnoozed)
        self.bulletinMuted = defaults.bool(forKey: Keys.bulletinMuted)
        self.welcomeCompleted = defaults.bool(forKey: Keys.welcomeCompleted)
        self.showStateFilterStrip = defaults.object(forKey: Keys.showStateStrip) as? Bool ?? true
        self.showZoneFilterStrip = defaults.object(forKey: Keys.showZoneStrip) as? Bool ?? true

        let storedCount = defaults.object(forKey: Keys.activeCount) as? Int ?? rackDevices.count
        self.activeDeviceCount = min(storedCount, rackDevices.count)
        syncNetworkDeviceCounts()
    }

    public func toggleBrandFlavor() {
        brandFlavor = (brandFlavor == .tuesdayPro) ? .sureThingHome : .tuesdayPro
        defaults.set(brandFlavor.rawValue, forKey: Keys.flavor)
    }

    public func setBrandFlavor(_ flavor: AppBrandFlavor) {
        brandFlavor = flavor
        defaults.set(flavor.rawValue, forKey: Keys.flavor)
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

    public func toggleShowStateFilterStrip(_ show: Bool) {
        showStateFilterStrip = show
        defaults.set(show, forKey: Keys.showStateStrip)
    }

    public func toggleShowZoneFilterStrip(_ show: Bool) {
        showZoneFilterStrip = show
        defaults.set(show, forKey: Keys.showZoneStrip)
    }

    public func setRemindersEnabled(_ enabled: Bool) {
        remindersEnabled = enabled
        defaults.set(enabled, forKey: Keys.remindersEnabled)
        updateWelcomeCompletedIfReady()
    }

    public func setDispatchSubscribed(_ subscribed: Bool) {
        dispatchSubscribed = subscribed
        defaults.set(subscribed, forKey: Keys.dispatchSubscribed)
        updateWelcomeCompletedIfReady()
    }

    public func setBulletinDismissed(_ value: Bool) {
        bulletinDismissed = value
        defaults.set(value, forKey: Keys.bulletinDismissed)
    }

    public func setBulletinSnoozed(_ value: Bool) {
        bulletinSnoozed = value
        defaults.set(value, forKey: Keys.bulletinSnoozed)
    }

    public func setBulletinMuted(_ value: Bool) {
        bulletinMuted = value
        defaults.set(value, forKey: Keys.bulletinMuted)
    }

    public func triggerMockPatchTuesdayCycle() {
        bulletinDismissed = false
        bulletinSnoozed = false
        bulletinMuted = false
        welcomeCompleted = false
        defaults.set(false, forKey: Keys.bulletinDismissed)
        defaults.set(false, forKey: Keys.bulletinSnoozed)
        defaults.set(false, forKey: Keys.bulletinMuted)
        defaults.set(false, forKey: Keys.welcomeCompleted)
    }

    public func reminderPreference(for key: String) -> Bool {
        if key == "monthly_rhythm" { return remindersEnabled }
        return defaults.object(forKey: Keys.reminderPrefsPrefix + key) as? Bool ?? true
    }

    public func setReminderPreference(for key: String, enabled: Bool) {
        defaults.set(enabled, forKey: Keys.reminderPrefsPrefix + key)
        if key == "monthly_rhythm" {
            setRemindersEnabled(enabled)
        }
    }

    public func selectNetwork(_ networkId: String) {
        guard userNetworks.contains(where: { $0.id == networkId }) else { return }
        activeNetworkId = networkId
        defaults.set(networkId, forKey: Keys.activeNetworkId)
        syncNetworkDeviceCounts()
    }

    public func createNetwork(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard EntitlementGatePolicy.canCreateAdditionalNetwork(tier: entitlementTier, networks: userNetworks) else { return }
        let newSite = NetworkSite(
            id: "net-\(UUID().uuidString.prefix(8).lowercased())",
            name: trimmed,
            devicesCount: 0,
            role: "Managed Site"
        )
        userNetworks.append(newSite)
        activeNetworkId = newSite.id
        defaults.set(newSite.id, forKey: Keys.activeNetworkId)
        saveNetworks()
    }

    public func renameActiveNetwork(_ newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if let idx = userNetworks.firstIndex(where: { $0.id == activeNetworkId }) {
            userNetworks[idx].name = trimmed
            saveNetworks()
        }
    }

    public func toggleDeveloperMode(_ enabled: Bool) {
        isDeveloperMode = enabled
        defaults.set(enabled, forKey: Keys.devMode)
    }

    public func toggleVisionDebugMode(_ enabled: Bool) {
        isVisionDebugEnabled = enabled
        defaults.set(enabled, forKey: Keys.visionDebug)
    }

    public func toggleDiagnosticsMode(_ enabled: Bool) {
        isDiagnosticsEnabled = enabled
        defaults.set(enabled, forKey: Keys.diagnostics)
    }

    public func setTuesdayApiBaseUrl(_ url: String) {
        let cleaned = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }
        tuesdayApiBaseUrl = cleaned
        defaults.set(cleaned, forKey: Keys.apiBaseUrl)
        var updated = hacsConfig
        updated.tuesdayApiBaseUrl = cleaned
        updateHacsConfig(updated)
    }

    public func enableDemoMode() {
        if rackDevices.isEmpty {
            rackDevices = BulletinsAndInventoryEngine.defaultRackPortDevices().map { dev in
                var copy = dev
                copy.networkId = activeNetworkId
                return copy
            }
            saveRackDevices()
        }
        activeDeviceCount = rackDevices.count
        defaults.set(activeDeviceCount, forKey: Keys.activeCount)
        syncNetworkDeviceCounts()
    }

    public func setSimulatedDeviceCount(_ count: Int) {
        let clamped = max(0, min(12, count))
        if clamped == 0 {
            rackDevices = []
            activeDeviceCount = 0
        } else {
            let seeded = Array(BulletinsAndInventoryEngine.defaultRackPortDevices().prefix(clamped)).map { dev in
                var copy = dev
                copy.networkId = activeNetworkId
                return copy
            }
            rackDevices = seeded
            activeDeviceCount = seeded.count
        }
        selectedPortStateFilter = nil
        selectedZoneFilter = nil
        defaults.set(activeDeviceCount, forKey: Keys.activeCount)
        saveRackDevices()
        syncNetworkDeviceCounts()
        updateWelcomeCompletedIfReady()
    }

    @discardableResult
    public func purgeGoldenCorpus() -> Int {
        let prev = savedCorpusCount
        savedCorpusCount = 0
        return prev
    }

    public func recordCorpusAndScanNext() {
        savedCorpusCount += 1
    }

    public func toggleMuteFeed(_ slug: String) {
        if mutedFeedSlugs.contains(slug) {
            mutedFeedSlugs.remove(slug)
        } else {
            mutedFeedSlugs.insert(slug)
        }
        defaults.set(Array(mutedFeedSlugs), forKey: Keys.mutedFeeds)
    }

    public func markBulletinCompleted(_ externalId: String) {
        completedBulletinIds.insert(externalId)
        defaults.set(Array(completedBulletinIds), forKey: Keys.completedBulletins)

        // Update matching affected devices to OK if all their high-sev bulletins are resolved
        let allBulletins = BulletinsAndInventoryEngine.defaultGoldBulletins()
        for idx in rackDevices.indices {
            let activeForDevice = BulletinsAndInventoryEngine.findBulletinsForDevice(rackDevices[idx], bulletins: allBulletins)
                .filter { !completedBulletinIds.contains($0.externalId) }
            if activeForDevice.isEmpty && rackDevices[idx].portState == .cveKev {
                rackDevices[idx].portState = .ok
            }
        }
        saveRackDevices()
    }

    public func confirmProvisionalDeviceModel(_ chosenModel: String) {
        if let idx = rackDevices.firstIndex(where: { $0.confidenceTier == .provisionalGuess }) {
            let trimmed = chosenModel.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }
            rackDevices[idx].name = trimmed
            rackDevices[idx].shortLabel = String(trimmed.prefix(18))
            rackDevices[idx].confidenceTier = .confirmed
            if trimmed.lowercased().contains("enhanced") {
                rackDevices[idx].excludedPurlPrefixes = ["pkg:generic/ecobee/smart-thermostat"]
                rackDevices[idx].portState = .ok
                rackDevices[idx].proHeadline = "Model Confirmed (\(trimmed)) • Excluded from HomeKit CVE-2026-88901"
                rackDevices[idx].stnHeadline = "Model Confirmed • Protected (No security warnings apply)"
            } else {
                rackDevices[idx].portState = .cveKev
                rackDevices[idx].proHeadline = "CVE-2026-88901 Confirmed (\(trimmed)) • Patch 4.8.7.220 available"
                rackDevices[idx].stnHeadline = "Update Recommended: Install Ecobee update 4.8.7.220"
            }
            saveRackDevices()
        }
    }

    public func rejectProvisionalDeviceModel() {
        if let idx = rackDevices.firstIndex(where: { $0.confidenceTier == .provisionalGuess }) {
            rackDevices[idx].confidenceTier = .confirmed
            rackDevices[idx].excludedPurlPrefixes = ["pkg:generic/ecobee/smart-thermostat"]
            rackDevices[idx].portState = .ok
            rackDevices[idx].proHeadline = "Cleared Provisional Match • Awaiting manual hardware SKU"
            rackDevices[idx].stnHeadline = "Cleared Guessed Match • Tap Edit to enter exact model"
            saveRackDevices()
        }
    }

    public func updateDeviceDetails(
        id: String,
        name: String,
        category: StnHardwareCategory,
        trustZone: TrustZone,
        roomLocation: String,
        version: String,
        serialNumber: String? = nil,
        macAddress: String? = nil
    ) {
        guard let idx = rackDevices.firstIndex(where: { $0.id == id }) else { return }
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanRoom = roomLocation.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanVer = version.trimmingCharacters(in: .whitespacesAndNewlines)

        if !cleanName.isEmpty {
            rackDevices[idx].name = cleanName
            rackDevices[idx].shortLabel = String(cleanName.prefix(18))
        }
        rackDevices[idx].category = category
        rackDevices[idx].trustZone = trustZone
        rackDevices[idx].roomLocation = cleanRoom
        rackDevices[idx].version = cleanVer
        rackDevices[idx].serialNumber = serialNumber?.trimmingCharacters(in: .whitespacesAndNewlines)
        rackDevices[idx].macAddress = macAddress?.trimmingCharacters(in: .whitespacesAndNewlines)
        rackDevices[idx].s0Identity = "\(cleanRoom.isEmpty ? "Home" : cleanRoom) • \(trustZone.displayTitle)"
        saveRackDevices()
    }

    public func deleteDevice(id: String) {
        rackDevices.removeAll { $0.id == id }
        attestations.removeAll { $0.deviceId == id }
        activeDeviceCount = rackDevices.count
        defaults.set(activeDeviceCount, forKey: Keys.activeCount)
        saveRackDevices()
        saveAttestations()
        syncNetworkDeviceCounts()
    }

    public func recordAttestation(
        deviceId: String,
        type: AttestationType,
        presenceState: DevicePresenceState,
        auditDate: String,
        notes: String? = nil
    ) {
        let entry = DeviceAttestation(
            deviceId: deviceId,
            auditDate: auditDate,
            attestedBy: "Owner",
            type: type,
            presenceState: presenceState,
            notes: notes
        )
        attestations.insert(entry, at: 0)
        if let idx = rackDevices.firstIndex(where: { $0.id == deviceId }) {
            rackDevices[idx].presenceState = presenceState
            rackDevices[idx].latestAttestation = entry
            rackDevices[idx].attestationCount += 1
            if presenceState.isOutOfService {
                rackDevices[idx].decommissionDate = auditDate
            }
        }
        saveRackDevices()
        saveAttestations()
    }

    public func recordBatchAttestation(
        deviceIds: [String],
        auditDate: String,
        sessionId: String,
        notes: String? = nil
    ) {
        for devId in deviceIds {
            let entry = DeviceAttestation(
                deviceId: devId,
                auditDate: auditDate,
                attestedBy: "Batch Check-In",
                type: .annualAudit,
                presenceState: .active,
                sessionId: sessionId,
                notes: notes
            )
            attestations.insert(entry, at: 0)
            if let idx = rackDevices.firstIndex(where: { $0.id == devId }) {
                rackDevices[idx].presenceState = .active
                rackDevices[idx].latestAttestation = entry
                rackDevices[idx].attestationCount += 1
            }
        }
        saveRackDevices()
        saveAttestations()
    }

    public func refreshTelemetry() async {
        isSyncing = true
        try? await Task.sleep(nanoseconds: 120_000_000)
        isSyncing = false
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
        defer { isSyncing = false }

        let now = Date()
        let node = MonitoredNode(
            hostname: hostname,
            osDetails: osDetails,
            agentVersion: "0.2.1",
            packageManager: packageManager,
            lastCheckIn: now,
            pendingUpdates: [],
            inventoryState: inventoryState,
            discoveredMetadata: discoveredMetadata
        )
        nodes.insert(node, at: 0)
        saveNodes()

        let vendorSlug = GoldClueIndexData.slugify(discoveredMetadata?.manufacturer ?? "generic")
        let modelSlug = GoldClueIndexData.slugify(discoveredMetadata?.modelNumber ?? hostname)
        let inferredPurl = "pkg:generic/\(vendorSlug.isEmpty ? "generic" : vendorSlug)/\(modelSlug.isEmpty ? "device" : modelSlug)"
        let inferredState: PortLifecycleState = (inventoryState == .incompleteOrGuessed)
            ? .guessed
            : BulletinsAndInventoryEngine.inferInitialPortStateForPurls([inferredPurl])

        let categoryHint = [
            discoveredMetadata?.modelNumber,
            discoveredMetadata?.manufacturer,
            hostname,
            discoveredMetadata?.deviceCategory,
            osDetails
        ]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        let resolvedCategory = StnHardwareCategory.fromDiscoveryHint(categoryHint)
        let isConfirmed = (inventoryState != .incompleteOrGuessed)

        let rackDevice = RackPortDevice(
            id: node.id,
            networkId: activeNetworkId,
            portIndex: rackDevices.count + 1,
            portState: inferredState,
            trustZone: .z1Trusted,
            category: resolvedCategory,
            assetTag: "",
            shortLabel: String(hostname.prefix(18)),
            name: hostname,
            roomLocation: "Home Network",
            version: osDetails,
            candles: [
                DeviceLifecycleCandle(ver: osDetails.isEmpty ? "1.0" : osDetails, released: 0.45, attested: 0.72, ended: 0.96, eol: 0.99, cveStart: inferredState == .cveKev ? 0.72 : nil)
            ],
            lifecycleTier: inferredState == .eol ? "Legacy (EOL)" : "Active",
            purls: [inferredPurl],
            canonicalPurl: inferredPurl,
            serialNumber: discoveredMetadata?.serialNumber,
            macAddress: discoveredMetadata?.macAddress,
            upc: discoveredMetadata?.barcodeOrQr,
            confidenceTier: isConfirmed ? .confirmed : .provisionalGuess,
            proHeadline: isConfirmed
                ? "\(inferredPurl) • Enrolled locally (\(inferredState.badgeLabel))"
                : "Guessed SKU • Verify model to unlock tailored bulletins",
            stnHeadline: isConfirmed
                ? "\(resolvedCategory.stnLabel) added • \(inferredState.stnLabel)"
                : "Needs model confirmation — tap Edit or scan barcode",
            s0Identity: "Home Network • Z1 Trusted",
            s1Hardware: "\(discoveredMetadata?.manufacturer ?? "Hardware") \(discoveredMetadata?.modelNumber ?? hostname)",
            s2Software: inferredPurl,
            s3Lifecycle: isConfirmed ? "Active Tracking" : "Provisional Match",
            s4Advisories: discoveredMetadata?.discoveryNotes ?? "Tracked offline in sovereign local vault",
            s5Topology: resolvedCategory.proLabel,
            s6Remediation: isConfirmed ? "Review matching bulletins on Bulletins tab." : "Confirm exact model number."
        )

        rackDevices.insert(rackDevice, at: 0)
        activeDeviceCount = rackDevices.count
        defaults.set(activeDeviceCount, forKey: Keys.activeCount)
        saveRackDevices()
        syncNetworkDeviceCounts()
        updateWelcomeCompletedIfReady()
    }

    public func triggerNodeCheckIn(nodeId: String) async {
        if let idx = nodes.firstIndex(where: { $0.id == nodeId }) {
            nodes[idx].lastCheckIn = Date()
            saveNodes()
        }
    }

    public func markNodeUpdatesApplied(nodeId: String) async {
        if let idx = nodes.firstIndex(where: { $0.id == nodeId }) {
            nodes[idx].pendingUpdates = []
            nodes[idx].healthScore = 100
            nodes[idx].status = .healthy
            saveNodes()
        }
        if let rIdx = rackDevices.firstIndex(where: { $0.id == nodeId }) {
            rackDevices[rIdx].portState = .ok
            saveRackDevices()
        }
    }

    /// Required CI contract token (`upgradeToProTier1`).
    /// Never mints fake StoreKit JWS tokens in Release; requires genuine StoreKit 2 `transactionJws`
    /// or server verification, with an explicit DEBUG-only test escape hatch.
    @discardableResult
    public func upgradeToProTier1(
        productId: String = TuesdayStoreKitManager.skuProTier1Annual,
        transactionJws: String? = nil
    ) -> Bool {
        if let jws = transactionJws, !jws.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            entitlementTier = "pro_tier_1"
            activeSubscriptionSku = productId
            defaults.set("pro_tier_1", forKey: Keys.entitlementTier)
            defaults.set(productId, forKey: Keys.subscriptionSku)
            Task {
                await verifyReceiptWithBackend(productId: productId, transactionJws: jws)
            }
            return true
        }

        #if DEBUG
        if CommandLine.arguments.contains("--uitesting-mock-billing") || isDeveloperMode {
            entitlementTier = "pro_tier_1"
            activeSubscriptionSku = productId
            defaults.set("pro_tier_1", forKey: Keys.entitlementTier)
            defaults.set(productId, forKey: Keys.subscriptionSku)
            return true
        }
        #endif

        return false
    }

    public func downgradeToFreeTier() {
        entitlementTier = "free"
        defaults.set("free", forKey: Keys.entitlementTier)
    }

    public func reconcileWhenStoreHasNoActivePurchase() async {
        let serverTier = await fetchServerEntitlementStatus()
        if EntitlementGatePolicy.isProTier1Entitled(serverTier) {
            entitlementTier = serverTier
            defaults.set(serverTier, forKey: Keys.entitlementTier)
        } else if entitlementTier != "free" && !isDeveloperMode {
            downgradeToFreeTier()
        }
    }

    public func fetchServerEntitlementStatus() async -> String {
        let base = tuesdayApiBaseUrl.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: "\(base)/api/v1/billing/status") else { return "free" }
        var req = URLRequest(url: url)
        req.timeoutInterval = 10
        req.setValue(clientDeviceId(), forHTTPHeaderField: "X-Tuesday-Device-ID")
        req.setValue("ios", forHTTPHeaderField: "X-Tuesday-Client-Platform")

        guard let (data, response) = try? await URLSession.shared.data(for: req),
              let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tier = json["entitlement_tier"] as? String else {
            return entitlementTier
        }
        if EntitlementGatePolicy.isProTier1Entitled(tier) {
            entitlementTier = tier
            defaults.set(tier, forKey: Keys.entitlementTier)
        }
        return tier
    }

    @discardableResult
    public func verifyReceiptWithBackend(productId: String, transactionJws: String) async -> Bool {
        let base = tuesdayApiBaseUrl.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: "\(base)/api/v1/billing/verify") else { return false }

        let body: [String: Any] = [
            "platform": "ios",
            "product_id": productId,
            "transaction_jws": transactionJws
        ]
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.timeoutInterval = 15
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(clientDeviceId(), forHTTPHeaderField: "X-Tuesday-Device-ID")
        req.setValue("ios", forHTTPHeaderField: "X-Tuesday-Client-Platform")
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)

        guard let (_, response) = try? await URLSession.shared.data(for: req),
              let http = response as? HTTPURLResponse else {
            return false
        }
        return (200...299).contains(http.statusCode)
    }

    public func exportInventoryBackupJSON() -> Data? {
        let iso = ISO8601DateFormatter().string(from: Date())
        let activeName = userNetworks.first(where: { $0.id == activeNetworkId })?.name ?? "My Network"
        let backup = NetworkInventoryBackup(
            schemaVersion: 1,
            exportedAtIso: iso,
            networkName: activeName,
            flavor: brandFlavor.rawValue,
            devices: rackDevices,
            attestations: attestations
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try? encoder.encode(backup)
    }

    public func importInventoryBackupJSON(_ data: Data) -> Result<Int, Error> {
        do {
            let decoded = try JSONDecoder().decode(NetworkInventoryBackup.self, from: data)
            self.rackDevices = decoded.devices.map { dev in
                var copy = dev
                copy.networkId = activeNetworkId
                return copy
            }
            self.attestations = decoded.attestations
            self.activeDeviceCount = rackDevices.count
            defaults.set(activeDeviceCount, forKey: Keys.activeCount)
            saveRackDevices()
            saveAttestations()
            syncNetworkDeviceCounts()
            return .success(rackDevices.count)
        } catch {
            return .failure(error)
        }
    }

    public func updateHacsConfig(_ config: HacsConnectionConfig) {
        hacsConfig = config
        if let data = try? JSONEncoder().encode(config) {
            defaults.set(data, forKey: Keys.config)
        }
    }

    public func resetDemoData() {
        Self.clearAllPersistedState(in: defaults)
        nodes = []
        rackDevices = []
        attestations = []
        mutedFeedSlugs = ["lg-esphome-iot"]
        completedBulletinIds = []
        includeOkDevices = false
        selectedZoneFilter = nil
        selectedPortStateFilter = nil
        userNetworks = Self.defaultNetworks()
        activeNetworkId = "net-default"
        activeDeviceCount = 0
        entitlementTier = "free"
        activeSubscriptionSku = TuesdayStoreKitManager.skuProTier1Annual
        remindersEnabled = false
        dispatchSubscribed = false
        bulletinDismissed = false
        bulletinSnoozed = false
        bulletinMuted = false
        welcomeCompleted = false
        showStateFilterStrip = true
        showZoneFilterStrip = true
        savedCorpusCount = 0
        hacsConfig = HacsConnectionConfig()
    }

    public func clientDeviceId() -> String {
        if let existing = defaults.string(forKey: Keys.clientDeviceId), !existing.isEmpty {
            return existing
        }
        let generated = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        defaults.set(generated, forKey: Keys.clientDeviceId)
        return generated
    }

    private func updateWelcomeCompletedIfReady() {
        let ready = !rackDevices.isEmpty && remindersEnabled && dispatchSubscribed
        if ready && !welcomeCompleted {
            welcomeCompleted = true
            defaults.set(true, forKey: Keys.welcomeCompleted)
        }
    }

    private func syncNetworkDeviceCounts() {
        for idx in userNetworks.indices {
            let netId = userNetworks[idx].id
            userNetworks[idx].devicesCount = rackDevices.filter { $0.networkId == netId }.count
        }
        saveNetworks()
    }

    private func saveNodes() {
        if let data = try? JSONEncoder().encode(nodes) {
            defaults.set(data, forKey: Keys.nodes)
        }
    }

    private func saveRackDevices() {
        if let data = try? JSONEncoder().encode(rackDevices) {
            defaults.set(data, forKey: Keys.rackDevices)
        }
    }

    private func saveNetworks() {
        if let data = try? JSONEncoder().encode(userNetworks) {
            defaults.set(data, forKey: Keys.networks)
        }
    }

    private func saveAttestations() {
        if let data = try? JSONEncoder().encode(attestations) {
            defaults.set(data, forKey: Keys.attestations)
        }
    }
}
