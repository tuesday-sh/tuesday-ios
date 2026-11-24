import Foundation

public struct RhythmPostureItem: Identifiable, Equatable {
    public let id: String
    public let title: String
    public let action: String?
    public let recommendation: String?

    public init(id: String, title: String, action: String?, recommendation: String?) {
        self.id = id
        self.title = title
        self.action = action
        self.recommendation = recommendation
    }
}

public enum RhythmPostureEvaluator {
    public static func hasActiveRecommendation(
        devices: [RackPortDevice],
        welcomeComplete: Bool = false
    ) -> Bool {
        if !welcomeComplete { return true }
        return devices.contains {
            $0.portState == .cveKev || $0.portState == .eol || $0.portState == .guessed
        }
    }

    public static func evaluatePosture(
        flavor: AppBrandFlavor,
        devices: [RackPortDevice],
        bulletins: [BulletinInboxView] = [],
        welcomeComplete: Bool = false
    ) -> [RhythmPostureItem] {
        let isStn = (flavor == .sureThingHome)
        let isDayZero = devices.isEmpty

        let provisionalDevices = devices.filter { $0.portState == .guessed }
        let cveDevices = devices.filter { $0.portState == .cveKev }
        let eolDevices = devices.filter { $0.portState == .eol }

        let recallBulletins = bulletins.filter { $0.bulletinType.caseInsensitiveCompare("RECALL") == .orderedSame }
        let patchBulletins = bulletins.filter {
            $0.bulletinType.caseInsensitiveCompare("CVE") == .orderedSame ||
            $0.bulletinType.caseInsensitiveCompare("CISA_KEV") == .orderedSame ||
            $0.bulletinType.caseInsensitiveCompare("ADVISORY") == .orderedSame
        }

        let r1Action: String? = (isDayZero || provisionalDevices.isEmpty) ? nil : {
            let count = provisionalDevices.count
            let labels = provisionalDevices.map(\.name).joined(separator: ", ")
            return "\(count) provisional device\(count == 1 ? "" : "s") to verify (\(labels))"
        }()
        let r1Rec: String? = r1Action != nil
            ? "Confirm exact hardware model on Bulletins tab or scan barcode."
            : nil

        let r2Action: String?
        let r2Rec: String?
        if !welcomeComplete {
            r2Action = isStn
                ? "Welcome Bulletin: 3 preparation steps for upcoming Patch Tuesday (2nd Tuesday of the month)."
                : "Welcome Bulletin: Complete 3-step setup before Patch Tuesday (2nd Tuesday of the month)."
            r2Rec = isStn
                ? "Review Welcome Bulletin steps: [1 Add Router, 2 Turn On Notifications, 3 Subscribe]."
                : "Check Welcome Bulletin: [1 Add Router, 2 Enable 10:00 AM PT Push, 3 Subscribe Dispatch]."
        } else if !patchBulletins.isEmpty {
            let count = patchBulletins.count
            let titles = patchBulletins.map(\.title).joined(separator: " • ")
            r2Action = "\(count) active Patch Tuesday / security bulletin\(count == 1 ? "" : "s"): \(titles)"
            r2Rec = "Review affected devices and apply vendor firmware updates on the Bulletins tab."
        } else {
            r2Action = nil
            r2Rec = nil
        }

        var r3Parts: [String] = []
        if !recallBulletins.isEmpty {
            let count = recallBulletins.count
            let titles = recallBulletins.map(\.title).joined(separator: ", ")
            r3Parts.append("\(count) Product Safety Recall\(count == 1 ? "" : "s") (\(titles))")
        }
        if !cveDevices.isEmpty {
            let count = cveDevices.count
            let names = cveDevices.map(\.name).joined(separator: ", ")
            r3Parts.append("\(count) CVE-affected device\(count == 1 ? "" : "s") (\(names))")
        }
        let r3Action: String? = (isDayZero || r3Parts.isEmpty) ? nil : r3Parts.joined(separator: " • ")
        let r3Rec: String? = r3Action != nil
            ? (isStn
                ? "Do a 5-minute seasonal check: reboot & dust your router, confirm backups, and review who has Wi-Fi or household access."
                : "Reboot & dust core networking gear, confirm backups ran recently, and review Wi-Fi & C8 People access.")
            : nil

        let r4Action: String? = (isDayZero || eolDevices.isEmpty) ? nil : {
            let count = eolDevices.count
            let labels = eolDevices.map(\.name).joined(separator: ", ")
            return "\(count) aging device\(count == 1 ? "" : "s") past vendor support (\(labels))"
        }()
        let r4Rec: String? = r4Action != nil
            ? "Plan replacements for aging devices approaching end-of-life, save a local copy of your network list, and share your summary with a trusted helper."
            : nil

        return [
            RhythmPostureItem(
                id: "r1",
                title: isStn ? "R1 • Hardware Lifecycle (Buy, Install, Retire)" : "R1 • HARDWARE LIFECYCLE & ENROLLMENT",
                action: r1Action,
                recommendation: r1Rec
            ),
            RhythmPostureItem(
                id: "r2",
                title: isStn ? "R2 • Monthly Patch Tuesday Check-Up" : "R2 • MONTHLY PATCH TUESDAY CHECK-UP",
                action: r2Action,
                recommendation: r2Rec
            ),
            RhythmPostureItem(
                id: "r3",
                title: isStn ? "R3 • Seasonal Home Check-Up (Quarterly)" : "R3 • SEASONAL CHECK-UP (QUARTERLY)",
                action: r3Action,
                recommendation: r3Rec
            ),
            RhythmPostureItem(
                id: "r4",
                title: isStn ? "R4 • Yearly Gear & Lifespan Check-In" : "R4 • YEARLY GEAR & LIFESPAN CHECK-IN",
                action: r4Action,
                recommendation: r4Rec
            )
        ]
    }

    public static func formatShareReport(
        flavor: AppBrandFlavor,
        items: [RhythmPostureItem]
    ) -> String {
        let isStn = (flavor == .sureThingHome)
        let header = isStn
            ? "🛡️ SureThingNet Home Safety & Software Check-Up\nCadence: 4-Rhythm Home Protection Check-Up"
            : "🛡️ Tuesday.sh (STN-Pro) Fleet Check-Up\nCadence: 4-Rhythm Continuous Operational Posture"
        let body = items.enumerated().map { idx, r in
            let status = (r.action != nil) ? "⚠️ Action Needed" : "✓ Everything OK"
            let summary = r.action ?? "Everything OK"
            let recLine = r.recommendation != nil ? "\n   💡 Recommendation: \(r.recommendation!)" : ""
            return "\(idx + 1). [\(r.title)] — \(status)\n   Status: \(summary)\(recLine)"
        }.joined(separator: "\n\n")
        return "\(header)\n\n\(body)"
    }
}
