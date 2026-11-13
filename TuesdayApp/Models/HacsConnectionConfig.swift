import Foundation

public enum AiProviderType: String, Codable, CaseIterable, Identifiable {
    case elastix = "elastix"
    case gemini = "gemini"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .elastix: return "Elastix.ai"
        case .gemini: return "GCP Gemini"
        }
    }

    public var shortLabel: String {
        switch self {
        case .elastix: return "Elastix"
        case .gemini: return "Gemini"
        }
    }
}

public struct HacsConnectionConfig: Codable, Equatable {
    public var instanceName: String
    public var baseUrl: String
    public var apiToken: String
    public var hacsComponentVersion: String
    public var tuesdayServerVersion: String
    public var requireLocalWifi: Bool
    public var trustedSsid: String
    public var isConnected: Bool
    public var lastSyncedAt: Date
    public var aiProvider: AiProviderType
    public var elastixApiKey: String
    public var elastixModel: String
    public var geminiApiKey: String
    public var geminiModel: String
    public var tuesdayApiBaseUrl: String

    public init(
        instanceName: String = "Home Assistant (HACS)",
        baseUrl: String = "http://homeassistant.local:8123",
        apiToken: String = "tuesday_hacs_live_98f2a4c1d0",
        hacsComponentVersion: String = "0.4.2",
        tuesdayServerVersion: String = "0.2.0-hacs",
        requireLocalWifi: Bool = false,
        trustedSsid: String = "SureThing-Home-5G",
        isConnected: Bool = true,
        lastSyncedAt: Date = Date(),
        aiProvider: AiProviderType = .elastix,
        elastixApiKey: String = "",
        elastixModel: String = "qwen3.8-27b",
        geminiApiKey: String = "",
        geminiModel: String = "gemini-3.8-flash",
        tuesdayApiBaseUrl: String = "https://api.tuesday.sh"
    ) {
        self.instanceName = instanceName
        self.baseUrl = baseUrl
        self.apiToken = apiToken
        self.hacsComponentVersion = hacsComponentVersion
        self.tuesdayServerVersion = tuesdayServerVersion
        self.requireLocalWifi = requireLocalWifi
        self.trustedSsid = trustedSsid
        self.isConnected = isConnected
        self.lastSyncedAt = lastSyncedAt
        self.aiProvider = aiProvider
        self.elastixApiKey = elastixApiKey
        self.elastixModel = elastixModel
        self.geminiApiKey = geminiApiKey
        self.geminiModel = geminiModel
        self.tuesdayApiBaseUrl = tuesdayApiBaseUrl
    }

    enum CodingKeys: String, CodingKey {
        case instanceName
        case baseUrl
        case apiToken
        case hacsComponentVersion
        case tuesdayServerVersion
        case requireLocalWifi
        case trustedSsid
        case isConnected
        case lastSyncedAt
        case aiProvider
        case elastixApiKey
        case elastixModel
        case geminiApiKey
        case geminiModel
        case tuesdayApiBaseUrl
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.instanceName = try container.decodeIfPresent(String.self, forKey: .instanceName) ?? "Home Assistant (HACS)"
        self.baseUrl = try container.decodeIfPresent(String.self, forKey: .baseUrl) ?? "http://homeassistant.local:8123"
        self.apiToken = try container.decodeIfPresent(String.self, forKey: .apiToken) ?? "tuesday_hacs_live_98f2a4c1d0"
        self.hacsComponentVersion = try container.decodeIfPresent(String.self, forKey: .hacsComponentVersion) ?? "0.4.2"
        self.tuesdayServerVersion = try container.decodeIfPresent(String.self, forKey: .tuesdayServerVersion) ?? "0.2.0-hacs"
        self.requireLocalWifi = try container.decodeIfPresent(Bool.self, forKey: .requireLocalWifi) ?? false
        self.trustedSsid = try container.decodeIfPresent(String.self, forKey: .trustedSsid) ?? "SureThing-Home-5G"
        self.isConnected = try container.decodeIfPresent(Bool.self, forKey: .isConnected) ?? true
        self.lastSyncedAt = try container.decodeIfPresent(Date.self, forKey: .lastSyncedAt) ?? Date()
        self.aiProvider = try container.decodeIfPresent(AiProviderType.self, forKey: .aiProvider) ?? .elastix
        self.elastixApiKey = try container.decodeIfPresent(String.self, forKey: .elastixApiKey) ?? ""
        self.elastixModel = try container.decodeIfPresent(String.self, forKey: .elastixModel) ?? "qwen3.8-27b"
        self.geminiApiKey = try container.decodeIfPresent(String.self, forKey: .geminiApiKey) ?? ""
        self.geminiModel = try container.decodeIfPresent(String.self, forKey: .geminiModel) ?? "gemini-3.8-flash"
        self.tuesdayApiBaseUrl = try container.decodeIfPresent(String.self, forKey: .tuesdayApiBaseUrl) ?? "https://api.tuesday.sh"
    }
}
