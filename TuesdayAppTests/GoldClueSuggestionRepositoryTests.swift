import XCTest
@testable import TuesdayApp

final class GoldClueSuggestionRepositoryTests: XCTestCase {

    private var index: GoldClueIndexData!

    override func setUpWithError() throws {
        index = GoldClueSuggestionRepository.shared.index
        XCTAssertFalse(index.types.isEmpty, "Expected bundled gold_clue_index.gci to load in host app bundle")
        XCTAssertFalse(index.models.isEmpty, "Expected Gold hardware SKUs to load from .gci")
    }

    func testMatchesDeviceTypesAndBrands() {
        let routerHits = index.querySuggestions(rawQuery: "router")
        XCTAssertTrue(routerHits.contains { $0.kind == .deviceType && $0.typeId == "router" && $0.categoryCode == "C3" })

        let switchHits = index.querySuggestions(rawQuery: "switch")
        XCTAssertTrue(switchHits.contains { $0.kind == .deviceType && $0.typeId == "switch" && $0.categoryCode == "C4" })

        let doorbellHits = index.querySuggestions(rawQuery: "doorbell")
        XCTAssertTrue(doorbellHits.contains { $0.kind == .deviceType && $0.typeId == "doorbell" })
        XCTAssertTrue(doorbellHits.contains { $0.kind == .model && $0.title.localizedCaseInsensitiveContains("Doorbell") })

        let linksysHits = index.querySuggestions(rawQuery: "linksys")
        XCTAssertEqual(linksysHits.first?.vendor, "Linksys")

        let googleHits = index.querySuggestions(rawQuery: "google")
        XCTAssertEqual(googleHits.first?.vendor, "Google")
    }

    func testExcludesErpNoiseFromConsumerRingQuery() {
        let ringHits = index.querySuggestions(rawQuery: "ring")
        XCTAssertTrue(ringHits.contains { $0.vendor == "Amazon Ring" })
        XCTAssertFalse(ringHits.contains {
            $0.title.localizedCaseInsensitiveContains("banking") ||
            $0.title.localizedCaseInsensitiveContains("turing")
        })
    }

    func testContextualQuickPicksNarrowFromTypeToBrandToModel() throws {
        let initialPicks = index.contextualQuickPicks([])
        XCTAssertTrue(initialPicks.allSatisfy { $0.kind == .deviceType })

        let doorbellClue = try XCTUnwrap(index.querySuggestions(rawQuery: "doorbell").first { $0.kind == .deviceType })
        let brandPicks = index.contextualQuickPicks([doorbellClue])
        XCTAssertTrue(brandPicks.contains { $0.vendor == "Google" })

        let googleBrand = try XCTUnwrap(brandPicks.first { $0.vendor == "Google" })
        let modelPicks = index.contextualQuickPicks([doorbellClue, googleBrand])
        XCTAssertFalse(modelPicks.isEmpty)
        XCTAssertTrue(modelPicks.allSatisfy { $0.vendor == "Google" && $0.title.localizedCaseInsensitiveContains("Doorbell") })
    }

    func testResolvesUpcOuiAndRadioModuleFccWarnings() {
        let upcHits = index.querySuggestions(rawQuery: "817882027373")
        XCTAssertEqual(upcHits.first?.model, "UDM-Pro")

        let macHits = index.querySuggestions(rawQuery: "74:83:C2:9E:11")
        XCTAssertEqual(macHits.first?.vendor, "Ubiquiti")

        let fccHits = index.querySuggestions(rawQuery: "2AC7Z-ESP32")
        let fccClue = fccHits.first { $0.kind == .identifier }
        XCTAssertNotNil(fccClue)
        XCTAssertNotNil(fccClue?.warningNote)
    }

    func testZeroTurnLocalResolutionAndUnknownMiss() throws {
        let doorbellType = try XCTUnwrap(index.querySuggestions(rawQuery: "doorbell").first { $0.kind == .deviceType })
        let googleBrand = try XCTUnwrap(index.querySuggestions(rawQuery: "google").first { $0.kind == .brand })
        let nestBattery = try XCTUnwrap(index.contextualQuickPicks([doorbellType, googleBrand]).first {
            $0.title.localizedCaseInsensitiveContains("Battery")
        })

        let exactRes = index.resolveLocalDiscoveryResult(
            selected: [doorbellType, googleBrand, nestBattery],
            accumulatedIdentifiers: ExtractedDeviceIdentifiers(),
            manualDeviceName: "Front Porch Doorbell"
        )
        XCTAssertNotNil(exactRes)
        XCTAssertEqual(exactRes?.usedLiveGeminiApi, false)
        XCTAssertEqual(exactRes?.candidates.count, 1)
        XCTAssertEqual(exactRes?.candidates.first?.manufacturer, "Google")
        XCTAssertEqual(exactRes?.candidates.first?.confidencePercent, 99)
        XCTAssertEqual(exactRes?.candidates.first?.suggestedHostname, "Front Porch Doorbell")
        XCTAssertEqual(exactRes?.candidates.first?.goldAlignment?.aligned, true)

        let unknownCustom = index.classifyFreeTextClue("UnknownFutureModel-9999X")
        XCTAssertNil(index.resolveLocalDiscoveryResult(selected: [unknownCustom], accumulatedIdentifiers: ExtractedDeviceIdentifiers()))
    }

    func testReconcilesHallucinatedIrRemoteAndPreservesUsbOnlyExclusion() {
        let taintedTurn = GeminiDiscoveryTurnResult(
            visualSummary: "A small square brushed-silver Sharp MX-M453N module.",
            isNetworkedDevice: false,
            outOfScopeReason: "The Sharp MX-M453N is an infrared remote-control receiver module.",
            candidates: [
                DeviceCandidateMatch(
                    manufacturer: "Sharp",
                    modelNumber: "MX-M453N",
                    displayName: "[Center] Sharp MX-M453N IR remote module",
                    deviceCategory: "IR Remote Module",
                    confidencePercent: 92,
                    reasoning: "Sharp MX-M453N appears to be an infrared remote module.",
                    suggestedHostname: "sharp-mx-m453n",
                    suggestedOsDetails: "Unknown",
                    suggestedPackageManager: "none",
                    goldAlignment: GoldAlignmentInfo(aligned: false, statusLabel: "UNALIGNED RAW MATCH")
                )
            ]
        )

        let reconciled = index.reconcileDiscoveryResult(taintedTurn)
        XCTAssertTrue(reconciled.isNetworkedDevice)
        XCTAssertNil(reconciled.outOfScopeReason)
        XCTAssertEqual(reconciled.candidates.first?.goldAlignment?.aligned, true)
        XCTAssertEqual(reconciled.candidates.first?.goldAlignment?.statusLabel, "GOLD ALIGNED")

        let usbReason = "Brother HL-L2400D is a USB-only mono laser printer."
        let usbTurn = GeminiDiscoveryTurnResult(
            visualSummary: "Brother HL-L2400D desktop laser printer with USB-B port.",
            isNetworkedDevice: false,
            outOfScopeReason: usbReason,
            candidates: [
                DeviceCandidateMatch(
                    manufacturer: "Brother",
                    modelNumber: "HL-L2400D",
                    displayName: "Brother HL-L2400D",
                    deviceCategory: "Printer",
                    confidencePercent: 94,
                    reasoning: usbReason,
                    suggestedHostname: "usb-printer",
                    suggestedOsDetails: "Embedded Printer",
                    suggestedPackageManager: "firmware",
                    goldAlignment: GoldAlignmentInfo(aligned: false, statusLabel: "UNALIGNED RAW MATCH")
                )
            ]
        )

        let usbReconciled = index.reconcileDiscoveryResult(usbTurn)
        XCTAssertFalse(usbReconciled.isNetworkedDevice)
        XCTAssertEqual(usbReconciled.outOfScopeReason, usbReason)
        XCTAssertEqual(usbReconciled.candidates.first?.goldAlignment?.aligned, false)
    }

    func testInferFromDeviceNameMatchesGoldModelAndSkipsSelected() throws {
        let inferred = try XCTUnwrap(GoldClueSuggestionRepository.shared.inferFromDeviceName("My Living Room UDM-Pro", selected: []))
        XCTAssertEqual(inferred.kind, .model)
        XCTAssertEqual(inferred.model, "UDM-Pro")

        let alreadySelected = GoldClueSuggestionRepository.shared.inferFromDeviceName("My Living Room UDM-Pro", selected: [inferred])
        XCTAssertNil(alreadySelected)
    }
}
