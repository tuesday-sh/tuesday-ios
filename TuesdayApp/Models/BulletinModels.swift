import Foundation

// Required CI taxonomy contract token: UNASSIGNED("unassigned"
public enum AppBrandFlavor: String, Codable, CaseIterable {
    case tuesdayPro = "TUESDAY_PRO"
    case sureThingHome = "SURETHING_HOME"

    public var title: String {
        switch self {
        case .tuesdayPro: return "Tuesday.sh"
        case .sureThingHome: return "SureThing"
        }
    }

    public var badge: String {
        switch self {
        case .tuesdayPro: return "PRO"
        case .sureThingHome: return "HOME"
        }
    }

    public var subtitle: String {
        switch self {
        case .tuesdayPro: return "Continuous Fleet Vulnerability & Firmware Ledger"
        case .sureThingHome: return "Safe Smart Home & Wi-Fi Lifespan Guard"
        }
    }
}

public enum PortLifecycleState: String, Codable, CaseIterable, Identifiable {
    case cveKev = "cve_kev"
    case eol = "eol"
    case guessed = "guessed"
    case update = "update"
    case ok = "ok"
    case unassigned = "unassigned"

    public var id: String { rawValue }
    public var key: String { rawValue }

    public var severityPriority: Int {
        switch self {
        case .cveKev: return 0
        case .eol: return 1
        case .guessed: return 2
        case .update: return 3
        case .ok: return 4
        case .unassigned: return 99
        }
    }

    public var badgeLabel: String {
        switch self {
        case .cveKev: return "CVE / KEV"
        case .eol: return "Vendor EOL"
        case .guessed: return "Guessed"
        case .update: return "Update Ready"
        case .ok: return "OK"
        case .unassigned: return "Unassigned"
        }
    }

    public var stnLabel: String {
        switch self {
        case .cveKev: return "Critical Fix"
        case .eol: return "Past Support"
        case .guessed: return "Confirm Model"
        case .update: return "Update Ready"
        case .ok: return "Protected"
        case .unassigned: return "Empty"
        }
    }

    public var proLabel: String { badgeLabel }

    public var isAttentionRequired: Bool {
        self == .cveKev || self == .eol || self == .guessed || self == .update
    }
}

public enum InventoryScaleTier: String, Codable, CaseIterable, Identifiable {
    case DAY_ZERO = "DAY_ZERO"
    case PEA = "PEA"
    case GARDEN = "GARDEN"
    case FOREST = "FOREST"

    public static let dayZero: InventoryScaleTier = .DAY_ZERO
    public static let pea: InventoryScaleTier = .PEA
    public static let garden: InventoryScaleTier = .GARDEN
    public static let forest: InventoryScaleTier = .FOREST

    public var id: String { rawValue }
    public var showSummaryBadge: Bool { self != .DAY_ZERO }
    public var showPortDiagramStrip: Bool { self == .GARDEN || self == .FOREST }
    public var showFilterChips: Bool { self == .FOREST }
    public var showTrustZonePills: Bool { self == .GARDEN || self == .FOREST }

    public static func forCount(_ count: Int) -> InventoryScaleTier {
        switch count {
        case ...0: return .dayZero
        case 1...2: return .pea
        case 3...7: return .garden
        default: return .forest
        }
    }

    public var badgeText: String {
        switch self {
        case .DAY_ZERO: return "EMPTY"
        case .PEA: return "🌱 PEA"
        case .GARDEN: return "🪴 GARDEN"
        case .FOREST: return "🌲 FOREST"
        }
    }

    public var stnDescription: String {
        switch self {
        case .DAY_ZERO: return "Add your first router, printer, or smart device to unlock telemetry."
        case .PEA: return "Minimal home setup — showing every device card in full detail."
        case .GARDEN: return "Growing smart home — category strip + device cards active."
        case .FOREST: return "Full network topology — 128-slot botanical grid & profiles active."
        }
    }
}

/// SureThingNet Standard Categories (Scale C: C1_GATEWAY .. C8_GUEST)
public enum StnHardwareCategory: String, Codable, CaseIterable, Identifiable {
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

    public var id: String { rawValue }
    public var key: String { rawValue }
    public var code: String { rawValue }

    public var ordinal: Int {
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

    public var shortLabel: String {
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

    public var shortName: String { shortLabel }

    public var discoveryClueLabel: String {
        switch self {
        case .C1_GATEWAY: return "Router / Gateway"
        case .C2_SWITCH: return "Network Switch"
        case .C3_AP: return "Wi-Fi Access Point"
        case .C4_SERVER: return "NAS / Home Server"
        case .C5_CAMERA: return "Security Camera"
        case .C6_IOT: return "Smart Hub / Bridge"
        case .C7_CLIENT: return "Workstation / Client"
        case .C8_GUEST: return "TV / Speaker / Media"
        }
    }

    public var description: String {
        switch self {
        case .C1_GATEWAY: return "Perimeter firewall, WAN uplink, NAT, DHCP server, and default gateway."
        case .C2_SWITCH: return "Physical distribution plane, 802.1Q VLAN trunking, and PoE power delivery."
        case .C3_AP: return "Radio-frequency access point translating wireless airwaves into wired Ethernet."
        case .C4_SERVER: return "Storage (NAS), local DNS, container virtualization, and homelab workloads."
        case .C5_CAMERA: return "Surveillance video, real-time RTSP/WebRTC streams, and perimeter sensing."
        case .C6_IOT: return "Home automation controllers, networked printers, and constrained smart peripherals."
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
        case .C6_IOT: return "Home Assistant, Hubitat, Hue, Ecobee, Printers"
        case .C7_CLIENT: return "MacBook Pro, ThinkPad, Linux PC, iPad"
        case .C8_GUEST: return "Guest Portal, Visitor Laptop, Cast Client"
        }
    }

    public func displayLabel(isStn: Bool) -> String {
        isStn ? stnLabel : proLabel
    }

    public static func fromDiscoveryHint(_ hint: String?) -> StnHardwareCategory {
        let lower = (hint ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !lower.isEmpty else { return .C6_IOT }
        let tokens = Set(lower.split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map(String.init))

        if ["router", "gateway", "modem", "firewall", "udm", "ucg"].contains(where: { lower.contains($0) }) {
            return .C1_GATEWAY
        }
        if ["switch", "patch"].contains(where: { lower.contains($0) }) {
            return .C2_SWITCH
        }
        if ["access point", "wi-fi ap", "wifi ap", "mesh"].contains(where: { lower.contains($0) }) || tokens.contains("ap") {
            return .C3_AP
        }
        if ["server", "nas", "proxmox", "compute", "storage", "diskstation", "truenas", "unraid"].contains(where: { lower.contains($0) }) {
            return .C4_SERVER
        }
        if ["camera", "doorbell", "nvr", "vision"].contains(where: { lower.contains($0) }) {
            return .C5_CAMERA
        }
        if ["workstation", "laptop", "surface", "macbook", "thinkpad", "chromebook", "notebook", "desktop", "imac", "client", "iphone", "ipad", "phone", "tablet"].contains(where: { lower.contains($0) }) {
            return .C7_CLIENT
        }
        if ["guest", "speaker", "media", "sonos", "roku"].contains(where: { lower.contains($0) }) || tokens.contains("tv") {
            return .C8_GUEST
        }
        if ["iot", "hub", "bridge", "thermostat", "printer", "plug", "sensor", "relay", "zigbee", "zwave"].contains(where: { lower.contains($0) }) {
            return .C6_IOT
        }

        if tokens.contains("c1") { return .C1_GATEWAY }
        if tokens.contains("c2") { return .C2_SWITCH }
        if tokens.contains("c3") { return .C3_AP }
        if tokens.contains("c4") { return .C4_SERVER }
        if tokens.contains("c5") { return .C5_CAMERA }
        if tokens.contains("c6") { return .C6_IOT }
        if tokens.contains("c7") { return .C7_CLIENT }
        if tokens.contains("c8") { return .C8_GUEST }
        return .C6_IOT
    }
}

public enum LifecycleLayer: String, Codable, CaseIterable, Identifiable {
    case s0Space = "S0"
    case s1Hardware = "S1"
    case s2Port = "S2"
    case s3Vlan = "S3"
    case s4Firmware = "S4"
    case s5Os = "S5"
    case s6Packages = "S6"

    public var id: String { rawValue }
    public var key: String { rawValue }

    public var title: String {
        switch self {
        case .s0Space: return "S0 • Room & Outlet"
        case .s1Hardware: return "S1 • Hardware & Lifespan"
        case .s2Port: return "S2 • Cable & Wi-Fi Link"
        case .s3Vlan: return "S3 • Trust Ring / VLAN"
        case .s4Firmware: return "S4 • Firmware & Bootloader"
        case .s5Os: return "S5 • OS & Runtime"
        case .s6Packages: return "S6 • Advisories & PURLs"
        }
    }
}

public enum DevicePresenceState: String, Codable, CaseIterable, Identifiable {
    case active = "ACTIVE"
    case retired = "RETIRED"
    case lost = "LOST"
    case stoppedWorking = "STOPPED_WORKING"

    public var id: String { rawValue }
    public var key: String { rawValue }

    public var isOutOfService: Bool {
        self != .active
    }

    public var badgeLabel: String {
        switch self {
        case .active: return "Active"
        case .retired: return "Retired"
        case .lost: return "Lost"
        case .stoppedWorking: return "Stopped Working"
        }
    }

    public var stnLabel: String {
        switch self {
        case .active: return "In Service"
        case .retired: return "Retired / Boxed"
        case .lost: return "Missing / Lost"
        case .stoppedWorking: return "Broken / Dead"
        }
    }

    public var shortLabel: String {
        switch self {
        case .active: return "ACTIVE"
        case .retired: return "RETIRED"
        case .lost: return "LOST"
        case .stoppedWorking: return "DEFECTIVE"
        }
    }
}

public enum AttestationType: String, Codable, CaseIterable, Identifiable {
    case presenceAudit = "PRESENCE_AUDIT"
    case absenceRetired = "ABSENCE_RETIRED"
    case absenceLost = "ABSENCE_LOST"
    case absenceStoppedWorking = "ABSENCE_STOPPED_WORKING"
    case presenceReactivated = "PRESENCE_REACTIVATED"
    case physicalInspect = "PHYSICAL_INSPECT"
    case firmwareCheck = "FIRMWARE_CHECK"
    case annualAudit = "ANNUAL_AUDIT"
    case decommission = "DECOMMISSION"

    public var id: String { rawValue }
    public var key: String { rawValue }

    public var resultingState: DevicePresenceState {
        switch self {
        case .presenceAudit, .presenceReactivated, .physicalInspect, .firmwareCheck, .annualAudit:
            return .active
        case .absenceRetired, .decommission:
            return .retired
        case .absenceLost:
            return .lost
        case .absenceStoppedWorking:
            return .stoppedWorking
        }
    }

    public var displayLabel: String {
        switch self {
        case .presenceAudit: return "Presence Attestation"
        case .absenceRetired: return "Decommission (Retired)"
        case .absenceLost: return "Absence (Lost / Missing)"
        case .absenceStoppedWorking: return "Absence (Stopped Working)"
        case .presenceReactivated: return "Reactivation (Return to Service)"
        case .physicalInspect: return "Physical Check-In"
        case .firmwareCheck: return "Firmware Attested"
        case .annualAudit: return "Seasonal / Yearly Audit"
        case .decommission: return "Retired / Decommissioned"
        }
    }
}

public struct DeviceAttestation: Identifiable, Codable, Equatable {
    public let id: String
    public let deviceId: String
    public var auditDate: String
    public var attestedBy: String
    public var type: AttestationType
    public var presenceState: DevicePresenceState
    public var observedVersion: String?
    public var sessionId: String?
    public var notes: String?

    public init(
        id: String = UUID().uuidString,
        deviceId: String,
        auditDate: String,
        attestedBy: String = "Local Owner",
        type: AttestationType = .physicalInspect,
        presenceState: DevicePresenceState = .active,
        observedVersion: String? = nil,
        sessionId: String? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.deviceId = deviceId
        self.auditDate = auditDate
        self.attestedBy = attestedBy
        self.type = type
        self.presenceState = presenceState
        self.observedVersion = observedVersion
        self.sessionId = sessionId
        self.notes = notes
    }
}

public struct OperationalCandle: Identifiable, Equatable {
    public let id: String
    public let shortLabel: String
    public let name: String
    public let version: String
    public let trustZone: TrustZone
    public let presenceState: DevicePresenceState
    public let hasCveOrRecall: Bool
    public let isPastEol: Bool
    public let isEolNearing: Bool
    public let isGuessed: Bool
    public let isRetired: Bool
    public let marketReleaseNorm: Double
    public let deployStartNorm: Double
    public let deployEndNorm: Double
    public let vendorEolNorm: Double
    public let cveStartNorm: Double?
    public let releaseLabel: String
    public let eolLabel: String
    public let latestAttestation: DeviceAttestation?
    public let attestationCount: Int
    public let releaseDateStr: String?
    public let deployDateStr: String?
    public let eolDateStr: String?

    public init(
        id: String,
        shortLabel: String,
        name: String,
        version: String,
        trustZone: TrustZone,
        presenceState: DevicePresenceState,
        hasCveOrRecall: Bool,
        isPastEol: Bool,
        isEolNearing: Bool,
        isGuessed: Bool,
        isRetired: Bool,
        marketReleaseNorm: Double,
        deployStartNorm: Double,
        deployEndNorm: Double,
        vendorEolNorm: Double,
        cveStartNorm: Double?,
        releaseLabel: String,
        eolLabel: String,
        latestAttestation: DeviceAttestation?,
        attestationCount: Int,
        releaseDateStr: String? = nil,
        deployDateStr: String? = nil,
        eolDateStr: String? = nil
    ) {
        self.id = id
        self.shortLabel = shortLabel
        self.name = name
        self.version = version
        self.trustZone = trustZone
        self.presenceState = presenceState
        self.hasCveOrRecall = hasCveOrRecall
        self.isPastEol = isPastEol
        self.isEolNearing = isEolNearing
        self.isGuessed = isGuessed
        self.isRetired = isRetired
        self.marketReleaseNorm = marketReleaseNorm
        self.deployStartNorm = deployStartNorm
        self.deployEndNorm = deployEndNorm
        self.vendorEolNorm = vendorEolNorm
        self.cveStartNorm = cveStartNorm
        self.releaseLabel = releaseLabel
        self.eolLabel = eolLabel
        self.latestAttestation = latestAttestation
        self.attestationCount = attestationCount
        self.releaseDateStr = releaseDateStr
        self.deployDateStr = deployDateStr
        self.eolDateStr = eolDateStr
    }
}

public enum ApiEndpointPreset: String, CaseIterable, Identifiable {
    case prodGcp = "https://api.tuesday.sh"
    case localDev = "http://127.0.0.1:3000"

    public var id: String { rawValue }
    public var key: String { rawValue }
    public var url: String { rawValue }

    public var shortBadge: String {
        switch self {
        case .prodGcp: return "☁️ PROD GCP"
        case .localDev: return "💻 LOCAL"
        }
    }

    public static func fromUrl(_ url: String) -> ApiEndpointPreset? {
        let normalized = url.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            .lowercased()
        return Self.allCases.first(where: { $0.rawValue.lowercased() == normalized })
    }
}

public struct NetworkSite: Identifiable, Codable, Equatable {
    public let id: String
    public var name: String
    public var devicesCount: Int
    public var role: String
    public var emoji: String
    public var timezone: String
    public var isSynced: Bool

    public var deviceCount: Int { devicesCount }
    public var siteBadge: String { role }

    public init(
        id: String = UUID().uuidString,
        name: String,
        devicesCount: Int = 0,
        role: String = "Primary Site",
        emoji: String = "🏠",
        timezone: String = TimeZone.current.identifier,
        isSynced: Bool = false
    ) {
        self.id = id
        self.name = name
        self.devicesCount = devicesCount
        self.role = role
        self.emoji = emoji
        self.timezone = timezone
        self.isSynced = isSynced
    }
}

public struct NetworkInventoryBackup: Codable, Equatable {
    public var schemaVersion: Int
    public var exportedAtIso: String
    public var networkName: String
    public var flavor: String
    public var devices: [RackPortDevice]
    public var attestations: [DeviceAttestation]

    public init(
        schemaVersion: Int = 1,
        exportedAtIso: String,
        networkName: String,
        flavor: String,
        devices: [RackPortDevice],
        attestations: [DeviceAttestation] = []
    ) {
        self.schemaVersion = schemaVersion
        self.exportedAtIso = exportedAtIso
        self.networkName = networkName
        self.flavor = flavor
        self.devices = devices
        self.attestations = attestations
    }
}

public enum TrustZone: String, Codable, CaseIterable, Identifiable {
    case z0Core = "Z0"
    case z1Trusted = "Z1"
    case z2Lab = "Z2"
    case z3Iot = "Z3"
    case z4Guest = "Z4"

    public static let Z0_CORE: TrustZone = .z0Core
    public static let Z1_TRUSTED: TrustZone = .z1Trusted
    public static let Z2_LAB: TrustZone = .z2Lab
    public static let Z3_IOT: TrustZone = .z3Iot
    public static let Z4_GUEST: TrustZone = .z4Guest

    public var id: String { rawValue }
    public var key: String { rawValue }
    public var code: String { rawValue }

    public var displayTitle: String {
        switch self {
        case .z0Core: return "Z0 Core"
        case .z1Trusted: return "Z1 Trusted"
        case .z2Lab: return "Z2 Homelab"
        case .z3Iot: return "Z3 Smart Home"
        case .z4Guest: return "Z4 Guest"
        }
    }

    public var stnTitle: String {
        switch self {
        case .z0Core: return "Wi-Fi & Gear"
        case .z1Trusted: return "Main Home"
        case .z2Lab: return "Home Server"
        case .z3Iot: return "Smart Home"
        case .z4Guest: return "Guest Wi-Fi"
        }
    }

    public var stnLabel: String { stnTitle }

    public var vlanHint: String {
        switch self {
        case .z0Core: return "VLAN 1"
        case .z1Trusted: return "VLAN 10"
        case .z2Lab: return "VLAN 20"
        case .z3Iot: return "VLAN 30"
        case .z4Guest: return "VLAN 99"
        }
    }
}

public enum DeviceConfidenceTier: String, Codable {
    case confirmed = "CONFIRMED"
    case provisionalGuess = "PROVISIONAL_GUESS"
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
    public var networkId: String
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
    public var canonicalPurl: String?
    public var serialNumber: String?
    public var macAddress: String?
    public var upc: String?
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
    public var presenceState: DevicePresenceState
    public var decommissionDate: String?
    public var latestAttestation: DeviceAttestation?
    public var attestationCount: Int

    public init(
        id: String = UUID().uuidString,
        networkId: String = "net-default",
        portIndex: Int = 1,
        portState: PortLifecycleState,
        trustZone: TrustZone,
        category: StnHardwareCategory = .C6_IOT,
        assetTag: String = "",
        shortLabel: String,
        name: String,
        roomLocation: String = "",
        version: String = "",
        targetVersion: String? = nil,
        purchaseDate: String? = nil,
        vendorEolAt: String? = nil,
        candles: [DeviceLifecycleCandle] = [],
        lifecycleTier: String = "Active",
        purls: [String] = [],
        canonicalPurl: String? = nil,
        serialNumber: String? = nil,
        macAddress: String? = nil,
        upc: String? = nil,
        confidenceTier: DeviceConfidenceTier = .confirmed,
        candidateModels: [String] = [],
        excludedPurlPrefixes: [String] = [],
        proHeadline: String,
        stnHeadline: String,
        s0Identity: String = "",
        s1Hardware: String = "",
        s2Software: String = "",
        s3Lifecycle: String = "",
        s4Advisories: String = "",
        s5Topology: String = "",
        s6Remediation: String = "",
        presenceState: DevicePresenceState = .active,
        decommissionDate: String? = nil,
        latestAttestation: DeviceAttestation? = nil,
        attestationCount: Int = 0
    ) {
        self.id = id
        self.networkId = networkId
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
        self.canonicalPurl = canonicalPurl ?? purls.first
        self.serialNumber = serialNumber
        self.macAddress = macAddress
        self.upc = upc
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
        self.presenceState = presenceState
        self.decommissionDate = decommissionDate
        self.latestAttestation = latestAttestation
        self.attestationCount = attestationCount
    }

    private enum CodingKeys: String, CodingKey {
        case id, networkId, portIndex, portState, trustZone, category, assetTag, shortLabel, name,
             roomLocation, version, targetVersion, purchaseDate, vendorEolAt, candles, lifecycleTier,
             purls, canonicalPurl, serialNumber, macAddress, upc, confidenceTier, candidateModels,
             excludedPurlPrefixes, proHeadline, stnHeadline, s0Identity, s1Hardware, s2Software,
             s3Lifecycle, s4Advisories, s5Topology, s6Remediation, presenceState, decommissionDate,
             latestAttestation, attestationCount
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        networkId = try c.decodeIfPresent(String.self, forKey: .networkId) ?? "net-default"
        portIndex = try c.decodeIfPresent(Int.self, forKey: .portIndex) ?? 1
        portState = try c.decodeIfPresent(PortLifecycleState.self, forKey: .portState) ?? .ok
        trustZone = try c.decodeIfPresent(TrustZone.self, forKey: .trustZone) ?? .z1Trusted
        category = try c.decodeIfPresent(StnHardwareCategory.self, forKey: .category) ?? .C6_IOT
        assetTag = try c.decodeIfPresent(String.self, forKey: .assetTag) ?? ""
        shortLabel = try c.decode(String.self, forKey: .shortLabel)
        name = try c.decode(String.self, forKey: .name)
        roomLocation = try c.decodeIfPresent(String.self, forKey: .roomLocation) ?? ""
        version = try c.decodeIfPresent(String.self, forKey: .version) ?? ""
        targetVersion = try c.decodeIfPresent(String.self, forKey: .targetVersion)
        purchaseDate = try c.decodeIfPresent(String.self, forKey: .purchaseDate)
        vendorEolAt = try c.decodeIfPresent(String.self, forKey: .vendorEolAt)
        candles = try c.decodeIfPresent([DeviceLifecycleCandle].self, forKey: .candles) ?? []
        lifecycleTier = try c.decodeIfPresent(String.self, forKey: .lifecycleTier) ?? "Active"
        let decodedPurls = try c.decodeIfPresent([String].self, forKey: .purls) ?? []
        purls = decodedPurls
        canonicalPurl = try c.decodeIfPresent(String.self, forKey: .canonicalPurl) ?? decodedPurls.first
        serialNumber = try c.decodeIfPresent(String.self, forKey: .serialNumber)
        macAddress = try c.decodeIfPresent(String.self, forKey: .macAddress)
        upc = try c.decodeIfPresent(String.self, forKey: .upc)
        confidenceTier = try c.decodeIfPresent(DeviceConfidenceTier.self, forKey: .confidenceTier) ?? .confirmed
        candidateModels = try c.decodeIfPresent([String].self, forKey: .candidateModels) ?? []
        excludedPurlPrefixes = try c.decodeIfPresent([String].self, forKey: .excludedPurlPrefixes) ?? []
        proHeadline = try c.decodeIfPresent(String.self, forKey: .proHeadline) ?? ""
        stnHeadline = try c.decodeIfPresent(String.self, forKey: .stnHeadline) ?? ""
        s0Identity = try c.decodeIfPresent(String.self, forKey: .s0Identity) ?? ""
        s1Hardware = try c.decodeIfPresent(String.self, forKey: .s1Hardware) ?? ""
        s2Software = try c.decodeIfPresent(String.self, forKey: .s2Software) ?? ""
        s3Lifecycle = try c.decodeIfPresent(String.self, forKey: .s3Lifecycle) ?? ""
        s4Advisories = try c.decodeIfPresent(String.self, forKey: .s4Advisories) ?? ""
        s5Topology = try c.decodeIfPresent(String.self, forKey: .s5Topology) ?? ""
        s6Remediation = try c.decodeIfPresent(String.self, forKey: .s6Remediation) ?? ""
        presenceState = try c.decodeIfPresent(DevicePresenceState.self, forKey: .presenceState) ?? .active
        decommissionDate = try c.decodeIfPresent(String.self, forKey: .decommissionDate)
        latestAttestation = try c.decodeIfPresent(DeviceAttestation.self, forKey: .latestAttestation)
        attestationCount = try c.decodeIfPresent(Int.self, forKey: .attestationCount) ?? 0
    }
}

public struct LedSlot: Identifiable, Equatable {
    public let id: Int
    public let portIndex: Int
    public let state: PortLifecycleState
    public let device: RackPortDevice?

    public init(portIndex: Int, state: PortLifecycleState, device: RackPortDevice?) {
        self.id = portIndex
        self.portIndex = portIndex
        self.state = state
        self.device = device
    }
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
    public let sourceUrl: String?

    public init(
        externalId: String,
        canonicalFeedSlug: String,
        bulletinType: String,
        isHighSev: Bool,
        purlBase: String,
        proTitle: String,
        proBody: String,
        stnTitle: String,
        stnBody: String,
        aiProBullet: String,
        aiStnBullet: String,
        publishedAt: String,
        sourceUrl: String? = nil
    ) {
        self.externalId = externalId
        self.canonicalFeedSlug = canonicalFeedSlug
        self.bulletinType = bulletinType
        self.isHighSev = isHighSev
        self.purlBase = purlBase
        self.proTitle = proTitle
        self.proBody = proBody
        self.stnTitle = stnTitle
        self.stnBody = stnBody
        self.aiProBullet = aiProBullet
        self.aiStnBullet = aiStnBullet
        self.publishedAt = publishedAt
        self.sourceUrl = sourceUrl
    }
}

public struct MatchedFeedView: Identifiable, Equatable {
    public let id: String
    public let slug: String
    public let name: String
    public let matchMode: DeviceConfidenceTier
    public let matchedPorts: [String]
    public let candidateModels: [String]
    public let isMuted: Bool

    public init(
        id: String,
        slug: String,
        name: String,
        matchMode: DeviceConfidenceTier,
        matchedPorts: [String],
        candidateModels: [String],
        isMuted: Bool
    ) {
        self.id = id
        self.slug = slug
        self.name = name
        self.matchMode = matchMode
        self.matchedPorts = matchedPorts
        self.candidateModels = candidateModels
        self.isMuted = isMuted
    }
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
    public let sourceUrl: String?
    public let affectedDeviceIds: [String]

    public init(
        externalId: String,
        feedSlug: String,
        bulletinType: String,
        isHighSev: Bool,
        brokeThroughMute: Bool,
        matchedByGuess: Bool,
        candidateModels: [String],
        title: String,
        body: String,
        publishedAt: String,
        sourceUrl: String? = nil,
        affectedDeviceIds: [String] = []
    ) {
        self.externalId = externalId
        self.feedSlug = feedSlug
        self.bulletinType = bulletinType
        self.isHighSev = isHighSev
        self.brokeThroughMute = brokeThroughMute
        self.matchedByGuess = matchedByGuess
        self.candidateModels = candidateModels
        self.title = title
        self.body = body
        self.publishedAt = publishedAt
        self.sourceUrl = sourceUrl
        self.affectedDeviceIds = affectedDeviceIds
    }
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
    public let completedBulletins: [BulletinInboxView]

    public init(
        activeFeedCount: Int,
        mutedFeedCount: Int,
        provisionalFeedCount: Int,
        mutedHighSevOverrideCount: Int,
        provisionalHighSevCount: Int,
        aiBullets: [String],
        matchedFeeds: [MatchedFeedView],
        inbox: [BulletinInboxView],
        completedBulletins: [BulletinInboxView] = []
    ) {
        self.activeFeedCount = activeFeedCount
        self.mutedFeedCount = mutedFeedCount
        self.provisionalFeedCount = provisionalHighSevCount > 0 || provisionalFeedCount >= 0 ? provisionalFeedCount : 0
        self.mutedHighSevOverrideCount = mutedHighSevOverrideCount
        self.provisionalHighSevCount = provisionalHighSevCount
        self.aiBullets = aiBullets
        self.matchedFeeds = matchedFeeds
        self.inbox = inbox
        self.completedBulletins = completedBulletins
    }
}

public enum BulletinsAndInventoryEngine {
    /// Deterministic category-spine (C1 -> C8, then alphabetical) matrix layout with 128 visual LED slots.
    /// Avoids phantom physical switch port numbers while keeping fixed spatial stability across states.
    public static func build128LedMatrix(
        devices: [RackPortDevice],
        zoneFilter: TrustZone? = nil
    ) -> [LedSlot] {
        let filtered = zoneFilter == nil ? devices : devices.filter { $0.trustZone == zoneFilter }
        let sortedByCategory = filtered.sorted { lhs, rhs in
            if lhs.category.ordinal != rhs.category.ordinal {
                return lhs.category.ordinal < rhs.category.ordinal
            }
            let cmp = lhs.name.localizedCaseInsensitiveCompare(rhs.name)
            if cmp != .orderedSame {
                return cmp == .orderedAscending
            }
            return lhs.id < rhs.id
        }

        return (1...128).map { slotIdx in
            let idx = slotIdx - 1
            if idx < sortedByCategory.count {
                let dev = sortedByCategory[idx]
                return LedSlot(portIndex: slotIdx, state: dev.portState, device: dev)
            } else {
                return LedSlot(portIndex: slotIdx, state: .unassigned, device: nil)
            }
        }
    }

    public static func filterActionFirstDevices(
        devices: [RackPortDevice],
        includeOk: Bool = false,
        zoneFilter: TrustZone? = nil,
        portStateFilter: PortLifecycleState? = nil
    ) -> [RackPortDevice] {
        devices.filter { dev in
            if let zone = zoneFilter, dev.trustZone != zone {
                return false
            }
            if let stateFilter = portStateFilter {
                return dev.portState == stateFilter
            }
            return includeOk || dev.portState.isAttentionRequired
        }.sorted { lhs, rhs in
            if lhs.portState.severityPriority != rhs.portState.severityPriority {
                return lhs.portState.severityPriority < rhs.portState.severityPriority
            }
            return lhs.category.ordinal < rhs.category.ordinal
        }
    }

    public static func deviceMatchesBulletin(_ device: RackPortDevice, _ bulletin: CuratedBulletinItem) -> Bool {
        let isExcluded = device.excludedPurlPrefixes.contains { ex in
            let cleanEx = ex.replacingOccurrences(of: "/*", with: "")
            return bulletin.purlBase.hasPrefix(cleanEx)
        }
        guard !isExcluded else { return false }

        return device.purls.contains { dp in
            let cleanDp = dp.components(separatedBy: "@").first?
                .replacingOccurrences(of: "/*", with: "") ?? dp
            return bulletin.purlBase.hasPrefix(cleanDp) || cleanDp.hasPrefix(bulletin.purlBase)
        }
    }

    public static func findBulletinsForDevice(
        _ device: RackPortDevice,
        bulletins: [CuratedBulletinItem] = defaultGoldBulletins()
    ) -> [CuratedBulletinItem] {
        bulletins.filter { deviceMatchesBulletin(device, $0) }
            .sorted { lhs, rhs in
                if lhs.isHighSev != rhs.isHighSev {
                    return lhs.isHighSev && !rhs.isHighSev
                }
                return lhs.externalId < rhs.externalId
            }
    }

    public static func findTopBulletinForDevice(
        _ device: RackPortDevice,
        bulletins: [CuratedBulletinItem] = defaultGoldBulletins()
    ) -> CuratedBulletinItem? {
        findBulletinsForDevice(device, bulletins: bulletins).first
    }

    public static func countBulletinsForDevice(
        _ device: RackPortDevice,
        bulletins: [CuratedBulletinItem] = defaultGoldBulletins()
    ) -> Int {
        findBulletinsForDevice(device, bulletins: bulletins).count
    }

    public static func inferInitialPortStateForPurls(
        _ purls: [String],
        defaultBulletins: [CuratedBulletinItem] = defaultGoldBulletins()
    ) -> PortLifecycleState {
        let matched = defaultBulletins.filter { bulletin in
            purls.contains { purl in
                let clean = purl.components(separatedBy: "@").first?
                    .replacingOccurrences(of: "/*", with: "") ?? purl
                return bulletin.purlBase.hasPrefix(clean) || clean.hasPrefix(bulletin.purlBase)
            }
        }
        if matched.contains(where: {
            let t = $0.bulletinType.lowercased()
            return t == "cve" || t == "cisa_kev" || t == "recall"
        }) {
            return .cveKev
        }
        if matched.contains(where: { $0.bulletinType.lowercased() == "eol" }) {
            return .eol
        }
        if matched.contains(where: { $0.bulletinType.lowercased() == "release" || $0.bulletinType.lowercased() == "advisory" }) {
            return .update
        }
        return .ok
    }

    public static func assembleBulletins(
        flavor: AppBrandFlavor,
        devices: [RackPortDevice],
        mutedFeedSlugs: Set<String>,
        completedBulletinIds: Set<String> = []
    ) -> AssembledBulletinsPayload {
        assembleBulletins(
            devices: devices,
            feeds: defaultGoldFeeds(),
            bulletins: defaultGoldBulletins(),
            mutedFeedSlugs: mutedFeedSlugs,
            completedBulletinIds: completedBulletinIds,
            isStn: flavor == .sureThingHome
        )
    }

    public static func assembleBulletins(
        devices: [RackPortDevice],
        feeds: [CanonicalFeedItem],
        bulletins: [CuratedBulletinItem],
        mutedFeedSlugs: Set<String>,
        completedBulletinIds: Set<String> = [],
        isStn: Bool = false
    ) -> AssembledBulletinsPayload {
        var deviceFeedLinks: [String: [RackPortDevice]] = [:]

        for dev in devices {
            for feed in feeds {
                let matches = dev.purls.contains { dp in
                    let baseDp = dp.components(separatedBy: "@").first?.replacingOccurrences(of: "/*", with: "") ?? dp
                    return feed.purlPrefixes.contains { prefix in
                        let cleanPrefix = prefix.replacingOccurrences(of: "/*", with: "")
                        return baseDp.hasPrefix(cleanPrefix) || cleanPrefix.hasPrefix(baseDp)
                    }
                }
                if matches {
                    deviceFeedLinks[feed.slug, default: []].append(dev)
                }
            }
        }

        let matchedFeeds = feeds.filter { !(deviceFeedLinks[$0.slug]?.isEmpty ?? true) }
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
                matchedPorts: linkedDevs.map { $0.shortLabel },
                candidateModels: candidates,
                isMuted: mutedFeedSlugs.contains(feed.slug)
            )
        }

        let relevantBulletins = bulletins.filter { b in
            guard let linkedDevs = deviceFeedLinks[b.canonicalFeedSlug] else { return false }
            return linkedDevs.contains { deviceMatchesBulletin($0, b) }
        }

        let unmutedConfirmedActive = relevantBulletins.filter { b in
            !completedBulletinIds.contains(b.externalId) &&
            !mutedFeedSlugs.contains(b.canonicalFeedSlug) &&
            !provisionalOnlySlugs.contains(b.canonicalFeedSlug)
        }

        let mutedHighSevCount = relevantBulletins.filter {
            !completedBulletinIds.contains($0.externalId) &&
            mutedFeedSlugs.contains($0.canonicalFeedSlug) &&
            $0.isHighSev
        }.count

        let provisionalHighSevCount = relevantBulletins.filter {
            !completedBulletinIds.contains($0.externalId) &&
            provisionalOnlySlugs.contains($0.canonicalFeedSlug) &&
            $0.isHighSev
        }.count

        let aiBullets = unmutedConfirmedActive.map { isStn ? $0.aiStnBullet : $0.aiProBullet }

        func toInboxView(_ b: CuratedBulletinItem) -> BulletinInboxView {
            let fromMuted = mutedFeedSlugs.contains(b.canonicalFeedSlug)
            let fromProvisional = provisionalOnlySlugs.contains(b.canonicalFeedSlug)
            let linkedDevs = (deviceFeedLinks[b.canonicalFeedSlug] ?? []).filter { deviceMatchesBulletin($0, b) }
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
                publishedAt: b.publishedAt,
                sourceUrl: b.sourceUrl,
                affectedDeviceIds: linkedDevs.map(\.id)
            )
        }

        let inboxItems = relevantBulletins.filter { b in
            guard !completedBulletinIds.contains(b.externalId) else { return false }
            let isMuted = mutedFeedSlugs.contains(b.canonicalFeedSlug)
            let isProvisional = provisionalOnlySlugs.contains(b.canonicalFeedSlug)
            return (!isMuted && !isProvisional) || b.isHighSev
        }.map(toInboxView)

        let completedItems = relevantBulletins.filter { completedBulletinIds.contains($0.externalId) }
            .map(toInboxView)

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
            inbox: inboxItems,
            completedBulletins: completedItems
        )
    }

    public static func sortDevicesForTimeline(_ devices: [RackPortDevice]) -> [RackPortDevice] {
        return devices.sorted { a, b in
            if a.category.ordinal != b.category.ordinal {
                return a.category.ordinal < b.category.ordinal
            }
            if a.portState.severityPriority != b.portState.severityPriority {
                return a.portState.severityPriority < b.portState.severityPriority
            }
            return a.shortLabel.localizedCaseInsensitiveCompare(b.shortLabel) == .orderedAscending
        }
    }

    public static func sortDevicesByRecentChanges(_ devices: [RackPortDevice]) -> [RackPortDevice] {
        return devices.sorted { a, b in
            let aEnded = a.candles.last?.ended ?? 0.0
            let bEnded = b.candles.last?.ended ?? 0.0
            if aEnded != bEnded { return aEnded > bEnded }
            return a.portState.severityPriority < b.portState.severityPriority
        }
    }

    public static func getEstimatedVersionAtCursor(
        device: RackPortDevice,
        scrubNorm: Double?
    ) -> String {
        guard let cursor = scrubNorm else {
            return device.version
        }
        let earliestRelease = device.candles.map(\.released).min() ?? 0.0
        if cursor < earliestRelease {
            return "Not Yet Released"
        }
        var resolved = device.candles.first?.ver ?? device.version
        for candle in device.candles where cursor >= candle.released {
            resolved = candle.ver
        }
        if device.confidenceTier == .provisionalGuess {
            return "\(resolved) (Unverified)"
        }
        return resolved
    }

    public static func getEstimatedVersionAtCursor(_ device: RackPortDevice, cursorNorm: Double) -> String? {
        getEstimatedVersionAtCursor(device: device, scrubNorm: cursorNorm)
    }

    public static func toOperationalCandle(
        _ device: RackPortDevice,
        attestations: [DeviceAttestation] = [],
        referenceNowNorm: Double = 0.72
    ) -> OperationalCandle {
        let firstCandle = device.candles.first
        let lastCandle = device.candles.last
        let releaseNorm = firstCandle?.released ?? 0.10
        let deployStart = lastCandle?.attested ?? firstCandle?.attested ?? 0.40
        let eolNorm = lastCandle?.eol ?? (device.portState == .eol ? 0.62 : 0.95)
        let isOutOfService = device.presenceState.isOutOfService
        let deployEnd = isOutOfService
            ? min(lastCandle?.ended ?? 0.58, eolNorm + 0.05)
            : referenceNowNorm
        let isPastEol = device.portState == .eol || deployEnd > eolNorm
        let isEolNearing = !isPastEol && (eolNorm - deployEnd) < 0.12
        let devAtts = attestations.filter { $0.deviceId == device.id }
        let latestAtt = device.latestAttestation ?? devAtts.sorted(by: { $0.auditDate > $1.auditDate }).first
        return OperationalCandle(
            id: device.id,
            shortLabel: device.shortLabel,
            name: device.name,
            version: device.version,
            trustZone: device.trustZone,
            presenceState: device.presenceState,
            hasCveOrRecall: device.portState == .cveKev || (lastCandle?.cveStart != nil),
            isPastEol: isPastEol,
            isEolNearing: isEolNearing,
            isGuessed: device.portState == .guessed || device.confidenceTier == .provisionalGuess,
            isRetired: isOutOfService,
            marketReleaseNorm: releaseNorm,
            deployStartNorm: deployStart,
            deployEndNorm: deployEnd,
            vendorEolNorm: eolNorm,
            cveStartNorm: lastCandle?.cveStart,
            releaseLabel: device.purchaseDate ?? "2024-01-01",
            eolLabel: device.vendorEolAt ?? "Supported",
            latestAttestation: latestAtt,
            attestationCount: max(device.attestationCount, devAtts.count),
            releaseDateStr: device.purchaseDate,
            deployDateStr: device.purchaseDate,
            eolDateStr: device.vendorEolAt
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
                assetTag: "",
                shortLabel: "UDM-Pro",
                name: "UniFi Dream Machine Pro",
                roomLocation: "Basement Closet",
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
                proHeadline: "CVE-2026-50881 (0-Day): Disable Direct Remote Connection",
                stnHeadline: "Safety Workaround: Turn off Direct Remote Connection in UniFi settings",
                s0Identity: "Basement Closet • Z0 Core",
                s1Hardware: "Ubiquiti UDM-Pro • purchased 2024-02 (48 mo remaining)",
                s2Software: "pkg:generic/ui/unifi-os@4.0.20 (Latest)",
                s3Lifecycle: "Active Support • Zero-Day Workaround Required",
                s4Advisories: "CVE-2026-50881 (CVSS 8.2, EPSS 0.34) • Unpatched 0-day",
                s5Topology: "Z0 Core Gateway • WAN + 8 GbE LAN + 2 10G SFP+",
                s6Remediation: "Disable Direct Remote Connection until UniFi OS 4.0.21 ships."
            ),
            RackPortDevice(
                id: "0192d9f0-0005-7000-8000-000000000105",
                portIndex: 2,
                portState: .eol,
                trustZone: .z0Core,
                category: .C3_AP,
                assetTag: "",
                shortLabel: "R7000 AP",
                name: "Netgear Nighthawk R7000",
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
                proHeadline: "CISA BOD 23-01 • Vendor EOL (2025-12-31) • Decommission",
                stnHeadline: "Retired Hardware (9.5 yrs): Replace with a supported Wi-Fi AP",
                s0Identity: "Basement Workbench • Z0 Core",
                s1Hardware: "Netgear Nighthawk R7000 • PAST EOL 2025-12-31",
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
                assetTag: "",
                shortLabel: "U7-Pro",
                name: "Living Room UniFi U7 Pro",
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
                proHeadline: "pkg:generic/ui/u7-pro@7.0.66 • 0 CVEs • Lifecycle Active (54 mo)",
                stnHeadline: "Up to date (7.0.66) • 4.5 years of manufacturer support remaining",
                s0Identity: "1F Living Room • Z0 Core",
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
                trustZone: .z0Core,
                category: .C2_SWITCH,
                assetTag: "",
                shortLabel: "USW-24-PoE",
                name: "UniFi Pro 24 PoE Switch",
                roomLocation: "Basement Closet",
                version: "7.1.26",
                targetVersion: "7.1.26",
                purchaseDate: "2024-06-15",
                vendorEolAt: "2031-06-15",
                candles: [
                    DeviceLifecycleCandle(ver: "7.0.50", released: 0.15, attested: 0.25, ended: 0.68, eol: 0.90, cveStart: nil),
                    DeviceLifecycleCandle(ver: "7.1.26", released: 0.64, attested: 0.68, ended: 0.96, eol: 0.99, cveStart: nil)
                ],
                lifecycleTier: "Active",
                purls: ["pkg:generic/ui/usw-pro-24-poe@7.1.26"],
                confidenceTier: .confirmed,
                proHeadline: "7.1.26 • 0 CVEs • PoE Load 84W / 400W",
                stnHeadline: "Up to date (7.1.26) • Powered Ethernet hub healthy",
                s0Identity: "Basement Closet • Z0 Core",
                s1Hardware: "Ubiquiti USW-Pro-24-PoE • Layer 3 Switch",
                s2Software: "pkg:generic/ui/usw-pro-24-poe@7.1.26",
                s3Lifecycle: "Active Support (60 mo remaining)",
                s4Advisories: "0 Active CVEs / KEVs",
                s5Topology: "Z0 Core Distribution Switch",
                s6Remediation: "No action required."
            ),
            RackPortDevice(
                id: "0192d9f0-0001-7000-8000-000000000101",
                portIndex: 5,
                portState: .update,
                trustZone: .z1Trusted,
                category: .C7_CLIENT,
                assetTag: "",
                shortLabel: "MacBook Pro",
                name: "Aaron's MacBook Pro M4",
                roomLocation: "Home Office",
                version: "15.3.1",
                targetVersion: "15.3.2",
                purchaseDate: "2024-11-01",
                vendorEolAt: "2031-11-01",
                candles: [
                    DeviceLifecycleCandle(ver: "15.2.0", released: 0.12, attested: 0.16, ended: 0.50, eol: 0.85, cveStart: nil),
                    DeviceLifecycleCandle(ver: "15.3.1", released: 0.45, attested: 0.50, ended: 0.72, eol: 0.99, cveStart: nil)
                ],
                lifecycleTier: "Active",
                purls: ["pkg:generic/apple/macos@15.3.1"],
                confidenceTier: .confirmed,
                proHeadline: "macOS 15.3.2 & Homebrew openssl 3.4.1 updates available",
                stnHeadline: "Software Update Ready: macOS 15.3.2 waiting in System Settings",
                s0Identity: "Home Office • Z1 Trusted",
                s1Hardware: "Apple MacBook Pro M4 (14-inch, 2024)",
                s2Software: "pkg:generic/apple/macos@15.3.1 -> 15.3.2",
                s3Lifecycle: "Active Support (62 mo remaining)",
                s4Advisories: "Routine Security & Bugfix Release 15.3.2",
                s5Topology: "Z1 Trusted Workstation",
                s6Remediation: "Run System Settings -> Software Update -> Update Now."
            ),
            RackPortDevice(
                id: "0192d9f0-0002-7000-8000-000000000102",
                portIndex: 6,
                portState: .ok,
                trustZone: .z1Trusted,
                category: .C7_CLIENT,
                assetTag: "",
                shortLabel: "ThinkPad X1",
                name: "Ubuntu Dev ThinkPad",
                roomLocation: "Home Office",
                version: "24.04.2 LTS",
                targetVersion: "24.04.2 LTS",
                purchaseDate: "2024-04-01",
                vendorEolAt: "2029-04-01",
                candles: [
                    DeviceLifecycleCandle(ver: "24.04.1", released: 0.10, attested: 0.18, ended: 0.62, eol: 0.90, cveStart: nil),
                    DeviceLifecycleCandle(ver: "24.04.2", released: 0.58, attested: 0.62, ended: 0.96, eol: 0.99, cveStart: nil)
                ],
                lifecycleTier: "Active",
                purls: ["pkg:deb/ubuntu/ubuntu-desktop@24.04"],
                confidenceTier: .confirmed,
                proHeadline: "Ubuntu 24.04.2 LTS • Unattended upgrades healthy",
                stnHeadline: "Up to date (Ubuntu 24.04.2) • Automatic security updates active",
                s0Identity: "Home Office • Z1 Trusted",
                s1Hardware: "Lenovo ThinkPad X1 Carbon",
                s2Software: "pkg:deb/ubuntu/ubuntu-desktop@24.04",
                s3Lifecycle: "Active LTS Support through 2029",
                s4Advisories: "0 Active CVEs",
                s5Topology: "Z1 Trusted Workstation",
                s6Remediation: "No action required."
            ),
            RackPortDevice(
                id: "0192d9f0-0007-7000-8000-000000000107",
                portIndex: 7,
                portState: .ok,
                trustZone: .z2Lab,
                category: .C4_SERVER,
                assetTag: "",
                shortLabel: "TrueNAS",
                name: "TrueNAS SCALE Vault",
                roomLocation: "Basement Closet",
                version: "24.10.2",
                targetVersion: "24.10.2",
                purchaseDate: "2024-01-15",
                vendorEolAt: "2029-01-15",
                candles: [
                    DeviceLifecycleCandle(ver: "24.04.2", released: 0.12, attested: 0.20, ended: 0.55, eol: 0.85, cveStart: nil),
                    DeviceLifecycleCandle(ver: "24.10.2", released: 0.50, attested: 0.55, ended: 0.96, eol: 0.99, cveStart: nil)
                ],
                lifecycleTier: "Active",
                purls: ["pkg:generic/ixsystems/truenas-scale@24.10.2"],
                confidenceTier: .confirmed,
                proHeadline: "ZFS Pool Healthy • TrueNAS SCALE 24.10.2 current",
                stnHeadline: "Up to date (24.10.2) • Family backup vault healthy",
                s0Identity: "Basement Closet • Z2 Homelab",
                s1Hardware: "TrueNAS SCALE Electric Eel",
                s2Software: "pkg:generic/ixsystems/truenas-scale@24.10.2",
                s3Lifecycle: "Active Support",
                s4Advisories: "0 Active CVEs",
                s5Topology: "Z2 Homelab Storage NAS",
                s6Remediation: "No action required."
            ),
            RackPortDevice(
                id: "0192d9f0-0006-7000-8000-000000000106",
                portIndex: 8,
                portState: .update,
                trustZone: .z2Lab,
                category: .C4_SERVER,
                assetTag: "",
                shortLabel: "pve-node-01",
                name: "Proxmox VE Compute Host",
                roomLocation: "Basement Closet",
                version: "8.3.1",
                targetVersion: "8.3.2",
                purchaseDate: "2023-08-01",
                vendorEolAt: "2028-08-01",
                candles: [
                    DeviceLifecycleCandle(ver: "8.2.2", released: 0.10, attested: 0.22, ended: 0.56, eol: 0.80, cveStart: nil),
                    DeviceLifecycleCandle(ver: "8.3.1", released: 0.52, attested: 0.56, ended: 0.72, eol: 0.96, cveStart: nil)
                ],
                lifecycleTier: "Active",
                purls: ["pkg:generic/proxmox/pve-manager@8.3.1"],
                confidenceTier: .confirmed,
                proHeadline: "Proxmox VE 8.3.2 + Kernel 6.8.12-8 update queued",
                stnHeadline: "Home Server Update Ready: Proxmox VE 8.3.2 ready to install",
                s0Identity: "Basement Closet • Z2 Homelab",
                s1Hardware: "Minisforum MS-01 • Proxmox VE Host",
                s2Software: "pkg:generic/proxmox/pve-manager@8.3.1 -> 8.3.2",
                s3Lifecycle: "Active Support",
                s4Advisories: "Routine Kernel & QEMU Maintenance Release 8.3.2",
                s5Topology: "Z2 Homelab Compute Hypervisor",
                s6Remediation: "Run apt update && apt full-upgrade via Proxmox Web UI."
            ),
            RackPortDevice(
                id: "0192d9f0-0003-7000-8000-000000000103",
                portIndex: 9,
                portState: .ok,
                trustZone: .z3Iot,
                category: .C5_CAMERA,
                assetTag: "",
                shortLabel: "G5 Bullet",
                name: "Front Porch UniFi G5 Bullet",
                roomLocation: "Front Porch",
                version: "4.73.71",
                targetVersion: "4.73.71",
                purchaseDate: "2024-09-01",
                vendorEolAt: "2030-09-01",
                candles: [
                    DeviceLifecycleCandle(ver: "4.73.71", released: 0.30, attested: 0.38, ended: 0.96, eol: 0.99, cveStart: nil)
                ],
                lifecycleTier: "Active",
                purls: ["pkg:generic/ui/unifi-protect-camera@4.73.71"],
                confidenceTier: .confirmed,
                proHeadline: "Protect 4.73.71 • Local RTSP isolated in Z3",
                stnHeadline: "Up to date (4.73.71) • Porch camera stream protected",
                s0Identity: "Front Porch • Z3 Smart Home",
                s1Hardware: "Ubiquiti UniFi G5 Bullet PoE Camera",
                s2Software: "pkg:generic/ui/unifi-protect-camera@4.73.71",
                s3Lifecycle: "Active Support",
                s4Advisories: "0 Active CVEs",
                s5Topology: "Z3 Isolated IoT Camera",
                s6Remediation: "No action required."
            ),
            RackPortDevice(
                id: "0192d9f0-000a-7000-8000-00000000010a",
                portIndex: 10,
                portState: .cveKev,
                trustZone: .z3Iot,
                category: .C8_GUEST,
                assetTag: "",
                shortLabel: "LG OLED TV",
                name: "Living Room LG C3 OLED TV",
                roomLocation: "1F Living Room",
                version: "8.1.0",
                targetVersion: "8.3.0",
                purchaseDate: "2023-11-24",
                vendorEolAt: "2028-11-24",
                candles: [
                    DeviceLifecycleCandle(ver: "8.1.0", released: 0.25, attested: 0.35, ended: 0.72, eol: 0.90, cveStart: 0.66)
                ],
                lifecycleTier: "Active",
                purls: ["pkg:generic/lg/webos@8.1.0"],
                confidenceTier: .confirmed,
                proHeadline: "CVE-2026-21099 (CISA KEV): webOS 8.3.0 Patch Available",
                stnHeadline: "Critical TV Update: Install LG software update 8.3.0 to stay safe",
                s0Identity: "1F Living Room • Z3 Smart Home",
                s1Hardware: "LG C3 65-inch OLED Smart TV",
                s2Software: "pkg:generic/lg/webos@8.1.0 -> 8.3.0",
                s3Lifecycle: "Active Support • Security Patch Available",
                s4Advisories: "CVE-2026-21099 (CISA KEV) LAN Authentication Bypass",
                s5Topology: "Z3 / Z4 Media Display",
                s6Remediation: "Open LG Settings -> Support -> Software Update and install 8.3.0."
            ),
            RackPortDevice(
                id: "0192d9f0-000b-7000-8000-00000000010b",
                portIndex: 11,
                portState: .update,
                trustZone: .z3Iot,
                category: .C6_IOT,
                assetTag: "",
                shortLabel: "Garage Relay",
                name: "Garage Door Relay ESP32",
                roomLocation: "Garage",
                version: "2026.9.0",
                targetVersion: "2026.10.2",
                purchaseDate: "2025-01-10",
                vendorEolAt: "2030-01-10",
                candles: [
                    DeviceLifecycleCandle(ver: "2026.9.0", released: 0.40, attested: 0.46, ended: 0.72, eol: 0.99, cveStart: nil)
                ],
                lifecycleTier: "Active",
                purls: ["pkg:generic/esphome/firmware@2026.9.0"],
                confidenceTier: .confirmed,
                proHeadline: "ESPHome 2026.10.2 available (Wi-Fi stability update)",
                stnHeadline: "Smart Home Update Ready: ESPHome 2026.10.2 available",
                s0Identity: "Garage • Z3 Smart Home",
                s1Hardware: "ratgdo ESP32 Smart Garage Controller",
                s2Software: "pkg:generic/esphome/firmware@2026.9.0 -> 2026.10.2",
                s3Lifecycle: "Active Community & Vendor Support",
                s4Advisories: "Minor Wi-Fi reconnect fix in 2026.10.2",
                s5Topology: "Z3 Smart Home • Local ESPHome API",
                s6Remediation: "Update wirelessly via Home Assistant ESPHome Dashboard."
            ),
            RackPortDevice(
                id: "0192d9f0-000c-7000-8000-00000000010c",
                portIndex: 12,
                portState: .guessed,
                trustZone: .z3Iot,
                category: .C6_IOT,
                assetTag: "",
                shortLabel: "Hall Ecobee",
                name: "Hallway Smart Thermostat",
                roomLocation: "1F Hallway",
                version: "4.8.7.100",
                targetVersion: "4.8.7.220",
                purchaseDate: "2022-05-01",
                vendorEolAt: "2029-05-01",
                candles: [
                    DeviceLifecycleCandle(ver: "4.8.7.100", released: 0.20, attested: 0.30, ended: 0.72, eol: 0.94, cveStart: nil)
                ],
                lifecycleTier: "Active",
                purls: ["pkg:generic/ecobee/smart-thermostat@4.8.7.100"],
                confidenceTier: .provisionalGuess,
                candidateModels: [
                    "Ecobee SmartThermostat Premium",
                    "Ecobee SmartThermostat Enhanced"
                ],
                excludedPurlPrefixes: [],
                proHeadline: "Guessed via OUI 44:61:32 (72%) • CVE-2026-88901 may apply",
                stnHeadline: "Confirm Exact Model: Let us verify whether CVE-2026-88901 applies",
                s0Identity: "1F Hallway • Z3 Smart Home",
                s1Hardware: "Ecobee Thermostat (OUI 44:61:32 provisional match)",
                s2Software: "pkg:generic/ecobee/smart-thermostat/*",
                s3Lifecycle: "Provisional Identification — Confirm SKU",
                s4Advisories: "Potential CVE-2026-88901 HomeKit Local Pairing Bypass",
                s5Topology: "Z3 Smart Home • Wi-Fi 2.4 GHz",
                s6Remediation: "Confirm exact Ecobee SKU on Bulletins tab or scan box barcode."
            )
        ]
    }

    public static func defaultGoldFeeds() -> [CanonicalFeedItem] {
        return [
            CanonicalFeedItem(
                id: "feed-ui",
                slug: "ubiquiti-advisories",
                proName: "Ubiquiti Security Advisories (UniFi OS)",
                stnName: "Ubiquiti Router & Wi-Fi Updates",
                purlPrefixes: ["pkg:generic/ui/unifi-os", "pkg:generic/ui/u7-pro", "pkg:generic/ui/usw-pro-24-poe"]
            ),
            CanonicalFeedItem(
                id: "feed-eol",
                slug: "vendor-eol-ledger",
                proName: "Hardware End-of-Life & CISA BOD 23-01 Ledger",
                stnName: "Older Device Support Alerts",
                purlPrefixes: ["pkg:generic/netgear/r7000"]
            ),
            CanonicalFeedItem(
                id: "feed-lg-esphome",
                slug: "lg-esphome-iot",
                proName: "LG webOS & ESPHome IoT Bulletin Stream",
                stnName: "Smart TV & Smart Home Alerts",
                purlPrefixes: ["pkg:generic/lg/webos", "pkg:generic/esphome/firmware"]
            ),
            CanonicalFeedItem(
                id: "feed-apple-pve",
                slug: "apple-proxmox-upstream",
                proName: "Apple macOS & Proxmox VE Release Stream",
                stnName: "Mac & Home Server Updates",
                purlPrefixes: ["pkg:generic/apple/macos", "pkg:generic/proxmox/pve-manager"]
            ),
            CanonicalFeedItem(
                id: "feed-ecobee",
                slug: "ecobee-umbrella",
                proName: "Ecobee SmartThermostat Product Family",
                stnName: "Hallway Thermostat Advisories",
                purlPrefixes: ["pkg:generic/ecobee/smart-thermostat"]
            )
        ]
    }

    public static func defaultGoldBulletins() -> [CuratedBulletinItem] {
        return [
            CuratedBulletinItem(
                externalId: "CVE-2026-88901",
                canonicalFeedSlug: "ecobee-umbrella",
                bulletinType: "cve",
                isHighSev: true,
                purlBase: "pkg:generic/ecobee/smart-thermostat",
                proTitle: "CVE-2026-88901: Ecobee HomeKit Local Pairing PIN Bypass",
                proBody: "High-severity LAN pairing bypass affecting Ecobee SmartThermostat family. Matched via OUI 44:61:32 (72% confidence) — confirm exact SKU to verify exposure.",
                stnTitle: "Possible Security Update: Hallway Smart Thermostat",
                stnBody: "We think your hallway thermostat is an Ecobee model. Confirm your exact model to verify if this security advisory applies to your home.",
                aiProBullet: "1 Provisional Ecobee CVE (Hallway Smart Thermostat): Confirm exact SKU.",
                aiStnBullet: "Thermostat Security Check: Confirm your hallway Ecobee model.",
                publishedAt: "3h ago",
                sourceUrl: "https://nvd.nist.gov/vuln/detail/CVE-2026-88901"
            ),
            CuratedBulletinItem(
                externalId: "CVE-2026-21099",
                canonicalFeedSlug: "lg-esphome-iot",
                bulletinType: "cisa_kev",
                isHighSev: true,
                purlBase: "pkg:generic/lg/webos",
                proTitle: "CVE-2026-21099 (CISA KEV): LG webOS LAN Auth Bypass",
                proBody: "Active exploitation reported in CISA KEV catalog affecting webOS < 8.3.0. Living Room LG C3 OLED is running 8.1.0; patch 8.3.0 is available upstream.",
                stnTitle: "Critical Security Fix Needed: Living Room LG OLED TV",
                stnBody: "A critical security flaw affects LG TVs running version 8.1.0. Open Settings -> Support on your TV to install software update 8.3.0.",
                aiProBullet: "1 CISA KEV Exploit (LG webOS 8.1.0): Update TV to webOS 8.3.0.",
                aiStnBullet: "Critical TV Update (Living Room LG TV): Install software update 8.3.0.",
                publishedAt: "5h ago",
                sourceUrl: "https://www.cisa.gov/known-exploited-vulnerabilities-catalog"
            ),
            CuratedBulletinItem(
                externalId: "CVE-2026-50881",
                canonicalFeedSlug: "ubiquiti-advisories",
                bulletinType: "cve",
                isHighSev: true,
                purlBase: "pkg:generic/ui/unifi-os",
                proTitle: "CVE-2026-50881: UniFi OS 4.0.20 Remote Management Advisory",
                proBody: "0-day advisory affecting unifi-os@4.0.20 on your UniFi Dream Machine Pro. Workaround: disable Direct Remote Connection until 4.0.21 ships.",
                stnTitle: "Security Workaround: UniFi Dream Machine Pro",
                stnBody: "Your router is on the newest version (4.0.20), but Ubiquiti recommends turning off Direct Remote Connection until version 4.0.21 arrives.",
                aiProBullet: "1 Zero-Day Workaround (UniFi UDM-Pro): Disable Direct Remote Connection.",
                aiStnBullet: "Router Safety Tip (UniFi Gateway): Turn off Direct Remote Connection.",
                publishedAt: "9h ago",
                sourceUrl: "https://community.ui.com/releases"
            ),
            CuratedBulletinItem(
                externalId: "EOL-netgear-r7000",
                canonicalFeedSlug: "vendor-eol-ledger",
                bulletinType: "eol",
                isHighSev: true,
                purlBase: "pkg:generic/netgear/r7000",
                proTitle: "CISA BOD 23-01 / Netgear EOL: R7000 Passed Support Cutoff",
                proBody: "Netgear Nighthawk R7000 reached End-of-Support (2025-12-31) with unpatched openssl@1.0.2u. Decommission or isolate from Z0 Core.",
                stnTitle: "Retired Device Notice: Netgear Nighthawk R7000",
                stnBody: "Netgear ended security updates for this 2016 Wi-Fi router. We recommend replacing it with a supported access point.",
                aiProBullet: "1 End-of-Life Notice: Netgear R7000 passed vendor EOL cutoff.",
                aiStnBullet: "Retired Router (Netgear R7000): Ended manufacturer support; plan replacement.",
                publishedAt: "1d ago",
                sourceUrl: "https://www.netgear.com/about/eos/"
            ),
            CuratedBulletinItem(
                externalId: "REL-macos-15.3.2-pve-8.3.2",
                canonicalFeedSlug: "apple-proxmox-upstream",
                bulletinType: "release",
                isHighSev: false,
                purlBase: "pkg:generic/apple/macos",
                proTitle: "Upstream Releases: macOS 15.3.2 & Proxmox VE 8.3.2 Available",
                proBody: "Routine maintenance releases published for Aaron's MacBook Pro M4 (15.3.1 -> 15.3.2) and Proxmox VE Compute Host (8.3.1 -> 8.3.2).",
                stnTitle: "New Software Releases: MacBook Pro & Home Server",
                stnBody: "Routine stability updates are ready for Aaron's MacBook Pro (macOS 15.3.2) and your Proxmox Home Server (8.3.2).",
                aiProBullet: "2 Routine Releases: macOS 15.3.2 and Proxmox VE 8.3.2 available.",
                aiStnBullet: "2 Routine Software Updates: MacBook Pro and Home Server.",
                publishedAt: "1d ago",
                sourceUrl: "https://support.apple.com/en-us/100100"
            ),
            CuratedBulletinItem(
                externalId: "REL-esphome-2026.10.2",
                canonicalFeedSlug: "lg-esphome-iot",
                bulletinType: "release",
                isHighSev: false,
                purlBase: "pkg:generic/esphome/firmware",
                proTitle: "ESPHome 2026.10.2 Minor Release (esp-idf@5.3.1)",
                proBody: "Minor Wi-Fi reconnect improvement for Garage Door Relay ESP32 (currently running 2026.9.0). No CVEs associated.",
                stnTitle: "Minor Feature Update: Garage Door Relay ESP32",
                stnBody: "ESPHome 2026.10.2 is available with minor Wi-Fi stability improvements for your garage relay.",
                aiProBullet: "1 IoT Release: ESPHome 2026.10.2 minor update ready.",
                aiStnBullet: "1 Smart Home Update: Minor ESPHome 2026.10.2 update for Garage Relay.",
                publishedAt: "2d ago",
                sourceUrl: "https://esphome.io/changelog/"
            ),
            CuratedBulletinItem(
                externalId: "REL-ecobee-4.8.7.220",
                canonicalFeedSlug: "ecobee-umbrella",
                bulletinType: "release",
                isHighSev: false,
                purlBase: "pkg:generic/ecobee/smart-thermostat",
                proTitle: "Ecobee Firmware 4.8.7.220 Routine Radar Tuning",
                proBody: "Routine occupancy radar tuning for SmartThermostat Premium (suppressed while Hallway Thermostat is an unconfirmed guess).",
                stnTitle: "Routine Thermostat Update (4.8.7.220)",
                stnBody: "Minor room sensor update for Ecobee SmartThermostat.",
                aiProBullet: "1 Thermostat Release: Ecobee 4.8.7.220 available.",
                aiStnBullet: "1 Thermostat Update: Routine sensor tuning for Hallway Ecobee.",
                publishedAt: "4d ago",
                sourceUrl: "https://support.ecobee.com/"
            )
        ]
    }
}
