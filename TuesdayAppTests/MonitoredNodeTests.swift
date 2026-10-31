import XCTest
@testable import TuesdayApp

final class MonitoredNodeTests: XCTestCase {
    func testHealthyNodeEvaluation() {
        let now = Date()
        let node = MonitoredNode(
            hostname: "aaronpro18",
            osDetails: "macOS 15.7.9",
            packageManager: .brew,
            lastCheckIn: now.addingTimeInterval(-10 * 60),
            pendingUpdates: [],
            referenceDate: now
        )

        XCTAssertEqual(node.status, .healthy)
        XCTAssertEqual(node.healthScore, 100.0)
        XCTAssertEqual(node.haEntityId, "sensor.tuesday_aaronpro18")
    }

    func testWarningNodeEvaluationWithNonCriticalUpdates() {
        let now = Date()
        let updates = [
            PackageUpdate(name: "esphome", currentVersion: "2026.9.1", availableVersion: "2026.10.0")
        ]
        let node = MonitoredNode(
            hostname: "homeassistant.local",
            osDetails: "Home Assistant OS 14.2",
            packageManager: .hacs,
            lastCheckIn: now.addingTimeInterval(-5 * 60),
            pendingUpdates: updates,
            referenceDate: now
        )

        XCTAssertEqual(node.status, .warning)
        XCTAssertEqual(node.healthScore, 92.0)
        XCTAssertEqual(node.haEntityId, "sensor.tuesday_homeassistant_local")
    }

    func testCriticalNodeEvaluationWithSecurityCriticalUpdate() {
        let now = Date()
        let updates = [
            PackageUpdate(
                name: "openssl",
                currentVersion: "3.0.13-1",
                availableVersion: "3.0.13-4",
                isSecurityCritical: true
            )
        ]
        let node = MonitoredNode(
            hostname: "ubuntu-dev",
            osDetails: "Ubuntu 24.04",
            packageManager: .apt,
            lastCheckIn: now,
            pendingUpdates: updates,
            referenceDate: now
        )

        XCTAssertEqual(node.status, .critical)
        XCTAssertEqual(node.healthScore, 70.0)
    }

    @MainActor
    func testMockHacsServiceEnrollmentAndPatching() async {
        let suiteName = "sh.tuesday.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let service = MockHacsTuesdayService(defaults: defaults)

        XCTAssertEqual(service.nodes.count, 4)

        await service.enrollNode(
            hostname: "unifi-gateway",
            osDetails: "UniFi OS 4.0",
            packageManager: .apt,
            agentToken: "tok_123"
        )
        XCTAssertEqual(service.nodes.count, 5)
        XCTAssertEqual(service.nodes.first?.hostname, "unifi-gateway")

        if let ubuntuId = service.nodes.first(where: { $0.hostname == "ubuntu-dev" })?.id {
            await service.markNodeUpdatesApplied(nodeId: ubuntuId)
            let patched = service.nodes.first(where: { $0.id == ubuntuId })
            XCTAssertEqual(patched?.status, .healthy)
            XCTAssertTrue(patched?.pendingUpdates.isEmpty ?? false)
        }
    }

    @MainActor
    func testProgressiveDevicePhotoDiscoveryAndIncompleteEnrollment() async {
        var identifiers = ExtractedDeviceIdentifiers()
        let initialResult = GeminiDeviceDiscoveryService.fallbackHeuristicAnalysis(
            accumulatedIdentifiers: identifiers,
            userClueNotes: [],
            imageCount: 1,
            usedLiveApi: false
        )
        XCTAssertFalse(initialResult.candidates.isEmpty)
        XCTAssertTrue(initialResult.nextNarrowingQuestion.contains("Barcode") || initialResult.nextNarrowingQuestion.contains("MAC"))

        // Refine with Model & MAC clue
        identifiers.modelNumber = "UCG-Ultra"
        identifiers.macAddress = "74:83:C2:9E:11:04"
        let refinedResult = GeminiDeviceDiscoveryService.fallbackHeuristicAnalysis(
            accumulatedIdentifiers: identifiers,
            userClueNotes: ["Model=UCG-Ultra"],
            imageCount: 1,
            usedLiveApi: false
        )
        XCTAssertGreaterThanOrEqual(refinedResult.candidates.first?.confidencePercent ?? 0, 90)
        XCTAssertEqual(refinedResult.candidates.first?.modelNumber, "UCG-Ultra")

        // Verify incomplete/guessed device enrollment
        let suiteName = "sh.tuesday.tests.wizard.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let service = MockHacsTuesdayService(defaults: defaults)

        let metadata = DiscoveredDeviceMetadata(
            manufacturer: "Ubiquiti Inc.",
            modelNumber: "UCG-Ultra",
            deviceCategory: "Router",
            macAddress: "74:83:C2:9E:11:04",
            confidenceScore: 68
        )
        await service.enrollNode(
            hostname: "unifi-ucg-ultra.local (guessed)",
            osDetails: "UniFi Cloud Gateway Ultra",
            packageManager: .apt,
            agentToken: "tok_guess",
            inventoryState: .incompleteOrGuessed,
            discoveredMetadata: metadata
        )
        XCTAssertEqual(service.nodes.first?.inventoryState, .incompleteOrGuessed)
        XCTAssertEqual(service.nodes.first?.discoveredMetadata?.modelNumber, "UCG-Ultra")
    }
}
