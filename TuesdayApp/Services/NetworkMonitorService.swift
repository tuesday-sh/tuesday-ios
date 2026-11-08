import Foundation
import Network
import NetworkExtension
import Combine

@MainActor
public final class NetworkMonitorService: ObservableObject {
    @Published public var isWifiConnected: Bool = true
    @Published public var currentSsid: String = "SureThing-Home-5G"
    @Published public var simulateWifiDisconnected: Bool = false {
        didSet {
            updateEffectiveWifiStatus()
        }
    }

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "sh.tuesday.app.networkmonitor")
    private var rawHasWifiOrWired: Bool = true

    public init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let connected = path.status == .satisfied &&
                (path.usesInterfaceType(.wifi) || path.usesInterfaceType(.wiredEthernet))
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.rawHasWifiOrWired = connected
                self.updateEffectiveWifiStatus()
                await self.refreshSsid()
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }

    private func updateEffectiveWifiStatus() {
        if simulateWifiDisconnected {
            isWifiConnected = false
        } else {
            isWifiConnected = rawHasWifiOrWired
        }
    }

    public func setSimulateDisconnected(_ disconnected: Bool) {
        simulateWifiDisconnected = disconnected
    }

    public func refreshSsid() async {
        guard isWifiConnected else {
            currentSsid = "Disconnected"
            return
        }
        #if targetEnvironment(simulator)
        currentSsid = "SureThing-Home-5G"
        #else
        if let network = await NEHotspotNetwork.fetchCurrent() {
            currentSsid = network.ssid
        } else {
            currentSsid = "SureThing-Home-5G"
        }
        #endif
    }
}
