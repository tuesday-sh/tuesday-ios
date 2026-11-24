import Foundation
import UIKit

/// Client-side formatted Home & Rack Dossier exporter (Pro Tier 1).
///
/// Sovereign Local JSON backup remains 100% Free; formatted human-readable
/// exports (Insurance/Disaster-Recovery PDF, CSV spreadsheet, Markdown spec sheet)
/// are unlocked with Pro Tier 1.
public enum RackDossierExporter {

    public static func currentTimestampIso() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: Date())
    }

    public static func formatMarkdown(
        siteName: String,
        devices: [RackPortDevice],
        generatedAtIso: String = currentTimestampIso()
    ) -> String {
        let safeSite = siteName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "My Network" : siteName
        let sorted = devices.sorted { lhs, rhs in
            if lhs.category.rawValue != rhs.category.rawValue {
                return lhs.category.rawValue < rhs.category.rawValue
            }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }

        let cveCount = sorted.filter { $0.portState == .cveKev }.count
        let eolCount = sorted.filter { $0.portState == .eol }.count
        let updateCount = sorted.filter { $0.portState == .update }.count
        let guessedCount = sorted.filter { $0.portState == .guessed }.count
        let okCount = sorted.filter { $0.portState == .ok }.count

        var lines: [String] = [
            "# \(safeSite) — Hardware & Network Dossier",
            "",
            "- **Generated**: \(generatedAtIso)",
            "- **Tracked Devices**: \(sorted.count)",
            "- **Posture Summary**: \(okCount) OK • \(updateCount) Update • \(eolCount) EOL • \(cveCount) CVE/KEV • \(guessedCount) Unverified",
            "",
            "| Category | Device | Room / Location | Firmware | Status | Trust Zone |",
            "| :--- | :--- | :--- | :--- | :--- | :--- |"
        ]

        for d in sorted {
            let cat = "\(d.category.code) \(d.category.proLabel)"
            let dev = d.name.replacingOccurrences(of: "|", with: "\\|")
            let room = (d.roomLocation.isEmpty ? "—" : d.roomLocation).replacingOccurrences(of: "|", with: "\\|")
            let ver = (d.version.isEmpty ? "—" : d.version).replacingOccurrences(of: "|", with: "\\|")
            let status = d.portState.rawValue.uppercased()
            let zone = d.trustZone.displayTitle
            lines.append("| \(cat) | \(dev) | \(room) | `\(ver)` | \(status) | \(zone) |")
        }

        return lines.joined(separator: "\n") + "\n"
    }

    public static func formatCsv(
        siteName: String,
        devices: [RackPortDevice]
    ) -> String {
        let safeSite = siteName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "My Network" : siteName
        let sorted = devices.sorted { lhs, rhs in
            if lhs.category.rawValue != rhs.category.rawValue {
                return lhs.category.rawValue < rhs.category.rawValue
            }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }

        var lines = ["Site,CategoryCode,Category,Name,ShortLabel,Room,Firmware,Status,TrustZone,Lifecycle,PURLs"]
        for d in sorted {
            let cols = [
                safeSite,
                d.category.code,
                d.category.proLabel,
                d.name,
                d.shortLabel,
                d.roomLocation,
                d.version,
                d.portState.rawValue.uppercased(),
                d.trustZone.displayTitle,
                d.lifecycleTier,
                d.purls.joined(separator: "; ")
            ]
            lines.append(cols.map(escapeCsv).joined(separator: ","))
        }
        return lines.joined(separator: "\n") + "\n"
    }

    public static func renderPdfData(
        siteName: String,
        devices: [RackPortDevice],
        generatedAtIso: String = currentTimestampIso()
    ) -> Data {
        let safeSite = siteName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "My Network" : siteName
        let sorted = devices.sorted { lhs, rhs in
            if lhs.category.rawValue != rhs.category.rawValue {
                return lhs.category.rawValue < rhs.category.rawValue
            }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }

        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let margin: CGFloat = 40
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 18),
            .foregroundColor: UIColor(red: 17/255, green: 24/255, blue: 39/255, alpha: 1)
        ]
        let subtitleAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedSystemFont(ofSize: 9.5, weight: .regular),
            .foregroundColor: UIColor(red: 75/255, green: 85/255, blue: 99/255, alpha: 1)
        ]
        let headerAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.monospacedSystemFont(ofSize: 9.5, weight: .bold),
            .foregroundColor: UIColor(red: 229/255, green: 120/255, blue: 25/255, alpha: 1)
        ]
        let rowAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9.5),
            .foregroundColor: UIColor(red: 31/255, green: 41/255, blue: 55/255, alpha: 1)
        ]

        let rowsPerPage = 32
        let pageCount = max(1, Int(ceil(Double(sorted.count) / Double(rowsPerPage))))

        return renderer.pdfData { ctx in
            for pageIndex in 0..<pageCount {
                ctx.beginPage()
                let cg = ctx.cgContext

                var y: CGFloat = 44
                ("\(safeSite) — Hardware Dossier" as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: titleAttrs)
                y += 22
                ("Tuesday.sh Pro • \(sorted.count) tracked devices • Generated \(generatedAtIso) • Page \(pageIndex + 1)/\(pageCount)" as NSString)
                    .draw(at: CGPoint(x: margin, y: y), withAttributes: subtitleAttrs)
                y += 18

                cg.setStrokeColor(UIColor(red: 209/255, green: 213/255, blue: 219/255, alpha: 1).cgColor)
                cg.setLineWidth(0.75)
                cg.move(to: CGPoint(x: margin, y: y))
                cg.addLine(to: CGPoint(x: pageRect.width - margin, y: y))
                cg.strokePath()
                y += 10

                ("CAT" as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: headerAttrs)
                ("DEVICE" as NSString).draw(at: CGPoint(x: margin + 38, y: y), withAttributes: headerAttrs)
                ("ROOM" as NSString).draw(at: CGPoint(x: margin + 235, y: y), withAttributes: headerAttrs)
                ("FIRMWARE" as NSString).draw(at: CGPoint(x: margin + 355, y: y), withAttributes: headerAttrs)
                ("STATUS" as NSString).draw(at: CGPoint(x: margin + 455, y: y), withAttributes: headerAttrs)
                y += 18

                let start = pageIndex * rowsPerPage
                let end = min(start + rowsPerPage, sorted.count)
                if sorted.isEmpty {
                    ("No devices tracked in this network site yet." as NSString)
                        .draw(at: CGPoint(x: margin, y: y), withAttributes: rowAttrs)
                } else {
                    for d in sorted[start..<end] {
                        (d.category.code as NSString).draw(at: CGPoint(x: margin, y: y), withAttributes: rowAttrs)
                        (String(d.name.prefix(32)) as NSString).draw(at: CGPoint(x: margin + 38, y: y), withAttributes: rowAttrs)
                        (String((d.roomLocation.isEmpty ? "—" : d.roomLocation).prefix(18)) as NSString).draw(at: CGPoint(x: margin + 235, y: y), withAttributes: rowAttrs)
                        (String((d.version.isEmpty ? "—" : d.version).prefix(14)) as NSString).draw(at: CGPoint(x: margin + 355, y: y), withAttributes: rowAttrs)
                        (d.portState.rawValue.uppercased() as NSString).draw(at: CGPoint(x: margin + 455, y: y), withAttributes: rowAttrs)
                        y += 19
                    }
                }
            }
        }
    }

    private static func escapeCsv(_ value: String) -> String {
        if !value.contains(",") && !value.contains("\"") && !value.contains("\n") && !value.contains("\r") {
            return value
        }
        return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}
