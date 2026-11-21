import SwiftUI
import UIKit

final class TuesdayAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let hexToken = deviceToken.map { String(format: "%02x", $0) }.joined()
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "ios-default"
        Task {
            await SiteNotificationFeedClient.shared.registerDeviceToken(
                apnsTokenHex: hexToken,
                deviceId: deviceId
            )
        }
    }
}

@main
struct TuesdayApp: App {
    @UIApplicationDelegateAdaptor(TuesdayAppDelegate.self) private var appDelegate
    @StateObject private var repository: MockHacsTuesdayService
    @StateObject private var networkMonitor = NetworkMonitorService()
    @StateObject private var notificationManager = TuesdayNotificationManager.shared
    @StateObject private var storeKitManager: TuesdayStoreKitManager

    @State private var pendingDeepLink: DeepLinkDestination?

    init() {
        let defaults = UserDefaults.standard
        if CommandLine.arguments.contains("--uitesting-reset") {
            MockHacsTuesdayService.clearAllPersistedState(in: defaults)
        }
        let repo = MockHacsTuesdayService(defaults: defaults)
        _repository = StateObject(wrappedValue: repo)
        _storeKitManager = StateObject(wrappedValue: TuesdayStoreKitManager(repository: repo))
        if let idx = CommandLine.arguments.firstIndex(of: "--deeplink"),
           idx + 1 < CommandLine.arguments.count,
           let url = URL(string: CommandLine.arguments[idx + 1]) {
            _pendingDeepLink = State(initialValue: DeepLinkDestination.parse(url))
        }
    }

    var body: some Scene {
        WindowGroup {
            HomeView(
                repository: repository,
                networkMonitor: networkMonitor,
                notificationManager: notificationManager,
                storeKitManager: storeKitManager,
                pendingDeepLink: $pendingDeepLink
            )
            .onOpenURL { url in
                pendingDeepLink = DeepLinkDestination.parse(url)
            }
            .task {
                GoldClueSuggestionRepository.shared.preload()
                await storeKitManager.start()
                await GoldClueSuggestionRepository.shared.refreshFromServerIfNeeded(
                    baseUrl: repository.tuesdayApiBaseUrl
                )
                if await notificationManager.requestAuthorizationIfNeeded() {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
}
