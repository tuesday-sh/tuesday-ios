import Foundation
import AVFoundation
import Vision

public struct ParsedBarcodeResult: Equatable {
    public let normalizedValue: String
    public let is2DMatrix: Bool

    public init(normalizedValue: String, is2DMatrix: Bool) {
        self.normalizedValue = normalizedValue
        self.is2DMatrix = is2DMatrix
    }
}

public enum BarcodeIdentifierParser {
    public static func is2DSymbology(_ symbology: VNBarcodeSymbology) -> Bool {
        symbology == .qr ||
            symbology == .dataMatrix ||
            symbology == .aztec ||
            symbology == .pdf417 ||
            symbology == .microQR ||
            symbology == .microPDF417
    }

    public static func is2DMetadataObjectType(_ objectType: AVMetadataObject.ObjectType) -> Bool {
        objectType == .qr ||
            objectType == .dataMatrix ||
            objectType == .aztec ||
            objectType == .pdf417 ||
            objectType == .microQR ||
            objectType == .microPDF417
    }

    /// Normalizes scanned 1D/2D barcode payloads:
    /// - Trims whitespace and returns `nil` on blank strings
    /// - Distinguishes 2D matrices (QR, DataMatrix, Aztec, PDF417) from 1D retail/serial barcodes
    /// - Strips leading `0` from 13-digit numeric EAN-13 payloads into 12-digit UPC-A for Android/iOS parity
    public static func parse(rawValue: String, is2DMatrix: Bool) -> ParsedBarcodeResult? {
        let cleaned = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return nil }
        let isAllDigits = cleaned.allSatisfy { $0.isNumber && $0.isASCII }
        let normalized: String
        if !is2DMatrix && cleaned.count == 13 && cleaned.hasPrefix("0") && isAllDigits {
            normalized = String(cleaned.dropFirst())
        } else {
            normalized = cleaned
        }
        return ParsedBarcodeResult(normalizedValue: normalized, is2DMatrix: is2DMatrix)
    }

    public static func parse(rawValue: String, symbology: VNBarcodeSymbology) -> ParsedBarcodeResult? {
        parse(rawValue: rawValue, is2DMatrix: is2DSymbology(symbology))
    }

    public static func parse(rawValue: String, metadataType: AVMetadataObject.ObjectType) -> ParsedBarcodeResult? {
        parse(rawValue: rawValue, is2DMatrix: is2DMetadataObjectType(metadataType))
    }
}
