import XCTest
@testable import TuesdayApp

final class DomainEvaluatorsTests: XCTestCase {

    private func makeDevice(
        id: String,
        name: String,
        state: PortLifecycleState,
        category: StnHardwareCategory = .C1_GATEWAY
    ) -> RackPortDevice {
        RackPortDevice(
            id: id,
            portIndex: 0,
            portState: state,
            trustZone: .z0Core,
            category: category,
            assetTag: "",
            shortLabel: String(name.prefix(8)).uppercased(),
            name: name,
            roomLocation: "Network Closet",
            version: "4.0.6",
            lifecycleTier: "Active",
            purls: ["pkg:generic/ui/unifi-os@4.0.6"],
            proHeadline: "",
            stnHeadline: ""
        )
    }

    private func makeBulletin(id: String, type: String, title: String) -> BulletinInboxView {
        BulletinInboxView(
            externalId: id,
            feedSlug: "ubiquiti-advisories",
            bulletinType: type,
            isHighSev: true,
            brokeThroughMute: false,
            matchedByGuess: false,
            candidateModels: [],
            title: title,
            body: "Summary for \(title)",
            publishedAt: "2026-11-10"
        )
    }

    private func makeAttestation(deviceId: String, auditDate: String) -> DeviceAttestation {
        DeviceAttestation(
            id: "att-\(deviceId)",
            deviceId: deviceId,
            auditDate: auditDate,
            attestedBy: "Test Auditor",
            type: .annualAudit,
            presenceState: .active
        )
    }

    private func makeCandle(
        id: String = "dev-1",
        deployEndNorm: Double = 0.72,
        vendorEolNorm: Double = 0.95,
        presenceState: DevicePresenceState = .active,
        hasCveOrRecall: Bool = false,
        latestAttestation: DeviceAttestation? = nil
    ) -> OperationalCandle {
        OperationalCandle(
            id: id,
            shortLabel: "UDM-PRO",
            name: "UniFi Dream Machine Pro",
            version: "4.0.20",
            trustZone: .z0Core,
            presenceState: presenceState,
            hasCveOrRecall: hasCveOrRecall,
            isPastEol: deployEndNorm > vendorEolNorm,
            isEolNearing: deployEndNorm <= vendorEolNorm && (vendorEolNorm - deployEndNorm) < 0.12,
            isGuessed: false,
            isRetired: presenceState == .retired,
            marketReleaseNorm: 0.20,
            deployStartNorm: 0.35,
            deployEndNorm: deployEndNorm,
            vendorEolNorm: vendorEolNorm,
            cveStartNorm: nil,
            releaseLabel: "2024-02-01",
            eolLabel: "2030-06-01",
            latestAttestation: latestAttestation,
            attestationCount: latestAttestation == nil ? 0 : 1
        )
    }

    func testRhythmPostureEvaluatorHandlesDayZeroHealthyAndActiveFindings() {
        XCTAssertTrue(RhythmPostureEvaluator.hasActiveRecommendation(devices: [], welcomeComplete: false))
        let dayZeroPro = RhythmPostureEvaluator.evaluatePosture(
            flavor: .tuesdayPro,
            devices: [],
            bulletins: [],
            welcomeComplete: false
        )
        XCTAssertEqual(dayZeroPro.count, 4)
        XCTAssertNil(dayZeroPro[0].action)
        XCTAssertNotNil(dayZeroPro[1].action)
        XCTAssertNil(dayZeroPro[2].action)
        XCTAssertNil(dayZeroPro[3].action)

        let okFleet = [makeDevice(id: "d1", name: "UDM-Pro", state: .ok)]
        XCTAssertFalse(RhythmPostureEvaluator.hasActiveRecommendation(devices: okFleet, welcomeComplete: true))
        let healthyItems = RhythmPostureEvaluator.evaluatePosture(
            flavor: .sureThingHome,
            devices: okFleet,
            bulletins: [],
            welcomeComplete: true
        )
        XCTAssertTrue(healthyItems.allSatisfy { $0.action == nil && $0.recommendation == nil })

        let mixedFleet = [
            makeDevice(id: "d1", name: "Mystery Plug", state: .guessed, category: .C6_IOT),
            makeDevice(id: "d2", name: "EdgeRouter X", state: .cveKev, category: .C1_GATEWAY),
            makeDevice(id: "d3", name: "AirPort Extreme", state: .eol, category: .C3_AP)
        ]
        let bulletins = [
            makeBulletin(id: "b1", type: "RECALL", title: "Smart Plug Thermal Recall"),
            makeBulletin(id: "b2", type: "CISA_KEV", title: "CVE-2026-1001 Actively Exploited")
        ]
        XCTAssertTrue(RhythmPostureEvaluator.hasActiveRecommendation(devices: mixedFleet, welcomeComplete: true))

        let proPosture = RhythmPostureEvaluator.evaluatePosture(
            flavor: .tuesdayPro,
            devices: mixedFleet,
            bulletins: bulletins,
            welcomeComplete: true
        )
        let homePosture = RhythmPostureEvaluator.evaluatePosture(
            flavor: .sureThingHome,
            devices: mixedFleet,
            bulletins: bulletins,
            welcomeComplete: true
        )

        XCTAssertTrue(proPosture.allSatisfy { $0.action != nil && $0.recommendation != nil })
        XCTAssertTrue(proPosture[0].title.contains("NEW HARDWARE INTAKE"))
        XCTAssertTrue(homePosture[0].title.contains("New Devices & Recognition"))
        XCTAssertTrue(proPosture[3].recommendation?.contains("Guest VLAN") == true)
        XCTAssertTrue(homePosture[3].recommendation?.contains("unplugging") == true)

        let shareReport = RhythmPostureEvaluator.formatShareReport(flavor: .tuesdayPro, items: proPosture)
        XCTAssertTrue(shareReport.contains("Tuesday.sh (STN-Pro) Fleet Check-Up"))
        XCTAssertTrue(shareReport.contains("⚠️ Action Needed"))
    }

    func testEntitlementGatePolicyIgnoresDemoSandboxAndGatesSecondSite() {
        let demoOnly = [
            NetworkSite(id: "net-demo", name: "Demo Sandbox", devicesCount: 12, role: "owner")
        ]
        let oneRealPlusDemo = [
            NetworkSite(id: "net-home", name: "Seattle Home", devicesCount: 8, role: "owner"),
            NetworkSite(id: "net-demo", name: "Demo Sandbox", devicesCount: 12, role: "owner")
        ]

        XCTAssertEqual(EntitlementGatePolicy.realNetworkCount(demoOnly), 0)
        XCTAssertTrue(EntitlementGatePolicy.canCreateAdditionalNetwork(tier: "free", networks: demoOnly))
        XCTAssertFalse(EntitlementGatePolicy.requiresUpgradeForNewSite(tier: "free", networks: demoOnly))

        XCTAssertEqual(EntitlementGatePolicy.realNetworkCount(oneRealPlusDemo), 1)
        XCTAssertFalse(EntitlementGatePolicy.canCreateAdditionalNetwork(tier: "free", networks: oneRealPlusDemo))
        XCTAssertTrue(EntitlementGatePolicy.requiresUpgradeForNewSite(tier: nil, networks: oneRealPlusDemo))

        XCTAssertTrue(EntitlementGatePolicy.canCreateAdditionalNetwork(tier: "pro_tier_1", networks: oneRealPlusDemo))
        XCTAssertTrue(EntitlementGatePolicy.canCreateAdditionalNetwork(tier: "multisite_tier_1", networks: oneRealPlusDemo))
        XCTAssertTrue(EntitlementGatePolicy.canCreateAdditionalNetwork(tier: "FLEET", networks: oneRealPlusDemo))
    }

    func testBarcodeIdentifierParserNormalizesEan13AndPreserves2DMatrices() {
        let upc = BarcodeIdentifierParser.parse(rawValue: " 0817882027373 ", metadataType: .ean13)
        XCTAssertEqual(upc?.normalizedValue, "817882027373")
        XCTAssertEqual(upc?.is2DMatrix, false)

        let intlEan = BarcodeIdentifierParser.parse(rawValue: "4902370519969", metadataType: .ean13)
        XCTAssertEqual(intlEan?.normalizedValue, "4902370519969")
        XCTAssertEqual(intlEan?.is2DMatrix, false)

        let qrZero = BarcodeIdentifierParser.parse(rawValue: "0123456789012", metadataType: .qr)
        XCTAssertEqual(qrZero?.normalizedValue, "0123456789012")
        XCTAssertEqual(qrZero?.is2DMatrix, true)

        XCTAssertNil(BarcodeIdentifierParser.parse(rawValue: "   ", metadataType: .code128))
    }

    func testManualEnrollmentResolverSynthesizesGoldVerifiedAndProvisional() {
        XCTAssertNil(
            ManualEnrollmentResolver.resolve(
                manualHostname: "   ",
                selectedClues: [],
                accumulatedIdentifiers: ExtractedDeviceIdentifiers()
            )
        )

        let modelClue = GoldClueItem(
            id: "model:udm-pro",
            kind: .model,
            title: "Ubiquiti UDM-Pro",
            subtitle: "Router / Gateway • C3",
            chipLabel: "Ubiquiti UDM-Pro",
            vendor: "Ubiquiti",
            model: "UDM-Pro",
            categoryCode: "C3",
            upc: "810010073006"
        )
        let goldResolved = ManualEnrollmentResolver.resolve(
            manualHostname: "",
            selectedClues: [modelClue],
            accumulatedIdentifiers: ExtractedDeviceIdentifiers(
                serialNumber: "SN-UDM-99",
                macAddress: "74:83:C2:00:11:22"
            )
        )
        XCTAssertEqual(goldResolved?.hostname, "Ubiquiti UDM-Pro")
        XCTAssertEqual(goldResolved?.inventoryState, .enrolled)
        XCTAssertTrue(goldResolved?.osSummary.contains("Gold Verified") == true)
        XCTAssertEqual(goldResolved?.metadata.manufacturer, "Ubiquiti")
        XCTAssertEqual(goldResolved?.metadata.modelNumber, "UDM-Pro")
        XCTAssertEqual(goldResolved?.metadata.macAddress, "74:83:C2:00:11:22")
        XCTAssertEqual(goldResolved?.metadata.serialNumber, "SN-UDM-99")
        XCTAssertEqual(goldResolved?.metadata.barcodeOrQr, "810010073006")
    }

    func testTimelineStatusEvaluatorComputesRunwayAndClamping() {
        XCTAssertFalse(TimelineStatusEvaluator.isAnnualCheckInDue(latestAuditDate: "2026-03-15", referenceYearPrefix: "2026"))
        XCTAssertTrue(TimelineStatusEvaluator.isAnnualCheckInDue(latestAuditDate: "2025-11-10", referenceYearPrefix: "2026"))
        XCTAssertTrue(TimelineStatusEvaluator.isAnnualCheckInDue(latestAuditDate: nil, referenceYearPrefix: "2026"))

        let att = makeAttestation(deviceId: "dev-ok", auditDate: "2026-04-01")
        let healthy = TimelineStatusEvaluator.evaluateCandleStatus(
            candle: makeCandle(id: "dev-ok", latestAttestation: att),
            attestations: [],
            referenceYearPrefix: "2026"
        )
        XCTAssertEqual(healthy.statusText, "ACTIVE • SUPPORTED RUNWAY")
        XCTAssertFalse(healthy.needsStatusCheck)

        let pastEol = TimelineStatusEvaluator.evaluateCandleStatus(
            candle: makeCandle(id: "dev-eol", deployEndNorm: 0.85, vendorEolNorm: 0.65, latestAttestation: att),
            attestations: [],
            referenceYearPrefix: "2026"
        )
        XCTAssertEqual(pastEol.statusText, "ZOMBIE HARDWARE • PAST EOL")
        XCTAssertTrue(pastEol.needsStatusCheck)

        XCTAssertEqual(TimelineStatusEvaluator.formatScrubberCursorDate(scrubberXNorm: 0.72), "2026-11-11 (TODAY)")
        XCTAssertEqual(TimelineStatusEvaluator.formatScrubberCursorDate(scrubberXNorm: 0.62), "2026-11-11 (-12d)")
        XCTAssertEqual(TimelineStatusEvaluator.formatScrubberCursorDate(scrubberXNorm: 0.82), "2026-11-11 (+12d projection)")

        XCTAssertEqual(TimelineStatusEvaluator.clampPopoverArrowFraction(anchorXInStripPx: 0, stripWidthPx: 300), 0.08, accuracy: 0.0001)
        XCTAssertEqual(TimelineStatusEvaluator.clampPopoverArrowFraction(anchorXInStripPx: 9999, stripWidthPx: 300), 0.92, accuracy: 0.0001)
        XCTAssertEqual(TimelineStatusEvaluator.clampPopoverArrowFraction(anchorXInStripPx: 100, stripWidthPx: 0), 0.5, accuracy: 0.0001)
    }

    func testVisionImageDownscaleRespects1024PxAndEdgePayloadBudget() throws {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let bigImage = UIGraphicsImageRenderer(size: CGSize(width: 3000, height: 2000), format: format).image { ctx in
            UIColor.darkGray.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 3000, height: 2000))
            UIColor.orange.setFill()
            ctx.fill(CGRect(x: 300, y: 300, width: 1200, height: 600))
        }

        let b64 = try XCTUnwrap(GeminiDeviceDiscoveryService.downscaleAndEncode(bigImage))
        XCTAssertLessThanOrEqual(b64.utf8.count, 380_000)

        let rawData = try XCTUnwrap(Data(base64Encoded: b64))
        let decoded = try XCTUnwrap(UIImage(data: rawData))
        XCTAssertLessThanOrEqual(decoded.size.width * decoded.scale, 1024.0)
        XCTAssertLessThanOrEqual(decoded.size.height * decoded.scale, 1024.0)
    }

    func testParseBackendDiscoveryResponseSupportsEdgeAndRailsCamelCase() throws {
        let edgeJson = """
        {
          "visualSummary": "Matched Ubiquiti Inc. UDM-Pro in Tier 0 Edge Gold Catalog.",
          "nextNarrowingQuestion": "Exact model matched.",
          "recommendedClueTypes": ["Model", "MAC Address"],
          "extractedIdentifiersObject": {"model": "UDM-Pro"},
          "candidates": [{
            "manufacturer": "Ubiquiti Inc.",
            "modelNumber": "UDM-Pro",
            "displayName": "UniFi Dream Machine Pro (UDM-Pro)",
            "category": "Router / Security Gateway",
            "confidencePercent": 98,
            "suggestedHostname": "unifi-udm-pro",
            "osDetails": "UniFi OS 4.0.20 (Debian 12 apt)",
            "pkgManager": "apt",
            "reasoning": "Tier 0 Edge short-circuit."
          }],
          "providerLabel": "Tuesday Edge (Catalog $0 Short-Circuit • 1ms)"
        }
        """.data(using: .utf8)!

        let edgeParsed = try XCTUnwrap(GeminiDeviceDiscoveryService.parseBackendDiscoveryResponse(edgeJson))
        XCTAssertTrue(edgeParsed.usedLiveGeminiApi)
        XCTAssertEqual(edgeParsed.extractedIdentifiers.modelNumber, "UDM-Pro")
        XCTAssertEqual(edgeParsed.candidates.first?.deviceCategory, "Router / Security Gateway")
        XCTAssertEqual(edgeParsed.candidates.first?.suggestedOsDetails, "UniFi OS 4.0.20 (Debian 12 apt)")
        XCTAssertEqual(edgeParsed.candidates.first?.suggestedPackageManager, "apt")
        XCTAssertEqual(edgeParsed.candidates.first?.confidencePercent, 98)

        let railsJson = """
        {
          "visualSummary": "Detected Synology DiskStation NAS front bezel.",
          "isNetworkedDevice": true,
          "nextPromptForUser": "Confirm DS923+ vs DS920+ on base sticker.",
          "extractedIdentifiers": {
            "barcode": "846504004423",
            "macAddress": "00:11:32:AA:BB:CC"
          },
          "candidates": [{
            "manufacturer": "Synology",
            "modelNumber": "DS923+",
            "displayName": "Synology DiskStation DS923+",
            "deviceCategory": "Compute / Server",
            "confidencePercent": 91,
            "suggestedHostname": "synology-ds923plus",
            "suggestedOsDetails": {"osName": "DSM", "osVersion": "7.2"},
            "suggestedPackageManager": "spk",
            "goldAlignment": {
              "aligned": true,
              "inferredPurl": "pkg:generic/synology/ds923plus",
              "statusLabel": "GOLD ALIGNED"
            }
          }],
          "debugTrace": ["Turn 1: Elastix qwen3.8-27b 1.4s"]
        }
        """.data(using: .utf8)!

        let railsParsed = try XCTUnwrap(GeminiDeviceDiscoveryService.parseBackendDiscoveryResponse(railsJson))
        XCTAssertEqual(railsParsed.extractedIdentifiers.barcode, "846504004423")
        XCTAssertEqual(railsParsed.extractedIdentifiers.macAddress, "00:11:32:AA:BB:CC")
        XCTAssertEqual(railsParsed.nextNarrowingQuestion, "Confirm DS923+ vs DS920+ on base sticker.")
        XCTAssertEqual(railsParsed.candidates.first?.suggestedOsDetails, "DSM 7.2")
        XCTAssertEqual(railsParsed.candidates.first?.goldAlignment?.aligned, true)
        XCTAssertEqual(railsParsed.candidates.first?.goldAlignment?.inferredPurl, "pkg:generic/synology/ds923plus")
        XCTAssertEqual(railsParsed.debugTrace, "Turn 1: Elastix qwen3.8-27b 1.4s")
    }

    func testHardwareCategoryInferenceClassifiesLaptopsEvenWithGenericC8Hint() {
        XCTAssertEqual(
            StnHardwareCategory.fromDiscoveryHint("surface-laptop-go Microsoft Surface Microsoft Surface Laptop Go C8 • IoT / Hub / Misc"),
            .C7_CLIENT
        )
        XCTAssertEqual(
            StnHardwareCategory.fromDiscoveryHint("UDM-Pro Ubiquiti Router / Gateway"),
            .C1_GATEWAY
        )
        XCTAssertEqual(
            StnHardwareCategory.fromDiscoveryHint("C8 • Guest / Media"),
            .C8_GUEST
        )
        XCTAssertEqual(
            StnHardwareCategory.fromDiscoveryHint("Synology DS923+ NAS"),
            .C4_SERVER
        )
    }
}
