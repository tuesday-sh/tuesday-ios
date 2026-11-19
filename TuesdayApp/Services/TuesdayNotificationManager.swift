import Foundation
import UserNotifications

/// Manages iOS local notification permissions, monthly Patch Tuesday reminders,
/// and on-demand / developer bulletin alert dispatches via `UNUserNotificationCenter`.
@MainActor
public final class TuesdayNotificationManager: ObservableObject {
    public static let shared = TuesdayNotificationManager()

    public static let patchTuesdayReminderIdentifier = "sh.tuesday.app.monthly_patch_tuesday"
    public static let mockPatchTuesdayIdentifier = "sh.tuesday.app.mock_patch_tuesday"

    @Published public private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private let center = UNUserNotificationCenter.current()

    public init() {
        Task {
            await refreshAuthorizationStatus()
        }
    }

    public func refreshAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    @discardableResult
    public func requestAuthorizationIfNeeded() async -> Bool {
        let current = await center.notificationSettings()
        authorizationStatus = current.authorizationStatus
        switch current.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            let granted = (try? await center.requestAuthorization(options: [.alert, .badge, .sound])) ?? false
            await refreshAuthorizationStatus()
            return granted
        @unknown default:
            return false
        }
    }

    /// Configures or clears the recurring Patch Tuesday check-in reminder (2nd Tuesday, 10:00 AM local).
    public func syncMonthlyPatchTuesdaySchedule(enabled: Bool, isStnFlavor: Bool) async {
        center.removePendingNotificationRequests(withIdentifiers: [Self.patchTuesdayReminderIdentifier])
        guard enabled else { return }

        let granted = await requestAuthorizationIfNeeded()
        guard granted else { return }

        let content = UNMutableNotificationContent()
        content.title = isStnFlavor
            ? "Patch Tuesday Home Check-Up"
            : "Monthly Patch Tuesday Readiness"
        content.body = isStnFlavor
            ? "Spend 5 minutes checking your Wi-Fi router and home gear for vendor updates."
            : "Review new upstream CVEs, firmware advisories, and Fleet inventory bulletins."
        content.sound = .default
        content.userInfo = ["deeplink": "tuesday://bulletins"]

        // Weekday 3 = Tuesday, weekdayOrdinal 2 = 2nd Tuesday of month, 10:00 AM local time.
        var components = DateComponents()
        components.weekday = 3
        components.weekdayOrdinal = 2
        components.hour = 10
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: Self.patchTuesdayReminderIdentifier,
            content: content,
            trigger: trigger
        )
        try? await center.add(request)
    }

    /// Triggers an immediate simulated Patch Tuesday notification (Dev Simulator).
    public func triggerMockPatchTuesdayNotification(isStnFlavor: Bool) async -> Bool {
        let granted = await requestAuthorizationIfNeeded()
        guard granted else { return false }

        let content = UNMutableNotificationContent()
        content.title = isStnFlavor
            ? "Patch Tuesday Readiness Reminder"
            : "R2 • Patch Tuesday Cycle Ready"
        content.body = isStnFlavor
            ? "Your monthly 5-minute router & smart home update check is ready to review."
            : "Curated CVE & firmware bulletins assembled for your active inventory."
        content.sound = .default
        content.userInfo = ["deeplink": "tuesday://bulletins"]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: Self.mockPatchTuesdayIdentifier,
            content: content,
            trigger: trigger
        )
        try? await center.add(request)
        return true
    }

    /// Dispatches immediate local alerts for active inventory bulletins (dev/test trigger & foreground sync).
    public func dispatchBulletinNotifications(_ bulletins: [BulletinInboxView], limit: Int = 5) async -> Int {
        guard !bulletins.isEmpty else { return 0 }
        let granted = await requestAuthorizationIfNeeded()
        guard granted else { return 0 }

        var sentCount = 0
        for (idx, item) in bulletins.prefix(limit).enumerated() {
            let content = UNMutableNotificationContent()
            content.title = item.title
            content.body = item.body
            content.sound = .default
            content.userInfo = [
                "deeplink": "tuesday://bulletins",
                "bulletinId": item.externalId
            ]
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(1 + idx), repeats: false)
            let request = UNNotificationRequest(
                identifier: "sh.tuesday.app.bulletin.\(item.externalId)",
                content: content,
                trigger: trigger
            )
            do {
                try await center.add(request)
                sentCount += 1
            } catch {
                // Continue dispatching remaining alerts cleanly
            }
        }
        return sentCount
    }
}
