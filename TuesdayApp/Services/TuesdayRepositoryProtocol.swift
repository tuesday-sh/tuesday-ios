import Foundation
import Combine

@MainActor
public protocol TuesdayRepositoryProtocol: ObservableObject {
    var nodes: [MonitoredNode] { get }
    var hacsConfig: HacsConnectionConfig { get set }
    var isSyncing: Bool { get }

    func refreshTelemetry() async
    func enrollNode(
        hostname: String,
        osDetails: String,
        packageManager: PackageManagerType,
        agentToken: String,
        inventoryState: InventoryConfidenceState?,
        discoveredMetadata: DiscoveredDeviceMetadata?
    ) async
    func triggerNodeCheckIn(nodeId: String) async
    func markNodeUpdatesApplied(nodeId: String) async
    func updateHacsConfig(_ config: HacsConnectionConfig)
    func resetDemoData()
}
