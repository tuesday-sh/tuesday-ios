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

public struct GoldAlignmentInfo: Codable, Equatable {
    public var aligned: Bool
    public var inferredPurl: String?
    public var catalogItemId: String?
    public var statusLabel: String
    public var matchedFeedName: String?
    public var matchedFeedSlug: String?
    public var latestGoldRelease: String?

    public init(
        aligned: Bool = false,
        inferredPurl: String? = nil,
        catalogItemId: String? = nil,
        statusLabel: String = "UNALIGNED RAW MATCH",
        matchedFeedName: String? = nil,
        matchedFeedSlug: String? = nil,
        latestGoldRelease: String? = nil
    ) {
        self.aligned = aligned
        self.inferredPurl = inferredPurl
        self.catalogItemId = catalogItemId
        self.statusLabel = statusLabel
        self.matchedFeedName = matchedFeedName
        self.matchedFeedSlug = matchedFeedSlug
        self.latestGoldRelease = latestGoldRelease
    }
}

public struct DeviceCandidateMatch: Identifiable, Codable, Equatable {
    public var id: String { "\(manufacturer)-\(modelNumber)-\(confidencePercent)" }
    public var manufacturer: String
    public var modelNumber: String
    public var displayName: String
    public var deviceCategory: String
    public var confidencePercent: Int
    public var reasoning: String
    public var suggestedHostname: String
    public var suggestedOsDetails: String
    public var suggestedPackageManager: String
    public var goldAlignment: GoldAlignmentInfo?

    public init(
        manufacturer: String,
        modelNumber: String,
        displayName: String,
        deviceCategory: String,
        confidencePercent: Int,
        reasoning: String,
        suggestedHostname: String,
        suggestedOsDetails: String,
        suggestedPackageManager: String,
        goldAlignment: GoldAlignmentInfo? = nil
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
        self.goldAlignment = goldAlignment
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
    public var isNetworkedDevice: Bool
    public var outOfScopeReason: String?
    public var nextNarrowingQuestion: String
    public var recommendedClueTypes: [String]
    public var extractedIdentifiers: ExtractedDeviceIdentifiers
    public var candidates: [DeviceCandidateMatch]
    public var usedLiveGeminiApi: Bool
    public var debugTrace: String?
    public var rawJsonResponse: String?
    public var multipleDevicesDetected: Bool
    public var multiDeviceWarning: String?

    public init(
        visualSummary: String,
        isNetworkedDevice: Bool = true,
        outOfScopeReason: String? = nil,
        nextNarrowingQuestion: String = "",
        recommendedClueTypes: [String] = [],
        extractedIdentifiers: ExtractedDeviceIdentifiers = ExtractedDeviceIdentifiers(),
        candidates: [DeviceCandidateMatch] = [],
        usedLiveGeminiApi: Bool = false,
        debugTrace: String? = nil,
        rawJsonResponse: String? = nil,
        multipleDevicesDetected: Bool = false,
        multiDeviceWarning: String? = nil
    ) {
        self.visualSummary = visualSummary
        self.isNetworkedDevice = isNetworkedDevice
        self.outOfScopeReason = outOfScopeReason
        self.nextNarrowingQuestion = nextNarrowingQuestion
        self.recommendedClueTypes = recommendedClueTypes
        self.extractedIdentifiers = extractedIdentifiers
        self.candidates = candidates
        self.usedLiveGeminiApi = usedLiveGeminiApi
        self.debugTrace = debugTrace
        self.rawJsonResponse = rawJsonResponse
        self.multipleDevicesDetected = multipleDevicesDetected
        self.multiDeviceWarning = multiDeviceWarning
    }
}

public final class GeminiDeviceDiscoveryService {
    public static let shared = GeminiDeviceDiscoveryService()

    public static let defaultServerBaseUrl = "https://api.tuesday.sh"
    public static let defaultClientDeviceId = "ios-sim-device"
    public static let pilotClientToken = "tuesday-pilot-v1-public-client-token"
    public static let maxImagesPerTurn = 2
    public static let maxTotalBase64Bytes = 780_000

    private let stateLock = NSLock()
    private var sessionStickinessId = "tuesday-ios-" + String(UUID().uuidString.prefix(8)).lowercased()
    private var turnCounter = 0

    private init() {}

    @discardableResult
    public func startNewSession() -> String {
        stateLock.lock()
        defer { stateLock.unlock() }
        sessionStickinessId = "tuesday-ios-" + String(UUID().uuidString.prefix(8)).lowercased()
        turnCounter = 0
        return sessionStickinessId
    }

    private func nextTurnContext() -> (sessionId: String, turnIndex: Int) {
        stateLock.lock()
        defer { stateLock.unlock() }
        turnCounter += 1
        return (sessionStickinessId, turnCounter)
    }

    private func applyStandardHeaders(
        to request: inout URLRequest,
        includeImageRetention: Bool = false,
        debugCapture: Bool = false
    ) {
        let info = Bundle.main.infoDictionary
        let appVer = (info?["CFBundleShortVersionString"] as? String) ?? "1.0.0"
        let buildNum = (info?["CFBundleVersion"] as? String) ?? "9"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Tuesday.sh-iOS/\(appVer) (Build \(buildNum); iOS \(UIDevice.current.systemVersion))", forHTTPHeaderField: "User-Agent")
        request.setValue(appVer, forHTTPHeaderField: "X-Tuesday-App-Version")
        request.setValue(buildNum, forHTTPHeaderField: "X-Tuesday-Build")
        request.setValue("ios", forHTTPHeaderField: "X-Tuesday-Client-Platform")
        request.setValue(Self.pilotClientToken, forHTTPHeaderField: "X-Tuesday-Pilot-Token")
        request.setValue(debugCapture ? "true" : "false", forHTTPHeaderField: "X-Tuesday-Debug")
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? Self.defaultClientDeviceId
        request.setValue(deviceId, forHTTPHeaderField: "X-Tuesday-Device-ID")
        if includeImageRetention {
            request.setValue("none_ephemeral_ram_only", forHTTPHeaderField: "X-Tuesday-Image-Retention")
        }
    }

    /// Downscales camera/library images to <= 1024px (scale 1.0, normalized upright) and keeps
    /// base64 JPEG payload safely within the edge proxy's ephemeral transit budget.
    public static func downscaleAndEncode(
        _ image: UIImage,
        maxDimension: CGFloat = 1024,
        maxBase64Bytes: Int = 380_000
    ) -> String? {
        func renderAndCompress(maxSide: CGFloat, qualities: [CGFloat]) -> String? {
            let srcWidth = image.size.width * image.scale
            let srcHeight = image.size.height * image.scale
            guard srcWidth > 0, srcHeight > 0 else { return nil }

            let ratio = min(maxSide / srcWidth, maxSide / srcHeight, 1.0)
            let targetSize = CGSize(
                width: max(1, (srcWidth * ratio).rounded()),
                height: max(1, (srcHeight * ratio).rounded())
            )
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1.0
            format.opaque = true
            let rendered = UIGraphicsImageRenderer(size: targetSize, format: format).image { _ in
                image.draw(in: CGRect(origin: .zero, size: targetSize))
            }

            var lastEncoded: String?
            for q in qualities {
                if let data = rendered.jpegData(compressionQuality: q) {
                    let b64 = data.base64EncodedString()
                    lastEncoded = b64
                    if b64.utf8.count <= maxBase64Bytes {
                        return b64
                    }
                }
            }
            return lastEncoded
        }

        if let primary = renderAndCompress(maxSide: maxDimension, qualities: [0.80, 0.65, 0.50]),
           primary.utf8.count <= maxBase64Bytes {
            return primary
        }
        return renderAndCompress(maxSide: min(maxDimension, 768), qualities: [0.55, 0.42])
    }

    /// Calls POST /api/v1/discovery/analyze (ephemeral RAM-only processing on Tuesday.sh backend)
    /// and reconciles returned candidates against the offline Gold Clue Index.
    public func analyzeDeviceProgressive(
        images: [UIImage],
        accumulatedIdentifiers: ExtractedDeviceIdentifiers,
        userClueNotes: [String],
        apiKeyOverride: String = "",
        modelName: String = "qwen3.8-27b",
        providerOverride: String? = nil,
        serverBaseUrl: String = GeminiDeviceDiscoveryService.defaultServerBaseUrl,
        debugCapture: Bool = false
    ) async -> GeminiDiscoveryTurnResult {
        if CommandLine.arguments.contains("--uitesting-mock-gemini") {
            let simulated = Self.fallbackHeuristicAnalysis(
                accumulatedIdentifiers: accumulatedIdentifiers,
                userClueNotes: userClueNotes,
                imageCount: images.count,
                note: "Offline UI test heuristic simulation (--uitesting-mock-gemini)"
            )
            return GoldClueSuggestionRepository.shared.reconcileDiscoveryResult(simulated)
        }

        let trimmedBase = (serverBaseUrl.isEmpty ? Self.defaultServerBaseUrl : serverBaseUrl)
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: "\(trimmedBase)/api/v1/discovery/analyze") else {
            return GoldClueSuggestionRepository.shared.reconcileDiscoveryResult(
                Self.fallbackHeuristicAnalysis(
                    accumulatedIdentifiers: accumulatedIdentifiers,
                    userClueNotes: userClueNotes,
                    imageCount: images.count,
                    note: "Invalid Tuesday.sh Server URL: \(serverBaseUrl)"
                )
            )
        }

        let turnCtx = nextTurnContext()
        let selectedImages = Array(images.suffix(Self.maxImagesPerTurn))
        let perImageBudget = min(380_000, Self.maxTotalBase64Bytes / max(1, selectedImages.count))
        let base64Images: [String] = selectedImages.compactMap { img in
            Self.downscaleAndEncode(img, maxDimension: 1024, maxBase64Bytes: perImageBudget)
        }

        var idsDict: [String: String] = [:]
        if let b = accumulatedIdentifiers.barcode, !b.isEmpty { idsDict["barcode"] = b }
        if let s = accumulatedIdentifiers.serialNumber, !s.isEmpty { idsDict["serialNumber"] = s }
        if let q = accumulatedIdentifiers.qrCode, !q.isEmpty { idsDict["qrCode"] = q }
        if let m = accumulatedIdentifiers.modelNumber, !m.isEmpty { idsDict["modelNumber"] = m }
        if let mac = accumulatedIdentifiers.macAddress, !mac.isEmpty { idsDict["macAddress"] = mac }

        let clientDeviceId = UIDevice.current.identifierForVendor?.uuidString ?? Self.defaultClientDeviceId
        var payload: [String: Any] = [
            "session_id": turnCtx.sessionId,
            "turn_index": turnCtx.turnIndex,
            "client_platform": "ios",
            "device_id": clientDeviceId,
            "initial_mode": "photo_wizard",
            "provider_override": providerOverride?.nilIfBlank ?? "auto",
            "images_base64": base64Images,
            "user_clue_notes": userClueNotes,
            "extracted_identifiers": idsDict,
            "ephemeral_ram_only": true,
            "model_preference": modelName,
            "debug": debugCapture
        ]
        if !apiKeyOverride.isEmpty {
            payload["api_key_override"] = apiKeyOverride
        }

        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.timeoutInterval = 55
            applyStandardHeaders(to: &request, includeImageRetention: true, debugCapture: debugCapture)
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                let status = (response as? HTTPURLResponse)?.statusCode ?? -1
                let errDetail: String = {
                    if let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let msg = (obj["error"] as? String)?.nilIfBlank {
                        return msg
                    }
                    return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfBlank ?? "Unexpected response"
                }()
                return GoldClueSuggestionRepository.shared.reconcileDiscoveryResult(
                    Self.fallbackHeuristicAnalysis(
                        accumulatedIdentifiers: accumulatedIdentifiers,
                        userClueNotes: userClueNotes,
                        imageCount: images.count,
                        note: "HTTP \(status): \(errDetail)"
                    )
                )
            }

            let rawString = debugCapture ? String(data: data, encoding: .utf8) : nil
            if var parsed = Self.parseBackendDiscoveryResponse(data) {
                parsed.rawJsonResponse = rawString
                return GoldClueSuggestionRepository.shared.reconcileDiscoveryResult(parsed)
            }

            return GoldClueSuggestionRepository.shared.reconcileDiscoveryResult(
                Self.fallbackHeuristicAnalysis(
                    accumulatedIdentifiers: accumulatedIdentifiers,
                    userClueNotes: userClueNotes,
                    imageCount: images.count,
                    note: "Could not parse backend discovery JSON; using local heuristic fallback."
                )
            )
        } catch {
            return GoldClueSuggestionRepository.shared.reconcileDiscoveryResult(
                Self.fallbackHeuristicAnalysis(
                    accumulatedIdentifiers: accumulatedIdentifiers,
                    userClueNotes: userClueNotes,
                    imageCount: images.count,
                    note: "Network error (\(error.localizedDescription)); using offline heuristics."
                )
            )
        }
    }

    /// Sends explicit human-in-the-loop model confirmation to backend telemetry loop.
    @discardableResult
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

        let payload: [String: Any] = [
            "inferred_vendor": inferredVendor ?? "",
            "inferred_model": inferredModel ?? "",
            "confirmed_vendor": confirmedVendor,
            "confirmed_model": confirmedModel,
            "was_edited": wasEdited,
            "identifiers": [
                "barcode": accumulatedIdentifiers.barcode ?? "",
                "serial_number": accumulatedIdentifiers.serialNumber ?? "",
                "qr_code": accumulatedIdentifiers.qrCode ?? "",
                "model_number": accumulatedIdentifiers.modelNumber ?? "",
                "mac_address": accumulatedIdentifiers.macAddress ?? ""
            ]
        ]

        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.timeoutInterval = 10
            applyStandardHeaders(to: &request)
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse).map { (200...299).contains($0.statusCode) } ?? false
        } catch {
            return false
        }
    }

    public static func parseBackendDiscoveryResponse(_ data: Data) -> GeminiDiscoveryTurnResult? {
        guard let root = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return nil
        }

        let visualSummary = ((root["visualSummary"] as? String)?.nilIfBlank
            ?? (root["visual_summary"] as? String)?.nilIfBlank)
            ?? "Analyzed hardware clues"
        let isNetworked = (root["isNetworkedDevice"] as? Bool)
            ?? (root["is_networked_device"] as? Bool)
            ?? true
        let outOfScope = (root["outOfScopeReason"] as? String)?.nilIfBlank
            ?? (root["out_of_scope_reason"] as? String)?.nilIfBlank
        let nextQuestion = (root["nextNarrowingQuestion"] as? String)?.nilIfBlank
            ?? (root["next_narrowing_question"] as? String)?.nilIfBlank
            ?? (root["nextPromptForUser"] as? String)?.nilIfBlank
            ?? ""
        let recommendedClues = (root["recommendedClueTypes"] as? [String])
            ?? (root["recommended_clue_types"] as? [String])
            ?? ["Model", "Serial Number"]
        let providerLabel = (root["providerLabel"] as? String)?.nilIfBlank
            ?? (root["providerUsed"] as? String)?.nilIfBlank
            ?? (root["provider_used"] as? String)?.nilIfBlank
            ?? "tuesday-server"
        let debugTrace: String? = {
            if let arr = root["debugTrace"] as? [String], !arr.isEmpty {
                return arr.joined(separator: "\n")
            }
            if let s = (root["debugTrace"] as? String)?.nilIfBlank { return s }
            if let s = (root["debug_trace"] as? String)?.nilIfBlank { return s }
            return (root["debugLogText"] as? String)?.nilIfBlank
        }()

        let idsJson = (root["extractedIdentifiersObject"] as? [String: Any])
            ?? (root["extractedIdentifiers"] as? [String: Any])
            ?? (root["extracted_identifiers"] as? [String: Any])
            ?? [:]
        let extracted = ExtractedDeviceIdentifiers(
            barcode: (idsJson["barcode"] as? String)?.nilIfBlank,
            serialNumber: ((idsJson["serialNumber"] as? String)?.nilIfBlank
                ?? (idsJson["serial_number"] as? String)?.nilIfBlank),
            qrCode: ((idsJson["qrCode"] as? String)?.nilIfBlank
                ?? (idsJson["qr_code"] as? String)?.nilIfBlank),
            modelNumber: ((idsJson["modelNumber"] as? String)?.nilIfBlank
                ?? (idsJson["model"] as? String)?.nilIfBlank
                ?? (idsJson["model_number"] as? String)?.nilIfBlank),
            macAddress: ((idsJson["macAddress"] as? String)?.nilIfBlank
                ?? (idsJson["mac_address"] as? String)?.nilIfBlank)
        )

        let rawCandidates = (root["candidates"] as? [[String: Any]]) ?? []
        let candidates: [DeviceCandidateMatch] = rawCandidates.map { obj in
            let gaJson = (obj["goldAlignment"] as? [String: Any])
                ?? (obj["gold_alignment"] as? [String: Any])
            let ga: GoldAlignmentInfo? = gaJson.map { g in
                let aligned = (g["aligned"] as? Bool) ?? false
                return GoldAlignmentInfo(
                    aligned: aligned,
                    inferredPurl: ((g["inferredPurl"] as? String)?.nilIfBlank
                        ?? (g["inferred_purl"] as? String)?.nilIfBlank),
                    catalogItemId: ((g["catalogItemId"] as? String)?.nilIfBlank
                        ?? (g["catalog_item_id"] as? String)?.nilIfBlank),
                    statusLabel: ((g["statusLabel"] as? String)?.nilIfBlank
                        ?? (g["status_label"] as? String)?.nilIfBlank)
                        ?? (aligned ? "GOLD ALIGNED" : "UNALIGNED RAW MATCH"),
                    matchedFeedName: ((g["matchedFeedName"] as? String)?.nilIfBlank
                        ?? (g["matched_feed_name"] as? String)?.nilIfBlank),
                    matchedFeedSlug: ((g["matchedFeedSlug"] as? String)?.nilIfBlank
                        ?? (g["matched_feed_slug"] as? String)?.nilIfBlank),
                    latestGoldRelease: ((g["latestGoldRelease"] as? String)?.nilIfBlank
                        ?? (g["latest_gold_release"] as? String)?.nilIfBlank)
                )
            }

            let osDetails: String = {
                if let s = (obj["suggestedOsDetails"] as? String)?.nilIfBlank { return s }
                if let dict = obj["suggestedOsDetails"] as? [String: Any] {
                    let osName = (dict["osName"] as? String) ?? "Firmware"
                    let osVer = (dict["osVersion"] as? String) ?? ""
                    return "\(osName) \(osVer)".trimmingCharacters(in: .whitespaces)
                }
                return (obj["osDetails"] as? String)?.nilIfBlank
                    ?? (obj["suggested_os_details"] as? String)?.nilIfBlank
                    ?? "Embedded Firmware"
            }()

            let manufacturer = (obj["manufacturer"] as? String)?.nilIfBlank ?? "Unknown"
            let modelNum = ((obj["modelNumber"] as? String)?.nilIfBlank
                ?? (obj["model_number"] as? String)?.nilIfBlank)
                ?? "Unknown Model"
            let displayName = ((obj["displayName"] as? String)?.nilIfBlank
                ?? (obj["display_name"] as? String)?.nilIfBlank)
                ?? "\(manufacturer) \(modelNum)".trimmingCharacters(in: .whitespaces)

            return DeviceCandidateMatch(
                manufacturer: manufacturer,
                modelNumber: modelNum,
                displayName: displayName,
                deviceCategory: ((obj["deviceCategory"] as? String)?.nilIfBlank
                    ?? (obj["category"] as? String)?.nilIfBlank
                    ?? (obj["device_category"] as? String)?.nilIfBlank)
                    ?? "Network Hardware",
                confidencePercent: (obj["confidencePercent"] as? Int)
                    ?? (obj["confidence_percent"] as? Int)
                    ?? 65,
                reasoning: (obj["reasoning"] as? String) ?? "",
                suggestedHostname: ((obj["suggestedHostname"] as? String)?.nilIfBlank
                    ?? (obj["suggested_hostname"] as? String)?.nilIfBlank)
                    ?? "network-device",
                suggestedOsDetails: osDetails,
                suggestedPackageManager: ((obj["suggestedPackageManager"] as? String)?.nilIfBlank
                    ?? (obj["pkgManager"] as? String)?.nilIfBlank
                    ?? (obj["suggested_package_manager"] as? String)?.nilIfBlank)
                    ?? "firmware",
                goldAlignment: ga
            )
        }

        let multipleDevicesDetected = (root["multipleDevicesDetected"] as? Bool)
            ?? (root["multiple_devices_detected"] as? Bool)
            ?? false
        let multiDeviceWarning = (root["multiDeviceWarning"] as? String)?.nilIfBlank
            ?? (root["multi_device_warning"] as? String)?.nilIfBlank

        return GeminiDiscoveryTurnResult(
            visualSummary: visualSummary,
            isNetworkedDevice: isNetworked,
            outOfScopeReason: outOfScope,
            nextNarrowingQuestion: nextQuestion,
            recommendedClueTypes: recommendedClues,
            extractedIdentifiers: extracted,
            candidates: candidates,
            usedLiveGeminiApi: true,
            debugTrace: debugTrace ?? providerLabel,
            multipleDevicesDetected: multipleDevicesDetected,
            multiDeviceWarning: multiDeviceWarning
        )
    }

    public static func fallbackHeuristicAnalysis(
        accumulatedIdentifiers: ExtractedDeviceIdentifiers,
        userClueNotes: [String],
        imageCount: Int,
        usedLiveApi: Bool = false,
        note: String? = nil
    ) -> GeminiDiscoveryTurnResult {
        let modelText = accumulatedIdentifiers.modelNumber?.lowercased() ?? ""
        let macText = accumulatedIdentifiers.macAddress?.lowercased() ?? ""
        let qrText = accumulatedIdentifiers.qrCode?.lowercased() ?? ""
        let barcodeText = accumulatedIdentifiers.barcode?.lowercased() ?? ""
        let cluesCombined = (userClueNotes.joined(separator: " ") + " " + modelText + " " + macText + " " + qrText + " " + barcodeText).lowercased()

        if cluesCombined.contains("ucg") || cluesCombined.contains("udm") || cluesCombined.contains("unifi") || macText.hasPrefix("74:83:c2") {
            let isUltra = cluesCombined.contains("ultra") || cluesCombined.contains("ucg")
            let candidate = DeviceCandidateMatch(
                manufacturer: "Ubiquiti",
                modelNumber: isUltra ? "UCG-Ultra" : "UDM-Pro",
                displayName: isUltra ? "Ubiquiti UniFi Cloud Gateway Ultra" : "Ubiquiti UniFi Dream Machine Pro",
                deviceCategory: "Router / Gateway",
                confidencePercent: isUltra || !macText.isEmpty ? 95 : 86,
                reasoning: "Matched Ubiquiti UniFi gateway clues across hardware identifiers.",
                suggestedHostname: isUltra ? "ucg-ultra" : "udm-pro",
                suggestedOsDetails: "UniFi OS 4.0.20 (Debian Bookworm)",
                suggestedPackageManager: "firmware"
            )
            return GeminiDiscoveryTurnResult(
                visualSummary: "Identified Ubiquiti UniFi gateway chassis (\(imageCount) frame(s) evaluated). \(note ?? "")",
                nextNarrowingQuestion: candidate.confidencePercent >= 90 ? "Confirm exact hardware SKU or adjust." : "Do you see UCG-Ultra or UDM-Pro printed on the base?",
                recommendedClueTypes: ["Model", "Serial Number", "MAC Address"],
                extractedIdentifiers: accumulatedIdentifiers,
                candidates: [candidate],
                usedLiveGeminiApi: usedLiveApi,
                debugTrace: note
            )
        }

        if cluesCombined.contains("ecobee") || macText.hasPrefix("44:61:32") || cluesCombined.contains("thermostat") {
            let candidates = [
                DeviceCandidateMatch(
                    manufacturer: "Ecobee",
                    modelNumber: "SmartThermostat Premium",
                    displayName: "Ecobee SmartThermostat Premium",
                    deviceCategory: "Smart Thermostat",
                    confidencePercent: 78,
                    reasoning: "Matched Ecobee Wi-Fi thermostat clues; Premium vs Enhanced disambiguation suggested.",
                    suggestedHostname: "ecobee-hallway",
                    suggestedOsDetails: "Ecobee Firmware 4.8.7.100",
                    suggestedPackageManager: "firmware"
                ),
                DeviceCandidateMatch(
                    manufacturer: "Ecobee",
                    modelNumber: "SmartThermostat Enhanced",
                    displayName: "Ecobee SmartThermostat Enhanced",
                    deviceCategory: "Smart Thermostat",
                    confidencePercent: 72,
                    reasoning: "Alternative SKU sharing Ecobee OUI range.",
                    suggestedHostname: "ecobee-enhanced",
                    suggestedOsDetails: "Ecobee Firmware 4.8.7.100",
                    suggestedPackageManager: "firmware"
                )
            ]
            return GeminiDiscoveryTurnResult(
                visualSummary: "Evaluated smart thermostat clues (\(imageCount) photo(s)). \(note ?? "")",
                nextNarrowingQuestion: "Check the backplate for SmartThermostat Premium vs Enhanced.",
                recommendedClueTypes: ["Model", "QR Code", "Serial Number"],
                extractedIdentifiers: accumulatedIdentifiers,
                candidates: candidates,
                usedLiveGeminiApi: usedLiveApi,
                debugTrace: note
            )
        }

        if cluesCombined.contains("r7000") || cluesCombined.contains("netgear") {
            return GeminiDiscoveryTurnResult(
                visualSummary: "Matched Netgear Nighthawk hardware pattern. \(note ?? "")",
                nextNarrowingQuestion: "Verify exact Nighthawk model suffix on bottom label.",
                recommendedClueTypes: ["Model", "Barcode", "Serial Number"],
                extractedIdentifiers: accumulatedIdentifiers,
                candidates: [
                    DeviceCandidateMatch(
                        manufacturer: "Netgear",
                        modelNumber: "R7000",
                        displayName: "Netgear Nighthawk R7000 AC1900",
                        deviceCategory: "Wi-Fi Router / Gateway",
                        confidencePercent: 89,
                        reasoning: "Matched Netgear R7000 identifier clue.",
                        suggestedHostname: "netgear-r7000",
                        suggestedOsDetails: "Netgear Genie 1.0.11.136",
                        suggestedPackageManager: "firmware"
                    )
                ],
                usedLiveGeminiApi: usedLiveApi,
                debugTrace: note
            )
        }

        let fallback = DeviceCandidateMatch(
            manufacturer: "Generic",
            modelNumber: accumulatedIdentifiers.modelNumber ?? "Unidentified Hardware",
            displayName: accumulatedIdentifiers.modelNumber ?? "Unverified Network Device",
            deviceCategory: "Smart Home / IoT",
            confidencePercent: 52,
            reasoning: "Insufficient specific identifiers yet. Add Model, Brand, Barcode, or MAC prefix clues to improve accuracy.",
            suggestedHostname: "unknown-device",
            suggestedOsDetails: "Embedded Firmware",
            suggestedPackageManager: "firmware"
        )
        return GeminiDiscoveryTurnResult(
            visualSummary: "Evaluated \(imageCount) photo(s) and \(accumulatedIdentifiers.nonEmptyPairs.count) identifier(s). \(note ?? "")",
            nextNarrowingQuestion: "Try adding Brand, Device Type, Barcode UPC, or Model label text.",
            recommendedClueTypes: ["Model", "Barcode", "Serial Number"],
            extractedIdentifiers: accumulatedIdentifiers,
            candidates: [fallback],
            usedLiveGeminiApi: usedLiveApi,
            debugTrace: note
        )
    }

    /// Generates clean sample hardware images for UI tests & simulator demos.
    public static func renderSampleHardwareImage(presetName: String) -> UIImage {
        let size = CGSize(width: 640, height: 420)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let cg = ctx.cgContext
            cg.setFillColor(UIColor(red: 0.11, green: 0.13, blue: 0.17, alpha: 1.0).cgColor)
            cg.fill(CGRect(origin: .zero, size: size))

            let boxRect = CGRect(x: 90, y: 80, width: 460, height: 220)
            let path = UIBezierPath(roundedRect: boxRect, cornerRadius: 24)
            UIColor(red: 0.92, green: 0.94, blue: 0.96, alpha: 1.0).setFill()
            path.fill()

            let label: String = {
                switch presetName.lowercased() {
                case "barcode-udm-pro":
                    return "UPC 817882027373 • UniFi UDM-Pro"
                case "qr-ucg-ultra":
                    return "QR • UniFi UCG-Ultra"
                case "zigbee-iot", "iot-zigbee":
                    return "Smart Home Sensor • MAC 44:61:32"
                default:
                    return "UniFi Cloud Gateway Ultra (UCG-Ultra)"
                }
            }()
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 20),
                .foregroundColor: UIColor.darkGray
            ]
            label.draw(in: CGRect(x: 120, y: 165, width: 400, height: 60), withAttributes: attrs)
        }
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
