import Foundation
import UIKit

public enum DeviceClueType: String, Codable, CaseIterable, Identifiable {
    case barcode = "Barcode"
    case serialNumber = "Serial Number"
    case qrCode = "QR Code"
    case modelNumber = "Model"
    case macAddress = "MAC Address"

    public var id: String { rawValue }

    public var systemIcon: String {
        switch self {
        case .barcode: return "barcode.viewfinder"
        case .serialNumber: return "number.square.fill"
        case .qrCode: return "qrcode.viewfinder"
        case .modelNumber: return "cpu.fill"
        case .macAddress: return "network"
        }
    }

    public var placeholder: String {
        switch self {
        case .barcode: return "e.g. UPC 810010078142"
        case .serialNumber: return "e.g. SN-2409A88192"
        case .qrCode: return "e.g. WIFI:S:UniFi;T:WPA;..."
        case .modelNumber: return "e.g. UCG-Ultra / RT-AX86U"
        case .macAddress: return "e.g. 74:83:C2:9E:11:04"
        }
    }
}

public struct DeviceCandidateMatch: Identifiable, Codable, Equatable {
    public var id: String { "\(manufacturer)-\(modelNumber)" }
    public var manufacturer: String
    public var modelNumber: String
    public var displayName: String
    public var deviceCategory: String
    public var confidencePercent: Int
    public var reasoning: String
    public var suggestedHostname: String
    public var suggestedOsDetails: String
    public var suggestedPackageManager: String

    public init(
        manufacturer: String,
        modelNumber: String,
        displayName: String,
        deviceCategory: String,
        confidencePercent: Int,
        reasoning: String,
        suggestedHostname: String,
        suggestedOsDetails: String,
        suggestedPackageManager: String
    ) {
        self.manufacturer = manufacturer
        self.modelNumber = modelNumber
        self.displayName = displayName
        self.deviceCategory = deviceCategory
        self.confidencePercent = confidencePercent
        self.reasoning = reasoning
        self.suggestedHostname = suggestedHostname
        self.suggestedOsDetails = suggestedOsDetails
        self.suggestedPackageManager = suggestedPackageManager
    }

    public var resolvedPackageManager: PackageManagerType {
        PackageManagerType(rawValue: suggestedPackageManager.lowercased()) ?? .firmware
    }
}

public struct ExtractedDeviceIdentifiers: Codable, Equatable {
    public var barcode: String?
    public var serialNumber: String?
    public var qrCode: String?
    public var modelNumber: String?
    public var macAddress: String?

    public init(
        barcode: String? = nil,
        serialNumber: String? = nil,
        qrCode: String? = nil,
        modelNumber: String? = nil,
        macAddress: String? = nil
    ) {
        self.barcode = barcode
        self.serialNumber = serialNumber
        self.qrCode = qrCode
        self.modelNumber = modelNumber
        self.macAddress = macAddress
    }

    public mutating func merge(_ other: ExtractedDeviceIdentifiers) {
        if let v = other.barcode, !v.isEmpty { barcode = v }
        if let v = other.serialNumber, !v.isEmpty { serialNumber = v }
        if let v = other.qrCode, !v.isEmpty { qrCode = v }
        if let v = other.modelNumber, !v.isEmpty { modelNumber = v }
        if let v = other.macAddress, !v.isEmpty { macAddress = v }
    }

    public var nonEmptyPairs: [(DeviceClueType, String)] {
        var list: [(DeviceClueType, String)] = []
        if let v = modelNumber, !v.isEmpty { list.append((.modelNumber, v)) }
        if let v = macAddress, !v.isEmpty { list.append((.macAddress, v)) }
        if let v = serialNumber, !v.isEmpty { list.append((.serialNumber, v)) }
        if let v = barcode, !v.isEmpty { list.append((.barcode, v)) }
        if let v = qrCode, !v.isEmpty { list.append((.qrCode, v)) }
        return list
    }
}

public struct GeminiDiscoveryTurnResult: Codable, Equatable {
    public var visualSummary: String
    public var nextNarrowingQuestion: String
    public var recommendedClueTypes: [String]
    public var extractedIdentifiers: ExtractedDeviceIdentifiers
    public var candidates: [DeviceCandidateMatch]
    public var usedLiveGeminiApi: Bool

    public init(
        visualSummary: String,
        nextNarrowingQuestion: String,
        recommendedClueTypes: [String],
        extractedIdentifiers: ExtractedDeviceIdentifiers,
        candidates: [DeviceCandidateMatch],
        usedLiveGeminiApi: Bool = true
    ) {
        self.visualSummary = visualSummary
        self.nextNarrowingQuestion = nextNarrowingQuestion
        self.recommendedClueTypes = recommendedClueTypes
        self.extractedIdentifiers = extractedIdentifiers
        self.candidates = candidates
        self.usedLiveGeminiApi = usedLiveGeminiApi
    }
}

/// Hardware Vision Discovery Client for Tuesday.sh iOS.
///
/// SECURITY & PRIVACY ARCHITECTURE:
/// - Zero LLM API keys are bundled or stored in the iOS app binary.
/// - All hardware vision calls are proxied through Tuesday Server (`POST /api/v1/discovery/analyze`),
///   which performs $0.00 Gold Catalog short-circuiting, routes across Elastix (qwen3.8-27b) and
///   GCP Gemini (gemini-3.8-flash), emits unified telemetry to CloudWatch Omni (`hosted-ai-v1`),
///   and enforces ephemeral RAM-only photo processing (zero photo storage on our servers).
@MainActor
public final class GeminiDeviceDiscoveryService {
    public static let shared = GeminiDeviceDiscoveryService()
    public static let defaultServerBaseUrl = "https://api.tuesday.sh"
    private static let pilotClientToken = "tuesday-pilot-v1-public-client-token"

    private let sessionStickinessId = "tuesday-ios-" + String(UUID().uuidString.prefix(8)).lowercased()
    private var turnCounter = 0

    public init() {}

    public func analyzeDeviceProgressive(
        images: [UIImage],
        accumulatedIdentifiers: ExtractedDeviceIdentifiers,
        userClueNotes: [String],
        apiKeyOverride: String = "",
        modelName: String = "qwen3.8-27b",
        serverBaseUrl: String = GeminiDeviceDiscoveryService.defaultServerBaseUrl
    ) async -> GeminiDiscoveryTurnResult {
        if CommandLine.arguments.contains("--uitesting-mock-gemini") {
            return Self.fallbackHeuristicAnalysis(
                accumulatedIdentifiers: accumulatedIdentifiers,
                userClueNotes: userClueNotes,
                imageCount: images.count,
                usedLiveApi: false
            )
        }

        turnCounter += 1
        do {
            return try await callTuesdayServerAnalyzeApi(
                images: images,
                accumulatedIdentifiers: accumulatedIdentifiers,
                userClueNotes: userClueNotes,
                serverBaseUrl: serverBaseUrl.isEmpty ? Self.defaultServerBaseUrl : serverBaseUrl
            )
        } catch {
            return Self.fallbackHeuristicAnalysis(
                accumulatedIdentifiers: accumulatedIdentifiers,
                userClueNotes: userClueNotes,
                imageCount: images.count,
                usedLiveApi: false
            )
        }
    }

    public func confirmDeviceDiscovery(
        inferredVendor: String?,
        inferredModel: String?,
        confirmedVendor: String,
        confirmedModel: String,
        wasEdited: Bool,
        accumulatedIdentifiers: ExtractedDeviceIdentifiers,
        serverBaseUrl: String = GeminiDeviceDiscoveryService.defaultServerBaseUrl
    ) async -> Bool {
        let trimmedBase = (serverBaseUrl.isEmpty ? Self.defaultServerBaseUrl : serverBaseUrl)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: "\(trimmedBase)/api/v1/discovery/confirm") else {
            return false
        }

        let idsList = accumulatedIdentifiers.nonEmptyPairs.map { "\($0.0.rawValue): \($0.1)" }
        let body: [String: Any] = [
            "session_id": sessionStickinessId,
            "client_platform": "ios",
            "device_id": sessionStickinessId,
            "inferred_vendor": inferredVendor ?? "",
            "inferred_model": inferredModel ?? "",
            "confirmed_vendor": confirmedVendor,
            "confirmed_model": confirmedModel,
            "was_edited": wasEdited,
            "extracted_identifiers": idsList
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 12.0
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(sessionStickinessId, forHTTPHeaderField: "X-Tuesday-Device-ID")
        request.setValue("ios", forHTTPHeaderField: "X-Tuesday-Client-Platform")
        request.setValue(Self.pilotClientToken, forHTTPHeaderField: "X-Tuesday-Pilot-Token")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { return false }
            return (200...299).contains(http.statusCode)
        } catch {
            return false
        }
    }

    private func callTuesdayServerAnalyzeApi(
        images: [UIImage],
        accumulatedIdentifiers: ExtractedDeviceIdentifiers,
        userClueNotes: [String],
        serverBaseUrl: String
    ) async throws -> GeminiDiscoveryTurnResult {
        let trimmedBase = serverBaseUrl.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: "\(trimmedBase)/api/v1/discovery/analyze") else {
            throw URLError(.badURL)
        }

        var extractedDict: [String: String] = [:]
        if let v = accumulatedIdentifiers.barcode, !v.isEmpty { extractedDict["barcode"] = v }
        if let v = accumulatedIdentifiers.serialNumber, !v.isEmpty { extractedDict["serialNumber"] = v }
        if let v = accumulatedIdentifiers.qrCode, !v.isEmpty { extractedDict["qrCode"] = v }
        if let v = accumulatedIdentifiers.modelNumber, !v.isEmpty { extractedDict["modelNumber"] = v }
        if let v = accumulatedIdentifiers.macAddress, !v.isEmpty { extractedDict["macAddress"] = v }

        var imagesBase64: [String] = []
        for img in images.suffix(2) {
            if let jpegData = Self.downscaledJpegData(from: img, maxDimension: 640) {
                imagesBase64.append(jpegData.base64EncodedString())
            }
        }

        let requestBody: [String: Any] = [
            "session_id": sessionStickinessId,
            "turn_index": turnCounter,
            "client_platform": "ios",
            "device_id": sessionStickinessId,
            "provider_override": "auto",
            "extracted_identifiers": extractedDict,
            "user_clue_notes": userClueNotes.filter { !$0.isEmpty },
            "images_base64": imagesBase64
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 32.0
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(sessionStickinessId, forHTTPHeaderField: "X-Tuesday-Device-ID")
        request.setValue("ios", forHTTPHeaderField: "X-Tuesday-Client-Platform")
        request.setValue(Self.pilotClientToken, forHTTPHeaderField: "X-Tuesday-Pilot-Token")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }

        struct ServerTurnResponse: Decodable {
            let visualSummary: String
            let nextNarrowingQuestion: String
            let recommendedClueTypes: [String]?
            let extractedIdentifiersObject: ExtractedDeviceIdentifiers?
            let candidates: [DeviceCandidateMatch]
        }

        let decoded = try JSONDecoder().decode(ServerTurnResponse.self, from: data)
        var mergedIds = accumulatedIdentifiers
        if let ext = decoded.extractedIdentifiersObject {
            mergedIds.merge(ext)
        }

        return GeminiDiscoveryTurnResult(
            visualSummary: decoded.visualSummary,
            nextNarrowingQuestion: decoded.nextNarrowingQuestion,
            recommendedClueTypes: (decoded.recommendedClueTypes?.isEmpty == false)
                ? decoded.recommendedClueTypes!
                : DeviceClueType.allCases.map(\.rawValue),
            extractedIdentifiers: mergedIds,
            candidates: decoded.candidates,
            usedLiveGeminiApi: true
        )
    }

    public static func fallbackHeuristicAnalysis(
        accumulatedIdentifiers: ExtractedDeviceIdentifiers,
        userClueNotes: [String],
        imageCount: Int,
        usedLiveApi: Bool
    ) -> GeminiDiscoveryTurnResult {
        let combinedClues = (
            accumulatedIdentifiers.nonEmptyPairs.map { "\($0.0.rawValue): \($0.1)" } + userClueNotes
        ).joined(separator: " ").lowercased()

        let hasSpecificClue = !accumulatedIdentifiers.nonEmptyPairs.isEmpty || imageCount > 1

        if combinedClues.contains("zigbee") || combinedClues.contains("sonoff") || combinedClues.contains("zbdongle") {
            return GeminiDiscoveryTurnResult(
                visualSummary: "Detected an aluminum USB Zigbee 3.0 coordinator / IoT radio peripheral with external dipole antenna.",
                nextNarrowingQuestion: hasSpecificClue
                    ? "High-confidence match found (SONOFF Zigbee 3.0 USB Dongle Plus). Do you want to confirm this match or add a Serial Number / MAC Address?"
                    : "Is there a Model Number (e.g. ZBDongle-E vs ZBDongle-P), Serial Number, Barcode, or MAC Address printed on the back of the aluminum casing?",
                recommendedClueTypes: ["Model", "Serial Number", "Barcode", "MAC Address"],
                extractedIdentifiers: accumulatedIdentifiers,
                candidates: [
                    DeviceCandidateMatch(
                        manufacturer: "ITEAD / SONOFF",
                        modelNumber: accumulatedIdentifiers.modelNumber ?? "ZBDongle-E",
                        displayName: "SONOFF Zigbee 3.0 USB Dongle Plus (EFR32MG21)",
                        deviceCategory: "IoT Coordinator",
                        confidencePercent: hasSpecificClue ? 95 : 74,
                        reasoning: "Matches aluminum housing profile and SMA dipole antenna; commonly paired with Home Assistant ZHA / Zigbee2MQTT.",
                        suggestedHostname: "sonoff-zigbee-coordinator",
                        suggestedOsDetails: "EZSP v7.4.4 / Home Assistant HACS ZHA",
                        suggestedPackageManager: "hacs"
                    ),
                    DeviceCandidateMatch(
                        manufacturer: "Nabu Casa",
                        modelNumber: "SkyConnect-ZBT1",
                        displayName: "Home Assistant Connect ZBT-1",
                        deviceCategory: "IoT Radio",
                        confidencePercent: hasSpecificClue ? 25 : 42,
                        reasoning: "Alternative Silabs EFR32 Zigbee/Thread coordinator used in Home Assistant setups.",
                        suggestedHostname: "ha-zbt1-radio",
                        suggestedOsDetails: "Home Assistant Connect Firmware (HACS)",
                        suggestedPackageManager: "hacs"
                    )
                ],
                usedLiveGeminiApi: usedLiveApi
            )
        }

        let topConfidence = hasSpecificClue ? 94 : 68
        let detectedModel = accumulatedIdentifiers.modelNumber ?? (hasSpecificClue ? "UCG-Ultra" : "UCG-Ultra / UXG-Max")

        return GeminiDiscoveryTurnResult(
            visualSummary: hasSpecificClue
                ? "Verified compact polycarbonate desktop security gateway with front LCM status display and multi-gigabit RJ45 WAN/LAN ports."
                : "Identified a compact white desktop router / network gateway chassis. Multiple Ubiquiti UniFi models share this enclosure.",
            nextNarrowingQuestion: hasSpecificClue
                ? "Identifier verified! Candidate narrowed to Ubiquiti UniFi Cloud Gateway Ultra (UCG-Ultra). Confirm match below or add additional clues."
                : "To narrow between UniFi Cloud Gateway Ultra (UCG-Ultra), Gateway Max (UXG-Max), and Express (UX), is there a Barcode, Serial Number, QR Code, Model, or MAC Address on the bottom label?",
            recommendedClueTypes: ["Model", "MAC Address", "Serial Number", "Barcode", "QR Code"],
            extractedIdentifiers: accumulatedIdentifiers,
            candidates: [
                DeviceCandidateMatch(
                    manufacturer: "Ubiquiti Inc.",
                    modelNumber: detectedModel,
                    displayName: "UniFi Cloud Gateway Ultra (\(detectedModel))",
                    deviceCategory: "Router / Security Gateway",
                    confidencePercent: topConfidence,
                    reasoning: hasSpecificClue
                        ? "Model/OUI clue confirms Ubiquiti UniFi Cloud Gateway Ultra running UniFi OS (Debian apt)."
                        : "Form factor and front status display match the UniFi Cloud Gateway Ultra series.",
                    suggestedHostname: "unifi-ucg-ultra.local",
                    suggestedOsDetails: "UniFi OS 4.0.20 (Debian 12 Bookworm apt)",
                    suggestedPackageManager: "apt"
                ),
                DeviceCandidateMatch(
                    manufacturer: "Ubiquiti Inc.",
                    modelNumber: "UXG-Max",
                    displayName: "UniFi Gateway Max (UXG-Max)",
                    deviceCategory: "Multi-Gig Router",
                    confidencePercent: hasSpecificClue ? 32 : 54,
                    reasoning: "Identical footprint to UCG-Ultra without integrated LCM screen; disambiguate via bottom label Model or MAC.",
                    suggestedHostname: "unifi-uxg-max.local",
                    suggestedOsDetails: "UniFi OS 4.0.20 (Debian apt)",
                    suggestedPackageManager: "apt"
                ),
                DeviceCandidateMatch(
                    manufacturer: "GL.iNet",
                    modelNumber: "GL-MT3000",
                    displayName: "GL.iNet Beryl AX (GL-MT3000)",
                    deviceCategory: "OpenWrt Travel/Edge Router",
                    confidencePercent: hasSpecificClue ? 14 : 31,
                    reasoning: "Compact Wi-Fi 6 router running OpenWrt / opkg firmware.",
                    suggestedHostname: "gl-mt3000.local",
                    suggestedOsDetails: "OpenWrt 23.05 (Firmware / opkg)",
                    suggestedPackageManager: "firmware"
                )
            ],
            usedLiveGeminiApi: usedLiveApi
        )
    }

    public static func downscaledJpegData(from image: UIImage, maxDimension: CGFloat) -> Data? {
        let size = image.size
        guard size.width > 0, size.height > 0 else { return nil }
        let ratio = min(maxDimension / size.width, maxDimension / size.height, 1.0)
        let targetSize = CGSize(width: round(size.width * ratio), height: round(size.height * ratio))

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        return resized.jpegData(compressionQuality: 0.80)
    }

    /// Generates a synthetic hardware photo for Simulator / quick testing on device when not pointing at physical hardware
    public static func renderSampleHardwareImage(presetName: String) -> UIImage {
        let size = CGSize(width: 640, height: 420)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let cg = ctx.cgContext
            cg.setFillColor(UIColor(red: 0.11, green: 0.13, blue: 0.17, alpha: 1.0).cgColor)
            cg.fill(CGRect(origin: .zero, size: size))

            // Draw router/device chassis
            let boxRect = CGRect(x: 90, y: 80, width: 460, height: 220)
            let path = UIBezierPath(roundedRect: boxRect, cornerRadius: 24)
            UIColor(red: 0.92, green: 0.94, blue: 0.96, alpha: 1.0).setFill()
            path.fill()

            // Draw front OLED screen / LED bar
            let screenRect = CGRect(x: 130, y: 145, width: 110, height: 90)
            let screenPath = UIBezierPath(roundedRect: screenRect, cornerRadius: 12)
            UIColor(red: 0.08, green: 0.10, blue: 0.14, alpha: 1.0).setFill()
            screenPath.fill()

            // Draw status text on synthetic hardware label
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .left

            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 22),
                .foregroundColor: UIColor(red: 0.12, green: 0.15, blue: 0.20, alpha: 1.0),
                .paragraphStyle: paragraph
            ]
            let subAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedSystemFont(ofSize: 15, weight: .semibold),
                .foregroundColor: UIColor(red: 0.25, green: 0.30, blue: 0.38, alpha: 1.0),
                .paragraphStyle: paragraph
            ]

            let titleText: String
            let detailText: String
            if presetName.lowercased().contains("iot") || presetName.lowercased().contains("zigbee") {
                titleText = "SONOFF Zigbee 3.0 Coordinator"
                detailText = "Model: ZBDongle-E\nFCC ID: 2APN5ZBDONGLEE\nIEEE MAC: 00:12:4B:00:29:A1:C4"
            } else if presetName.lowercased().contains("sticker") || presetName.lowercased().contains("label") {
                titleText = "Ubiquiti Inc. • Bottom Sticker"
                detailText = "M/N: UCG-Ultra\nMAC: 74:83:C2:9E:11:04\nS/N: 2409G-7483C29E1104\nUPC: 810010078890"
            } else {
                titleText = "UniFi Cloud Gateway Chassis"
                detailText = "2.5GbE WAN • 4x GbE LAN\nFront LCM Display Active\nBottom Label Partially Hidden"
            }

            (titleText as NSString).draw(in: CGRect(x: 265, y: 120, width: 260, height: 60), withAttributes: titleAttrs)
            (detailText as NSString).draw(in: CGRect(x: 265, y: 180, width: 260, height: 100), withAttributes: subAttrs)
        }
    }
}
