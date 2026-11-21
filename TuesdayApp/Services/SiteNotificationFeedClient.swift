import Foundation

/// Canonical server-issued notification record returned by `GET /api/v1/notifications/feed`
/// and transitioned via `PATCH /api/v1/notifications/:id`.
public struct SiteNotificationItem: Codable, Identifiable, Equatable {
    public let id: Int
    public let networkSiteId: Int
    public let ruleId: String
    public let triggerType: String
    public let dedupKey: String
    public let surfaces: [String]
    public let priority: String
    public let status: String
    public let pushStatus: String
    public let title: String
    public let body: String
    public let ctaLabel: String?
    public let deepLinkUri: String?
    public let monitoredDeviceId: String?
    public let monitoredDeviceLabel: String?
    public let snoozedUntil: String?
    public let expiresAt: String?
    public let seenAt: String?
    public let resolvedAt: String?
    public let createdAt: String?
    public let updatedAt: String?

    public func targetsSurface(_ surface: String) -> Bool {
        surfaces.contains { $0.caseInsensitiveCompare(surface) == .orderedSame }
    }

    public var isUnresolved: Bool {
        ["active", "seen", "snoozed"].contains(status)
    }
}

public struct SiteNotificationFeedResponse: Codable {
    public let status: String
    public let networkSiteId: Int
    public let syncedAt: String
    public let count: Int
    public let notifications: [SiteNotificationItem]
}

public struct SiteNotificationUpdateResponse: Codable {
    public let status: String
    public let notification: SiteNotificationItem
}

/// Thin async client for the unified server-side Notification Engine (`/api/v1/notifications/feed`).
public final class SiteNotificationFeedClient {
    public static let shared = SiteNotificationFeedClient()

    private let baseURL: URL
    private let session: URLSession

    public init(
        baseURL: URL = URL(string: "https://api.tuesday.sh")!,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.session = session
    }

    public func fetchFeed(
        ownerKey: String,
        deviceId: String,
        surface: String? = nil,
        since: String? = nil,
        status: String = "unresolved"
    ) async throws -> SiteNotificationFeedResponse {
        var components = URLComponents(url: baseURL.appendingPathComponent("api/v1/notifications/feed"), resolvingAgainstBaseURL: false)!
        var queryItems = [URLQueryItem(name: "status", value: status)]
        if let surface, !surface.isEmpty {
            queryItems.append(URLQueryItem(name: "surface", value: surface))
        }
        if let since, !since.isEmpty {
            queryItems.append(URLQueryItem(name: "since", value: since))
        }
        components.queryItems = queryItems

        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        request.setValue(ownerKey, forHTTPHeaderField: "X-Tuesday-Owner-Key")
        request.setValue(deviceId, forHTTPHeaderField: "X-Tuesday-Device-ID")
        request.setValue("ios", forHTTPHeaderField: "X-Tuesday-Client-Platform")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(SiteNotificationFeedResponse.self, from: data)
    }

    /// Transitions a canonical notification (`seen`, `snoozed`, `completed`, `dismissed`, `push_seen`, `reopen`).
    public func updateState(
        notificationId: Int,
        actionType: String,
        ownerKey: String,
        deviceId: String,
        snoozeMinutes: Int? = nil
    ) async throws -> SiteNotificationItem {
        let url = baseURL.appendingPathComponent("api/v1/notifications/\(notificationId)")
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(ownerKey, forHTTPHeaderField: "X-Tuesday-Owner-Key")
        request.setValue(deviceId, forHTTPHeaderField: "X-Tuesday-Device-ID")
        request.setValue("ios", forHTTPHeaderField: "X-Tuesday-Client-Platform")

        var payload: [String: Any] = ["action_type": actionType]
        if let snoozeMinutes {
            payload["snooze_minutes"] = snoozeMinutes
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(SiteNotificationUpdateResponse.self, from: data).notification
    }

    /// Registers an iOS APNs device token with `POST /api/v1/notifications/register_token`.
    public func registerDeviceToken(
        apnsTokenHex: String,
        deviceId: String,
        appFlavor: String = "tuesday"
    ) async {
        let url = baseURL.appendingPathComponent("api/v1/notifications/register_token")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(deviceId, forHTTPHeaderField: "X-Tuesday-Device-ID")
        request.setValue("ios", forHTTPHeaderField: "X-Tuesday-Client-Platform")

        let payload: [String: Any] = [
            "fcm_token": apnsTokenHex,
            "platform": "ios",
            "app_flavor": appFlavor,
            "client_device_id": deviceId
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
        _ = try? await session.data(for: request)
    }
}
