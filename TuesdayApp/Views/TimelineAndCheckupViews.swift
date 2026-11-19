import SwiftUI

public func hasActiveCheckupRecommendation(
    devices: [RackPortDevice],
    welcomeComplete: Bool = false
) -> Bool {
    RhythmPostureEvaluator.hasActiveRecommendation(devices: devices, welcomeComplete: welcomeComplete)
}

public struct SwimlaneTimelineView: View {
    public let devices: [RackPortDevice]
    public let attestations: [DeviceAttestation]
    public let flavor: AppBrandFlavor
    public let palette: BrandPalette
    public var initialModal: String? = nil
    public var onConsumeInitialModal: () -> Void = {}
    public let onInspectDevice: (RackPortDevice) -> Void
    public let onRecordAttestation: (String, AttestationType, DevicePresenceState, String, String?) -> Void
    public let onRecordBatchAttestation: ([String], String, String, String?) -> Void

    @State private var scrubberXNorm: Double = 0.72
    @State private var selectedCandleForAttestation: OperationalCandle? = nil
    @State private var showBatchAuditModal: Bool = false

    public init(
        devices: [RackPortDevice],
        attestations: [DeviceAttestation] = [],
        flavor: AppBrandFlavor,
        palette: BrandPalette,
        initialModal: String? = nil,
        onConsumeInitialModal: @escaping () -> Void = {},
        onInspectDevice: @escaping (RackPortDevice) -> Void,
        onRecordAttestation: @escaping (String, AttestationType, DevicePresenceState, String, String?) -> Void = { _, _, _, _, _ in },
        onRecordBatchAttestation: @escaping ([String], String, String, String?) -> Void = { _, _, _, _ in }
    ) {
        self.devices = devices
        self.attestations = attestations
        self.flavor = flavor
        self.palette = palette
        self.initialModal = initialModal
        self.onConsumeInitialModal = onConsumeInitialModal
        self.onInspectDevice = onInspectDevice
        self.onRecordAttestation = onRecordAttestation
        self.onRecordBatchAttestation = onRecordBatchAttestation
    }

    public var body: some View {
        let isStn = (flavor == .sureThingHome)
        let sortedDevices = BulletinsAndInventoryEngine.sortDevicesForTimeline(devices)
        let candles = sortedDevices.map { BulletinsAndInventoryEngine.toOperationalCandle($0, attestations: attestations) }
        let cursorDateText = TimelineStatusEvaluator.formatScrubberCursorDate(scrubberXNorm: scrubberXNorm)

        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(isStn ? "HARDWARE LIFESPAN" : "OPERATIONAL LIFESPAN & EOL")
                                .font(.system(size: 11.5, weight: .heavy, design: .monospaced))
                                .foregroundColor(palette.textMuted)
                            Text("Cursor: \(cursorDateText)")
                                .font(.system(size: 12.5, weight: .bold, design: .monospaced))
                                .foregroundColor(palette.accentText)
                        }
                        Spacer()
                        Button(action: { showBatchAuditModal = true }) {
                            Text("✓ Annual Check-In")
                                .font(.system(size: 11.5, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .frame(minHeight: 32)
                                .background(palette.accent)
                                .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusBadge))
                        }
                        .buttonStyle(.plain)
                        .disabled(candles.isEmpty)
                    }

                    SwimlaneCanvasView(
                        candles: candles,
                        palette: palette,
                        scrubberXNorm: $scrubberXNorm
                    )
                    .frame(height: candles.isEmpty ? 110 : CGFloat(max(180, candles.count * 22 + 24)))
                    .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
                    .overlay(
                        RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl)
                            .stroke(palette.border, lineWidth: 1)
                    )

                    Text("Drag or tap chart to inspect historical firmware releases & projected EOL windows.")
                        .font(.system(size: 11.5))
                        .foregroundColor(palette.textMuted)
                }
                .padding(12)
                .background(palette.surface)
                .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard))
                .overlay(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard).stroke(palette.border, lineWidth: 1))
                .uiSlot("timeline-header-card")

                SurfaceListContainer(palette: palette) {
                    if sortedDevices.isEmpty {
                        Text("No hardware devices to display on the timeline yet.")
                            .font(.system(size: 13))
                            .foregroundColor(palette.textMuted)
                            .padding(14)
                    } else {
                        ForEach(Array(zip(sortedDevices.indices, zip(sortedDevices, candles))), id: \.1.0.id) { idx, pair in
                            let (dev, candle) = pair
                            if idx > 0 { SurfaceListDivider(palette: palette) }
                            let summary = TimelineStatusEvaluator.evaluateCandleStatus(candle: candle, attestations: attestations)
                            let scrubbedVersion = BulletinsAndInventoryEngine.getEstimatedVersionAtCursor(
                                device: dev,
                                scrubNorm: scrubberXNorm
                            )
                            let stateColor = candle.presenceState.isOutOfService
                                ? TuesdayTheme.presenceColor(for: candle.presenceState, isStn: isStn)
                                : TuesdayTheme.ledColor(for: dev.portState, isStn: isStn)

                            VStack(alignment: .leading, spacing: 6) {
                                Button(action: { onInspectDevice(dev) }) {
                                    HStack(spacing: 10) {
                                        HardwareCategoryIcon(category: dev.category, tint: stateColor, size: 18)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(dev.name)
                                                .font(.system(size: 13.5, weight: .bold))
                                                .foregroundColor(palette.textPrimary)
                                            Text("\(summary.statusText) • Ver: \(scrubbedVersion)")
                                                .font(.system(size: 11.5, weight: .medium, design: .monospaced))
                                                .foregroundColor(stateColor)
                                        }
                                        Spacer()
                                        if summary.needsStatusCheck {
                                            Button(action: { selectedCandleForAttestation = candle }) {
                                                Text("Verify")
                                                    .font(.system(size: 11, weight: .bold))
                                                    .foregroundColor(palette.accentText)
                                                    .padding(.horizontal, 8)
                                                    .frame(minHeight: 26)
                                                    .background(palette.accent.opacity(0.14))
                                                    .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusBadge))
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)

                                CondensedMiniCandleBar(candle: candle, palette: palette)
                                    .frame(height: 10)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                        }
                    }
                }
            }
            .padding(.horizontal, TuesdayDimens.screenPaddingHorizontal)
            .padding(.vertical, 12)
        }
        .background(palette.bg.ignoresSafeArea())
        .uiComponent("SwimlaneTimelineScreen")
        .onAppear {
            if initialModal == "checkin", !candles.isEmpty {
                showBatchAuditModal = true
                onConsumeInitialModal()
            }
        }
        .sheet(item: $selectedCandleForAttestation) { candle in
            LifecycleAttestationSheet(
                candle: candle,
                palette: palette,
                onSubmit: { type, presence, date, notes in
                    onRecordAttestation(candle.id, type, presence, date, notes)
                    selectedCandleForAttestation = nil
                },
                onDismiss: { selectedCandleForAttestation = nil }
            )
        }
        .sheet(isPresented: $showBatchAuditModal) {
            BatchAuditModalView(
                candles: candles,
                palette: palette,
                onSubmitBatch: { ids, date, sessionId, notes in
                    onRecordBatchAttestation(ids, date, sessionId, notes)
                    showBatchAuditModal = false
                },
                onDismiss: { showBatchAuditModal = false }
            )
        }
    }
}

public struct SwimlaneCanvasView: View {
    public let candles: [OperationalCandle]
    public let palette: BrandPalette
    @Binding public var scrubberXNorm: Double

    public var body: some View {
        let isStn = palette.isStn
        let labelW: CGFloat = 92

        GeometryReader { geo in
            Canvas { context, size in
                let w = size.width
                let h = size.height
                let footerH: CGFloat = 14
                let plotW = max(20, w - labelW - 10)

                context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(palette.chassisRecessed))

                if candles.isEmpty {
                    let midY = h / 2
                    var line = Path()
                    line.move(to: CGPoint(x: 32, y: midY))
                    line.addLine(to: CGPoint(x: w - 32, y: midY))
                    context.stroke(line, with: .color(palette.border), lineWidth: 1)
                    context.draw(
                        Text("No Hardware Devices in Inventory")
                            .font(.system(size: 12.5, weight: .bold))
                            .foregroundColor(palette.textPrimary),
                        at: CGPoint(x: w / 2, y: midY - 14)
                    )
                    context.draw(
                        Text("Add a device or seed inventory to visualize hardware lifecycles")
                            .font(.system(size: 11))
                            .foregroundColor(palette.textMuted),
                        at: CGPoint(x: w / 2, y: midY + 14)
                    )
                    return
                }

                let okColor = TuesdayTheme.ledColor(for: .ok, isStn: isStn)
                let cveColor = TuesdayTheme.ledColor(for: .cveKev, isStn: isStn)
                let eolColor = TuesdayTheme.ledColor(for: .eol, isStn: isStn)
                let overhangColor = TuesdayTheme.overhangColor(isStn: isStn)

                for i in 0...6 {
                    let gx = labelW + plotW * CGFloat(i) / 6.0
                    var grid = Path()
                    grid.move(to: CGPoint(x: gx, y: 0))
                    grid.addLine(to: CGPoint(x: gx, y: h - footerH))
                    context.stroke(grid, with: .color(palette.border.opacity(0.6)), lineWidth: 1)
                }

                let laneH = (h - footerH) / CGFloat(max(1, candles.count))

                for (idx, candle) in candles.enumerated() {
                    let yTop = CGFloat(idx) * laneH
                    let yCenter = yTop + laneH / 2
                    let zoneColor = TuesdayTheme.zoneColor(for: candle.trustZone, isStn: isStn)

                    context.fill(
                        Path(CGRect(x: 0, y: yTop + 2, width: 3, height: max(2, laneH - 4))),
                        with: .color(zoneColor)
                    )
                    context.draw(
                        Text(candle.shortLabel)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(palette.textPrimary),
                        at: CGPoint(x: 7, y: yCenter),
                        anchor: .leading
                    )

                    var laneBase = Path()
                    laneBase.move(to: CGPoint(x: labelW, y: yCenter))
                    laneBase.addLine(to: CGPoint(x: labelW + plotW, y: yCenter))
                    context.stroke(laneBase, with: .color(palette.border.opacity(0.45)), lineWidth: 1)

                    let xRel = labelW + CGFloat(candle.marketReleaseNorm) * plotW
                    let xDeployStart = labelW + CGFloat(candle.deployStartNorm) * plotW
                    let xDeployEnd = labelW + CGFloat(candle.deployEndNorm) * plotW
                    let xEol = labelW + CGFloat(candle.vendorEolNorm) * plotW
                    let candleH = min(10, max(6, laneH * 0.46))
                    let cTop = yCenter - candleH / 2

                    if xDeployStart > xRel {
                        var wick = Path()
                        wick.move(to: CGPoint(x: xRel, y: yCenter))
                        wick.addLine(to: CGPoint(x: xDeployStart, y: yCenter))
                        context.stroke(wick, with: .color(palette.textMuted), lineWidth: 1.2)
                        context.fill(Path(ellipseIn: CGRect(x: xRel - 2, y: yCenter - 2, width: 4, height: 4)), with: .color(palette.textMuted))
                    }

                    let supportedEnd = min(xDeployEnd, xEol)
                    let supportedW = max(3, supportedEnd - xDeployStart)
                    let bodyColor: Color = {
                        if candle.presenceState.isOutOfService {
                            return TuesdayTheme.presenceColor(for: candle.presenceState, isStn: isStn)
                        }
                        if candle.hasCveOrRecall { return cveColor }
                        if candle.isPastEol { return overhangColor }
                        if candle.isEolNearing { return eolColor }
                        return okColor
                    }()

                    let barRect = CGRect(x: xDeployStart, y: cTop, width: supportedW, height: candleH)
                    if candle.isGuessed || candle.presenceState == .lost {
                        context.fill(Path(barRect), with: .color(bodyColor.opacity(0.20)))
                        context.stroke(
                            Path(barRect),
                            with: .color(candle.isGuessed ? palette.textMuted : bodyColor),
                            style: StrokeStyle(lineWidth: 1.1, dash: [4, 4])
                        )
                    } else if candle.presenceState == .retired || candle.presenceState == .stoppedWorking {
                        context.fill(Path(barRect), with: .color(bodyColor.opacity(0.16)))
                        context.stroke(Path(barRect), with: .color(bodyColor), lineWidth: 1.2)
                    } else {
                        context.fill(Path(barRect), with: .color(bodyColor))
                    }

                    // Post-EOL active overhang crimson stripe + hatch
                    if candle.isPastEol && xDeployEnd > xEol {
                        let overhangW = max(3, xDeployEnd - xEol)
                        let overRect = CGRect(x: xEol, y: cTop, width: overhangW, height: candleH)
                        context.fill(Path(overRect), with: .color(cveColor))

                        var eolMarker = Path()
                        eolMarker.move(to: CGPoint(x: xEol, y: cTop - 2))
                        eolMarker.addLine(to: CGPoint(x: xEol, y: cTop + candleH + 2))
                        context.stroke(eolMarker, with: .color(palette.textPrimary), lineWidth: 1.5)

                        var hx = xEol
                        while hx < xEol + overhangW + candleH {
                            let p1x = min(max(hx - candleH, xEol), xEol + overhangW)
                            let p2x = min(max(hx, xEol), xEol + overhangW)
                            if p2x > p1x {
                                var hatch = Path()
                                hatch.move(to: CGPoint(x: p1x, y: cTop + candleH))
                                hatch.addLine(to: CGPoint(x: p2x, y: cTop))
                                context.stroke(hatch, with: .color(.white.opacity(0.65)), lineWidth: 1)
                            }
                            hx += 4
                        }
                    }

                    // Remaining supported runway tail
                    if !candle.isPastEol && xEol > xDeployEnd {
                        let runwayColor = candle.isEolNearing ? eolColor : palette.textMuted
                        var runway = Path()
                        runway.move(to: CGPoint(x: xDeployEnd, y: yCenter))
                        runway.addLine(to: CGPoint(x: xEol, y: yCenter))
                        context.stroke(runway, with: .color(runwayColor), lineWidth: 1.2)
                        context.fill(Path(ellipseIn: CGRect(x: xEol - 2, y: yCenter - 2, width: 4, height: 4)), with: .color(runwayColor))
                    }

                    // CVE onset warning triangle
                    if let cveNorm = candle.cveStartNorm {
                        let cx = labelW + CGFloat(cveNorm) * plotW
                        var tri = Path()
                        tri.move(to: CGPoint(x: cx, y: cTop - 5))
                        tri.addLine(to: CGPoint(x: cx - 3.5, y: cTop))
                        tri.addLine(to: CGPoint(x: cx + 3.5, y: cTop))
                        tri.closeSubpath()
                        context.fill(tri, with: .color(cveColor))
                    }
                }

                // Scrubber track & needle
                let fy = h - footerH + 5
                context.fill(Path(CGRect(x: labelW, y: fy, width: plotW, height: 3)), with: .color(palette.borderStrong))

                let scrubX = labelW + CGFloat(scrubberXNorm) * plotW
                var scrub = Path()
                scrub.move(to: CGPoint(x: scrubX, y: 0))
                scrub.addLine(to: CGPoint(x: scrubX, y: h - footerH))
                context.stroke(scrub, with: .color(palette.accent), lineWidth: 1.6)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let plotW = max(10, geo.size.width - labelW - 10)
                        let norm = Double((value.location.x - labelW) / plotW)
                        scrubberXNorm = min(1.0, max(0.0, norm))
                    }
            )
        }
    }
}

public struct CondensedMiniCandleBar: View {
    public let candle: OperationalCandle
    public let palette: BrandPalette

    public var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            let barH: CGFloat = 5
            let top = (h - barH) / 2
            context.fill(Path(roundedRect: CGRect(x: 0, y: top, width: w, height: barH), cornerRadius: 2), with: .color(palette.bg))

            let startX = CGFloat(candle.deployStartNorm) * w
            let endX = CGFloat(min(candle.deployEndNorm, candle.vendorEolNorm)) * w
            let color = candle.hasCveOrRecall
                ? TuesdayTheme.ledColor(for: .cveKev, isStn: palette.isStn)
                : (candle.isPastEol
                    ? TuesdayTheme.overhangColor(isStn: palette.isStn)
                    : TuesdayTheme.ledColor(for: .ok, isStn: palette.isStn))
            context.fill(Path(roundedRect: CGRect(x: startX, y: top, width: max(4, endX - startX), height: barH), cornerRadius: 2), with: .color(color))

            let todayX = 0.72 * w
            context.fill(Path(CGRect(x: todayX - 1, y: 0, width: 2, height: h)), with: .color(palette.accent))
        }
    }
}

private struct LifecycleAttestationSheet: View {
    let candle: OperationalCandle
    let palette: BrandPalette
    let onSubmit: (AttestationType, DevicePresenceState, String, String?) -> Void
    let onDismiss: () -> Void

    @State private var selectedPresence: DevicePresenceState
    @State private var selectedType: AttestationType = .physicalInspect
    @State private var notes: String = ""

    init(
        candle: OperationalCandle,
        palette: BrandPalette,
        onSubmit: @escaping (AttestationType, DevicePresenceState, String, String?) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.candle = candle
        self.palette = palette
        self.onSubmit = onSubmit
        self.onDismiss = onDismiss
        _selectedPresence = State(initialValue: candle.presenceState)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text(candle.name)
                        .font(.system(size: 17, weight: .heavy))
                        .foregroundColor(palette.textPrimary)

                    Text("Confirm physical presence and lifecycle state for local annual audit compliance.")
                        .font(.system(size: 13))
                        .foregroundColor(palette.textMuted)

                    Picker("Presence State", selection: $selectedPresence) {
                        ForEach(DevicePresenceState.allCases) { p in
                            Text(palette.isStn ? p.stnLabel : p.badgeLabel).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker("Check Type", selection: $selectedType) {
                        ForEach(AttestationType.allCases) { t in
                            Text(t.displayLabel).tag(t)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(palette.accentText)

                    TuesdayTextField(text: $notes, label: "Audit Note (Optional)", placeholder: "e.g. Verified plugged in & updated", palette: palette)

                    Button(action: {
                        onSubmit(selectedType, selectedPresence, TimelineStatusEvaluator.defaultReferenceDate, notes.isEmpty ? nil : notes)
                    }) {
                        Text("Record Check-In")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(palette.accent)
                            .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
            }
            .background(palette.bg.ignoresSafeArea())
            .navigationTitle("Verify Hardware")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onDismiss)
                        .foregroundColor(palette.accentText)
                }
            }
        }
    }
}

private struct BatchAuditModalView: View {
    let candles: [OperationalCandle]
    let palette: BrandPalette
    let onSubmitBatch: ([String], String, String, String?) -> Void
    let onDismiss: () -> Void

    @State private var selectedIds: Set<String>
    @State private var notes: String = ""

    init(
        candles: [OperationalCandle],
        palette: BrandPalette,
        onSubmitBatch: @escaping ([String], String, String, String?) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.candles = candles
        self.palette = palette
        self.onSubmitBatch = onSubmitBatch
        self.onDismiss = onDismiss
        _selectedIds = State(initialValue: Set(candles.map(\.id)))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Mark devices physically verified and still in service for your seasonal/yearly audit.")
                        .font(.system(size: 13))
                        .foregroundColor(palette.textMuted)

                    SurfaceListContainer(palette: palette) {
                        ForEach(Array(candles.enumerated()), id: \.element.id) { idx, candle in
                            if idx > 0 { SurfaceListDivider(palette: palette) }
                            let isChecked = selectedIds.contains(candle.id)
                            TuesdayListRow(
                                palette: palette,
                                title: candle.name,
                                onClick: {
                                    if isChecked { selectedIds.remove(candle.id) }
                                    else { selectedIds.insert(candle.id) }
                                },
                                leading: {
                                    Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(isChecked ? palette.accent : palette.textMuted)
                                },
                                subtitle: {
                                    Text("\(candle.shortLabel) • \(candle.version)")
                                        .font(.system(size: 11.5))
                                        .foregroundColor(palette.textMuted)
                                },
                                trailing: { EmptyView() }
                            )
                        }
                    }

                    TuesdayTextField(text: $notes, label: "Session Note (Optional)", placeholder: "e.g. Q4 Basement Closet check", palette: palette)

                    Button(action: {
                        onSubmitBatch(
                            Array(selectedIds),
                            TimelineStatusEvaluator.defaultReferenceDate,
                            "batch-\(Int(Date().timeIntervalSince1970))",
                            notes.isEmpty ? nil : notes
                        )
                    }) {
                        Text("Complete Check-In (\(selectedIds.count) Devices)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(selectedIds.isEmpty ? palette.borderStrong : palette.accent)
                            .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
                    }
                    .buttonStyle(.plain)
                    .disabled(selectedIds.isEmpty)
                }
                .padding(14)
            }
            .background(palette.bg.ignoresSafeArea())
            .navigationTitle("Annual Fleet Check-In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onDismiss)
                        .foregroundColor(palette.accentText)
                }
            }
        }
    }
}

public struct SeasonalCheckupView: View {
    public let devices: [RackPortDevice]
    public let bulletins: [BulletinInboxView]
    public let flavor: AppBrandFlavor
    public let palette: BrandPalette
    public var welcomeComplete: Bool = false

    public init(
        devices: [RackPortDevice],
        bulletins: [BulletinInboxView] = [],
        flavor: AppBrandFlavor,
        palette: BrandPalette,
        welcomeComplete: Bool = false
    ) {
        self.devices = devices
        self.bulletins = bulletins
        self.flavor = flavor
        self.palette = palette
        self.welcomeComplete = welcomeComplete
    }

    public var body: some View {
        let isStn = (flavor == .sureThingHome)
        let postureItems = RhythmPostureEvaluator.evaluatePosture(
            flavor: flavor,
            devices: devices,
            bulletins: bulletins,
            welcomeComplete: welcomeComplete
        )
        let shareReport = RhythmPostureEvaluator.formatShareReport(flavor: flavor, items: postureItems)
        let pillars: [(String, String, String)] = [
            ("PILLAR 1", isStn ? "Wi-Fi & Admin Password Check" : "Perimeter Credential & WAN Drift", isStn ? "Verify router admin password isn't factory default." : "Confirm SSH/API keys & disable remote WAN admin."),
            ("PILLAR 2", isStn ? "Guest & Kids Isolation" : "Z3/Z4 VLAN & Smart Home Segmentation", isStn ? "Keep visitors and cheap smart plugs on Guest Wi-Fi." : "Enforce firewall blocks from Z3 IoT -> Z0/Z1."),
            ("PILLAR 3", isStn ? "Firmware & Critical Fixes" : "Patch Tuesday & CISA KEV SLA", isStn ? "Apply queued security patches to router & TV." : "Remediate open CVE/KEV advisories inside 72h window."),
            ("PILLAR 4", isStn ? "Retire Old Hardware" : "EOL Cutoff & Physical Attestation", isStn ? "Unplug unsupported electronics past maker support." : "Inspect inventory & retire past-EOL Z0 gear.")
        ]

        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(isStn ? "HOME SAFETY CHECK-UP" : "R2 • CONTINUOUS CHECK-UP")
                            .font(.system(size: 11.5, weight: .heavy, design: .monospaced))
                            .foregroundColor(palette.accentText)
                        Text(isStn ? "4-Rhythm Protection Posture" : "4-Rhythm Fleet Operational Posture")
                            .font(.system(size: 17, weight: .heavy))
                            .foregroundColor(palette.textPrimary)
                    }
                    Spacer()
                    ShareLink(item: shareReport) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(palette.accentText)
                            .padding(.horizontal, 10)
                            .frame(minHeight: 34)
                            .background(palette.accent.opacity(0.14))
                            .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusBadge))
                    }
                    .uiAction("shareCheckupReport")
                }

                ForEach(postureItems) { item in
                    let hasAction = (item.action != nil)
                    let tint = hasAction
                        ? TuesdayTheme.ledColor(for: .eol, isStn: isStn)
                        : TuesdayTheme.ledColor(for: .ok, isStn: isStn)

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(item.title)
                                .font(.system(size: 13.5, weight: .bold))
                                .foregroundColor(palette.textPrimary)
                            Spacer()
                            MonospaceBadge(
                                text: hasAction ? "ACTION" : "OK",
                                color: tint
                            )
                        }
                        Text(item.action ?? "Everything OK")
                            .font(.system(size: 13))
                            .foregroundColor(hasAction ? palette.textPrimary : tint)
                        if let rec = item.recommendation {
                            Text("💡 \(rec)")
                                .font(.system(size: 12.5))
                                .foregroundColor(palette.textMuted)
                                .lineSpacing(3)
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(palette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard))
                    .overlay(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard).stroke(tint.opacity(0.4), lineWidth: 1))
                    .uiSlot(item.id == "r2" ? "r2-quarterly-tuneup-card" : "r3-annual-review-card")
                }

                Text("R2 QUARTERLY AUDIT PILLARS")
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .foregroundColor(palette.textMuted)

                Grid(horizontalSpacing: 8, verticalSpacing: 8) {
                    ForEach(0..<2, id: \.self) { rowIndex in
                        GridRow {
                            ForEach(0..<2, id: \.self) { colIndex in
                                let item = pillars[rowIndex * 2 + colIndex]
                                VStack(alignment: .leading, spacing: 4) {
                                    MonospaceBadge(text: item.0, color: palette.accentText, borderAlpha: 0)
                                    Text(item.1)
                                        .font(.system(size: 12.5, weight: .bold))
                                        .foregroundColor(palette.textPrimary)
                                    Text(item.2)
                                        .font(.system(size: 11.5))
                                        .foregroundColor(palette.textMuted)
                                        .lineSpacing(2)
                                }
                                .padding(10)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                .background(palette.surface)
                                .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
                                .overlay(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl).stroke(palette.border, lineWidth: 1))
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, TuesdayDimens.screenPaddingHorizontal)
            .padding(.vertical, 12)
        }
        .background(palette.bg.ignoresSafeArea())
        .uiComponent("SeasonalCheckupScreen")
        .overlay { EmptyView().uiSlot("r2-quarterly-tuneup-card").uiSlot("r3-annual-review-card").uiSlot("help-button").uiAction("openReferenceGuide").uiAction("askClaudeCheckup") }
    }
}
