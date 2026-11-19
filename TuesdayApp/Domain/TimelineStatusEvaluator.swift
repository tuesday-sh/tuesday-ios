import Foundation

public struct CandlestickStatusSummary: Equatable {
    public let statusText: String
    public let needsStatusCheck: Bool

    public init(statusText: String, needsStatusCheck: Bool) {
        self.statusText = statusText
        self.needsStatusCheck = needsStatusCheck
    }
}

public enum TimelineStatusEvaluator {
    public static let defaultReferenceDate = "2026-11-11"
    public static let defaultReferenceYear = "2026"

    public static func isAnnualCheckInDue(
        latestAuditDate: String?,
        referenceYearPrefix: String = defaultReferenceYear
    ) -> Bool {
        !(latestAuditDate?.hasPrefix(referenceYearPrefix) ?? false)
    }

    public static func evaluateCandleStatus(
        candle: OperationalCandle,
        attestations: [DeviceAttestation],
        referenceYearPrefix: String = defaultReferenceYear
    ) -> CandlestickStatusSummary {
        let statusText: String
        switch candle.presenceState {
        case .stoppedWorking:
            statusText = "STOPPED WORKING • DEFECT"
        case .lost:
            statusText = "LOST • UNACCOUNTED"
        case .retired:
            statusText = "RETIRED • DECOMMISSIONED"
        case .active:
            if candle.isPastEol {
                statusText = "ZOMBIE HARDWARE • PAST EOL"
            } else if candle.isEolNearing {
                statusText = "EOL NEARS • RUNWAY LOW"
            } else if candle.hasCveOrRecall {
                statusText = "SECURITY RECALL / CVE"
            } else {
                statusText = "ACTIVE • SUPPORTED RUNWAY"
            }
        }

        let latestAtt = candle.latestAttestation ?? attestations.first(where: { $0.deviceId == candle.id })
        let checkInDue = isAnnualCheckInDue(latestAuditDate: latestAtt?.auditDate, referenceYearPrefix: referenceYearPrefix)
        let needsStatusCheck = checkInDue ||
            candle.isPastEol ||
            candle.isEolNearing ||
            candle.hasCveOrRecall ||
            candle.presenceState == .lost ||
            candle.presenceState == .stoppedWorking

        return CandlestickStatusSummary(statusText: statusText, needsStatusCheck: needsStatusCheck)
    }

    public static func formatScrubberCursorDate(
        scrubberXNorm: Double,
        anchorNorm: Double = 0.72,
        baseDateStr: String = defaultReferenceDate
    ) -> String {
        let dayOffset = Int(((anchorNorm - scrubberXNorm) * 120.0).rounded())
        if abs(dayOffset) <= 1 {
            return "\(baseDateStr) (TODAY)"
        } else if dayOffset > 0 {
            return "\(baseDateStr) (-\(dayOffset)d)"
        } else {
            return "\(baseDateStr) (+\(-dayOffset)d projection)"
        }
    }

    public static func worstCategoryState(
        category: StnHardwareCategory,
        devices: [RackPortDevice]
    ) -> PortLifecycleState? {
        devices
            .filter { $0.category == category }
            .min(by: { $0.portState.severityPriority < $1.portState.severityPriority })?
            .portState
    }

    public static func clampPopoverArrowFraction(
        anchorXInStripPx: Double,
        stripWidthPx: Double
    ) -> Double {
        guard stripWidthPx > 0 else { return 0.5 }
        return min(0.92, max(0.08, anchorXInStripPx / stripWidthPx))
    }
}
