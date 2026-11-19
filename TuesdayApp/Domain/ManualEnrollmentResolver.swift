import Foundation

public struct ResolvedManualEnrollment: Equatable {
    public let hostname: String
    public let osSummary: String
    public let metadata: DiscoveredDeviceMetadata
    public let inventoryState: InventoryConfidenceState

    public init(
        hostname: String,
        osSummary: String,
        metadata: DiscoveredDeviceMetadata,
        inventoryState: InventoryConfidenceState
    ) {
        self.hostname = hostname
        self.osSummary = osSummary
        self.metadata = metadata
        self.inventoryState = inventoryState
    }
}

public enum ManualEnrollmentResolver {
    /// Resolves manual hardware enrollment metadata from selected Gold Catalog clues,
    /// scanned/OCR identifiers, and optional user-typed hostname.
    /// Returns `nil` if neither a hostname nor a Gold Model clue is present.
    public static func resolve(
        manualHostname: String,
        selectedClues: [GoldClueItem],
        accumulatedIdentifiers: ExtractedDeviceIdentifiers
    ) -> ResolvedManualEnrollment? {
        let matchedModelClue = selectedClues.last(where: { $0.kind == .model })
        let matchedBrandClue = selectedClues.last(where: { !($0.vendor ?? "").isEmpty })
        let matchedTypeClue = selectedClues.last(where: { $0.kind == .deviceType })

        let trimmedHost = manualHostname.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedName = trimmedHost.isEmpty ? (matchedModelClue?.chipLabel ?? "") : trimmedHost
        guard !resolvedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        let vendor = matchedModelClue?.vendor
            ?? matchedBrandClue?.vendor
            ?? "Manual"
        let model = matchedModelClue?.model
            ?? accumulatedIdentifiers.modelNumber?.nilIfBlank
            ?? matchedTypeClue?.title
            ?? resolvedName
        let mac = selectedClues.last(where: { !($0.macAddress ?? "").isEmpty })?.macAddress
            ?? accumulatedIdentifiers.macAddress?.nilIfBlank
        let serial = accumulatedIdentifiers.serialNumber?.nilIfBlank
        let barcode = selectedClues.last(where: { !($0.upc ?? "").isEmpty })?.upc
            ?? accumulatedIdentifiers.barcode?.nilIfBlank

        let metadata = DiscoveredDeviceMetadata(
            manufacturer: vendor,
            modelNumber: model,
            deviceCategory: matchedTypeClue?.title ?? (matchedModelClue?.subtitle.isEmpty == false ? matchedModelClue?.subtitle : matchedModelClue?.categoryCode),
            serialNumber: serial,
            macAddress: mac,
            barcodeOrQr: barcode
        )

        var summaryParts: [String] = []
        summaryParts.append(matchedModelClue != nil ? "Gold Verified" : "Manual Entry")
        if let typeTitle = matchedTypeClue?.title, !typeTitle.isEmpty {
            summaryParts.append(typeTitle)
        }
        if vendor != "Manual" {
            summaryParts.append(vendor)
        }
        if let m = matchedModelClue?.model, !m.isEmpty {
            summaryParts.append(m)
        }

        let inventoryState: InventoryConfidenceState =
            (matchedModelClue != nil || !(accumulatedIdentifiers.modelNumber ?? "").isEmpty)
            ? .enrolled
            : .incompleteOrGuessed

        return ResolvedManualEnrollment(
            hostname: resolvedName,
            osSummary: summaryParts.joined(separator: " • "),
            metadata: metadata,
            inventoryState: inventoryState
        )
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
