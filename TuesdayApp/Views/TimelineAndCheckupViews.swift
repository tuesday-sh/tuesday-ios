import SwiftUI

public struct SwimlaneTimelineView: View {
    public let flavor: AppBrandFlavor
    public let palette: BrandPalette
    public let devices: [RackPortDevice]

    public var body: some View {
        let isStn = (flavor == .sureThingHome)

        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(isStn ? "HOME DEVICE LIFESPAN TRACKER" : "Z0 → Z4 LIFECYCLE SWIMLANES (2024 – 2030)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(palette.accent)
                        Spacer()
                        if !isStn {
                            Text("CURSOR: NOW • Zoom: 1M")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(palette.textMuted)
                        }
                    }

                    Text(
                        isStn
                            ? "See how many years of safe manufacturer updates remain on each device in your home."
                            : "Hardware support windows, vendor EOL cutoffs, and active vs. vintage lifecycle tiers."
                    )
                    .font(.system(size: 11))
                    .foregroundColor(palette.textMuted)

                    if !isStn && !devices.isEmpty {
                        SwimlaneCanvasView(devices: devices, palette: palette)
                    }
                }
                .padding(12)
                .background(palette.surface)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(palette.border, lineWidth: 1)
                )
                .uiSlot("timeline-header-card")

                Text(
                    isStn
                        ? "DEVICE SUPPORT & WARRANTY WINDOWS (\(devices.count))"
                        : "PURL DEPENDENCY & ADVISORY LEDGER (\(devices.count) NODES)"
                )
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(palette.textMuted)

                ForEach(devices) { dev in
                    let barColor = TuesdayTheme.ledColor(for: dev.portState, isStn: isStn)
                    let progress: CGFloat = {
                        switch dev.portState {
                        case .eol: return 1.0
                        case .cveKev: return 0.68
                        case .guessed: return 0.50
                        case .update: return 0.35
                        case .ok: return 0.25
                        case .unassigned: return 0.0
                        }
                    }()

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(String(format: "#%02d %@", dev.portIndex, dev.name))
                                        .font(.system(size: 11.5, weight: .bold))
                                        .foregroundColor(palette.textPrimary)
                                    if !isStn {
                                        Text(dev.assetTag)
                                            .font(.system(size: 9, design: .monospaced))
                                            .foregroundColor(palette.textMuted)
                                    }
                                }
                                if !isStn && !dev.purls.isEmpty {
                                    Text(dev.purls.joined(separator: " • "))
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(palette.accent)
                                }
                            }
                            Spacer()
                            if isStn {
                                Text("\(dev.trustZone.stnLabel) • \(dev.lifecycleTier)")
                                    .font(.system(size: 9.5, weight: .bold))
                                    .foregroundColor(barColor)
                            } else {
                                RiskMeterView(portState: dev.portState, isStn: false)
                            }
                        }

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(palette.elevated)
                                    .frame(height: 6)
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(barColor)
                                    .frame(width: max(4, geo.size.width * progress), height: 6)
                            }
                        }
                        .frame(height: 6)

                        Text(isStn ? "\(dev.s3Lifecycle) • Version \(dev.version)" : "\(dev.s3Lifecycle) • \(dev.s4Advisories)")
                            .font(.system(size: 10, design: isStn ? .default : .monospaced))
                            .foregroundColor(palette.textMuted)
                    }
                    .padding(10)
                    .background(palette.surface)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(palette.border, lineWidth: 1)
                    )
                }
            }
            .padding(12)
        }
        .uiComponent("SwimlaneTimelineScreen")
    }
}

public struct SwimlaneCanvasView: View {
    public let devices: [RackPortDevice]
    public let palette: BrandPalette

    public var body: some View {
        Canvas { ctx, size in
            let w = size.width
            let h = size.height
            let footerH: CGFloat = 12.0
            let labelW: CGFloat = 74.0
            let plotW = max(10.0, w - labelW - 10.0)
            let laneCount = CGFloat(max(1, devices.count))
            let laneH = (h - footerH) / laneCount

            for (idx, dev) in devices.enumerated() {
                let yTop = CGFloat(idx) * laneH
                let yCenter = yTop + laneH / 2.0
                let ledColor = TuesdayTheme.ledColor(for: dev.portState, isStn: false)

                let startFrac = CGFloat((idx * 13) % 45) / 100.0 + 0.12
                let endFrac: CGFloat = 0.88
                let x1 = labelW + startFrac * plotW
                let x2 = labelW + endFrac * plotW

                var line = Path()
                line.move(to: CGPoint(x: x1, y: yCenter))
                line.addLine(to: CGPoint(x: x2, y: yCenter))
                ctx.stroke(line, with: .color(ledColor), lineWidth: 2.5)
            }
        }
        .frame(height: 156)
        .background(Color(red: 0x0B / 255.0, green: 0x0D / 255.0, blue: 0x11 / 255.0))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(palette.border, lineWidth: 1)
        )
    }
}

private struct AuditPillarItem {
    let proHeader: String
    let proSummary: String
    let stnHeader: String
    let stnSummary: String
    let state: PortLifecycleState
}

public struct SeasonalCheckupView: View {
    public let flavor: AppBrandFlavor
    public let palette: BrandPalette
    public let devices: [RackPortDevice]

    private let auditPillars: [AuditPillarItem] = [
        AuditPillarItem(
            proHeader: "PILLAR 1 • PUBLISHED RECALLS & CISA KEV",
            proSummary: "1 CPSC Recall (STN-CAM-01) • 1 KEV Patch (STN-IOT-01)",
            stnHeader: "! 1 Published Safety Recall Found",
            stnSummary: "Nursery Baby Monitor has an active manufacturer recall (CPSC-26-104).",
            state: .cveKev
        ),
        AuditPillarItem(
            proHeader: "PILLAR 2 • 0-DAY WORKAROUNDS (S4–S6)",
            proSummary: "STN-GW-01 on latest v4.0.20 (CVE-2026-50881)",
            stnHeader: "↻ 2 Software Updates Available",
            stnSummary: "Living Room LG OLED TV (security fix 8.3.0) and Garage Relay ESP32.",
            state: .eol
        ),
        AuditPillarItem(
            proHeader: "PILLAR 3 • HARDWARE LIFESPAN & EOL (S1)",
            proSummary: "STN-AP-00 Netgear R7000 passed EOL (2025-12-31)",
            stnHeader: "⏳ 1 Retired Device Past Support Cutoff",
            stnSummary: "Basement Netgear R7000 ended manufacturer updates on Dec 31, 2025.",
            state: .cveKev
        ),
        AuditPillarItem(
            proHeader: "PILLAR 4 • DEPENDENCY DRIFT & OCR PIN",
            proSummary: "1 Minor Update (ESPHome) • 1 Unverified Node",
            stnHeader: "🔍 1 Device Needs Model Verification",
            stnSummary: "Hallway Smart Thermostat is matched at 72% confidence — snap label to pin.",
            state: .update
        )
    ]

    public var body: some View {
        let isStn = (flavor == .sureThingHome)
        let nonGreen = devices.filter { $0.portState != .ok && $0.portState != .unassigned }

        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(isStn ? "🏡 R2/R3 FALL HOME CHECKUP • 10 MINS" : "⚡ Q4 FLEET TUNE-UP & REMEDIATION QUEUE")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(palette.accent)

                    Text("\(nonGreen.count) devices have pending lifecycle actions before the quarterly sign-off.")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(palette.textPrimary)

                    ForEach(Array(auditPillars.enumerated()), id: \.offset) { _, pillar in
                        let pColor = TuesdayTheme.ledColor(for: pillar.state, isStn: isStn)
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(isStn ? pillar.stnHeader : pillar.proHeader)
                                    .font(.system(size: isStn ? 11.5 : 9.5, weight: .heavy, design: isStn ? .default : .monospaced))
                                    .foregroundColor(pColor)
                                Text(isStn ? pillar.stnSummary : pillar.proSummary)
                                    .font(.system(size: 11))
                                    .foregroundColor(palette.textPrimary)
                            }
                            Spacer()
                            if !isStn {
                                RiskMeterView(portState: pillar.state, isStn: false)
                            }
                        }
                        .padding(10)
                        .background(palette.elevated)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(palette.border, lineWidth: 1)
                        )
                    }
                }
                .padding(12)
                .background(palette.surface)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(palette.accent.opacity(0.5), lineWidth: 1)
                )
                .uiSlot("r2-quarterly-tuneup-card")

                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(isStn ? "Yearly Lifespan Check (R3)" : "R3 Annual Gear Review (Active / Vintage / Legacy)")
                            .font(.system(size: 11.5, weight: .bold))
                            .foregroundColor(palette.textPrimary)
                        Spacer()
                        Text(isStn ? "1 Retired Model" : "1 Legacy EOL")
                            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                            .foregroundColor(TuesdayTheme.warningAmber)
                    }
                    Text(
                        isStn
                            ? "11 of your 12 devices are Current & Supported. Your Basement Netgear R7000 reached manufacturer End-of-Support on Dec 31, 2025 and no longer receives security updates."
                            : "Cross-referenced against Vendor EOL Schedules & CISA BOD 23-01: STN-AP-00 (Netgear R7000) reached End-of-Support on 2025-12-31 and no longer receives CVE patches."
                    )
                    .font(.system(size: 10.5))
                    .foregroundColor(palette.textMuted)
                }
                .padding(12)
                .background(palette.surface)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(palette.border, lineWidth: 1)
                )
                .uiSlot("r3-annual-review-card")

                ForEach(nonGreen) { dev in
                    let stateColor = TuesdayTheme.ledColor(for: dev.portState, isStn: isStn)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(String(format: "Port #%02d • %@", dev.portIndex, dev.name))
                                .font(.system(size: 11.5, weight: .bold))
                                .foregroundColor(palette.textPrimary)
                            Spacer()
                            Text(isStn ? dev.portState.stnLabel : dev.portState.proLabel)
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(stateColor)
                        }
                        Text(dev.s6Remediation)
                            .font(.system(size: 10.5))
                            .foregroundColor(palette.textMuted)
                    }
                    .padding(10)
                    .background(palette.surface)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(palette.border, lineWidth: 1)
                    )
                }
            }
            .padding(12)
        }
        .uiComponent("SeasonalCheckupScreen")
    }
}
