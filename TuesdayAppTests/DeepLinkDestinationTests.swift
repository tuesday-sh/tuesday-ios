import XCTest
@testable import TuesdayApp

final class DeepLinkDestinationTests: XCTestCase {

    func testParsesAllFiveMainTabsAndAliases() {
        XCTAssertEqual(DeepLinkDestination.fromUri("tuesday://status"), .tab("status"))
        XCTAssertEqual(DeepLinkDestination.fromUri("tuesday://fleet"), .tab("status"))
        XCTAssertEqual(DeepLinkDestination.fromUri("tuesday://bulletins"), .tab("bulletins"))
        XCTAssertEqual(DeepLinkDestination.fromUri("tuesday://alerts"), .tab("bulletins"))
        XCTAssertEqual(DeepLinkDestination.fromUri("tuesday://timeline"), .tab("timeline"))
        XCTAssertEqual(DeepLinkDestination.fromUri("tuesday://checkup"), .tab("checkup"))
        XCTAssertEqual(DeepLinkDestination.fromUri("tuesday://account"), .tab("account"))
        XCTAssertEqual(DeepLinkDestination.fromUri("tuesday://account/dev"), .tab("account-dev"))
        XCTAssertEqual(DeepLinkDestination.fromUri("tuesday://timeline/checkin"), .timelineAction(scenario: nil, modal: "checkin"))
        XCTAssertEqual(DeepLinkDestination.fromUri("tuesday://timeline/update-status"), .timelineAction(scenario: nil, modal: "update-status"))
        XCTAssertEqual(DeepLinkDestination.fromUri("tuesday://timeline?modal=checkin"), .timelineAction(scenario: nil, modal: "checkin"))
        XCTAssertEqual(DeepLinkDestination.fromUri("tuesday://timeline?modal=update-status"), .timelineAction(scenario: nil, modal: "update-status"))
        XCTAssertEqual(DeepLinkDestination.fromUri("tuesday://timeline/zombie"), .timelineAction(scenario: "zombie", modal: nil))
        XCTAssertEqual(DeepLinkDestination.fromUri("tuesday://account/plan"), .upgradePrompt(source: "account", sku: nil))
        XCTAssertEqual(DeepLinkDestination.fromUri("tuesday://upgrade"), .upgradePrompt(source: "modal", sku: nil))
        XCTAssertEqual(DeepLinkDestination.fromUri("tuesday://paywall/monthly"), .upgradePrompt(source: "modal", sku: "sh.tuesday.pro.tier1.monthly"))
        XCTAssertEqual(DeepLinkDestination.fromUri("tuesday://upgrade/annual"), .upgradePrompt(source: "modal", sku: "sh.tuesday.pro.tier1.annual"))
    }

    func testParsesDeterministicFlavorAndSeedTiers() {
        XCTAssertEqual(DeepLinkDestination.fromUri("tuesday://flavor/pro"), .setFlavor(.tuesdayPro))
        XCTAssertEqual(DeepLinkDestination.fromUri("tuesday://flavor/home"), .setFlavor(.sureThingHome))
        XCTAssertEqual(DeepLinkDestination.fromUri("tuesday://toggle-flavor"), .toggleFlavor)
        XCTAssertEqual(DeepLinkDestination.fromUri("tuesday://flavor"), .toggleFlavor)

        XCTAssertEqual(DeepLinkDestination.fromUri("tuesday://seed/0"), .seedFleet(count: 0))
        XCTAssertEqual(DeepLinkDestination.fromUri("tuesday://seed/1"), .seedFleet(count: 1))
        XCTAssertEqual(DeepLinkDestination.fromUri("tuesday://seed/7"), .seedFleet(count: 7))
        XCTAssertEqual(DeepLinkDestination.fromUri("tuesday://seed/12"), .seedFleet(count: 12))
        XCTAssertEqual(DeepLinkDestination.fromUri("tuesday://reset-demo"), .resetDemo)
    }

    func testParsesModalsWizardSynthAndApiEndpoints() {
        XCTAssertEqual(DeepLinkDestination.fromUri("tuesday://hacs"), .hacsSettings)
        XCTAssertEqual(DeepLinkDestination.fromUri("tuesday://network-picker"), .networkPicker)
        XCTAssertEqual(DeepLinkDestination.fromUri("tuesday://reference-guide"), .referenceGuide)
        XCTAssertEqual(DeepLinkDestination.fromUri("tuesday://device/dev-01"), .device(deviceId: "dev-01"))
        XCTAssertEqual(DeepLinkDestination.fromUri("tuesday://inspect/dev-01"), .device(deviceId: "dev-01"))
        XCTAssertEqual(DeepLinkDestination.fromUri("tuesday://patch-tuesday"), .triggerMockPatchTuesday)

        if case .addDevice(let mode, let synth, _, _, _) = DeepLinkDestination.fromUri("tuesday://synth/barcode") {
            XCTAssertEqual(mode, "scan")
            XCTAssertEqual(synth, "barcode-udm-pro")
        } else {
            XCTFail("Expected barcode synth addDevice route")
        }

        if case .addDevice(let mode, _, let q, let clues, _) = DeepLinkDestination.fromUri("tuesday://add-device?mode=manual&q=Ubiquiti&clues=UDM-Pro%2CC3") {
            XCTAssertEqual(mode, "manual")
            XCTAssertEqual(q, "Ubiquiti")
            XCTAssertEqual(clues, "UDM-Pro,C3")
        } else {
            XCTFail("Expected addDevice route with clues")
        }

        XCTAssertEqual(DeepLinkDestination.fromUri("tuesday://api-endpoint/local"), .setApiEndpoint("http://127.0.0.1:3000"))
        XCTAssertEqual(DeepLinkDestination.fromUri("tuesday://api-endpoint/prod"), .setApiEndpoint("https://api.tuesday.sh"))
        XCTAssertEqual(DeepLinkDestination.fromUri("tuesday://api-endpoint/dev"), .setApiEndpoint("http://127.0.0.1:3000"))
    }

    func testRejectsMalformedOrForeignSchemes() {
        XCTAssertNil(DeepLinkDestination.fromUri(nil))
        XCTAssertNil(DeepLinkDestination.fromUri(""))
        XCTAssertNil(DeepLinkDestination.fromUri("https://tuesday.sh/status"))
        XCTAssertNil(DeepLinkDestination.fromUri("tuesday://"))
        XCTAssertNil(DeepLinkDestination.fromUri("tuesday://unknown-route"))
        XCTAssertNil(DeepLinkDestination.fromUri("tuesday://device/"))
        XCTAssertEqual(DeepLinkDestination.fromUri("tuesday://vision-debug/off"), .visionDebug(false))
    }
}
