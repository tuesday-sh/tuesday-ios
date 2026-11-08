import Foundation

public enum AppBrandFlavor: String, Codable, CaseIterable {
    case tuesdayPro = "tuesday_pro"
    case sureThingHome = "surething_home"

    public var title: String {
        switch self {
        case .tuesdayPro: return "Tuesday.sh"
        case .sureThingHome: return "SureThingNet"
        }
    }

    public var badge: String {
        switch self {
        case .tuesdayPro: return "PRO • RACK"
        case .sureThingHome: return "HOME • CALM"
        }
    }
}

/// 6-State Port Lifecycle Taxonomy:
/// CVE_KEV("cve_kev", "CVE / KEV", "Safety / Security Alert", 1)
/// EOL("eol", "EOL", "Retired / EOL", 2)
/// GUESSED("guessed", "GUESSED", "Unknown / Guessed", 3)
/// UPDATE("update", "UPDATE", "Update Available", 4)
/// OK("ok", "OK", "Everything OK", 5)
/// UNASSIGNED("unassigned", "Empty Slot", "Empty Slot", 6)
public enum PortLifecycleState: String, Codable, CaseIterable {
    case cveKev = "cve_kev"
    case eol = "eol"
    case guessed = "guessed"
    case update = "update"
    case ok = "ok"
    case unassigned = "unassigned"

    public var key: String { rawValue }

    public var severityPriority: Int {
        switch self {
        case .cveKev: return 1
        case .eol: return 2
        case .guessed: return 3
        case .update: return 4
        case .ok: return 5
        case .unassigned: return 6
        }
    }

    public var proLabel: String {
        switch self {
        case .cveKev: return "CVE / KEV"
        case .eol: return "EOL"
        case .guessed: return "GUESSED"
        case .update: return "UPDATE"
        case .ok: return "OK"
        case .unassigned: return "Empty Slot"
        }
    }

    public var stnLabel: String {
        switch self {
        case .cveKev: return "Safety / Security Alert"
        case .eol: return "Retired / EOL"
        case .guessed: return "Unknown / Guessed"
        case .update: return "Update Available"
        case .ok: return "Everything OK"
        case .unassigned: return "Empty Slot"
        }
    }
}

/// Progressive Disclosure Scale Tiers (Botanical Spine):
/// - DAY_ZERO("day_zero", "Day 0", 0, 0)
/// - PEA("pea", "Pea", 1, 2, "🌱")
/// - GARDEN("garden", "Garden", 3, 7, "🪴")
/// - FOREST("forest", "Forest", 8, 128, "🌲")
public enum InventoryScaleTier: String, Codable, CaseIterable {
    case DAY_ZERO = "day_zero"
    case PEA = "pea"
    case GARDEN = "garden"
    case FOREST = "forest"

    public static let dayZero: InventoryScaleTier = .DAY_ZERO
    public static let pea: InventoryScaleTier = .PEA
    public static let garden: InventoryScaleTier = .GARDEN
    public static let forest: InventoryScaleTier = .FOREST

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .DAY_ZERO: return "Day 0"
        case .PEA: return "Pea"
        case .GARDEN: return "Garden"
        case .FOREST: return "Forest"
        }
    }

    public var showSummaryBadge: Bool {
        switch self {
        case .DAY_ZERO, .PEA: return false
        case .GARDEN, .FOREST: return true
        }
    }

    public var showPortDiagramStrip: Bool {
        self == .FOREST
    }

    public var showFilterChips: Bool {
        self == .FOREST
    }

    public var showTrustZonePills: Bool {
        self == .FOREST
    }

    public var botanicalOverlayEmoji: String {
        switch self {
        case .DAY_ZERO: return ""
        case .PEA: return "🌱"
        case .GARDEN: return "🪴"
        case .FOREST: return "🌲"
        }
    }

    public static func forCount(_ count: Int) -> InventoryScaleTier {
        if count <= 0 { return .DAY_ZERO }
        if count <= 2 { return .PEA }
        if count <= 7 { return .GARDEN }
        return .FOREST
    }
}

/// SureThingNet Standard Categories (Scale C: C1_GATEWAY .. C8_GUEST)
/// - C1_GATEWAY("C1", 1, "L3", "Gateway / WAN", "Wi-Fi Router / Gateway")
/// - C2_SWITCH("C2", 2, "L2", "Switch Backbone", "Wired Switch Hub")
/// - C3_AP("C3", 3, "L1/2", "Wireless AP", "Wi-Fi Access Point")
/// - C4_SERVER("C4", 4, "L4–7", "Compute / Server", "Home Server & Storage")
/// - C5_CAMERA("C5", 5, "L7", "Vision / Camera", "Smart Camera")
/// - C6_IOT("C6", 6, "L7", "Smart Home / IoT", "Smart Home Hub")
/// - C7_CLIENT("C7", 7, "L7", "Workstation / Client", "Personal Computer / Phone")
/// - C8_GUEST("C8", 8, "L8", "Guest / Human (L8)", "Guest / Visitor Device")
public enum StnHardwareCategory: String, Codable, CaseIterable {
    case C1_GATEWAY = "C1"
    case C2_SWITCH = "C2"
    case C3_AP = "C3"
    case C4_SERVER = "C4"
    case C5_CAMERA = "C5"
    case C6_IOT = "C6"
    case C7_CLIENT = "C7"
    case C8_GUEST = "C8"

    public static let c1Gateway: StnHardwareCategory = .C1_GATEWAY
    public static let c2Switch: StnHardwareCategory = .C2_SWITCH
    public static let c3Ap: StnHardwareCategory = .C3_AP
    public static let c4Server: StnHardwareCategory = .C4_SERVER
    public static let c5Camera: StnHardwareCategory = .C5_CAMERA
    public static let c6Iot: StnHardwareCategory = .C6_IOT
    public static let c7Client: StnHardwareCategory = .C7_CLIENT
    public static let c8Guest: StnHardwareCategory = .C8_GUEST

    public var code: String { rawValue }

    public var portSlot: Int {
        switch self {
        case .C1_GATEWAY: return 1
        case .C2_SWITCH: return 2
        case .C3_AP: return 3
        case .C4_SERVER: return 4
        case .C5_CAMERA: return 5
        case .C6_IOT: return 6
        case .C7_CLIENT: return 7
        case .C8_GUEST: return 8
        }
    }

    public var osiLayer: String {
        switch self {
        case .C1_GATEWAY: return "L3"
        case .C2_SWITCH: return "L2"
        case .C3_AP: return "L1/2"
        case .C4_SERVER: return "L4–7"
        case .C5_CAMERA: return "L7"
        case .C6_IOT: return "L7"
        case .C7_CLIENT: return "L7"
        case .C8_GUEST: return "L8"
        }
    }

    public var proLabel: String {
        switch self {
        case .C1_GATEWAY: return "Gateway / WAN"
        case .C2_SWITCH: return "Switch Backbone"
        case .C3_AP: return "Wireless AP"
        case .C4_SERVER: return "Compute / Server"
        case .C5_CAMERA: return "Vision / Camera"
        case .C6_IOT: return "Smart Home / IoT"
        case .C7_CLIENT: return "Workstation / Client"
        case .C8_GUEST: return "Guest / Human (L8)"
        }
    }

    public var stnLabel: String {
        switch self {
        case .C1_GATEWAY: return "Wi-Fi Router / Gateway"
        case .C2_SWITCH: return "Wired Switch Hub"
        case .C3_AP: return "Wi-Fi Access Point"
        case .C4_SERVER: return "Home Server & Storage"
        case .C5_CAMERA: return "Smart Camera"
        case .C6_IOT: return "Smart Home Hub"
        case .C7_CLIENT: return "Personal Computer / Phone"
        case .C8_GUEST: return "Guest / Visitor Device"
        }
    }

    public var shortName: String {
        switch self {
        case .C1_GATEWAY: return "Gateway"
        case .C2_SWITCH: return "Switch"
        case .C3_AP: return "Wi-Fi AP"
        case .C4_SERVER: return "Server"
        case .C5_CAMERA: return "Camera"
        case .C6_IOT: return "Smart IoT"
        case .C7_CLIENT: return "Client"
        case .C8_GUEST: return "Guest L8"
        }
    }

    public var description: String {
        switch self {
        case .C1_GATEWAY: return "Perimeter firewall, WAN uplink, NAT, DHCP server, and default gateway."
        case .C2_SWITCH: return "Physical distribution plane, 802.1Q VLAN trunking, and PoE power delivery."
        case .C3_AP: return "Radio-frequency access point translating wireless airwaves into wired Ethernet."
        case .C4_SERVER: return "Storage (NAS), local DNS, container virtualization, and homelab workloads."
        case .C5_CAMERA: return "Surveillance video, real-time RTSP/WebRTC streams, and perimeter sensing."
        case .C6_IOT: return "Home automation controllers, sensor bridges, and constrained smart peripherals."
        case .C7_CLIENT: return "Primary trusted user devices carrying user identities, keys, and productivity data."
        case .C8_GUEST: return "Isolated perimeter for ephemeral human visitors, guest Wi-Fi, and user policy."
        }
    }

    public var examples: String {
        switch self {
        case .C1_GATEWAY: return "UDM-Pro, UXG-Pro, Firewalla, pfSense"
        case .C2_SWITCH: return "USW-24-PoE, Enterprise 8 PoE, Catalyst"
        case .C3_AP: return "U6-Pro, U7-Pro, Netgear AP, Eero"
        case .C4_SERVER: return "TrueNAS, Unraid, Proxmox VE, Synology"
        case .C5_CAMERA: return "UniFi Protect G5, Owlet Cam, Reolink"
        case .C6_IOT: return "Home Assistant, Hubitat, Hue, Ecobee"
        case .C7_CLIENT: return "MacBook Pro, ThinkPad, Linux PC, iPad"
        case .C8_GUEST: return "Guest Portal, Visitor Laptop, Cast Client"
        }
    }
}

public struct NetworkSite: Identifiable, Codable, Equatable {
    public let id: String
    public var name: String
    public var devicesCount: Int
    public var role: String

    public init(id: String, name: String, devicesCount: Int, role: String) {
        self.id = id
        self.name = name
        self.devicesCount = devicesCount
        self.role = role
    }
}

/// Trust Zones (Z0_CORE .. Z4_GUEST):
/// Z0_CORE("z0_core", "Z0", "Core Gear", "Wi-Fi & Network Gear", 16)
/// Z1_TRUSTED("z1_trusted", "Z1", "Trusted", "Main Home Wi-Fi", 32)
/// Z2_LAB("z2_lab", "Z2", "Homelab", "Home Storage", 24)
/// Z3_IOT("z3_iot", "Z3", "Smart Home", "Smart Home Lane", 40)
/// Z4_GUEST("z4_guest", "Z4", "Guest", "Guest Wi-Fi", 16)
public enum TrustZone: String, Codable, CaseIterable {
    case z0Core = "z0_core"
    case z1Trusted = "z1_trusted"
    case z2Lab = "z2_lab"
    case z3Iot = "z3_iot"
    case z4Guest = "z4_guest"

    public static let Z0_CORE: TrustZone = .z0Core
    public static let Z1_TRUSTED: TrustZone = .z1Trusted
    public static let Z2_LAB: TrustZone = .z2Lab
    public static let Z3_IOT: TrustZone = .z3Iot
    public static let Z4_GUEST: TrustZone = .z4Guest

    public var shortCode: String {
        switch self {
        case .z0Core: return "Z0"
        case .z1Trusted: return "Z1"
        case .z2Lab: return "Z2"
        case .z3Iot: return "Z3"
        case .z4Guest: return "Z4"
        }
    }

    public var displayLabel: String {
        switch self {
        case .z0Core: return "Core Gear"
        case .z1Trusted: return "Trusted"
        case .z2Lab: return "Homelab"
        case .z3Iot: return "Smart Home"
        case .z4Guest: return "Guest"
        }
    }

    public var stnLabel: String {
        switch self {
        case .z0Core: return "Wi-Fi & Network Gear"
        case .z1Trusted: return "Main Home Wi-Fi"
        case .z2Lab: return "Home Storage"
        case .z3Iot: return "Smart Home Lane"
        case .z4Guest: return "Guest Wi-Fi"
        }
    }

    public var slotCount: Int {
        switch self {
        case .z0Core: return 16
        case .z1Trusted: return 32
        case .z2Lab: return 24
        case .z3Iot: return 40
        case .z4Guest: return 16
        }
    }

    public var orderIndex: Int {
        switch self {
        case .z0Core: return 0
        case .z1Trusted: return 1
        case .z2Lab: return 2
        case .z3Iot: return 3
        case .z4Guest: return 4
        }
    }
}

public enum DeviceConfidenceTier: String, Codable {
    case confirmed = "confirmed"
    case provisionalGuess = "provisional_guess"
    case opaqueUnknown = "opaque_unknown"
}

public struct DeviceLifecycleCandle: Codable, Equatable {
    public let ver: String
    public let released: Double
    public let attested: Double
    public let ended: Double
    public let eol: Double
    public let cveStart: Double?

    public init(
        ver: String,
        released: Double,
        attested: Double,
        ended: Double,
        eol: Double,
        cveStart: Double? = nil
    ) {
        self.ver = ver
        self.released = released
        self.attested = attested
        self.ended = ended
        self.eol = eol
        self.cveStart = cveStart
    }
}

public struct RackPortDevice: Identifiable, Codable, Equatable {
    public let id: String
    public var portIndex: Int
    public var portState: PortLifecycleState
    public var trustZone: TrustZone
    public var category: StnHardwareCategory
    public var assetTag: String
    public var shortLabel: String
    public var name: String
    public var roomLocation: String
    public var version: String
    public var targetVersion: String?
    public var purchaseDate: String?
    public var vendorEolAt: String?
    public var candles: [DeviceLifecycleCandle]
    public var lifecycleTier: String
    public var purls: [String]
    public var confidenceTier: DeviceConfidenceTier
    public var candidateModels: [String]
    public var excludedPurlPrefixes: [String]
    public var proHeadline: String
    public var stnHeadline: String
    public var s0Identity: String
    public var s1Hardware: String
    public var s2Software: String
    public var s3Lifecycle: String
    public var s4Advisories: String
    public var s5Topology: String
    public var s6Remediation: String

    public init(
        id: String,
        portIndex: Int,
        portState: PortLifecycleState,
        trustZone: TrustZone,
        category: StnHardwareCategory = .C6_IOT,
        assetTag: String,
        shortLabel: String,
        name: String,
        roomLocation: String,
        version: String,
        targetVersion: String? = nil,
        purchaseDate: String? = nil,
        vendorEolAt: String? = nil,
        candles: [DeviceLifecycleCandle] = [],
        lifecycleTier: String,
        purls: [String],
        confidenceTier: DeviceConfidenceTier = .confirmed,
        candidateModels: [String] = [],
        excludedPurlPrefixes: [String] = [],
        proHeadline: String,
        stnHeadline: String,
        s0Identity: String,
        s1Hardware: String,
        s2Software: String,
        s3Lifecycle: String,
        s4Advisories: String,
        s5Topology: String,
        s6Remediation: String
    ) {
        self.id = id
        self.portIndex = portIndex
        self.portState = portState
        self.trustZone = trustZone
        self.category = category
        self.assetTag = assetTag
        self.shortLabel = shortLabel
        self.name = name
        self.roomLocation = roomLocation
        self.version = version
        self.targetVersion = targetVersion
        self.purchaseDate = purchaseDate
        self.vendorEolAt = vendorEolAt
        self.candles = candles
        self.lifecycleTier = lifecycleTier
        self.purls = purls
        self.confidenceTier = confidenceTier
        self.candidateModels = candidateModels
        self.excludedPurlPrefixes = excludedPurlPrefixes
        self.proHeadline = proHeadline
        self.stnHeadline = stnHeadline
        self.s0Identity = s0Identity
        self.s1Hardware = s1Hardware
        self.s2Software = s2Software
        self.s3Lifecycle = s3Lifecycle
        self.s4Advisories = s4Advisories
        self.s5Topology = s5Topology
        self.s6Remediation = s6Remediation
    }
}

public struct LedSlot: Identifiable, Equatable {
    public let id: Int
    public let state: PortLifecycleState
    public let trustZone: TrustZone
    public let deviceId: String?
}

public struct CanonicalFeedItem: Identifiable, Codable, Equatable {
    public let id: String
    public let slug: String
    public let proName: String
    public let stnName: String
    public let purlPrefixes: [String]
}

public struct CuratedBulletinItem: Identifiable, Codable, Equatable {
    public var id: String { externalId }
    public let externalId: String
    public let canonicalFeedSlug: String
    public let bulletinType: String
    public let isHighSev: Bool
    public let purlBase: String
    public let proTitle: String
    public let proBody: String
    public let stnTitle: String
    public let stnBody: String
    public let aiProBullet: String
    public let aiStnBullet: String
    public let publishedAt: String
}

public struct MatchedFeedView: Identifiable, Equatable {
    public let id: String
    public let slug: String
    public let name: String
    public let matchMode: DeviceConfidenceTier
    public let matchedPorts: [String]
    public let candidateModels: [String]
    public let isMuted: Bool
}

public struct BulletinInboxView: Identifiable, Equatable {
    public var id: String { externalId }
    public let externalId: String
    public let feedSlug: String
    public let bulletinType: String
    public let isHighSev: Bool
    public let brokeThroughMute: Bool
    public let matchedByGuess: Bool
    public let candidateModels: [String]
    public let title: String
    public let body: String
    public let publishedAt: String
}

public struct AssembledBulletinsPayload: Equatable {
    public let activeFeedCount: Int
    public let mutedFeedCount: Int
    public let provisionalFeedCount: Int
    public let mutedHighSevOverrideCount: Int
    public let provisionalHighSevCount: Int
    public let aiBullets: [String]
    public let matchedFeeds: [MatchedFeedView]
    public let inbox: [BulletinInboxView]
}

public enum BulletinsAndInventoryEngine {

    public static func build128LedMatrix(
        devices: [RackPortDevice],
        zoneFilter: TrustZone? = nil
    ) -> [LedSlot] {
        var slots: [LedSlot] = []
        let filtered = zoneFilter != nil ? devices.filter { $0.trustZone == zoneFilter } : devices

        var runningIndex = 1
        for dev in filtered {
            if runningIndex <= 128 {
                slots.append(
                    LedSlot(
                        id: runningIndex,
                        state: dev.portState,
                        trustZone: dev.trustZone,
                        deviceId: dev.id
                    )
                )
                runningIndex += 1
            }
        }

        let totalCap = zoneFilter?.slotCount ?? 128
        let remainingUnassigned = max(0, totalCap - slots.count)
        for _ in 0..<remainingUnassigned {
            slots.append(
                LedSlot(
                    id: runningIndex,
                    state: .unassigned,
                    trustZone: zoneFilter ?? .z3Iot,
                    deviceId: nil
                )
            )
            runningIndex += 1
        }
        return slots
    }

    public static func filterActionFirstDevices(
        devices: [RackPortDevice],
        includeOk: Bool = false,
        zoneFilter: TrustZone? = nil,
        portStateFilter: PortLifecycleState? = nil
    ) -> [RackPortDevice] {
        return devices
            .filter { zoneFilter == nil || $0.trustZone == zoneFilter }
            .filter {
                if let pf = portStateFilter {
                    return $0.portState == pf
                }
                return includeOk || $0.portState != .ok
            }
            .sorted { lhs, rhs in
                if lhs.portState.severityPriority != rhs.portState.severityPriority {
                    return lhs.portState.severityPriority < rhs.portState.severityPriority
                }
                return lhs.trustZone.orderIndex < rhs.trustZone.orderIndex
            }
    }

    public static func getCategoryDeviceCount(
        category: StnHardwareCategory,
        devices: [RackPortDevice]
    ) -> Int {
        devices.filter { $0.category == category }.count
    }

    public static func sortDevicesForTimeline(_ devices: [RackPortDevice]) -> [RackPortDevice] {
        return devices.sorted { lhs, rhs in
            if lhs.trustZone.orderIndex != rhs.trustZone.orderIndex {
                return lhs.trustZone.orderIndex < rhs.trustZone.orderIndex
            }
            return lhs.portIndex < rhs.portIndex
        }
    }

    public static func sortDevicesByRecentChanges(_ devices: [RackPortDevice]) -> [RackPortDevice] {
        return Array(
            devices.sorted { lhs, rhs in
                if lhs.portState.severityPriority != rhs.portState.severityPriority {
                    return lhs.portState.severityPriority < rhs.portState.severityPriority
                }
                return (lhs.purchaseDate ?? "") > (rhs.purchaseDate ?? "")
            }.prefix(12)
        )
    }

    public static func getEstimatedVersionAtCursor(
        device: RackPortDevice,
        scrubNorm: Double? = nil
    ) -> String {
        guard let scrubNorm = scrubNorm else {
            return device.version
        }
        if device.portState == .guessed || device.version == "unverified" {
            return "Unverified (Est. Drift)"
        }
        let candles = device.candles
        if candles.isEmpty {
            return device.version
        }
        let earliestCandle = candles[0]
        if scrubNorm < earliestCandle.released {
            return "Not Yet Released"
        }
        let latestCandle = candles[candles.count - 1]
        if latestCandle.eol > 0 && scrubNorm > latestCandle.eol {
            return "\(latestCandle.ver) (EOL)"
        }
        for i in 0..<candles.count {
            let c = candles[i]
            if i + 1 < candles.count {
                let nextCandle = candles[i + 1]
                if scrubNorm >= c.attested && scrubNorm < nextCandle.attested {
                    return c.ver
                }
            } else {
                if scrubNorm >= c.attested {
                    return c.ver
                }
            }
        }
        return earliestCandle.ver
    }

    public static func assembleBulletins(
        flavor: AppBrandFlavor,
        devices: [RackPortDevice],
        mutedFeedSlugs: Set<String>,
        feeds: [CanonicalFeedItem] = defaultGoldFeeds(),
        bulletins: [CuratedBulletinItem] = defaultGoldBulletins()
    ) -> AssembledBulletinsPayload {
        let isStn = flavor == .sureThingHome
        var deviceFeedLinks: [String: [RackPortDevice]] = [:]

        for dev in devices {
            if dev.confidenceTier == .opaqueUnknown { continue }

            var matchedForDevice = feeds.filter { feed in
                let matchesPrefix = feed.purlPrefixes.contains { fp in
                    dev.purls.contains { dp in
                        let cleanDp = dp.components(separatedBy: "@").first?.replacingOccurrences(of: "/*", with: "") ?? dp
                        let cleanFp = fp.replacingOccurrences(of: "/*", with: "")
                        return cleanDp.hasPrefix(cleanFp) || cleanFp.hasPrefix(cleanDp)
                    }
                }
                let excluded = feed.purlPrefixes.allSatisfy { fp in
                    let cleanFp = fp.replacingOccurrences(of: "/*", with: "")
                    return dev.excludedPurlPrefixes.contains { ex in
                        cleanFp.hasPrefix(ex.replacingOccurrences(of: "/*", with: ""))
                    }
                }
                return matchesPrefix && !excluded
            }

            if dev.confidenceTier == .provisionalGuess {
                matchedForDevice = Array(matchedForDevice.prefix(1))
            }

            for feed in matchedForDevice {
                deviceFeedLinks[feed.slug, default: []].append(dev)
            }
        }

        let matchedFeeds = feeds.filter { deviceFeedLinks[$0.slug] != nil }
        var provisionalOnlySlugs = Set<String>()

        let feedViews: [MatchedFeedView] = matchedFeeds.map { feed in
            let linkedDevs = deviceFeedLinks[feed.slug] ?? []
            let hasConfirmed = linkedDevs.contains { $0.confidenceTier == .confirmed }
            let mode: DeviceConfidenceTier = hasConfirmed ? .confirmed : .provisionalGuess
            if !hasConfirmed { provisionalOnlySlugs.insert(feed.slug) }

            let candidates = Array(Set(linkedDevs.flatMap { $0.candidateModels })).sorted()
            return MatchedFeedView(
                id: feed.id,
                slug: feed.slug,
                name: isStn ? feed.stnName : feed.proName,
                matchMode: mode,
                matchedPorts: linkedDevs.map { String(format: "#%02d %@", $0.portIndex, $0.shortLabel) },
                candidateModels: candidates,
                isMuted: mutedFeedSlugs.contains(feed.slug)
            )
        }

        let relevantBulletins = bulletins.filter { b in
            guard let linkedDevs = deviceFeedLinks[b.canonicalFeedSlug] else { return false }
            return linkedDevs.contains { dev in
                let isExcluded = dev.excludedPurlPrefixes.contains { ex in
                    b.purlBase.hasPrefix(ex.replacingOccurrences(of: "/*", with: ""))
                }
                guard !isExcluded else { return false }
                return dev.purls.contains { dp in
                    let cleanDp = dp.components(separatedBy: "@").first?.replacingOccurrences(of: "/*", with: "") ?? dp
                    return b.purlBase.hasPrefix(cleanDp) || cleanDp.hasPrefix(b.purlBase)
                }
            }
        }

        let unmutedConfirmedBulletins = relevantBulletins.filter { b in
            !mutedFeedSlugs.contains(b.canonicalFeedSlug) && !provisionalOnlySlugs.contains(b.canonicalFeedSlug)
        }

        let mutedHighSevCount = relevantBulletins.filter {
            mutedFeedSlugs.contains($0.canonicalFeedSlug) && $0.isHighSev
        }.count

        let provisionalHighSevCount = relevantBulletins.filter {
            provisionalOnlySlugs.contains($0.canonicalFeedSlug) && $0.isHighSev
        }.count

        let aiBullets = unmutedConfirmedBulletins.map { isStn ? $0.aiStnBullet : $0.aiProBullet }

        let inboxItems: [BulletinInboxView] = relevantBulletins.filter { b in
            let isMuted = mutedFeedSlugs.contains(b.canonicalFeedSlug)
            let isProvisional = provisionalOnlySlugs.contains(b.canonicalFeedSlug)
            return (!isMuted && !isProvisional) || b.isHighSev
        }.map { b in
            let fromMuted = mutedFeedSlugs.contains(b.canonicalFeedSlug)
            let fromProvisional = provisionalOnlySlugs.contains(b.canonicalFeedSlug)
            let linkedDevs = deviceFeedLinks[b.canonicalFeedSlug] ?? []
            return BulletinInboxView(
                externalId: b.externalId,
                feedSlug: b.canonicalFeedSlug,
                bulletinType: b.bulletinType,
                isHighSev: b.isHighSev,
                brokeThroughMute: fromMuted && b.isHighSev,
                matchedByGuess: fromProvisional,
                candidateModels: fromProvisional ? linkedDevs.flatMap { $0.candidateModels } : [],
                title: isStn ? b.stnTitle : b.proTitle,
                body: isStn ? b.stnBody : b.proBody,
                publishedAt: b.publishedAt
            )
        }

        let confirmedFeeds = matchedFeeds.filter { !provisionalOnlySlugs.contains($0.slug) }
        let activeFeedCount = confirmedFeeds.filter { !mutedFeedSlugs.contains($0.slug) }.count
        let mutedFeedCount = matchedFeeds.filter { mutedFeedSlugs.contains($0.slug) }.count

        return AssembledBulletinsPayload(
            activeFeedCount: activeFeedCount,
            mutedFeedCount: mutedFeedCount,
            provisionalFeedCount: provisionalOnlySlugs.count,
            mutedHighSevOverrideCount: mutedHighSevCount,
            provisionalHighSevCount: provisionalHighSevCount,
            aiBullets: aiBullets,
            matchedFeeds: feedViews,
            inbox: inboxItems
        )
    }

    public static func defaultRackPortDevices() -> [RackPortDevice] {
        return [
            RackPortDevice(
                id: "0192d9f0-0008-7000-8000-000000000108",
                portIndex: 1,
                portState: .cveKev,
                trustZone: .z0Core,
                category: .C1_GATEWAY,
                assetTag: "STN-GW-01",
                shortLabel: "UDM-Pro",
                name: "Main Rack UniFi Dream Machine Pro",
                roomLocation: "Basement Rack U02",
                version: "4.0.20",
                targetVersion: "4.0.20",
                purchaseDate: "2024-02-01",
                vendorEolAt: "2030-06-01",
                candles: [
                    DeviceLifecycleCandle(ver: "3.2.12", released: 0.05, attested: 0.14, ended: 0.50, eol: 0.70, cveStart: nil),
                    DeviceLifecycleCandle(ver: "4.0.20", released: 0.46, attested: 0.50, ended: 0.96, eol: 0.99, cveStart: 0.78)
                ],
                lifecycleTier: "Active",
                purls: ["pkg:generic/ui/unifi-os@4.0.20"],
                confidenceTier: .confirmed,
                candidateModels: [],
                excludedPurlPrefixes: [],
                proHeadline: "CVE-2026-50881 (0-Day • No Patch): Disable Direct Remote Connection",
                stnHeadline: "Safety Workaround: Turn off Direct Remote Connection in UniFi settings",
                s0Identity: "STN-GW-01 • Basement Rack U02 • Z0 Core",
                s1Hardware: "Ubiquiti UDM-Pro • purchased 2022-11 (26 mo remaining)",
                s2Software: "pkg:generic/ui/unifi-os@4.0.20 (Latest)",
                s3Lifecycle: "Active Support • Zero-Day Workaround Required",
                s4Advisories: "CVE-2026-50881 (CVSS 8.2, EPSS 0.34) • Unpatched 0-day",
                s5Topology: "Z0 Core Gateway • WAN1 + 8 GbE RJ45 + 2 10G SFP+",
                s6Remediation: "Disable Direct Remote Connection until UniFi OS 4.0.21 ships."
            ),
            RackPortDevice(
                id: "0192d9f0-0005-7000-8000-000000000105",
                portIndex: 2,
                portState: .eol,
                trustZone: .z0Core,
                category: .C3_AP,
                assetTag: "STN-AP-00",
                shortLabel: "R7000 AP",
                name: "Basement Netgear R7000",
                roomLocation: "Basement Workbench",
                version: "1.0.11.136",
                targetVersion: nil,
                purchaseDate: "2016-09-01",
                vendorEolAt: "2025-12-31",
                candles: [
                    DeviceLifecycleCandle(ver: "1.0.11.136", released: 0.08, attested: 0.18, ended: 0.96, eol: 0.65, cveStart: nil)
                ],
                lifecycleTier: "Legacy (EOL)",
                purls: ["pkg:generic/netgear/r7000@1.0.11.136"],
                confidenceTier: .confirmed,
                candidateModels: [],
                excludedPurlPrefixes: [],
                proHeadline: "CISA BOD 23-01 • Vendor EOL (2025-12-31) • Decommission from Z0 Core",
                stnHeadline: "Retired Hardware (Age 9.5 yrs): Plan to replace with a modern Wi-Fi 7 access point",
                s0Identity: "STN-AP-00 • Basement Workbench • Z0 Core",
                s1Hardware: "Netgear Nighthawk R7000 • 2016-05 (PAST EOL 2025-12-31)",
                s2Software: "pkg:generic/netgear/r7000@1.0.11.136 + openssl@1.0.2u",
                s3Lifecycle: "Legacy / Obsolete (>8 yrs) • Zero vendor patches",
                s4Advisories: "CISA BOD 23-01 EOL Directive • Unpatched OpenSSL 1.0.2u",
                s5Topology: "Z0 Core AP • Recommend isolation or replacement",
                s6Remediation: "Replace with UniFi U7 Pro or move to isolated lab VLAN."
            ),
            RackPortDevice(
                id: "0192d9f0-0009-7000-8000-000000000109",
                portIndex: 3,
                portState: .ok,
                trustZone: .z0Core,
                category: .C3_AP,
                assetTag: "STN-AP-01",
                shortLabel: "U7-Pro",
                name: "Living Room Ceiling UniFi U7 Pro",
                roomLocation: "1F Living Room",
                version: "7.0.66",
                targetVersion: "7.0.66",
                purchaseDate: "2025-03-10",
                vendorEolAt: "2032-03-10",
                candles: [
                    DeviceLifecycleCandle(ver: "7.0.59", released: 0.10, attested: 0.16, ended: 0.58, eol: 0.85, cveStart: nil),
                    DeviceLifecycleCandle(ver: "7.0.66", released: 0.54, attested: 0.58, ended: 0.96, eol: 0.99, cveStart: nil)
                ],
                lifecycleTier: "Active",
                purls: ["pkg:generic/ui/u7-pro@7.0.66"],
                confidenceTier: .confirmed,
                candidateModels: [],
                excludedPurlPrefixes: [],
                proHeadline: "pkg:generic/ui/u7-pro@7.0.66 • 0 CVEs • Lifecycle Active (54 mo left)",
                stnHeadline: "Up to date (7.0.66) • 4.5 years of manufacturer support remaining",
                s0Identity: "STN-AP-01 • 1F Living Room • Z0 Core",
                s1Hardware: "Ubiquiti U7-Pro • Wi-Fi 7 Tri-Band AP",
                s2Software: "pkg:generic/ui/u7-pro@7.0.66",
                s3Lifecycle: "Active Support (54 mo remaining)",
                s4Advisories: "0 Active CVEs / KEVs",
                s5Topology: "Z0 Core Access Point",
                s6Remediation: "No action required."
            ),
            RackPortDevice(
                id: "0192d9f0-0004-7000-8000-000000000104",
                portIndex: 4,
                portState: .ok,
                trustZone: .z1Trusted,
                category: .C2_SWITCH,
                assetTag: "STN-SW-01",
                shortLabel: "Switch 2",
                name: "Living Room Nintendo Switch 2",
                roomLocation: "1F Media Console",
                version: "19.0.1",
                targetVersion: "19.0.1",
                purchaseDate: "2025-06-15",
                vendorEolAt: "2032-06-15",
                candles: [
                    DeviceLifecycleCandle(ver: "19.0.0", released: 0.15, attested: 0.25, ended: 0.68, eol: 0.90, cveStart: nil),
                    DeviceLifecycleCandle(ver: "19.0.1", released: 0.64, attested: 0.68, ended: 0.96, eol: 0.99, cveStart: nil)
                ],
                lifecycleTier: "Active",
                purls: ["pkg:generic/nintendo/horizon-os@19.0.1"],
                confidenceTier: .confirmed,
                candidateModels: [],
                excludedPurlPrefixes: [],
                proHeadline: "pkg:generic/nintendo/horizon-os@19.0.1 • Enrolled via Plug & Tag",
                stnHeadline: "Up to date (19.0.1) • Warranty receipt saved",
                s0Identity: "STN-SW-01 • 1F Media Console • Z1 Trusted",
                s1Hardware: "Nintendo Switch 2 (BEE-001)",
                s2Software: "pkg:generic/nintendo/horizon-os@19.0.1",
                s3Lifecycle: "Active Support",
                s4Advisories: "0 Active CVEs",
                s5Topology: "Z1 Trusted Docked Ethernet",
                s6Remediation: "No action required."
            ),
            RackPortDevice(
                id: "0192d9f0-0010-7000-8000-000000000110",
                portIndex: 5,
                portState: .update,
                trustZone: .z1Trusted,
                category: .C7_CLIENT,
                assetTag: "STN-CL-02",
                shortLabel: "MacBook M4",
                name: "Aaron's MacBook Pro 16 (M4 Max)",
                roomLocation: "2F Office Desk",
                version: "15.3.1",
                targetVersion: "15.3.2",
                purchaseDate: "2025-01-20",
                vendorEolAt: "2032-01-20",
                candles: [
                    DeviceLifecycleCandle(ver: "15.2.0", released: 0.12, attested: 0.18, ended: 0.52, eol: 0.80, cveStart: nil),
                    DeviceLifecycleCandle(ver: "15.3.1", released: 0.48, attested: 0.52, ended: 0.90, eol: 0.99, cveStart: nil)
                ],
                lifecycleTier: "Active",
                purls: ["pkg:generic/apple/macos@15.3.1"],
                confidenceTier: .confirmed,
                candidateModels: [],
                excludedPurlPrefixes: [],
                proHeadline: "Update Published: pkg:generic/apple/macos@15.3.1 → 15.3.2",
                stnHeadline: "Software Update Ready: macOS 15.3.2 is available to install",
                s0Identity: "STN-CL-02 • 2F Office Desk • Z1 Trusted",
                s1Hardware: "Apple MacBook Pro 16 (M4 Max)",
                s2Software: "pkg:generic/apple/macos@15.3.1 (15.3.2 available)",
                s3Lifecycle: "Active Support (60 mo remaining)",
                s4Advisories: "Routine maintenance update available",
                s5Topology: "Z1 Trusted Workstation",
                s6Remediation: "Install macOS 15.3.2 during Tuesday patch window."
            ),
            RackPortDevice(
                id: "0192d9f0-0001-7000-8000-000000000101",
                portIndex: 6,
                portState: .guessed,
                trustZone: .z2Lab,
                category: .C4_SERVER,
                assetTag: "STN-LAB-09",
                shortLabel: "Unknown Pi",
                name: "Unidentified Raspberry Pi 5 Node",
                roomLocation: "Basement Rack Shelf",
                version: "unverified",
                targetVersion: nil,
                purchaseDate: nil,
                vendorEolAt: nil,
                candles: [
                    DeviceLifecycleCandle(ver: "unverified", released: 0.60, attested: 0.65, ended: 0.96, eol: 0.99, cveStart: nil)
                ],
                lifecycleTier: "Unverified",
                purls: ["pkg:generic/unknown/*"],
                confidenceTier: .opaqueUnknown,
                candidateModels: [],
                excludedPurlPrefixes: [],
                proHeadline: "Opaque Unknown (42% MAC OUI D8:3A:DD): 0 Feeds Attached — Tag Model",
                stnHeadline: "Unidentified Device: Snap a photo of the label so we can track updates",
                s0Identity: "STN-LAB-09 • Basement Rack Shelf • Z2 Lab",
                s1Hardware: "Raspberry Pi Foundation OUI (D8:3A:DD) • Confidence 42%",
                s2Software: "Unverified OS / PURL",
                s3Lifecycle: "Unknown until identified",
                s4Advisories: "0 Feeds Attached (Opaque Unknown <50% confidence)",
                s5Topology: "Z2 Lab Switch Port 6",
                s6Remediation: "Use Plug & Tag camera or enroll tuesday-agent to verify OS."
            ),
            RackPortDevice(
                id: "0192d9f0-0002-7000-8000-000000000102",
                portIndex: 7,
                portState: .ok,
                trustZone: .z2Lab,
                category: .C4_SERVER,
                assetTag: "STN-NAS-01",
                shortLabel: "unraid-lml",
                name: "Unraid Storage Server (lml)",
                roomLocation: "Basement Rack U06",
                version: "7.0.0",
                targetVersion: "7.0.0",
                purchaseDate: "2024-11-15",
                vendorEolAt: "2031-11-15",
                candles: [
                    DeviceLifecycleCandle(ver: "6.12.14", released: 0.08, attested: 0.15, ended: 0.62, eol: 0.85, cveStart: nil),
                    DeviceLifecycleCandle(ver: "7.0.0", released: 0.58, attested: 0.62, ended: 0.96, eol: 0.99, cveStart: nil)
                ],
                lifecycleTier: "Active",
                purls: ["pkg:generic/limetech/unraid@7.0.0"],
                confidenceTier: .confirmed,
                candidateModels: [],
                excludedPurlPrefixes: [],
                proHeadline: "pkg:generic/limetech/unraid@7.0.0 • Chainguard Golden Digests Match",
                stnHeadline: "Up to date (Unraid 7.0.0) • All 14 apps healthy",
                s0Identity: "STN-NAS-01 • Basement Rack U06 • Z2 Lab",
                s1Hardware: "Custom 2U Rackmount NAS (lml)",
                s2Software: "pkg:generic/limetech/unraid@7.0.0",
                s3Lifecycle: "Active Support",
                s4Advisories: "0 Active CVEs",
                s5Topology: "Z2 Lab 10GbE Trunk",
                s6Remediation: "No action required."
            ),
            RackPortDevice(
                id: "0192d9f0-0011-7000-8000-000000000111",
                portIndex: 8,
                portState: .update,
                trustZone: .z2Lab,
                category: .C4_SERVER,
                assetTag: "STN-LAB-02",
                shortLabel: "Proxmox VE",
                name: "Homelab Hypervisor (pve-node-01)",
                roomLocation: "Basement Rack U04",
                version: "8.3.1",
                targetVersion: "8.3.2",
                purchaseDate: "2025-02-01",
                vendorEolAt: "2030-02-01",
                candles: [
                    DeviceLifecycleCandle(ver: "8.2.4", released: 0.08, attested: 0.14, ended: 0.46, eol: 0.78, cveStart: nil),
                    DeviceLifecycleCandle(ver: "8.3.1", released: 0.44, attested: 0.46, ended: 0.90, eol: 0.99, cveStart: nil)
                ],
                lifecycleTier: "Active",
                purls: ["pkg:deb/debian/proxmox-ve@8.3.1"],
                confidenceTier: .confirmed,
                candidateModels: [],
                excludedPurlPrefixes: [],
                proHeadline: "Update Published: pkg:deb/debian/proxmox-ve@8.3.1 → 8.3.2",
                stnHeadline: "Update Available: Proxmox Server 8.3.2 ready for Tuesday window",
                s0Identity: "STN-LAB-02 • Basement Rack U04 • Z2 Lab",
                s1Hardware: "Minisforum MS-01 (pve-node-01)",
                s2Software: "pkg:deb/debian/proxmox-ve@8.3.1 (8.3.2 available)",
                s3Lifecycle: "Active Support",
                s4Advisories: "QEMU maintenance update queued",
                s5Topology: "Z2 Lab Hypervisor Trunk",
                s6Remediation: "Apply apt dist-upgrade during Tuesday window."
            ),
            RackPortDevice(
                id: "0192d9f0-0006-7000-8000-000000000106",
                portIndex: 9,
                portState: .cveKev,
                trustZone: .z3Iot,
                category: .C5_CAMERA,
                assetTag: "STN-CAM-01",
                shortLabel: "Baby Cam",
                name: "Nursery Baby Monitor",
                roomLocation: "2F Nursery",
                version: "1.0.4",
                targetVersion: "2.1.0",
                purchaseDate: "2025-01-12",
                vendorEolAt: "2026-10-15",
                candles: [
                    DeviceLifecycleCandle(ver: "1.0.2", released: 0.05, attested: 0.12, ended: 0.45, eol: 0.55, cveStart: nil),
                    DeviceLifecycleCandle(ver: "1.0.4", released: 0.40, attested: 0.45, ended: 0.96, eol: 0.98, cveStart: 0.62)
                ],
                lifecycleTier: "Active",
                purls: ["pkg:generic/owlet/cam-2@1.0.4"],
                confidenceTier: .confirmed,
                candidateModels: [],
                excludedPurlPrefixes: [],
                proHeadline: "CPSC Recall #26-104 (Thermal Power Cord) + Firmware 1.0.4 → 2.1.0",
                stnHeadline: "Safety Recall & Firmware Fix: Check power cord and update to 2.1.0",
                s0Identity: "STN-CAM-01 • 2F Nursery • Z3 IoT",
                s1Hardware: "Owlet Cam 2 • S/N 44A819002106",
                s2Software: "pkg:generic/owlet/cam-2@1.0.4 (2.1.0 available)",
                s3Lifecycle: "Active Support • Physical Safety Recall",
                s4Advisories: "CPSC Recall #26-104 + RTSP Auth Bypass CVE",
                s5Topology: "Z3 IoT Wi-Fi VLAN 30",
                s6Remediation: "Order free replacement USB-C cord and update firmware to 2.1.0."
            ),
            RackPortDevice(
                id: "0192d9f0-0007-7000-8000-000000000107",
                portIndex: 10,
                portState: .cveKev,
                trustZone: .z3Iot,
                category: .C6_IOT,
                assetTag: "STN-IOT-01",
                shortLabel: "LG OLED",
                name: "Living Room LG OLED TV",
                roomLocation: "1F Living Room",
                version: "8.1.0",
                targetVersion: "8.3.0",
                purchaseDate: "2022-11-28",
                vendorEolAt: "2027-11-28",
                candles: [
                    DeviceLifecycleCandle(ver: "8.0.4", released: 0.04, attested: 0.10, ended: 0.38, eol: 0.60, cveStart: nil),
                    DeviceLifecycleCandle(ver: "8.1.0", released: 0.32, attested: 0.38, ended: 0.96, eol: 0.99, cveStart: 0.72)
                ],
                lifecycleTier: "Vintage",
                purls: ["pkg:generic/lg/webos@8.1.0"],
                confidenceTier: .confirmed,
                candidateModels: [],
                excludedPurlPrefixes: [],
                proHeadline: "CISA KEV CVE-2026-21099 (EPSS 0.91): Patch 8.1.0 → 8.3.0 Available",
                stnHeadline: "Security Update Ready: Update LG TV software from 8.1.0 to 8.3.0",
                s0Identity: "STN-IOT-01 • 1F Living Room • Z3 IoT",
                s1Hardware: "LG OLED65C3PUA • Vintage Tier",
                s2Software: "pkg:generic/lg/webos@8.1.0 (8.3.0 available)",
                s3Lifecycle: "Vintage Support (8 mo remaining)",
                s4Advisories: "CISA KEV CVE-2026-21099 (CVSS 9.1, EPSS 0.91)",
                s5Topology: "Z3 IoT Media VLAN",
                s6Remediation: "Update TV firmware to 8.3.0 in Settings -> Support -> Software Update."
            ),
            RackPortDevice(
                id: "0192d9f0-0003-7000-8000-000000000103",
                portIndex: 11,
                portState: .update,
                trustZone: .z3Iot,
                category: .C6_IOT,
                assetTag: "STN-IOT-04",
                shortLabel: "Garage ESP",
                name: "Garage Door Relay ESP32",
                roomLocation: "Garage Ceiling",
                version: "2026.9.0",
                targetVersion: "2026.10.2",
                purchaseDate: "2024-03-10",
                vendorEolAt: "2029-03-10",
                candles: [
                    DeviceLifecycleCandle(ver: "2026.8.2", released: 0.10, attested: 0.18, ended: 0.48, eol: 0.75, cveStart: nil),
                    DeviceLifecycleCandle(ver: "2026.9.0", released: 0.45, attested: 0.48, ended: 0.92, eol: 0.99, cveStart: nil)
                ],
                lifecycleTier: "Active",
                purls: ["pkg:generic/esphome/firmware@2026.9.0"],
                confidenceTier: .confirmed,
                candidateModels: [],
                excludedPurlPrefixes: [],
                proHeadline: "Update Published: pkg:generic/esphome/firmware@2026.9.0 → 2026.10.2",
                stnHeadline: "Minor Feature Update: ESPHome 2026.10.2 available in Home Assistant",
                s0Identity: "STN-IOT-04 • Garage Ceiling • Z3 IoT",
                s1Hardware: "ESP32-WROOM-32D Relay Node",
                s2Software: "pkg:generic/esphome/firmware@2026.9.0 (2026.10.2 available)",
                s3Lifecycle: "Active Support",
                s4Advisories: "0 Active CVEs • Minor Wi-Fi reconnect fix",
                s5Topology: "Z3 IoT Wi-Fi",
                s6Remediation: "Trigger OTA update via Home Assistant ESPHome dashboard."
            ),
            RackPortDevice(
                id: "0192d9f0-0012-7000-8000-000000000112",
                portIndex: 12,
                portState: .guessed,
                trustZone: .z3Iot,
                category: .C6_IOT,
                assetTag: "STN-IOT-09",
                shortLabel: "Thermostat",
                name: "Hallway Smart Thermostat",
                roomLocation: "1F Hallway",
                version: "unverified",
                targetVersion: nil,
                purchaseDate: nil,
                vendorEolAt: nil,
                candles: [
                    DeviceLifecycleCandle(ver: "unverified", released: 0.55, attested: 0.62, ended: 0.96, eol: 0.99, cveStart: nil)
                ],
                lifecycleTier: "Provisional Guess",
                purls: ["pkg:generic/ecobee/*"],
                confidenceTier: .provisionalGuess,
                candidateModels: ["SmartThermostat Premium", "Ecobee3 Lite"],
                excludedPurlPrefixes: [],
                proHeadline: "Best Guess (72% OUI 44:61:32 + _hap._tcp): Ecobee Family • Confirm Model",
                stnHeadline: "Likely Ecobee Thermostat (72% Match): Confirm exact model on Bulletins tab",
                s0Identity: "STN-IOT-09 • 1F Hallway • Z3 IoT",
                s1Hardware: "Ecobee Inc. OUI (44:61:32) + HomeKit mDNS • 72% Guess",
                s2Software: "pkg:generic/ecobee/* (Provisional Umbrella PURL)",
                s3Lifecycle: "Provisional Guardrail Mode (High-Sev Alerts Only)",
                s4Advisories: "CVE-2026-88901 HomeKit Pairing Bypass (Confirm Model to Verify)",
                s5Topology: "Z3 IoT Wi-Fi",
                s6Remediation: "Tap Confirm Model on Bulletins tab to lock exact hardware SKU."
            )
        ]
    }

    public static func defaultGoldFeeds() -> [CanonicalFeedItem] {
        return [
            CanonicalFeedItem(
                id: "f-01",
                slug: "ubiquiti-advisories",
                proName: "Ubiquiti UniFi Security & Firmware",
                stnName: "UniFi Wi-Fi & Router Updates",
                purlPrefixes: ["pkg:generic/ui/unifi-os", "pkg:generic/ui/u7-pro"]
            ),
            CanonicalFeedItem(
                id: "f-02",
                slug: "cpsc-safety",
                proName: "CPSC Consumer Recalls & IoT Advisories",
                stnName: "U.S. Safety Recalls & Nursery Alerts",
                purlPrefixes: ["pkg:generic/owlet/cam-2"]
            ),
            CanonicalFeedItem(
                id: "f-03",
                slug: "vendor-eol-ledger",
                proName: "CISA BOD 23-01 & Vendor EOL Ledger",
                stnName: "Retired Device & End-of-Support Notices",
                purlPrefixes: ["pkg:generic/netgear/r7000"]
            ),
            CanonicalFeedItem(
                id: "f-04",
                slug: "apple-proxmox-upstream",
                proName: "Apple macOS & Debian Proxmox Releases",
                stnName: "MacBook & Home Server Software Updates",
                purlPrefixes: ["pkg:generic/apple/macos", "pkg:deb/debian/proxmox-ve"]
            ),
            CanonicalFeedItem(
                id: "f-05",
                slug: "unraid-nintendo-stable",
                proName: "Unraid OS & Nintendo Horizon OS",
                stnName: "Media Server & Game Console Updates",
                purlPrefixes: ["pkg:generic/limetech/unraid", "pkg:generic/nintendo/horizon-os"]
            ),
            CanonicalFeedItem(
                id: "f-06",
                slug: "lg-esphome-iot",
                proName: "LG webOS TV & ESPHome Firmware",
                stnName: "Smart TV & Garage Sensor Updates",
                purlPrefixes: ["pkg:generic/lg/webos", "pkg:generic/esphome/firmware"]
            ),
            CanonicalFeedItem(
                id: "f-07",
                slug: "ecobee-umbrella",
                proName: "Ecobee SmartThermostat Family Advisories",
                stnName: "Ecobee Thermostat Security & Recalls",
                purlPrefixes: ["pkg:generic/ecobee/*"]
            ),
            CanonicalFeedItem(
                id: "f-08",
                slug: "synology-dsm",
                proName: "Synology DSM Advisories",
                stnName: "Synology NAS Updates",
                purlPrefixes: ["pkg:generic/synology/dsm"]
            )
        ]
    }

    public static func defaultGoldBulletins() -> [CuratedBulletinItem] {
        return [
            CuratedBulletinItem(
                externalId: "CPSC-26-104",
                canonicalFeedSlug: "cpsc-safety",
                bulletinType: "recall",
                isHighSev: true,
                purlBase: "pkg:generic/owlet/cam-2",
                proTitle: "CPSC-26-104: Owlet Cam 2 Thermal Power Cord Recall",
                proBody: "Published CPSC physical hazard notice matching S1 serial 44A819002106. Inspect USB-C power cable and request free replacement kit.",
                stnTitle: "Safety Recall: Nursery Baby Monitor Power Cord",
                stnBody: "The U.S. Consumer Product Safety Commission issued a recall for the power cord on your Nursery Baby Monitor. Tap to request a free replacement cord.",
                aiProBullet: "1 Physical Recall (Port #09): CPSC-26-104 thermal cord recall on Nursery Baby Cam.",
                aiStnBullet: "Safety Recall (Nursery Baby Monitor): Check the power cord and claim a free replacement kit.",
                publishedAt: "2h ago"
            ),
            CuratedBulletinItem(
                externalId: "CVE-2026-88901",
                canonicalFeedSlug: "ecobee-umbrella",
                bulletinType: "cve",
                isHighSev: true,
                purlBase: "pkg:generic/ecobee/smart-thermostat",
                proTitle: "CVE-2026-88901: Ecobee HomeKit Local Pairing PIN Bypass",
                proBody: "High-severity LAN pairing bypass affecting Ecobee SmartThermostat family. Matched via OUI 44:61:32 on Port #12 (72% confidence) — confirm exact SKU.",
                stnTitle: "Possible Security Update: Hallway Smart Thermostat",
                stnBody: "We think Port #12 is an Ecobee Thermostat. Confirm your exact model to verify if this security advisory applies to your home.",
                aiProBullet: "1 Confirmed Ecobee CVE (Port #12): HomeKit LAN pairing bypass.",
                aiStnBullet: "Thermostat Security Fix (Hallway Ecobee): Update firmware to fix HomeKit pairing bug.",
                publishedAt: "3h ago"
            ),
            CuratedBulletinItem(
                externalId: "CVE-2026-21099",
                canonicalFeedSlug: "lg-esphome-iot",
                bulletinType: "cisa_kev",
                isHighSev: true,
                purlBase: "pkg:generic/lg/webos",
                proTitle: "CVE-2026-21099 (CISA KEV): LG webOS LAN Auth Bypass",
                proBody: "Active exploitation reported in CISA KEV catalog affecting webOS < 8.3.0. Port #10 is running 8.1.0; patch 8.3.0 is available upstream.",
                stnTitle: "Critical Security Fix Needed: Living Room LG OLED TV",
                stnBody: "A critical security flaw affects LG TVs running version 8.1.0. Update your TV software to version 8.3.0 in Settings -> Support.",
                aiProBullet: "1 CISA KEV Exploit (Port #10): LG webOS 8.1.0 auth bypass; patch 8.3.0 ready.",
                aiStnBullet: "Critical TV Update (Living Room LG TV): Install software update 8.3.0 to fix a security warning.",
                publishedAt: "5h ago"
            ),
            CuratedBulletinItem(
                externalId: "CVE-2026-50881",
                canonicalFeedSlug: "ubiquiti-advisories",
                bulletinType: "cve",
                isHighSev: true,
                purlBase: "pkg:generic/ui/unifi-os",
                proTitle: "CVE-2026-50881: UniFi OS 4.0.20 Remote Management Advisory",
                proBody: "0-day advisory affecting unifi-core@4.0.20 (currently running on Port #01). Workaround: disable Direct Remote Connection until 4.0.21 ships.",
                stnTitle: "Security Workaround: Main Rack UniFi Gateway",
                stnBody: "Your router is on the newest version (4.0.20), but Ubiquiti recommends turning off Direct Remote Connection until 4.0.21 arrives.",
                aiProBullet: "1 Zero-Day Workaround (Port #01): UniFi OS 4.0.20 requires Direct Remote Connection disabled.",
                aiStnBullet: "Router Safety Tip (Main UniFi Gateway): Turn off Direct Remote Connection until version 4.0.21 releases.",
                publishedAt: "9h ago"
            ),
            CuratedBulletinItem(
                externalId: "EOL-netgear-r7000",
                canonicalFeedSlug: "vendor-eol-ledger",
                bulletinType: "eol",
                isHighSev: true,
                purlBase: "pkg:generic/netgear/r7000",
                proTitle: "CISA BOD 23-01 / Netgear EOL: R7000 Passed Support Cutoff",
                proBody: "Hardware on Port #02 reached End-of-Support (2025-12-31) with unpatched openssl@1.0.2u. Decommission from Z0 Core.",
                stnTitle: "Retired Device Notice: Basement Netgear R7000",
                stnBody: "Netgear ended security updates for this 2016 Wi-Fi router. We recommend replacing it with a supported access point.",
                aiProBullet: "1 End-of-Life Notice (Port #02): Netgear R7000 passed vendor EOL cutoff.",
                aiStnBullet: "Retired Router (Basement Netgear R7000): Ended manufacturer support; plan a replacement.",
                publishedAt: "1d ago"
            ),
            CuratedBulletinItem(
                externalId: "REL-macos-15.3.2-pve-8.3.2",
                canonicalFeedSlug: "apple-proxmox-upstream",
                bulletinType: "release",
                isHighSev: false,
                purlBase: "pkg:generic/apple/macos",
                proTitle: "Upstream Releases: macOS 15.3.2 & Proxmox VE 8.3.2 Available",
                proBody: "Routine maintenance releases published for Port #05 (MacBook Pro M4: 15.3.1 -> 15.3.2) and Port #08 (pve-node-01: 8.3.1 -> 8.3.2).",
                stnTitle: "New Software Releases: MacBook Pro & Home Server",
                stnBody: "Routine stability updates are ready for Aaron's MacBook Pro (macOS 15.3.2) and your Proxmox Home Server (8.3.2).",
                aiProBullet: "2 Routine Releases (Ports #05, #08): macOS 15.3.2 and Proxmox VE 8.3.2 available.",
                aiStnBullet: "2 Routine Software Updates: New maintenance releases for MacBook Pro and Home Server.",
                publishedAt: "1d ago"
            ),
            CuratedBulletinItem(
                externalId: "REL-esphome-2026.10.2",
                canonicalFeedSlug: "lg-esphome-iot",
                bulletinType: "release",
                isHighSev: false,
                purlBase: "pkg:generic/esphome/firmware",
                proTitle: "ESPHome 2026.10.2 Minor Release (esp-idf@5.3.1)",
                proBody: "Minor Wi-Fi reconnect improvement for ESP32 relays on Port #11 (currently running 2026.9.0). No CVEs associated.",
                stnTitle: "Minor Feature Update: Garage Door Relay ESP32",
                stnBody: "ESPHome 2026.10.2 is available with minor Wi-Fi stability improvements for your garage relay.",
                aiProBullet: "1 IoT Release (Port #11): ESPHome 2026.10.2 minor update ready.",
                aiStnBullet: "1 Smart Home Update: Minor ESPHome 2026.10.2 update for Garage Door Relay.",
                publishedAt: "2d ago"
            ),
            CuratedBulletinItem(
                externalId: "REL-ecobee-4.8.7.220",
                canonicalFeedSlug: "ecobee-umbrella",
                bulletinType: "release",
                isHighSev: false,
                purlBase: "pkg:generic/ecobee/smart-thermostat",
                proTitle: "Ecobee Firmware 4.8.7.220 Routine Radar Tuning",
                proBody: "Routine occupancy radar tuning for SmartThermostat Premium (suppressed while Port #12 is an unconfirmed guess).",
                stnTitle: "Routine Thermostat Update (4.8.7.220)",
                stnBody: "Minor room sensor update for Ecobee SmartThermostat.",
                aiProBullet: "1 Thermostat Release (Port #12): Ecobee 4.8.7.220 available.",
                aiStnBullet: "1 Thermostat Update: Routine sensor tuning for Hallway Ecobee.",
                publishedAt: "4d ago"
            )
        ]
    }
}
