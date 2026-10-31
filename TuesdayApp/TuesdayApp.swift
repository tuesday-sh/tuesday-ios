import SwiftUI

@main
struct TuesdayApp: App {
    @StateObject private var repository: MockHacsTuesdayService
    @StateObject private var networkMonitor = NetworkMonitorService()

    init() {
        let defaults = UserDefaults.standard
        if CommandLine.arguments.contains("--uitesting-reset") {
            defaults.removeObject(forKey: "tuesday_mock_nodes_v1")
            defaults.removeObject(forKey: "tuesday_mock_hacs_config_v1")
        }
        _repository = StateObject(wrappedValue: MockHacsTuesdayService(defaults: defaults))
    }

    var body: some Scene {
        WindowGroup {
            HomeView(
                repository: repository,
                networkMonitor: networkMonitor
            )
        }
    }
}
