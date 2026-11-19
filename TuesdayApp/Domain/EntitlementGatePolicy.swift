import Foundation

public enum EntitlementGatePolicy {
    public static let demoNetworkId = "net-demo"

    public static func isProTier1Entitled(_ tier: String?) -> Bool {
        let normalized = (tier ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return normalized == "pro_tier_1" ||
            normalized == "multisite_tier_1" ||
            normalized == "fleet"
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
