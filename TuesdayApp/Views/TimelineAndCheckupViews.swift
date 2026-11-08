import SwiftUI

public struct SwimlaneTimelineView: View {
    public let flavor: AppBrandFlavor
    public let palette: BrandPalette
    public let devices: [RackPortDevice]
    public var onOpenReferenceGuide: () -> Void = {}
    public var onInspectDevice: (RackPortDevice) -> Void = { _ in }

    @State private var scrubberXNorm: Double = 0.88

    public init(
        flavor: AppBrandFlavor,
        palette: BrandPalette,
        devices: [RackPortDevice],
        onOpenReferenceGuide: @escaping () -> Void = {},
        onInspectDevice: @escaping (RackPortDevice) -> Void = { _ in }
    ) {
        self.flavor = flavor
        self.palette = palette
        self.devices = devices
        self.onOpenReferenceGuide = onOpenReferenceGuide
        self.onInspectDevice = onInspectDevice
    }

    public var body: some View {
        let isStn = (flavor == .sureThingHome)
        let sortedDevices = BulletinsAndInventoryEngine.sortDevicesForTimeline(devices)
        let scrubMonthIdx = min(23, max(0, Int((scrubberXNorm * 23.0).rounded())))
        let scrubYear = 2025 + (scrubMonthIdx / 12)
        let monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        let scrubMonth = monthNames[scrubMonthIdx % 12]
        let cursorDateText = scrubberXNorm >= 0.86 ? "CURSOR: NOW (\(scrubMonth) \(scrubYear))" : "CURSOR: \(scrubMonth) \(scrubYear)"

        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // 1. Unboxed Lifespan Candlestick Header + Canvas
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(isStn ? "HOME DEVICE LIFESPAN TRACKER" : "Z0 → Z4 LIFECYCLE SWIMLANES (2024 – 2030)")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(palette.accent)
                        Spacer()
                        HStack(spacing: 6) {
                            if !isStn {
                                Text("\(cursorDateText) • Zoom: 1M")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(palette.textMuted)
                            }
                            Button(action: onOpenReferenceGuide) {
                                Text("?")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(palette.textMuted)
                                    .frame(width: 20, height: 20)
                                    .background(palette.elevated)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(palette.border, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                            .uiAction("openReferenceGuide")
                        }
                    }

                    Text(
                        isStn
                            ? "See how many years of safe manufacturer updates remain on each device in your home."
                            : "Drag the timeline cursor horizontally to inspect historical software versions, permissible version candle bodies, and release-to-EOL whiskers."
                    )
                    .font(.system(size: 12))
                    .foregroundColor(palette.textMuted)

                    if !isStn {
                        SwimlaneCanvasView(
                            devices: sortedDevices,
                            palette: palette,
                            scrubberXNorm: $scrubberXNorm
                        )
                    }
                }
                .uiSlot("timeline-header-card")

                // 2. Unboxed Section Header
                VStack(alignment: .leading, spacing: 6) {
                    Divider().background(palette.border)
                    HStack {
                        Text(
                            isStn
                                ? "DEVICE SUPPORT & WARRANTY WINDOWS (\(sortedDevices.count))"
                                : "PURL DEPENDENCY & ADVISORY LEDGER (\(sortedDevices.count) NODES)"
                        )
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(palette.textMuted)
                        Spacer()
                        Text(scrubberXNorm < 0.86 ? "Scrubbed: \(scrubMonth) \(scrubYear)" : "Sorted by Timeline")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(palette.textMuted)
                    }
                }

                // 3. Unboxed Timeline Device List (sorted identically to timeline canvas, no STN-... tags, dynamic version scrubbing)
                if sortedDevices.isEmpty {
                    VStack(spacing: 8) {
                        Divider().background(palette.border)
                        Text("No enrolled devices in inventory yet.")
                            .font(.system(size: 12))
                            .foregroundColor(palette.textMuted)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 12)
                    }
                } else {
                    ForEach(sortedDevices) { dev in
                        let stateColor = TuesdayTheme.ledColor(for: dev.portState, isStn: isStn)
                        let sqTextColor: Color = (dev.portState == .ok || dev.portState == .eol)
                            ? Color(red: 0x09 / 255.0, green: 0x0D / 255.0, blue: 0x0A / 255.0)
                            : .white
                        let scrubbedVersion = BulletinsAndInventoryEngine.getEstimatedVersionAtCursor(
                            device: dev,
                            scrubNorm: scrubberXNorm
                        )

                        Button(action: { onInspectDevice(dev) }) {
                            VStack(alignment: .leading, spacing: 0) {
                                Divider().background(palette.border)
                                HStack(spacing: 10) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(stateColor)
                                            .frame(width: 22, height: 22)
                                        Text("\(dev.portIndex)")
                                            .font(.system(size: 9.5, weight: .heavy, design: .monospaced))
                                            .foregroundColor(sqTextColor)
                                    }

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(dev.name)
                                            .font(.system(size: 12.5, weight: .bold))
                                            .foregroundColor(palette.textPrimary)
                                        HStack(spacing: 4) {
                                            Text("Current:")
                                                .font(.system(size: 11.5))
                                                .foregroundColor(palette.textMuted)
                                            Text(scrubbedVersion)
                                                .font(.system(size: 11.5, weight: .bold, design: .monospaced))
                                                .foregroundColor(palette.textPrimary)
                                            Text("• Release: \(dev.purchaseDate ?? "Known release") • EOL: \(dev.vendorEolAt ?? "TBD")")
                                                .font(.system(size: 11.5))
                                                .foregroundColor(palette.textMuted)
                                                .lineLimit(1)
                                        }
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, 10)
                            }
                        }
                        .buttonStyle(.plain)
                        .uiSlot("device-row", state: "port=\(dev.portIndex);state=\(dev.portState.key)")
                        .uiAction("inspectDevice")
                    }
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
    @Binding public var scrubberXNorm: Double

    public init(
        devices: [RackPortDevice],
        palette: BrandPalette,
        scrubberXNorm: Binding<Double> = .constant(0.88)
    ) {
        self.devices = devices
        self.palette = palette
        self._scrubberXNorm = scrubberXNorm
    }

    public var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let footerH: CGFloat = 12.0
            let labelW: CGFloat = 86.0
            let plotW = max(10.0, w - labelW - 10.0)

            Canvas { ctx, size in
                if devices.isEmpty {
                    let midY = h / 2.0
                    var line = Path()
                    line.move(to: CGPoint(x: 32, y: midY))
                    line.addLine(to: CGPoint(x: w - 32, y: midY))
                    ctx.stroke(line, with: .color(Color(red: 0x22 / 255.0, green: 0x26 / 255.0, blue: 0x31 / 255.0)), lineWidth: 1)
                    return
                }

                // Vertical quarterly grid lines
                let gridCount = 8
                for g in 0...gridCount {
                    let gx = labelW + (plotW * CGFloat(g) / CGFloat(gridCount))
                    var gridLine = Path()
                    gridLine.move(to: CGPoint(x: gx, y: 0))
                    gridLine.addLine(to: CGPoint(x: gx, y: h - footerH))
                    ctx.stroke(gridLine, with: .color(Color(red: 0x1E / 255.0, green: 0x21 / 255.0, blue: 0x2B / 255.0)), lineWidth: 1)
                }

                let laneCount = CGFloat(max(1, devices.count))
                let laneH = (h - footerH) / laneCount

                for (idx, dev) in devices.enumerated() {
                    let yTop = CGFloat(idx) * laneH
                    let yCenter = yTop + laneH / 2.0
                    let ledColor = TuesdayTheme.ledColor(for: dev.portState, isStn: false)

                    if dev.portState == .guessed || dev.version == "unverified" {
                        let gx1 = labelW + 0.55 * plotW
                        let gx2 = labelW + 0.94 * plotW
                        let rect = CGRect(x: gx1, y: yCenter - 3, width: max(6, gx2 - gx1), height: 6)
                        ctx.stroke(
                            Path(rect),
                            with: .color(TuesdayTheme.ledGuessedGrey),
                            style: StrokeStyle(lineWidth: 1.2, dash: [4, 3])
                        )
                    } else {
                        let firstCandle = dev.candles.first
                        let lastCandle = dev.candles.last
                        let wStartNorm = CGFloat(firstCandle?.released ?? 0.08)
                        let wEndNorm = CGFloat(lastCandle?.eol ?? 0.96)
                        let bStartNorm = CGFloat(lastCandle?.attested ?? 0.36)
                        let bEndNorm = CGFloat(lastCandle?.ended ?? 0.90)

                        let xWhiskerStart = labelW + wStartNorm * plotW
                        let xWhiskerEnd = labelW + wEndNorm * plotW
                        let xBodyStart = labelW + bStartNorm * plotW
                        let xBodyEnd = labelW + bEndNorm * plotW

                        // Whisker line + terminal dots
                        var whisker = Path()
                        whisker.move(to: CGPoint(x: xWhiskerStart, y: yCenter))
                        whisker.addLine(to: CGPoint(x: xWhiskerEnd, y: yCenter))
                        ctx.stroke(whisker, with: .color(ledColor.opacity(0.6)), lineWidth: 1.5)

                        let dotStart = CGRect(x: xWhiskerStart - 2, y: yCenter - 2, width: 4, height: 4)
                        let dotEnd = CGRect(x: xWhiskerEnd - 2, y: yCenter - 2, width: 4, height: 4)
                        ctx.fill(Path(ellipseIn: dotStart), with: .color(ledColor))
                        ctx.fill(Path(ellipseIn: dotEnd), with: .color(ledColor))

                        // Candle body (permissible software versions)
                        let candleH = min(8.0, max(5.0, laneH * 0.45))
                        let bodyRect = CGRect(
                            x: xBodyStart,
                            y: yCenter - candleH / 2.0,
                            width: max(6.0, xBodyEnd - xBodyStart),
                            height: candleH
                        )
                        ctx.fill(Path(roundedRect: bodyRect, cornerRadius: 2), with: .color(ledColor.opacity(0.32)))
                        ctx.stroke(Path(roundedRect: bodyRect, cornerRadius: 2), with: .color(ledColor), lineWidth: 1.2)

                        // Bright white vertical tick line for Current Version
                        let currentFrac: CGFloat = (dev.portState == .update) ? 0.35 : 0.90
                        let xCurrent = bodyRect.minX + bodyRect.width * currentFrac
                        var tick = Path()
                        tick.move(to: CGPoint(x: xCurrent, y: yCenter - candleH / 2.0 - 1.5))
                        tick.addLine(to: CGPoint(x: xCurrent, y: yCenter + candleH / 2.0 + 1.5))
                        ctx.stroke(tick, with: .color(.white), lineWidth: 2.0)
                    }
                }

                // Scrubber vertical cursor line
                let scrubX = labelW + CGFloat(scrubberXNorm) * plotW
                var cursorLine = Path()
                cursorLine.move(to: CGPoint(x: scrubX, y: 0))
                cursorLine.addLine(to: CGPoint(x: scrubX, y: h - footerH))
                ctx.stroke(cursorLine, with: .color(palette.accent), lineWidth: 1.5)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let norm = Double((value.location.x - labelW) / plotW)
                        scrubberXNorm = min(1.0, max(0.0, norm))
                    }
            )
        }
        .frame(height: 196)
        .background(Color(red: 0x0B / 255.0, green: 0x0D / 255.0, blue: 0x11 / 255.0))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(palette.border, lineWidth: 1)
        )
    }
}

// Retained audit pillar constants for D7 cross-platform parity verification:
// PILLAR 1 • PUBLISHED RECALLS & CISA KEV
// PILLAR 2 • 0-DAY WORKAROUNDS (S4–S6)
// PILLAR 3 • HARDWARE LIFESPAN & EOL (S1)
// PILLAR 4 • DEPENDENCY DRIFT & OCR PIN
public let CANONICAL_AUDIT_PILLAR_LABELS: [String] = [
    "PILLAR 1 • PUBLISHED RECALLS & CISA KEV",
    "PILLAR 2 • 0-DAY WORKAROUNDS (S4–S6)",
    "PILLAR 3 • HARDWARE LIFESPAN & EOL (S1)",
    "PILLAR 4 • DEPENDENCY DRIFT & OCR PIN"
]

public func hasActiveCheckupRecommendation(
    devices: [RackPortDevice],
    welcomeComplete: Bool = false
) -> Bool {
    if !welcomeComplete { return true }
    return devices.contains {
        $0.portState == .cveKev || $0.portState == .eol || $0.portState == .guessed
    }
}

private struct RhythmPostureRowItem: Identifiable {
    let id: String
    let title: String
    let action: String?
    let recommendation: String?
    let accentColor: Color
}

public struct SeasonalCheckupView: View {
    public let flavor: AppBrandFlavor
    public let palette: BrandPalette
    public let devices: [RackPortDevice]
    public var welcomeComplete: Bool = false
    public var onOpenReferenceGuide: () -> Void = {}

    @Environment(\.openURL) private var openURL

    public init(
        flavor: AppBrandFlavor,
        palette: BrandPalette,
        devices: [RackPortDevice],
        welcomeComplete: Bool = false,
        onOpenReferenceGuide: @escaping () -> Void = {}
    ) {
        self.flavor = flavor
        self.palette = palette
        self.devices = devices
        self.welcomeComplete = welcomeComplete
        self.onOpenReferenceGuide = onOpenReferenceGuide
    }

    public var body: some View {
        let isStn = (flavor == .sureThingHome)
        let isDayZero = devices.isEmpty
        let provisionalCount = devices.filter { $0.portState == .guessed }.count
        let nonGreen = devices.filter { $0.portState != .ok && $0.portState != .unassigned }

        let rhythms: [RhythmPostureRowItem] = {
            if !isStn {
                let r1Action: String? = isDayZero ? nil : (provisionalCount > 0 ? "\(provisionalCount) provisional candidate model to verify (Ecobee)" : nil)
                let r2Action: String? = !welcomeComplete ? "Welcome Bulletin: Complete 3-step setup before Patch Tuesday (Nov 10, 2026)." : nil
                let r3Action: String? = isDayZero ? nil : "1 CPSC Recall (STN-CAM-01) • 1 CVE-2026-50881 workaround • Check router admin password"
                let r4Action: String? = isDayZero ? nil : "1 EOL Device: STN-AP-00 Netgear R7000 passed vendor support"

                return [
                    RhythmPostureRowItem(
                        id: "r1",
                        title: "R1 • NEW HARDWARE INTAKE & ATTESTATION",
                        action: r1Action,
                        recommendation: r1Action != nil ? "Confirm exact thermostat model on Bulletins tab or scan barcode." : nil,
                        accentColor: TuesdayTheme.ledEolAmber
                    ),
                    RhythmPostureRowItem(
                        id: "r2",
                        title: "R2 • MONTHLY PATCH TUESDAY READINESS",
                        action: r2Action,
                        recommendation: r2Action != nil ? "Check Welcome Bulletin: [1 Add Router, 2 Enable 10:00 AM PT Push, 3 Subscribe Dispatch]." : nil,
                        accentColor: palette.accent
                    ),
                    RhythmPostureRowItem(
                        id: "r3",
                        title: "R3 • SEASONAL SAFETY, PASSWORDS & DRIFT AUDIT",
                        action: r3Action,
                        recommendation: r3Action != nil ? "Check router admin password, disable WAN management, resolve baby cam recall." : nil,
                        accentColor: TuesdayTheme.ledCveRed
                    ),
                    RhythmPostureRowItem(
                        id: "r4",
                        title: "R4 • YEARLY HARDWARE LIFESPAN & EOL",
                        action: r4Action,
                        recommendation: r4Action != nil ? "Plan replacement or move Netgear R7000 off Z0 Core." : nil,
                        accentColor: TuesdayTheme.ledEolAmber
                    )
                ]
            } else {
                let r1Action: String? = isDayZero ? nil : (provisionalCount > 0 ? "\(provisionalCount) device needs model confirmation (Hallway Thermostat)" : nil)
                let r2Action: String? = !welcomeComplete ? "Welcome Bulletin: Complete your 3-step home readiness setup before Patch Tuesday." : nil
                let r3Action: String? = isDayZero ? nil : "1 Baby Monitor Safety Recall • 2 Software Updates • Verify Wi-Fi password"
                let r4Action: String? = isDayZero ? nil : "1 Retired Device: Basement Netgear R7000 ended manufacturer updates"

                return [
                    RhythmPostureRowItem(
                        id: "r1",
                        title: "R1 • Plug & Tag New Devices",
                        action: r1Action,
                        recommendation: r1Action != nil ? "Tap Confirm on your Bulletins tab or snap a photo of the label." : nil,
                        accentColor: TuesdayTheme.ledEolAmber
                    ),
                    RhythmPostureRowItem(
                        id: "r2",
                        title: "R2 • Monthly Patch Tuesday Check",
                        action: r2Action,
                        recommendation: r2Action != nil ? "Add your router, turn on 10:00 AM PT reminders, and subscribe to the monthly digest." : nil,
                        accentColor: palette.accent
                    ),
                    RhythmPostureRowItem(
                        id: "r3",
                        title: "R3 • Seasonal Home Safety & Wi-Fi Password Check",
                        action: r3Action,
                        recommendation: r3Action != nil ? "Check baby monitor power cord, update LG TV, and review your guest Wi-Fi password." : nil,
                        accentColor: TuesdayTheme.ledCveRed
                    ),
                    RhythmPostureRowItem(
                        id: "r4",
                        title: "R4 • Yearly Device Lifespan & Retirement",
                        action: r4Action,
                        recommendation: r4Action != nil ? "Replace your 2016 Netgear router with a modern supported Wi-Fi access point." : nil,
                        accentColor: TuesdayTheme.ledEolAmber
                    )
                ]
            }
        }()

        let activeActionCount = rhythms.filter { $0.action != nil }.count

        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // 1. Unboxed Check-Up Header + Action Buttons (?, Ask Claude, Share)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        HStack(spacing: 6) {
                            Text(isStn ? "🏡 HOME CHECK-UPS (R1 → R4)" : "⚡ CHECK-UPS • 4 OPERATIONAL RHYTHMS")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(palette.accent)
                            Button(action: onOpenReferenceGuide) {
                                Text("?")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(palette.textMuted)
                                    .frame(width: 20, height: 20)
                                    .background(palette.elevated)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(palette.border, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                            .uiAction("openReferenceGuide")
                        }
                        Spacer()
                        HStack(spacing: 6) {
                            Button(action: {
                                if let url = URL(string: "https://claude.ai/new?q=Help+me+review+my+network+checkup+recommendations") {
                                    openURL(url)
                                }
                            }) {
                                Text("✦ Ask Claude")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(palette.accent)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(palette.accent.opacity(0.14))
                                    .cornerRadius(6)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(palette.accent.opacity(0.35), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                            .uiAction("askClaudeCheckup")

                            Button(action: {}) {
                                Text("Share")
                                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                    .foregroundColor(palette.textPrimary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(palette.elevated)
                                    .cornerRadius(6)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(palette.border, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                            .uiAction("shareCheckupReport")
                        }
                    }

                    Text(
                        activeActionCount > 0
                            ? "\(activeActionCount) of 4 operational rhythms have active recommendations."
                            : "All 4 operational rhythms are healthy — Everything OK."
                    )
                    .font(.system(size: 12.5, weight: .bold))
                    .foregroundColor(palette.textPrimary)

                    // 2. Unboxed 4-Rhythm Posture List (R1 -> R4)
                    ForEach(rhythms) { item in
                        let hasAction = (item.action != nil)
                        VStack(alignment: .leading, spacing: 0) {
                            Divider().background(palette.border)
                            HStack(alignment: .top, spacing: 10) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(hasAction ? item.accentColor : palette.border)
                                    .frame(width: hasAction ? 4 : 2, height: hasAction ? 52 : 30)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.title)
                                        .font(.system(size: 11.5, weight: .heavy, design: isStn ? .default : .monospaced))
                                        .foregroundColor(hasAction ? item.accentColor : palette.textMuted)
                                    if let action = item.action {
                                        Text(action)
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(palette.textPrimary)
                                        if let rec = item.recommendation {
                                            Text("💡 Recommendation: \(rec)")
                                                .font(.system(size: 11.5))
                                                .foregroundColor(palette.textMuted)
                                        }
                                    } else {
                                        Text("Everything OK")
                                            .font(.system(size: 11.5))
                                            .foregroundColor(palette.textMuted)
                                    }
                                }
                                Spacer()
                            }
                            .padding(.vertical, 10)
                            .opacity(hasAction ? 1.0 : 0.72)
                        }
                    }
                }
                .uiSlot("r2-quarterly-tuneup-card")

                // 3. Unboxed R4 Annual Lifespan Summary
                VStack(alignment: .leading, spacing: 6) {
                    Divider().background(palette.border)
                    HStack {
                        Text(isStn ? "Yearly Lifespan Check (R4)" : "R4 Annual Gear Review (Active / Vintage / Legacy)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(palette.textPrimary)
                        Spacer()
                        Text(isDayZero ? "Everything OK" : (isStn ? "1 Retired Model" : "1 Legacy EOL"))
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(isDayZero ? palette.textMuted : TuesdayTheme.warningAmber)
                    }
                    .padding(.top, 6)

                    Text(
                        isDayZero
                            ? "Everything OK"
                            : (isStn
                                ? "11 of your 12 devices are Current & Supported. Your Basement Netgear R7000 reached manufacturer End-of-Support on Dec 31, 2025 and no longer receives security updates."
                                : "Cross-referenced against Vendor EOL Schedules & CISA BOD 23-01: STN-AP-00 (Netgear R7000) reached End-of-Support on 2025-12-31 and no longer receives CVE patches.")
                    )
                    .font(.system(size: 11.5))
                    .foregroundColor(palette.textMuted)
                }
                .uiSlot("r3-annual-review-card")

                // 4. Unboxed Per-Device Remediation Queue
                ForEach(nonGreen) { dev in
                    let stateColor = TuesdayTheme.ledColor(for: dev.portState, isStn: isStn)
                    VStack(alignment: .leading, spacing: 4) {
                        Divider().background(palette.border)
                        HStack {
                            Text(String(format: "Port #%02d • %@", dev.portIndex, dev.name))
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(palette.textPrimary)
                            Spacer()
                            Text(isStn ? dev.portState.stnLabel : dev.portState.proLabel)
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(stateColor)
                        }
                        .padding(.top, 6)

                        Text(dev.s6Remediation)
                            .font(.system(size: 11.5))
                            .foregroundColor(palette.textMuted)
                    }
                }
            }
            .padding(12)
        }
        .uiComponent("SeasonalCheckupScreen")
    }
}
