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
    public var entitlementTier: String = "free"
    public var initialModal: String? = nil
    public var onConsumeInitialModal: () -> Void = {}
    public var onOpenReferenceGuide: () -> Void = {}
    public var onOpenUpgrade: () -> Void = {}
    public let onInspectDevice: (RackPortDevice) -> Void
    public let onRecordAttestation: (String, AttestationType, DevicePresenceState, String, String?) -> Void
    public let onRecordBatchAttestation: ([String], String, String, String?) -> Void

    @State private var scrubberXNorm: Double = 0.72
    @State private var zoomWidthPt: CGFloat?
    @State private var selectedDeviceForAttestation: RackPortDevice? = nil
    @State private var showBatchAuditModal: Bool = false
    @State private var showReportsModal: Bool = false

    public init(
        devices: [RackPortDevice],
        attestations: [DeviceAttestation] = [],
        flavor: AppBrandFlavor,
        palette: BrandPalette,
        entitlementTier: String = "free",
        initialModal: String? = nil,
        onConsumeInitialModal: @escaping () -> Void = {},
        onOpenReferenceGuide: @escaping () -> Void = {},
        onOpenUpgrade: @escaping () -> Void = {},
        onInspectDevice: @escaping (RackPortDevice) -> Void,
        onRecordAttestation: @escaping (String, AttestationType, DevicePresenceState, String, String?) -> Void = { _, _, _, _, _ in },
        onRecordBatchAttestation: @escaping ([String], String, String, String?) -> Void = { _, _, _, _ in }
    ) {
        self.devices = devices
        self.attestations = attestations
        self.flavor = flavor
        self.palette = palette
        self.entitlementTier = entitlementTier
        self.initialModal = initialModal
        self.onConsumeInitialModal = onConsumeInitialModal
        self.onOpenReferenceGuide = onOpenReferenceGuide
        self.onOpenUpgrade = onOpenUpgrade
        self.onInspectDevice = onInspectDevice
        self.onRecordAttestation = onRecordAttestation
        self.onRecordBatchAttestation = onRecordBatchAttestation
        let isPro = EntitlementGatePolicy.isProTier1Entitled(entitlementTier)
        _zoomWidthPt = State(initialValue: isPro ? nil : 560)
    }

    public var body: some View {
        let isStn = (flavor == .sureThingHome)
        let sortedDevices = BulletinsAndInventoryEngine.sortDevicesForTimeline(devices)
        let candles = sortedDevices.map {
            BulletinsAndInventoryEngine.toOperationalCandle(
                $0,
                attestations: attestations,
                referenceNowNorm: scrubberXNorm
            )
        }
        let cursorDateText = TimelineStatusEvaluator.formatScrubberCursorDate(scrubberXNorm: scrubberXNorm)
        let earliestRelease = candles.compactMap(\.releaseDateStr).min()
        let latestEol = candles.compactMap(\.eolDateStr).max()

        let okColor = TuesdayTheme.ledColor(for: .ok, isStn: isStn)
        let cveColor = TuesdayTheme.ledColor(for: .cveKev, isStn: isStn)
        let eolColor = TuesdayTheme.ledColor(for: .eol, isStn: isStn)
        let retiredColor = TuesdayTheme.presenceColor(for: .retired, isStn: isStn)
        let lostColor = TuesdayTheme.presenceColor(for: .lost, isStn: isStn)
        let defectColor = TuesdayTheme.presenceColor(for: .stoppedWorking, isStn: isStn)
        let overhangColor = TuesdayTheme.overhangColor(isStn: isStn)
        let canvasHeight = CGFloat(max(180, candles.count * 20 + 22))

        GeometryReader { geo in
            VStack(spacing: 0) {
                // Top 1/3 (~34%): Full-bleed edge-to-edge candlestick canvas + pinned 96pt label column
                ZStack {
                    if candles.isEmpty {
                        SwimlaneCanvasView(
                            candles: [],
                            palette: palette,
                            scrubberXNorm: $scrubberXNorm,
                            drawLabels: true,
                            allowDragScrub: true
                        )
                    } else {
                        ScrollView(.vertical) {
                            HStack(alignment: .top, spacing: 0) {
                                SwimlaneLabelsColumnView(
                                    candles: candles,
                                    palette: palette
                                )
                                .frame(width: 96, height: canvasHeight)

                                if let zoomW = zoomWidthPt {
                                    ScrollViewReader { proxy in
                                        ScrollView(.horizontal) {
                                            ZStack(alignment: .leading) {
                                                HStack(spacing: 0) {
                                                    Color.clear.frame(width: zoomW * 0.72, height: 1)
                                                    Color.clear.frame(width: 1, height: 1).id("timelineTodayAnchor")
                                                }
                                                SwimlaneCanvasView(
                                                    candles: candles,
                                                    palette: palette,
                                                    scrubberXNorm: $scrubberXNorm,
                                                    drawLabels: false,
                                                    allowDragScrub: false
                                                )
                                                .frame(width: zoomW, height: canvasHeight)
                                            }
                                        }
                                        .onAppear {
                                            scrubberXNorm = 0.72
                                            proxy.scrollTo("timelineTodayAnchor", anchor: .center)
                                        }
                                        .onChange(of: zoomWidthPt) { _, newZoom in
                                            if newZoom != nil {
                                                scrubberXNorm = 0.72
                                                proxy.scrollTo("timelineTodayAnchor", anchor: .center)
                                            }
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                } else {
                                    SwimlaneCanvasView(
                                        candles: candles,
                                        palette: palette,
                                        scrubberXNorm: $scrubberXNorm,
                                        drawLabels: false,
                                        allowDragScrub: true
                                    )
                                    .frame(maxWidth: .infinity)
                                    .frame(height: canvasHeight)
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: max(180, geo.size.height * 0.34))
                .background(palette.chassisRecessed)
                .uiSlot("timeline-swimlane-canvas")

                // Bottom 2/3 (~66%): Unboxed zoom/legend controls + standalone mini-candle device cards
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 6) {
                                let isProTier1 = EntitlementGatePolicy.isProTier1Entitled(entitlementTier)
                                HStack(spacing: 6) {
                                    ForEach([("All time", CGFloat?.none), ("1yr", CGFloat?(560)), ("6mo", CGFloat?(840))], id: \.0) { label, widthPt in
                                        let isProLockedRange = (widthPt == nil && !isProTier1)
                                        SelectableFilterChip(
                                            label: label,
                                            selected: zoomWidthPt == widthPt,
                                            palette: palette,
                                            action: {
                                                if isProLockedRange {
                                                    onOpenUpgrade()
                                                } else {
                                                    zoomWidthPt = widthPt
                                                    scrubberXNorm = 0.72
                                                }
                                            }
                                        )
                                        .uiAction("setTimelineRange")
                                    }
                                    SelectableFilterChip(
                                        label: "Today",
                                        selected: scrubberXNorm >= 0.98,
                                        palette: palette,
                                        action: {
                                            scrubberXNorm = 1.0
                                        }
                                    )
                                    .uiAction("snapTimelineToday")
                                }
                                .uiSlot("timeline-range-strip")

                                Spacer(minLength: 4)

                                HStack(spacing: 8) {
                                    Text(
                                        (zoomWidthPt == nil && (earliestRelease != nil || latestEol != nil))
                                            ? "\(earliestRelease ?? "—") → \(latestEol ?? "—")"
                                            : cursorDateText
                                    )
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(palette.textMuted)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)

                                    ZStack {
                                        HelpIconButton(
                                            palette: palette,
                                            accessibilityLabel: "Timeline Reference Guide",
                                            onClick: onOpenReferenceGuide
                                        )
                                    }
                                    .uiSlot("help-button")
                                }
                            }
                            .padding(.horizontal, 2)

                            // 6-State Visual Grammar Legend + Clickable Reports CTA (Feedback #20)
                            Button(action: {
                                showReportsModal = true
                            }) {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text("Legend:")
                                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                                            .foregroundColor(palette.accentText)
                                        Spacer()
                                        Text("Reports →")
                                            .font(.system(size: 11, weight: .heavy, design: .monospaced))
                                            .foregroundColor(palette.accentText)
                                    }

                                    HStack(spacing: 8) {
                                        legendSwatch(fill: okColor, border: nil, label: "Solid: Active", labelColor: palette.textMuted)
                                        legendSwatch(fill: nil, border: retiredColor, label: "Hollow: Retired", labelColor: palette.textMuted)
                                        legendSwatch(fill: nil, border: lostColor, label: "Dashed: Lost", labelColor: lostColor)
                                    }

                                    HStack(spacing: 8) {
                                        legendSwatch(fill: defectColor, border: nil, label: "Slash: Defect", labelColor: defectColor)
                                        legendSwatch(fill: eolColor, border: nil, label: "Amber: EOL Nears", labelColor: palette.textMuted)
                                        legendSwatch(fill: overhangColor, border: nil, label: "Hatched: Past EOL", labelColor: cveColor)
                                    }
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(palette.elevated)
                            }
                            .buttonStyle(.plain)
                            .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusBadge))
                            .overlay(
                                RoundedRectangle(cornerRadius: TuesdayDimens.radiusBadge)
                                    .stroke(palette.border, lineWidth: 1)
                            )
                            .uiSlot("timeline-6state-legend")
                        }
                        .uiSlot("timeline-header-card")

                        TuesdayListSection(
                            palette: palette,
                            items: Array(zip(sortedDevices, candles)),
                            id: \.1.id,
                            layoutStyle: .cardStack,
                            itemSpacing: 12,
                            sectionSpacing: 10,
                            title: isStn ? "Device Lifespan & Supported Versions" : "Hardware Lifecycles",
                            showHeader: true,
                            showHeaderTrailing: false,
                            showEmpty: true,
                            headerTrailing: { EmptyView() },
                            itemContent: { pair in
                                let dev = pair.0
                                let candle = pair.1
                                let summary = TimelineStatusEvaluator.evaluateCandleStatus(
                                    candle: candle,
                                    attestations: attestations
                                )

                                ZStack(alignment: .topLeading) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack(spacing: 8) {
                                            Button(action: { onInspectDevice(dev) }) {
                                                Text(candle.name)
                                                    .font(.system(size: 13, weight: .heavy))
                                                    .foregroundColor(palette.textPrimary)
                                                    .lineLimit(1)
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                            }
                                            .buttonStyle(.plain)

                                            if summary.needsStatusCheck {
                                                Button(action: { selectedDeviceForAttestation = dev }) {
                                                    Text("Update Status")
                                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                                        .foregroundColor(palette.accentText)
                                                        .padding(.horizontal, 8)
                                                        .padding(.vertical, 4)
                                                        .frame(minHeight: 28)
                                                        .background(palette.accent.opacity(0.15))
                                                        .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusBadge))
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: TuesdayDimens.radiusBadge)
                                                                .stroke(palette.accent, lineWidth: 1)
                                                        )
                                                }
                                                .buttonStyle(.plain)
                                                .uiAction("openLifecycleAttestation")
                                            }
                                        }

                                        Button(action: { onInspectDevice(dev) }) {
                                            CondensedCandlestickCard(
                                                candle: candle,
                                                palette: palette,
                                                showHeader: false
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(10)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(palette.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard)
                                            .stroke(palette.border, lineWidth: 1)
                                    )

                                    if candle.hasCveOrRecall || candle.isPastEol || candle.isEolNearing {
                                        HStack(spacing: 4) {
                                            if candle.hasCveOrRecall {
                                                Circle()
                                                    .fill(cveColor)
                                                    .frame(width: 8, height: 8)
                                            }
                                            if candle.isPastEol {
                                                RoundedRectangle(cornerRadius: 2)
                                                    .fill(cveColor)
                                                    .frame(width: 8, height: 8)
                                            } else if candle.isEolNearing {
                                                RoundedRectangle(cornerRadius: 2)
                                                    .fill(eolColor)
                                                    .frame(width: 8, height: 8)
                                            }
                                        }
                                        .padding(4)
                                        .allowsHitTesting(false)
                                    }
                                }
                            },
                            emptyContent: {
                                TuesdayListEmptyBanner(
                                    message: "No hardware devices tracked in your inventory yet.",
                                    palette: palette
                                )
                            }
                        )
                        .uiComponent("HardwareLifecyclesSection")
                    }
                    .padding(.horizontal, TuesdayDimens.screenPaddingHorizontal)
                    .padding(.vertical, 12)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(palette.bg.ignoresSafeArea())
        .uiComponent("SwimlaneTimelineScreen")
        .overlay {
            if showReportsModal {
                let isProTier1 = EntitlementGatePolicy.isProTier1Entitled(entitlementTier)
                let eolCount = candles.filter { $0.isPastEol || $0.isEolNearing }.count
                ZStack {
                    Color.black.opacity(0.6).ignoresSafeArea().onTapGesture { showReportsModal = false }
                    TuesdayModalCard(
                        palette: palette,
                        title: "Lifecycle Reports & Dossiers",
                        subtitle: "Multi-year EOL forecasting, full attestation audit history, and printable Home/Rack dossiers.",
                        componentName: "TimelineReportsModal",
                        closeActionName: "closeReportsModal",
                        onDismiss: { showReportsModal = false },
                        content: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("• Multi-Year EOL Forecast (\(eolCount) device\(eolCount == 1 ? "" : "s") nearing/past EOL)")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(palette.textPrimary)
                                Text("• Full Attestation Audit Log (\(attestations.count) recorded check-in\(attestations.count == 1 ? "" : "s"))")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(palette.textPrimary)
                                Text("• Printable PDF, CSV & Markdown Home/Rack Dossiers")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(palette.textPrimary)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(palette.elevated)
                            .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard))
                            .overlay(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard).stroke(palette.border, lineWidth: 1))

                            if !isProTier1 {
                                Button(action: {
                                    showReportsModal = false
                                    onOpenUpgrade()
                                }) {
                                    Text("Unlock Reports with Tier 1")
                                        .font(.system(size: 13.5, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity, minHeight: 42)
                                        .background(palette.accent)
                                        .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard))
                                }
                                .buttonStyle(.plain)
                            } else {
                                Text("Tier 1 Active — export PDF, CSV, or Markdown dossiers anytime from the Backup & Export menu (☰).")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(okColor)
                            }
                        }
                    )
                    .padding(.horizontal, 16)
                }
            }
        }
        .onAppear { handleInitialModalIfNeeded(sortedDevices: sortedDevices) }
        .onChange(of: initialModal) { _, _ in handleInitialModalIfNeeded(sortedDevices: sortedDevices) }
        .sheet(item: $selectedDeviceForAttestation) { dev in
            LifecycleAttestationSheet(
                device: dev,
                palette: palette,
                onSubmit: { type, presence, date, notes in
                    onRecordAttestation(dev.id, type, presence, date, notes)
                    selectedDeviceForAttestation = nil
                },
                onDismiss: { selectedDeviceForAttestation = nil }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showBatchAuditModal) {
            BatchAuditModalView(
                devices: sortedDevices,
                palette: palette,
                onSubmitBatch: { ids, date, sessionId, notes in
                    onRecordBatchAttestation(ids, date, sessionId, notes)
                    showBatchAuditModal = false
                },
                onDismiss: { showBatchAuditModal = false }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    private func handleInitialModalIfNeeded(sortedDevices: [RackPortDevice]) {
        guard let modal = initialModal else { return }
        onConsumeInitialModal()
        switch modal {
        case "checkin", "check-in":
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                selectedDeviceForAttestation = nil
                showBatchAuditModal = true
            }
        case "status", "update-status":
            let targetDevice = sortedDevices.first
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showBatchAuditModal = false
                selectedDeviceForAttestation = targetDevice
            }
        case "none", "close":
            showBatchAuditModal = false
            selectedDeviceForAttestation = nil
        default:
            break
        }
    }

    private func legendSwatch(fill: Color?, border: Color?, label: String, labelColor: Color) -> some View {
        HStack(spacing: 4) {
            Rectangle()
                .fill(fill ?? Color.clear)
                .frame(width: 8, height: 6)
                .overlay {
                    if let border {
                        Rectangle().stroke(border, lineWidth: 1)
                    }
                }
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(labelColor)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Pinned left-hand label column paired alongside the horizontally zoomable `SwimlaneCanvasView`.
private struct SwimlaneLabelsColumnView: View {
    let candles: [OperationalCandle]
    let palette: BrandPalette

    var body: some View {
        let isStn = palette.isStn
        Canvas { context, size in
            let footerH: CGFloat = 12
            let laneH = (size.height - footerH) / CGFloat(max(1, candles.count))

            for (idx, candle) in candles.enumerated() {
                let yTop = CGFloat(idx) * laneH
                let yCenter = yTop + laneH / 2
                let barColor: Color = {
                    if candle.presenceState.isOutOfService {
                        return TuesdayTheme.presenceColor(for: candle.presenceState, isStn: isStn)
                    }
                    if candle.hasCveOrRecall { return TuesdayTheme.ledColor(for: .cveKev, isStn: isStn) }
                    if candle.isPastEol { return TuesdayTheme.overhangColor(isStn: isStn) }
                    if candle.isEolNearing { return TuesdayTheme.ledColor(for: .eol, isStn: isStn) }
                    return TuesdayTheme.ledColor(for: .ok, isStn: isStn)
                }()

                context.fill(
                    Path(CGRect(x: 0, y: yTop + 2, width: 3, height: max(2, laneH - 4))),
                    with: .color(barColor)
                )
                context.draw(
                    Text(candle.shortLabel)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(palette.textPrimary),
                    at: CGPoint(x: 7, y: yCenter),
                    anchor: .leading
                )
            }
        }
        .background(palette.chassisRecessed)
    }
}

public struct SwimlaneCanvasView: View {
    public let candles: [OperationalCandle]
    public let palette: BrandPalette
    @Binding public var scrubberXNorm: Double
    public var drawLabels: Bool = true
    public var allowDragScrub: Bool = true

    public init(
        candles: [OperationalCandle],
        palette: BrandPalette,
        scrubberXNorm: Binding<Double>,
        drawLabels: Bool = true,
        allowDragScrub: Bool = true
    ) {
        self.candles = candles
        self.palette = palette
        self._scrubberXNorm = scrubberXNorm
        self.drawLabels = drawLabels
        self.allowDragScrub = allowDragScrub
    }

    public var body: some View {
        let isStn = palette.isStn
        let labelW: CGFloat = drawLabels ? 96 : 0

        GeometryReader { geo in
            let canvas = Canvas { context, size in
                let w = size.width
                let h = size.height
                let footerH: CGFloat = 12
                let plotW = max(10, w - labelW - 12)

                context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(palette.chassisRecessed))

                if candles.isEmpty {
                    let midY = h / 2
                    var line = Path()
                    line.move(to: CGPoint(x: 36, y: midY))
                    line.addLine(to: CGPoint(x: w - 36, y: midY))
                    context.stroke(line, with: .color(palette.border), lineWidth: 1)
                    context.fill(Path(ellipseIn: CGRect(x: 32, y: midY - 4, width: 8, height: 8)), with: .color(palette.textMuted))
                    context.fill(Path(ellipseIn: CGRect(x: w - 40, y: midY - 4, width: 8, height: 8)), with: .color(palette.textMuted))
                    context.draw(
                        Text("No Hardware Devices in Inventory")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(palette.textPrimary),
                        at: CGPoint(x: w / 2, y: midY - 14)
                    )
                    context.draw(
                        Text("Add a device or seed inventory to visualize hardware lifecycles")
                            .font(.system(size: 11))
                            .foregroundColor(palette.textMuted),
                        at: CGPoint(x: w / 2, y: midY + 16)
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

                    var laneDivider = Path()
                    laneDivider.move(to: CGPoint(x: 0, y: CGFloat(idx + 1) * laneH))
                    laneDivider.addLine(to: CGPoint(x: w, y: CGFloat(idx + 1) * laneH))
                    context.stroke(laneDivider, with: .color(palette.border), lineWidth: 1)

                    if drawLabels {
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
                    }

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
                        context.fill(
                            Path(ellipseIn: CGRect(x: xRel - 2.2, y: yCenter - 2.2, width: 4.4, height: 4.4)),
                            with: .color(palette.textMuted)
                        )
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
                    if candle.isGuessed {
                        context.fill(Path(barRect), with: .color(bodyColor.opacity(0.22)))
                        context.stroke(
                            Path(barRect),
                            with: .color(palette.textMuted),
                            style: StrokeStyle(lineWidth: 1, dash: [4, 4])
                        )
                    } else if candle.presenceState == .retired || candle.isRetired {
                        context.fill(Path(barRect), with: .color(bodyColor.opacity(0.12)))
                        context.stroke(Path(barRect), with: .color(bodyColor), lineWidth: 1.2)
                    } else if candle.presenceState == .lost {
                        context.fill(Path(barRect), with: .color(bodyColor.opacity(0.12)))
                        context.stroke(
                            Path(barRect),
                            with: .color(bodyColor),
                            style: StrokeStyle(lineWidth: 1.2, dash: [6, 4])
                        )
                    } else if candle.presenceState == .stoppedWorking {
                        context.fill(Path(barRect), with: .color(bodyColor.opacity(0.18)))
                        context.stroke(Path(barRect), with: .color(bodyColor), lineWidth: 1.4)
                        var slash = Path()
                        slash.move(to: CGPoint(x: xDeployStart + 3, y: cTop + 2))
                        slash.addLine(to: CGPoint(x: xDeployStart + supportedW - 3, y: cTop + candleH - 2))
                        context.stroke(slash, with: .color(bodyColor), lineWidth: 1.2)
                    } else {
                        context.fill(Path(barRect), with: .color(bodyColor))
                        context.stroke(Path(barRect), with: .color(palette.textPrimary.opacity(0.20)), lineWidth: 0.8)
                    }

                    // Post-EOL active overhang crimson stripe + hatch + subtle outline
                    if candle.isPastEol && xDeployEnd > xEol {
                        let overhangW = max(3, xDeployEnd - xEol)
                        let overRect = CGRect(x: xEol, y: cTop, width: overhangW, height: candleH)

                        var eolMarker = Path()
                        eolMarker.move(to: CGPoint(x: xEol, y: cTop - 2))
                        eolMarker.addLine(to: CGPoint(x: xEol, y: cTop + candleH + 2))
                        context.stroke(eolMarker, with: .color(palette.textPrimary), lineWidth: 1.5)

                        context.fill(Path(overRect), with: .color(cveColor))

                        var hx = xEol
                        while hx < xEol + overhangW + candleH {
                            let p1x = min(max(hx - candleH, xEol), xEol + overhangW)
                            let p2x = min(max(hx, xEol), xEol + overhangW)
                            if p2x > p1x {
                                var hatch = Path()
                                hatch.move(to: CGPoint(x: p1x, y: cTop + candleH))
                                hatch.addLine(to: CGPoint(x: p2x, y: cTop))
                                context.stroke(hatch, with: .color(.white.opacity(0.6)), lineWidth: 1)
                            }
                            hx += 4
                        }
                        context.stroke(Path(overRect), with: .color(cveColor.opacity(0.5)), lineWidth: 1)
                    }

                    // Remaining supported runway tail
                    if !candle.isPastEol && xEol > xDeployEnd {
                        let runwayColor = candle.isEolNearing ? eolColor : palette.textMuted
                        var runway = Path()
                        runway.move(to: CGPoint(x: xDeployEnd, y: yCenter))
                        runway.addLine(to: CGPoint(x: xEol, y: yCenter))
                        context.stroke(runway, with: .color(runwayColor), lineWidth: 1.2)
                        context.fill(
                            Path(ellipseIn: CGRect(x: xEol - 2.2, y: yCenter - 2.2, width: 4.4, height: 4.4)),
                            with: .color(runwayColor)
                        )
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

                // Scrubber track & vertical accent needle
                let fy = h - footerH + 4
                context.fill(Path(CGRect(x: labelW, y: fy, width: plotW, height: 3)), with: .color(palette.borderStrong))

                let scrubX = labelW + CGFloat(scrubberXNorm) * plotW
                var scrub = Path()
                scrub.move(to: CGPoint(x: scrubX, y: 0))
                scrub.addLine(to: CGPoint(x: scrubX, y: h - footerH))
                context.stroke(scrub, with: .color(palette.accent), lineWidth: 1.5)
            }
            .contentShape(Rectangle())

            if allowDragScrub {
                canvas.gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            updateScrub(x: value.location.x, width: geo.size.width, labelW: labelW)
                        }
                )
            } else {
                canvas.simultaneousGesture(
                    SpatialTapGesture()
                        .onEnded { value in
                            updateScrub(x: value.location.x, width: geo.size.width, labelW: labelW)
                        }
                )
            }
        }
    }

    private func updateScrub(x: CGFloat, width: CGFloat, labelW: CGFloat) {
        let plotW = max(10, width - labelW - 12)
        let norm = Double((x - labelW) / plotW)
        scrubberXNorm = min(1.0, max(0.0, norm))
    }
}

private struct LifecycleAttestationSheet: View {
    let device: RackPortDevice
    let palette: BrandPalette
    let onSubmit: (AttestationType, DevicePresenceState, String, String?) -> Void
    let onDismiss: () -> Void

    @State private var selectedType: AttestationType
    @State private var auditDate: String = TimelineStatusEvaluator.defaultReferenceDate
    @State private var notes: String = ""

    private let auditSessionId = "CHECKIN-2026-Q4"

    init(
        device: RackPortDevice,
        palette: BrandPalette,
        onSubmit: @escaping (AttestationType, DevicePresenceState, String, String?) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.device = device
        self.palette = palette
        self.onSubmit = onSubmit
        self.onDismiss = onDismiss
        _selectedType = State(
            initialValue: device.presenceState == .active ? .absenceRetired : .presenceReactivated
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("RHYTHM CHECK-IN & LIFECYCLE")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(palette.accentText)
                        Text(device.name)
                            .font(.system(size: 15.5, weight: .heavy))
                            .foregroundColor(palette.textPrimary)
                    }
                    Spacer()
                    MonospaceBadge(
                        text: "Current: \(device.presenceState.shortLabel)",
                        color: palette.textMuted
                    )
                }

                Text("Update this device's operational status. Your check-in updates the hardware lifecycle candlestick and keeps your seasonal rhythm posture accurate.")
                    .font(.system(size: 12))
                    .foregroundColor(palette.textMuted)
                    .lineSpacing(3)

                VStack(spacing: 5) {
                    AttestationOptionRow(
                        label: "🟢 Confirm Active (Check-In)",
                        desc: "Device is powered on, connected, and in active service.",
                        isSelected: selectedType == .presenceAudit,
                        palette: palette,
                        onClick: { selectedType = .presenceAudit }
                    )
                    AttestationOptionRow(
                        label: "📦 Retire Gear (Decommissioned)",
                        desc: "Planned sunset, replacement, or removed from active service.",
                        isSelected: selectedType == .absenceRetired,
                        palette: palette,
                        onClick: { selectedType = .absenceRetired }
                    )
                    AttestationOptionRow(
                        label: "❓ Mark Lost (Missing)",
                        desc: "Device unaccounted for during inventory check-in.",
                        isSelected: selectedType == .absenceLost,
                        palette: palette,
                        onClick: { selectedType = .absenceLost }
                    )
                    AttestationOptionRow(
                        label: "⚡ Stopped Working (Hardware Fault)",
                        desc: "Power supply failed, hardware defect, port failure, or bricked.",
                        isSelected: selectedType == .absenceStoppedWorking,
                        palette: palette,
                        onClick: { selectedType = .absenceStoppedWorking }
                    )
                    if device.presenceState != .active {
                        AttestationOptionRow(
                            label: "🔄 Return to Active Service (Reactivate)",
                            desc: "Repaired, located, or returned to active service.",
                            isSelected: selectedType == .presenceReactivated,
                            palette: palette,
                            onClick: { selectedType = .presenceReactivated }
                        )
                    }
                }

                TuesdayTextField(
                    text: $auditDate,
                    label: "Status Date (YYYY-MM-DD)",
                    placeholder: TimelineStatusEvaluator.defaultReferenceDate,
                    palette: palette
                )

                TuesdayTextField(
                    text: $notes,
                    label: "Check-In Notes (Optional)",
                    placeholder: "e.g. Replaced with UDM-SE for 2.5GbE PoE, or PSU failed",
                    palette: palette
                )

                HStack(spacing: 8) {
                    Button(action: onDismiss) {
                        Text("Cancel")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(palette.textMuted)
                            .frame(maxWidth: .infinity, minHeight: TuesdayDimens.hitTargetStandard)
                            .background(palette.elevated)
                            .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
                            .overlay(
                                RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl)
                                    .stroke(palette.border, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        let trimmed = notes.trimmingCharacters(in: .whitespacesAndNewlines)
                        onSubmit(
                            selectedType,
                            selectedType.resultingState,
                            auditDate,
                            trimmed.isEmpty ? nil : trimmed
                        )
                    }) {
                        Text("Save Lifecycle Status")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: TuesdayDimens.hitTargetStandard)
                            .background(palette.accent)
                            .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
                    }
                    .buttonStyle(.plain)
                    .uiAction("saveLifecycleAttestation")
                    .layoutPriority(1)
                }
                .padding(.vertical, 4)
            }
            .padding(16)
        }
        .background(palette.surface.ignoresSafeArea())
        .uiComponent("LifecycleAttestationModal")
    }
}

private struct AttestationOptionRow: View {
    let label: String
    let desc: String
    let isSelected: Bool
    let palette: BrandPalette
    let onClick: () -> Void

    var body: some View {
        Button(action: onClick) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(palette.textPrimary)
                    Text(desc)
                        .font(.system(size: 11))
                        .foregroundColor(palette.textMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text(isSelected ? "●" : "○")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(isSelected ? palette.accentText : palette.textMuted)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(isSelected ? palette.accent.opacity(0.12) : palette.elevated)
            .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusBadge))
            .overlay(
                RoundedRectangle(cornerRadius: TuesdayDimens.radiusBadge)
                    .stroke(isSelected ? palette.accent : palette.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct BatchAuditModalView: View {
    let devices: [RackPortDevice]
    let palette: BrandPalette
    let onSubmitBatch: ([String], String, String, String?) -> Void
    let onDismiss: () -> Void

    @State private var selectedIds: Set<String>
    @State private var auditDate: String = TimelineStatusEvaluator.defaultReferenceDate
    @State private var notes: String = "Seasonal inventory check-in."

    private let sessionId = "CHECKIN-2026-Q4-WALK"

    init(
        devices: [RackPortDevice],
        palette: BrandPalette,
        onSubmitBatch: @escaping ([String], String, String, String?) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.devices = devices
        self.palette = palette
        self.onSubmitBatch = onSubmitBatch
        self.onDismiss = onDismiss
        _selectedIds = State(initialValue: Set(devices.filter { $0.presenceState == .active }.map(\.id)))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("OPERATIONAL RHYTHM • CHECK-IN")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(palette.accentText)
                    Text("Inventory Check-In")
                        .font(.system(size: 15.5, weight: .heavy))
                        .foregroundColor(palette.textPrimary)
                }

                Text("Confirm which hardware devices are currently powered on and active in your network. Unchecked devices can be updated individually if retired or replaced.")
                    .font(.system(size: 12))
                    .foregroundColor(palette.textMuted)
                    .lineSpacing(3)

                HStack {
                    Text("ACTIVE HARDWARE (\(selectedIds.count) / \(devices.count))")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(palette.textMuted)
                    Spacer()
                    Button("Select All") {
                        selectedIds = Set(devices.map(\.id))
                    }
                    .font(.system(size: 11.5, weight: .bold))
                    .foregroundColor(palette.accentText)
                    .frame(minHeight: 28)
                }

                ScrollView {
                    VStack(spacing: 4) {
                        ForEach(devices) { dev in
                            let isChecked = selectedIds.contains(dev.id)
                            Button(action: {
                                if isChecked { selectedIds.remove(dev.id) }
                                else { selectedIds.insert(dev.id) }
                            }) {
                                HStack {
                                    Text("\(dev.category.code) • \(dev.shortLabel)")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(palette.textPrimary)
                                    Spacer()
                                    Text(isChecked ? "✓ Active" : "Tap to include")
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(isChecked ? palette.accentText : palette.textMuted)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .frame(minHeight: TuesdayDimens.hitTargetCompact)
                                .background(isChecked ? palette.accent.opacity(0.1) : palette.elevated)
                                .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusBadge))
                                .overlay(
                                    RoundedRectangle(cornerRadius: TuesdayDimens.radiusBadge)
                                        .stroke(isChecked ? palette.accent : palette.border, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(maxHeight: 170)

                TuesdayTextField(
                    text: $auditDate,
                    label: "Check-In Date (YYYY-MM-DD)",
                    placeholder: TimelineStatusEvaluator.defaultReferenceDate,
                    palette: palette
                )

                TuesdayTextField(
                    text: $notes,
                    label: "Check-In Notes (Optional)",
                    placeholder: "Seasonal inventory check-in.",
                    palette: palette
                )

                Button(action: {
                    let trimmed = notes.trimmingCharacters(in: .whitespacesAndNewlines)
                    onSubmitBatch(
                        Array(selectedIds),
                        auditDate,
                        sessionId,
                        trimmed.isEmpty ? nil : trimmed
                    )
                }) {
                    Text("Complete Check-In (\(selectedIds.count) Devices)")
                        .font(.system(size: 12.5, weight: .bold))
                        .foregroundColor(selectedIds.isEmpty ? palette.textMuted : .white)
                        .frame(maxWidth: .infinity, minHeight: TuesdayDimens.hitTargetStandard)
                        .background(selectedIds.isEmpty ? palette.elevated : palette.accent)
                        .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
                }
                .buttonStyle(.plain)
                .disabled(selectedIds.isEmpty)
                .uiAction("completeBatchCheckIn")
            }
            .padding(16)
        }
        .background(palette.surface.ignoresSafeArea())
        .uiComponent("BatchAuditModal")
    }
}

public struct SeasonalCheckupView: View {
    public let devices: [RackPortDevice]
    public let bulletins: [BulletinInboxView]
    public let flavor: AppBrandFlavor
    public let palette: BrandPalette
    public var welcomeComplete: Bool = false
    public var entitlementTier: String = "free"
    public var onOpenReferenceGuide: () -> Void = {}
    public var onOpenUpgrade: () -> Void = {}

    @Environment(\.openURL) private var openURL

    public init(
        devices: [RackPortDevice],
        bulletins: [BulletinInboxView] = [],
        flavor: AppBrandFlavor,
        palette: BrandPalette,
        welcomeComplete: Bool = false,
        entitlementTier: String = "free",
        onOpenReferenceGuide: @escaping () -> Void = {},
        onOpenUpgrade: @escaping () -> Void = {}
    ) {
        self.devices = devices
        self.bulletins = bulletins
        self.flavor = flavor
        self.palette = palette
        self.welcomeComplete = welcomeComplete
        self.entitlementTier = entitlementTier
        self.onOpenReferenceGuide = onOpenReferenceGuide
        self.onOpenUpgrade = onOpenUpgrade
    }

    private func accentColorForRhythm(_ id: String, isStn: Bool) -> Color {
        switch id {
        case "r1": return TuesdayTheme.ledColor(for: .eol, isStn: isStn)
        case "r2": return palette.accentText
        case "r3": return TuesdayTheme.ledColor(for: .cveKev, isStn: isStn)
        case "r4": return TuesdayTheme.overhangColor(isStn: isStn)
        default: return palette.accentText
        }
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
        let amberColor = TuesdayTheme.ledColor(for: .eol, isStn: isStn)

        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        HStack(spacing: 8) {
                            Text("Check-Ups")
                                .font(.system(size: 16, weight: .heavy))
                                .foregroundColor(palette.textPrimary)

                            ZStack {
                                HelpIconButton(
                                    palette: palette,
                                    accessibilityLabel: "Check-Up Reference Guide",
                                    onClick: onOpenReferenceGuide
                                )
                            }
                            .uiSlot("help-button")
                        }

                        Spacer()

                        let isProTier1 = EntitlementGatePolicy.isProTier1Entitled(entitlementTier)
                        HStack(spacing: 6) {
                            Button(action: {
                                if !isProTier1 {
                                    onOpenUpgrade()
                                    return
                                }
                                let fleetList = devices.prefix(30).map { "- \($0.name) (\($0.category.code), \($0.version), \($0.portState.rawValue.uppercased()))" }.joined(separator: "\n")
                                let prompt = "I am reviewing my Tuesday.sh Pro network check-up (\(devices.count) devices):\n\n" + shareReport + (fleetList.isEmpty ? "" : "\n\nTracked Fleet:\n\(fleetList)")
                                var allowed = CharacterSet.urlQueryAllowed
                                allowed.remove(charactersIn: "&+=#")
                                let encoded = prompt.addingPercentEncoding(withAllowedCharacters: allowed) ?? ""
                                if let url = URL(string: "https://claude.ai/new?q=\(encoded)") {
                                    openURL(url)
                                }
                            }) {
                                Text("✦ Ask Claude")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(amberColor)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 5)
                                    .frame(minHeight: 28)
                                    .background(amberColor.opacity(0.14))
                                    .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusBadge))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: TuesdayDimens.radiusBadge)
                                            .stroke(amberColor, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                            .uiAction("askClaudeCheckup")

                            ShareLink(item: shareReport) {
                                Text("Share")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(palette.textPrimary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 5)
                                    .frame(minHeight: 28)
                                    .background(palette.elevated)
                                    .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusBadge))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: TuesdayDimens.radiusBadge)
                                            .stroke(palette.border, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                            .uiAction("shareCheckupReport")
                        }
                    }
                    .padding(.horizontal, 2)

                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(postureItems) { rhythm in
                            let hasAction = (rhythm.action != nil)
                            let accentColor = hasAction
                                ? accentColorForRhythm(rhythm.id, isStn: isStn)
                                : palette.textMuted
                            let topperShape = UnevenRoundedRectangle(topLeadingRadius: 8, topTrailingRadius: 8)

                            VStack(alignment: .leading, spacing: 0) {
                                HStack(spacing: 0) {
                                    Rectangle()
                                        .fill(accentColor)
                                        .frame(width: hasAction ? 4 : 3, height: 34)
                                    Text(rhythm.title)
                                        .font(
                                            isStn
                                                ? .system(size: 12, weight: hasAction ? .heavy : .bold)
                                                : .system(size: 11, weight: hasAction ? .heavy : .bold, design: .monospaced)
                                        )
                                        .foregroundColor(accentColor)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .background(hasAction ? palette.surface : palette.surface.opacity(0.6))
                                .clipShape(topperShape)
                                .overlay(topperShape.stroke(palette.border, lineWidth: 1))

                                if !hasAction {
                                    Text("Everything OK")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(palette.textMuted)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 10)
                                    SurfaceListDivider(palette: palette)
                                } else {
                                    Text(rhythm.action ?? "")
                                        .font(.system(size: 12.5, weight: .semibold))
                                        .foregroundColor(palette.textPrimary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 10)
                                    SurfaceListDivider(palette: palette)
                                    if let rec = rhythm.recommendation {
                                        Text("💡 Recommendation: \(rec)")
                                            .font(.system(size: 12))
                                            .foregroundColor(palette.textMuted)
                                            .lineSpacing(3)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 10)
                                        SurfaceListDivider(palette: palette)
                                    }
                                }
                            }
                            .uiSlot("checkup-rhythm-section", state: rhythm.id)
                        }
                    }
                }
                .uiSlot("r2-quarterly-tuneup-card")

                // Off-loop retired R3 slot anchor for contract completeness
                Color.clear
                    .frame(width: 0, height: 0)
                    .uiSlot("r3-annual-review-card")
            }
            .padding(.horizontal, TuesdayDimens.screenPaddingHorizontal)
            .padding(.vertical, 12)
        }
        .background(palette.bg.ignoresSafeArea())
        .uiComponent("SeasonalCheckupScreen")
    }
}
