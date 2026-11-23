import Foundation

public enum EntitlementGatePolicy {
    public static let demoNetworkId = "net-demo"
    public static let freeDeviceLimit = 15
    public static let proDeviceLimit = 128
    public static let freeAiPhotoScanLimit = 15

    public static func isProTier1Entitled(_ tier: String?) -> Bool {
        let normalized = (tier ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return normalized == "pro_tier_1" ||
            normalized == "multisite_tier_1" ||
            normalized == "fleet"
    }

    public static func remainingFreeAiPhotoScans(tier: String?, scansUsed: Int) -> Int? {
        if isProTier1Entitled(tier) { return nil }
        return max(0, freeAiPhotoScanLimit - scansUsed)
    }

    public static func canRunAiPhotoScan(tier: String?, scansUsed: Int) -> Bool {
        isProTier1Entitled(tier) || scansUsed < freeAiPhotoScanLimit
    }

    public static func requiresUpgradeForAiPhotoScan(tier: String?, scansUsed: Int) -> Bool {
        !canRunAiPhotoScan(tier: tier, scansUsed: scansUsed)
    }

    public static func maxDevices(for tier: String?) -> Int {
        isProTier1Entitled(tier) ? proDeviceLimit : freeDeviceLimit
    }

    public static func canAddDevice(
        tier: String?,
        activeNetworkId: String?,
        currentDeviceCount: Int
    ) -> Bool {
        if activeNetworkId == demoNetworkId { return true }
        return currentDeviceCount < maxDevices(for: tier)
    }

    public static func requiresUpgradeForNewDevice(
        tier: String?,
        activeNetworkId: String?,
        currentDeviceCount: Int
    ) -> Bool {
        !isProTier1Entitled(tier) && !canAddDevice(tier: tier, activeNetworkId: activeNetworkId, currentDeviceCount: currentDeviceCount)
    }

    public static func realNetworkCount(_ networks: [NetworkSite]) -> Int {
        networks.filter { $0.id != demoNetworkId }.count
    }

    public static func canCreateAdditionalNetwork(tier: String?, networks: [NetworkSite]) -> Bool {
        isProTier1Entitled(tier) || realNetworkCount(networks) < 1
    }

    public static func requiresUpgradeForNewSite(tier: String?, networks: [NetworkSite]) -> Bool {
        !canCreateAdditionalNetwork(tier: tier, networks: networks)
    }
}
