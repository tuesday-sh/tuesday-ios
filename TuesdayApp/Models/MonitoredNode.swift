import Foundation

public enum PackageManagerType: String, Codable, CaseIterable, Identifiable {
    case apt = "apt"
    case apk = "apk"
    case brew = "brew"
    case yum = "yum"
    case docker = "docker"
    case hacs = "hacs"
    case firmware = "firmware"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .apt: return "APT (Debian/Ubuntu)"
        case .apk: return "APK (Alpine/Unraid)"
        case .brew: return "Homebrew (macOS)"
        case .yum: return "YUM/DNF (RHEL)"
        case .docker: return "Docker Containers"
        case .hacs: return "Home Assistant HACS"
        case .firmware: return "Device Firmware / OTA"
        }
    }
}

public enum InventoryConfidenceState: String, Codable, CaseIterable {
    case enrolled = "ENROLLED"
    case verified = "VERIFIED MATCH"
    case incompleteOrGuessed = "INCOMPLETE / GUESSED"

    public var displayTitle: String {
        switch self {
        case .enrolled: return "Agent Enrolled"
        case .verified: return "Verified Match"
        case .incompleteOrGuessed: return "Incomplete / Guessed"
        }
    }
}

public struct DiscoveredDeviceMetadata: Codable, Equatable {
    public var manufacturer: String?
    public var modelNumber: String?
    public var deviceCategory: String?
    public var serialNumber: String?
    public var macAddress: String?
    public var barcodeOrQr: String?
    public var confidenceScore: Int?
    public var discoveryNotes: String?

    public init(
        manufacturer: String? = nil,
        modelNumber: String? = nil,
        deviceCategory: String? = nil,
        serialNumber: String? = nil,
        macAddress: String? = nil,
        barcodeOrQr: String? = nil,
        confidenceScore: Int? = nil,
        discoveryNotes: String? = nil
    ) {
        self.manufacturer = manufacturer
        self.modelNumber = modelNumber
        self.deviceCategory = deviceCategory
        self.serialNumber = serialNumber
        self.macAddress = macAddress
        self.barcodeOrQr = barcodeOrQr
        self.confidenceScore = confidenceScore
        self.discoveryNotes = discoveryNotes
    }
}

public enum NodeHealthStatus: String, Codable, CaseIterable {
    case healthy = "HEALTHY"
    case warning = "WARNING"
    case critical = "CRITICAL"

    public var displayTitle: String {
        switch self {
        case .healthy: return "Healthy"
        case .warning: return "Warning"
        case .critical: return "Critical"
        }
    }
}

public struct PackageUpdate: Identifiable, Codable, Equatable {
    public let id: String
    public let name: String
    public let currentVersion: String
    public let availableVersion: String
    public let isSecurityCritical: Bool
    public let advisoryNote: String?

    public init(
        id: String = UUID().uuidString,
        name: String,
        currentVersion: String,
        availableVersion: String,
        isSecurityCritical: Bool = false,
        advisoryNote: String? = nil
    ) {
        self.id = id
        self.name = name
        self.currentVersion = currentVersion
        self.availableVersion = availableVersion
        self.isSecurityCritical = isSecurityCritical
        self.advisoryNote = advisoryNote
    }
}

public struct MonitoredNode: Identifiable, Codable, Equatable {
    public let id: String
    public var hostname: String
    public var osDetails: String
    public var agentVersion: String
    public var packageManager: PackageManagerType
    public var haEntityId: String
    public var lastCheckIn: Date
    public var pendingUpdates: [PackageUpdate]
    public var healthScore: Double
    public var status: NodeHealthStatus
    public var inventoryState: InventoryConfidenceState?
    public var discoveredMetadata: DiscoveredDeviceMetadata?

    public init(
        id: String = UUID().uuidString,
        hostname: String,
        osDetails: String,
        agentVersion: String = "0.1.0",
        packageManager: PackageManagerType,
        haEntityId: String? = nil,
        lastCheckIn: Date = Date(),
        pendingUpdates: [PackageUpdate] = [],
        healthScore: Double? = nil,
        inventoryState: InventoryConfidenceState? = nil,
        discoveredMetadata: DiscoveredDeviceMetadata? = nil,
        referenceDate: Date = Date()
    ) {
        self.id = id
        self.hostname = hostname
        self.osDetails = osDetails
        self.agentVersion = agentVersion
        self.packageManager = packageManager
        let slug = hostname
            .lowercased()
            .replacingOccurrences(of: ".", with: "_")
            .replacingOccurrences(of: "-", with: "_")
            .replacingOccurrences(of: " ", with: "_")
        self.haEntityId = haEntityId ?? "sensor.tuesday_\(slug)"
        self.lastCheckIn = lastCheckIn
        self.pendingUpdates = pendingUpdates
        self.inventoryState = inventoryState
        self.discoveredMetadata = discoveredMetadata

        let computedScore = healthScore ?? Self.calculateHealthScore(
            pendingUpdates: pendingUpdates,
            lastCheckIn: lastCheckIn,
            now: referenceDate
        )
        self.healthScore = computedScore
        self.status = Self.evaluateStatus(
            healthScore: computedScore,
            pendingUpdates: pendingUpdates,
            lastCheckIn: lastCheckIn,
            now: referenceDate
        )
    }

    public static func calculateHealthScore(
        pendingUpdates: [PackageUpdate],
        lastCheckIn: Date,
        now: Date = Date()
    ) -> Double {
        var score = 100.0
        let criticalCount = pendingUpdates.filter(\.isSecurityCritical).count
        let regularCount = pendingUpdates.count - criticalCount

        score -= Double(criticalCount) * 30.0
        score -= Double(regularCount) * 8.0

        let hoursSinceCheckIn = max(0, now.timeIntervalSince(lastCheckIn) / 3600.0)
        if hoursSinceCheckIn > 72 {
            score -= 45.0
        } else if hoursSinceCheckIn > 24 {
            score -= 20.0
        }

        return min(100.0, max(5.0, score))
    }

    /// Evaluates "Check Engine Light" status ported from SureThingNet's Device._calculateStatus
    public static func evaluateStatus(
        healthScore: Double,
        pendingUpdates: [PackageUpdate],
        lastCheckIn: Date,
        now: Date = Date()
    ) -> NodeHealthStatus {
        let hoursSinceCheckIn = now.timeIntervalSince(lastCheckIn) / 3600.0

        // 1. CRITICAL RULES:
        // - Any security-critical update pending
        // - Check-in stale > 72 hours
        // - Health score < 40.0
        if pendingUpdates.contains(where: \.isSecurityCritical) {
            return .critical
        }
        if hoursSinceCheckIn > 72.0 || healthScore < 40.0 {
            return .critical
        }

        // 2. WARNING RULES:
        // - Outdated packages pending
        // - Check-in stale > 24 hours
        if !pendingUpdates.isEmpty || hoursSinceCheckIn > 24.0 || healthScore < 75.0 {
            return .warning
        }

        // 3. Otherwise, silent and healthy
        return .healthy
    }
}
