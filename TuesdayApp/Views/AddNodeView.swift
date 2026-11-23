import SwiftUI
import PhotosUI
import Vision
import AVFoundation

private enum AddDeviceEntryMode: String, CaseIterable, Identifiable {
    case photo = "Photo"
    case scan = "Scan"
    case manual = "Manual"
    var id: String { rawValue }
}

public struct AddNodeView: View {
    @ObservedObject public var repository: MockHacsTuesdayService
    public let palette: BrandPalette
    public var initialMode: String? = nil
    public var initialSynthPreset: String? = nil
    public var initialQuery: String? = nil
    public var initialCluesCsv: String? = nil
    public var autoSearch: Bool = false
    public var onOpenUpgrade: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var entryMode: AddDeviceEntryMode = .photo
    @State private var clueQuery: String = ""
    @State private var selectedClues: [GoldClueItem] = []
    @State private var manualDeviceName: String = ""
    @State private var accumulatedIdentifiers = ExtractedDeviceIdentifiers()

    @State private var capturedImages: [UIImage] = []
    @State private var scannedBarcodesList: [String] = []
    @State private var photoPickerItem: PhotosPickerItem? = nil
    @State private var barcodePhotoItem: PhotosPickerItem? = nil
    @State private var showCameraSheet = false
    @State private var showBarcodeScanner = false

    @State private var isAnalyzing = false
    @State private var isSaving = false
    @State private var discoveryResult: GeminiDiscoveryTurnResult? = nil
    @State private var inspectedCandidate: DeviceCandidateMatch? = nil
    @State private var debugLogs: [String] = []
    @State private var copyLogFeedback: String? = nil
    @State private var statusBanner: String? = nil
    @State private var manualError: String? = nil
    @State private var didApplyInitialParams = false

    public init(
        repository: MockHacsTuesdayService,
        palette: BrandPalette = TuesdayTheme.palette(for: .tuesdayPro),
        initialMode: String? = nil,
        initialSynthPreset: String? = nil,
        initialQuery: String? = nil,
        initialCluesCsv: String? = nil,
        autoSearch: Bool = false,
        onOpenUpgrade: @escaping () -> Void = {}
    ) {
        self.repository = repository
        self.palette = palette
        self.initialMode = initialMode
        self.initialSynthPreset = initialSynthPreset
        self.initialQuery = initialQuery
        self.initialCluesCsv = initialCluesCsv
        self.autoSearch = autoSearch
        self.onOpenUpgrade = onOpenUpgrade
    }

    public var body: some View {
        let isStn = (repository.brandFlavor == .sureThingHome)
        let warningClue = selectedClues.last(where: { !($0.warningNote ?? "").isEmpty })
        let totalSignals = capturedImages.count + scannedBarcodesList.count + selectedClues.count

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 0) {
                        SegmentedTabRow(
                            options: AddDeviceEntryMode.allCases.map(\.rawValue),
                            selectedIndex: AddDeviceEntryMode.allCases.firstIndex(of: entryMode) ?? 0,
                            onSelect: { idx in
                                entryMode = AddDeviceEntryMode.allCases[idx]
                            },
                            palette: palette,
                            actionName: "switchEnrollmentMode"
                        )
                    }
                    .uiSlot("enrollment-mode-tabs")

                    Text(modeHeadline(isStn: isStn))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(palette.textPrimary)

                    Text(modeSubtitle)
                        .font(.system(size: 13.5))
                        .foregroundColor(palette.textMuted)
                        .lineSpacing(3)

                    if let manualError {
                        Text(manualError)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(TuesdayTheme.ledColor(for: .cveKev, isStn: isStn))
                    }

                    if let banner = statusBanner {
                        Text(banner)
                            .font(.system(size: 12.5, weight: .semibold))
                            .foregroundColor(palette.accentText)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(palette.accent.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
                    }

                    switch entryMode {
                    case .photo:
                        photoModeControls(isStn: isStn)
                    case .scan:
                        scanModeControls(isStn: isStn)
                    case .manual:
                        let pickedGoldModel = selectedClues.last(where: { $0.kind == .model })
                        VStack(alignment: .leading, spacing: 6) {
                            TuesdayTextField(
                                text: $manualDeviceName,
                                label: "Device Name",
                                placeholder: pickedGoldModel?.chipLabel ?? "e.g. Living Room Router, Front Doorbell, Synology NAS",
                                palette: palette
                            )

                            if manualDeviceName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                               let picked = pickedGoldModel {
                                Button(action: { manualDeviceName = picked.chipLabel }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "wand.and.stars")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundColor(TuesdayTheme.ledColor(for: .ok, isStn: isStn))
                                        Text("Use \"\(picked.chipLabel)\"")
                                            .font(.system(size: 11.5, weight: .medium))
                                            .foregroundColor(palette.textPrimary)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(palette.surface)
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .stroke(TuesdayTheme.ledColor(for: .ok, isStn: isStn).opacity(0.4), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    let inferredNameClue: GoldClueItem? = (entryMode == .manual)
                        ? GoldClueSuggestionRepository.shared.inferFromDeviceName(manualDeviceName, selected: selectedClues)
                        : nil

                    GoldHardwareCluesPicker(
                        palette: palette,
                        queryText: $clueQuery,
                        selectedClues: $selectedClues,
                        onClueAdded: { clue in applyClueIdentifiers(clue) },
                        inferredFromDeviceName: inferredNameClue
                    )

                    contextChipsStrip(isStn: isStn, warningNote: warningClue?.warningNote)

                    sharedActionButtonsRow(totalSignals: totalSignals)

                    if repository.isDeveloperMode {
                        devControlsSection()
                    }

                    // Search in progress is rendered inline via spinner inside the Search button (no extra callout card).

                    if let result = discoveryResult {
                        candidateResultsSection(result: result, isStn: isStn)
                    }

                    if repository.isDeveloperMode && repository.isVisionDebugEnabled {
                        visionDebugLogPanel()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .background(palette.bg.ignoresSafeArea())
            .navigationTitle(isStn ? "Add Home Device" : "Add Device")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(palette.accentText)
                }
            }
            .sheet(isPresented: $showCameraSheet) {
                CameraImagePicker(sourceType: .camera) { image in
                    handleCapturedOrPickedImage(image)
                }
            }
            .sheet(isPresented: $showBarcodeScanner) {
                BarcodeScannerSheet(
                    palette: palette,
                    onScanned: { parsed in
                        showBarcodeScanner = false
                        applyScannedBarcode(parsed)
                    },
                    onDismiss: { showBarcodeScanner = false }
                )
            }
            .sheet(item: $inspectedCandidate) { candidate in
                candidateConfirmationModal(candidate: candidate, isStn: isStn)
            }
            .onChange(of: photoPickerItem) { _, item in
                Task { await loadPhotoPickerImage(item, runBarcodeExtract: false) }
            }
            .onChange(of: barcodePhotoItem) { _, item in
                Task { await loadPhotoPickerImage(item, runBarcodeExtract: true) }
            }
            .onAppear {
                applyInitialDeepLinkArgsIfNeeded()
            }
        }
        .uiComponent("AddDeviceWizard")
    }

    private func modeHeadline(isStn: Bool) -> String {
        switch entryMode {
        case .photo: return isStn ? "Identify Device by Photo" : "Inventory Device by Photo"
        case .scan: return "Scan Barcode or QR Code"
        case .manual: return "Add Inventory Device Manually"
        }
    }

    private var modeSubtitle: String {
        switch entryMode {
        case .photo: return "Snap or upload hardware photos, or pick device type, brand, and model clues below before searching."
        case .scan: return "Scan 1D/2D barcodes for SureThingNet Insights lookup, or pick device clues below before searching."
        case .manual: return "Enter a device name and pick clues (e.g. Router, Doorbell, Google, Linksys) to search or add directly."
        }
    }

    @ViewBuilder
    private func photoModeControls(isStn: Bool) -> some View {
        let camDenied = (AVCaptureDevice.authorizationStatus(for: .video) == .denied)
        let remainingScans = EntitlementGatePolicy.remainingFreeAiPhotoScans(
            tier: repository.entitlementTier,
            scansUsed: repository.aiPhotoScansUsed
        )

        VStack(alignment: .leading, spacing: 8) {
            if let remaining = remainingScans {
                let isExhausted = remaining == 0
                Button(action: {
                    onOpenUpgrade()
                }) {
                    HStack {
                        Text(
                            isExhausted
                                ? "0 / \(EntitlementGatePolicy.freeAiPhotoScanLimit) free AI photo scans left — Upgrade to Tier 1"
                                : "\(remaining) / \(EntitlementGatePolicy.freeAiPhotoScanLimit) free AI photo scans left (Clues & Barcode always free)"
                        )
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(isExhausted ? palette.accentText : palette.textMuted)
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(isExhausted ? palette.accent.opacity(0.14) : palette.elevated)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isExhausted ? palette.accent.opacity(0.55) : palette.border, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 10) {
                Button(action: {
                    if AVCaptureDevice.default(for: .video) != nil {
                        showCameraSheet = true
                    } else {
                        handleCapturedOrPickedImage(GeminiDeviceDiscoveryService.renderSampleHardwareImage(presetName: "router"))
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 13.5, weight: .bold))
                        Text("Capture Photo")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, minHeight: 40)
                    .background(TuesdayTheme.healthyGreen)
                    .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
                }
                .buttonStyle(.plain)
                .uiAction("captureHardwarePhoto")

                PhotosPicker(selection: $photoPickerItem, matching: .images) {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.badge.plus")
                            .font(.system(size: 13.5, weight: .bold))
                        Text("Upload File")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(palette.textPrimary)
                    .padding(.horizontal, 14)
                    .frame(minHeight: 40)
                    .background(palette.elevated)
                    .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
                    .overlay(
                        RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl)
                            .stroke(palette.border, lineWidth: 1)
                    )
                }
                .uiAction("uploadHardwarePhoto")
            }

            if camDenied {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Camera access is optional. You can still upload a photo from your library, scan a barcode, or enter brand/model clues below.")
                        .font(.system(size: 12))
                        .foregroundColor(palette.textMuted)
                        .lineSpacing(2)
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        Button("Open iOS Settings") { openURL(url) }
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(palette.accentText)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func scanModeControls(isStn: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Button(action: { showBarcodeScanner = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 14, weight: .bold))
                        Text("Scan Barcode / QR")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, minHeight: 40)
                    .background(TuesdayTheme.healthyGreen)
                    .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
                }
                .buttonStyle(.plain)
                .uiAction("scanBarcodeOrQr")

                PhotosPicker(selection: $barcodePhotoItem, matching: .images) {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.badge.plus")
                            .font(.system(size: 13.5, weight: .bold))
                        Text("Upload File")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(palette.textPrimary)
                    .padding(.horizontal, 14)
                    .frame(minHeight: 40)
                    .background(palette.elevated)
                    .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
                    .overlay(
                        RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl)
                            .stroke(palette.border, lineWidth: 1)
                    )
                }
                .uiAction("uploadBarcodeImage")
            }

            if !capturedImages.isEmpty || !scannedBarcodesList.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("CAPTURED SCANS & BARCODES")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(0.5)
                            .foregroundColor(palette.textMuted)
                        Spacer()
                        Button("Clear All") {
                            capturedImages.removeAll()
                            scannedBarcodesList.removeAll()
                        }
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(TuesdayTheme.ledColor(for: .cveKev, isStn: isStn))
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(Array(capturedImages.enumerated()), id: \.offset) { idx, img in
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 110, height: 75)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(palette.accent.opacity(0.5), lineWidth: 1)
                                        )
                                    Button(action: { capturedImages.remove(at: idx) }) {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(.white)
                                            .frame(width: 26, height: 26)
                                            .background(Circle().fill(Color.black.opacity(0.78)))
                                    }
                                    .buttonStyle(.plain)
                                    .padding(3)
                                }
                            }

                            ForEach(scannedBarcodesList, id: \.self) { code in
                                let displayCode = code.count > 28 ? String(code.prefix(25)) + "…" : code
                                VStack(alignment: .leading, spacing: 0) {
                                    HStack {
                                        Image(systemName: "qrcode.viewfinder")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(palette.accentText)
                                        Spacer()
                                        Button(action: {
                                            scannedBarcodesList.removeAll { $0 == code }
                                        }) {
                                            Image(systemName: "xmark")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(palette.accentText)
                                                .frame(width: 26, height: 26)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    Spacer()
                                    Text(displayCode)
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .foregroundColor(palette.textPrimary)
                                        .lineLimit(2)
                                }
                                .padding(.leading, 8)
                                .padding(.trailing, 4)
                                .padding(.top, 4)
                                .padding(.bottom, 8)
                                .frame(width: 140, height: 75)
                                .background(palette.accent.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(palette.accent.opacity(0.4), lineWidth: 1)
                                )
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func contextChipsStrip(isStn: Bool, warningNote: String?) -> some View {
        if !capturedImages.isEmpty || !selectedClues.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(capturedImages.enumerated()), id: \.offset) { idx, img in
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(TuesdayTheme.healthyGreen.opacity(0.55), lineWidth: 1)
                                )
                            Button(action: { capturedImages.remove(at: idx) }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 24, height: 24)
                                    .background(Circle().fill(Color.black.opacity(0.8)))
                            }
                            .buttonStyle(.plain)
                            .padding(2)
                        }
                    }

                    ForEach(selectedClues) { clue in
                        RemovableAttachmentChip(
                            label: clue.chipLabel,
                            palette: palette,
                            onRemove: {
                                selectedClues.removeAll { $0.id == clue.id }
                            }
                        )
                    }
                }
            }
            .uiSlot("selected-clue-chips")
        }

        if let warnNote = warningNote, !warnNote.isEmpty {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 13))
                    .foregroundColor(TuesdayTheme.ledColor(for: .eol, isStn: isStn))
                Text(warnNote)
                    .font(.system(size: 12))
                    .foregroundColor(TuesdayTheme.ledColor(for: .eol, isStn: isStn))
                    .lineSpacing(3)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(TuesdayTheme.ledColor(for: .eol, isStn: isStn).opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
        }
    }

    private func sharedActionButtonsRow(totalSignals: Int) -> some View {
        HStack(spacing: 10) {
            Button(action: {
                Task { await runDeferredDiscoverySearch() }
            }) {
                HStack(spacing: 6) {
                    if isAnalyzing {
                        ProgressView()
                            .tint(.black)
                    } else {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14, weight: .bold))
                        Text(totalSignals > 0 ? "Search (\(totalSignals))" : "Search")
                            .font(.system(size: 14, weight: .bold))
                    }
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, minHeight: 42)
                .background(palette.accent)
                .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
            }
            .buttonStyle(.plain)
            .disabled(isAnalyzing)
            .uiAction("searchDeviceCandidates")

            Button(action: { dismiss() }) {
                Text("Cancel")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(palette.textPrimary)
                    .padding(.horizontal, 14)
                    .frame(minHeight: 42)
                    .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
                    .overlay(
                        RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl)
                            .stroke(palette.border, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .uiAction("cancelAddDevice")

            if entryMode == .manual {
                Button(action: {
                    Task { await enrollManually() }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                        Text("Add Device")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, minHeight: 42)
                    .background(TuesdayTheme.healthyGreen)
                    .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
                }
                .buttonStyle(.plain)
                .disabled(isSaving)
                .uiAction("enrollManualDevice")
            }
        }
    }

    private func analyzingProgressCard() -> some View {
        HStack(spacing: 12) {
            ProgressView()
                .tint(palette.accent)
            VStack(alignment: .leading, spacing: 2) {
                Text("Analyzing device with \(repository.hacsConfig.aiProvider.displayName)...")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(palette.textPrimary)
                Text("Inspecting chassis profile, ports, OUI prefix, and printed labels")
                    .font(.system(size: 11))
                    .foregroundColor(palette.textMuted)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard))
        .overlay(
            RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard)
                .stroke(palette.accent.opacity(0.4), lineWidth: 1)
        )
    }

    private func devControlsSection() -> some View {
        let isElastix = (repository.hacsConfig.aiProvider == .elastix)
        let activeAiColor = isElastix ? TuesdayTheme.healthyGreen : TuesdayTheme.ledUpdateBlue
        let debugActiveColor = repository.isVisionDebugEnabled ? TuesdayTheme.warningAmber : palette.textMuted
        let diagActiveColor = repository.isDiagnosticsEnabled ? palette.accentText : palette.textMuted

        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    Menu {
                        if entryMode == .photo {
                            Button(action: {
                                let sample = GeminiDeviceDiscoveryService.renderSampleHardwareImage(presetName: "router")
                                capturedImages.append(sample)
                            }) {
                                Label("Synth Router", systemImage: "wifi.router")
                            }
                            Button(action: {
                                let sample = GeminiDeviceDiscoveryService.renderSampleHardwareImage(presetName: "zigbee-iot")
                                capturedImages.append(sample)
                                let hubClue = GoldClueItem(
                                    id: "type:hub",
                                    kind: .deviceType,
                                    typeId: "hub",
                                    title: "Smart Hub / Bridge",
                                    subtitle: "C8 • Device Type",
                                    chipLabel: "Smart Hub / Bridge",
                                    categoryCode: "C8"
                                )
                                if !selectedClues.contains(where: { $0.id == hubClue.id }) {
                                    selectedClues.append(hubClue)
                                }
                            }) {
                                Label("Synth IoT", systemImage: "sensor.tag.radiowaves.forward")
                            }
                        } else {
                            Button(action: {
                                let sample = GeminiDeviceDiscoveryService.renderSampleHardwareImage(presetName: "barcode-udm-pro")
                                capturedImages.append(sample)
                                applyScannedBarcode(ParsedBarcodeResult(normalizedValue: "817882027373", is2DMatrix: false))
                            }) {
                                Label("Sample Barcode (UDM-Pro)", systemImage: "barcode")
                            }
                            Button(action: {
                                let sample = GeminiDeviceDiscoveryService.renderSampleHardwareImage(presetName: "qr-ucg-ultra")
                                capturedImages.append(sample)
                                applyScannedBarcode(
                                    ParsedBarcodeResult(
                                        normalizedValue: "https://setup.ui.com/entry?sku=UCG-Ultra&mac=74:AC:B9:4E:88:12",
                                        is2DMatrix: true
                                    )
                                )
                            }) {
                                Label("Sample QR (UCG-Ultra)", systemImage: "qrcode.viewfinder")
                            }
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "wand.and.stars")
                                .font(.system(size: 12))
                            Text("Synthesize...")
                                .font(.system(size: 11, weight: .semibold))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundColor(palette.accentText)
                        .padding(.horizontal, 10)
                        .frame(minHeight: 34)
                        .background(palette.accent.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(palette.accent.opacity(0.5), lineWidth: 1)
                        )
                    }

                    Menu {
                        Button(action: { seedSnapshotResults() }) {
                            Label("Seed Snapshot (All Components)", systemImage: "list.bullet.rectangle")
                        }
                        Button(action: { seedUnsupportedResult() }) {
                            Label("Unsupported Device", systemImage: "exclamationmark.triangle")
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "list.bullet.indent")
                                .font(.system(size: 12))
                            Text("Results...")
                                .font(.system(size: 11, weight: .semibold))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundColor(palette.accentText)
                        .padding(.horizontal, 10)
                        .frame(minHeight: 34)
                        .background(palette.accent.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(palette.accent.opacity(0.45), lineWidth: 1)
                        )
                    }
                    .uiAction("openResultsPicker")
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .trailing, spacing: 6) {
                    Toggle(isOn: Binding(
                        get: { repository.isVisionDebugEnabled },
                        set: { repository.toggleVisionDebugMode($0) }
                    )) {
                        Text("Debug Mode")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(debugActiveColor)
                    }
                    .tint(TuesdayTheme.warningAmber)
                    .controlSize(.mini)
                    .uiAction("toggleVisionDebugMode")

                    Toggle(isOn: Binding(
                        get: { repository.isDiagnosticsEnabled },
                        set: { repository.toggleDiagnosticsMode($0) }
                    )) {
                        Text("Diagnostics")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(diagActiveColor)
                    }
                    .tint(palette.accent)
                    .controlSize(.mini)
                    .uiAction("toggleDiagnosticsMode")

                    Toggle(isOn: Binding(
                        get: { repository.hacsConfig.aiProvider == .elastix },
                        set: { checked in
                            var next = repository.hacsConfig
                            next.aiProvider = checked ? .elastix : .gemini
                            repository.updateHacsConfig(next)
                        }
                    )) {
                        Text(isElastix ? "AI: Elastix" : "AI: Gemini")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(activeAiColor)
                    }
                    .tint(TuesdayTheme.healthyGreen)
                    .controlSize(.mini)
                    .uiAction("switchAiProvider")
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.leading, 12)
            .padding(.trailing, 10)
            .padding(.vertical, 8)
            .background(palette.elevated.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(palette.border.opacity(0.5), lineWidth: 1)
            )
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(TuesdayTheme.warningAmber)
                    .frame(width: 3.5)
            }
            .uiSlot("dev-controls")
        }
        .uiComponent("DevControlsCallout")
    }

    @ViewBuilder
    private func candidateResultsSection(result: GeminiDiscoveryTurnResult, isStn: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("RESULTS")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.6)
                    .foregroundColor(palette.textMuted)
                Spacer()
                Button("Clear All") {
                    discoveryResult = nil
                    inspectedCandidate = nil
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(palette.accentText)
                .uiAction("clearDiscoveryResults")
            }

            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 14) {
                    if !result.isNetworkedDevice || !(result.outOfScopeReason ?? "").isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("UNSUPPORTED DEVICE")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(0.8)
                                .foregroundColor(TuesdayTheme.ledColor(for: .eol, isStn: isStn))
                            Text(result.outOfScopeReason ?? "This item does not appear to have Wi-Fi or Ethernet networking and isn't tracked in SureThingNet Insights.")
                                .font(.system(size: 12))
                                .foregroundColor(palette.textPrimary)
                                .lineSpacing(3)
                            Button(action: {
                                discoveryResult = nil
                                capturedImages.removeAll()
                                scannedBarcodesList.removeAll()
                                selectedClues.removeAll()
                                if AVCaptureDevice.default(for: .video) != nil {
                                    showCameraSheet = true
                                }
                            }) {
                                Text("Start New Capture")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity, minHeight: 38)
                                    .background(TuesdayTheme.warningAmber)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                            .uiAction("startNewCapture")
                        }
                        .padding(12)
                        .background(TuesdayTheme.warningAmber.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(TuesdayTheme.warningAmber.opacity(0.45), lineWidth: 1)
                        )
                    }

                    if result.multipleDevicesDetected || !(result.multiDeviceWarning ?? "").isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("⚠ MULTIPLE DEVICES IN PHOTO — LOWER CONFIDENCE")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(TuesdayTheme.ledColor(for: .eol, isStn: isStn))
                            Text(result.multiDeviceWarning ?? "Multiple devices detected in this photo. Confidence can be lower when neighboring chassis appear in frame — for best results, snap a new photo framed around a single device.")
                                .font(.system(size: 13.5))
                                .foregroundColor(palette.textPrimary)
                                .lineSpacing(3)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(TuesdayTheme.warningAmber.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(TuesdayTheme.warningAmber.opacity(0.45), lineWidth: 1)
                        )
                        .uiSlot("multi-device-warning-banner")
                    }

                    if !result.candidates.isEmpty {
                        Text("CANDIDATE DEVICE MATCHES (\(result.candidates.count))")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(1)
                            .foregroundColor(palette.textMuted)

                        VStack(alignment: .leading, spacing: 0) {
                            SurfaceListContainer(palette: palette) {
                                ForEach(Array(result.candidates.enumerated()), id: \.element.id) { idx, candidate in
                                    if idx > 0 { SurfaceListDivider(palette: palette) }
                                    candidateResultRow(candidate, isStn: isStn)
                                }
                            }
                            .uiSlot("candidate-results-list")
                        }
                        .uiComponent("CandidateResultsList")
                    }

                    // Progressive Discovery Escape Hatch: allow saving rough/guessed hardware even if exact model isn't listed
                    Button(action: {
                        Task { await enrollRoughGuessedDevice(from: result) }
                    }) {
                        Text("Not listed or not sure? Save as Rough Device")
                            .font(.system(size: 12.5, weight: .semibold))
                            .foregroundColor(palette.textPrimary)
                            .frame(maxWidth: .infinity, minHeight: 40)
                            .background(palette.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(palette.borderStrong, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(isSaving)
                    .uiAction("saveRoughGuessedDevice")
                }
                .uiSlot("ai-discovery-panel")
            }
            .uiComponent("AiDiscoveryPanel")
        }
    }

    private func candidateResultRow(_ candidate: DeviceCandidateMatch, isStn: Bool) -> some View {
        let badgeColor: Color = {
            if candidate.confidencePercent >= 80 { return TuesdayTheme.ledColor(for: .ok, isStn: isStn) }
            if candidate.confidencePercent >= 50 { return TuesdayTheme.ledColor(for: .eol, isStn: isStn) }
            return palette.accentText
        }()

        return TuesdayListRow(
            palette: palette,
            title: candidate.displayName,
            titleLineLimit: 2,
            onClick: { inspectedCandidate = candidate },
            trailing: {
                MonospaceBadge(
                    text: "\(candidate.confidencePercent)% match",
                    color: badgeColor
                )
            }
        )
        .uiComponent("CandidateResultItem")
    }

    @ViewBuilder
    private func candidateConfirmationModal(candidate: DeviceCandidateMatch, isStn: Bool) -> some View {
        let badgeColor: Color = {
            if candidate.confidencePercent >= 80 { return TuesdayTheme.ledColor(for: .ok, isStn: isStn) }
            if candidate.confidencePercent >= 50 { return TuesdayTheme.ledColor(for: .eol, isStn: isStn) }
            return palette.accentText
        }()

        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                Text(candidate.displayName)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(palette.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                MonospaceBadge(
                    text: "\(candidate.confidencePercent)% match",
                    color: badgeColor
                )
            }

            SurfaceListDivider(palette: palette)

            detailRow(label: "Manufacturer", value: candidate.manufacturer)
            detailRow(label: "Model", value: candidate.modelNumber)
            detailRow(label: "Category", value: candidate.deviceCategory)
            if let ga = candidate.goldAlignment {
                detailRow(label: "SureThingNet Insights", value: ga.statusLabel)
                detailRow(label: "Feed", value: ga.matchedFeedName ?? ga.matchedFeedSlug)
                detailRow(label: "Latest Release", value: ga.latestGoldRelease)
                detailRow(label: "PURL", value: ga.inferredPurl)
            }

            if !candidate.reasoning.isEmpty {
                Text(candidate.reasoning)
                    .font(.system(size: 12.5))
                    .foregroundColor(palette.textMuted)
                    .lineSpacing(3)
            }

            Spacer()

            Button(action: {
                Task { await enrollCandidate(candidate) }
            }) {
                Text(isSaving ? "Adding..." : "Add to Inventory")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(TuesdayTheme.healthyGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .disabled(isSaving)
            .uiAction("addToInventoryFromModal")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(palette.surface.ignoresSafeArea())
        .uiComponent("CandidateConfirmModal")
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private func detailRow(label: String, value: String?) -> some View {
        if let v = value, !v.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            HStack {
                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(palette.textMuted)
                Spacer()
                Text(v)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundColor(palette.textPrimary)
                    .lineLimit(1)
            }
        }
    }

    private func visionDebugLogPanel() -> some View {
        let base = repository.tuesdayApiBaseUrl.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let combinedLogText: String = debugLogs.isEmpty
            ? """
            === TUESDAY VISION DEBUG CONSOLE READY ===
            Server Endpoint: \(base)/api/v1/discovery/analyze (debug=true)
            Active AI Provider: \(repository.hacsConfig.aiProvider.displayName)
            Submit a photo or clues to inspect trace & candidate alignment.
            """
            : debugLogs.reversed().joined(separator: "\n\n" + String(repeating: "=", count: 48) + "\n\n")

        let currentPreset = ApiEndpointPreset.fromUrl(repository.tuesdayApiBaseUrl)
        let isProd = (currentPreset == .prodGcp)
        let targetColor = isProd ? TuesdayTheme.ledUpdateBlue : TuesdayTheme.healthyGreen

        return VStack(alignment: .leading, spacing: 10) {
            Text("VISION API DEBUG LOG (\(debugLogs.count) TURN\(debugLogs.count == 1 ? "" : "S"))")
                .font(.system(size: 11.5, weight: .bold, design: .monospaced))
                .foregroundColor(TuesdayTheme.warningAmber)

            Text("Target: \(repository.tuesdayApiBaseUrl)")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(palette.textMuted)
                .lineLimit(1)

            if let feedback = copyLogFeedback {
                Text(feedback)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(TuesdayTheme.healthyGreen)
            }

            HStack(spacing: 6) {
                Button(action: {
                    let all = ApiEndpointPreset.allCases
                    let idx = currentPreset.flatMap { all.firstIndex(of: $0) } ?? 0
                    let next = all[(idx + 1) % all.count]
                    repository.setTuesdayApiBaseUrl(next.url)
                    copyLogFeedback = "Switched API → \(next.url)"
                }) {
                    Text("\(currentPreset?.shortBadge ?? "CUSTOM") ⇄")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(targetColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(targetColor.opacity(0.16))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(targetColor.opacity(0.55), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .uiAction("cycleApiEndpointPreset")

                Button(action: {
                    UIPasteboard.general.string = combinedLogText
                    copyLogFeedback = "Copied \(combinedLogText.count) chars to clipboard"
                }) {
                    Text("Copy Log")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(palette.accentText)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(palette.accent.opacity(0.18))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(palette.accent.opacity(0.5), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .uiAction("copyVisionDebugLog")

                if !debugLogs.isEmpty {
                    Button(action: {
                        debugLogs.removeAll()
                        copyLogFeedback = nil
                    }) {
                        Text("Clear")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(TuesdayTheme.criticalRed)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(TuesdayTheme.criticalRed.opacity(0.18))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(TuesdayTheme.criticalRed.opacity(0.5), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .uiAction("clearVisionDebugLog")
                }
            }

            ScrollView {
                Text(combinedLogText)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(Color(red: 0.89, green: 0.91, blue: 0.94))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .frame(minHeight: 140, maxHeight: 280)
            .padding(10)
            .background(Color(red: 0.02, green: 0.04, blue: 0.07))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(14)
        .background(Color(red: 0.04, green: 0.05, blue: 0.09))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(TuesdayTheme.warningAmber.opacity(0.55), lineWidth: 1)
        )
        .uiSlot("vision-debug-log-panel")
    }

    private func seedSnapshotResults() {
        discoveryResult = GeminiDiscoveryTurnResult(
            visualSummary: "Identified a circular white ceiling-mounted Ubiquiti UniFi U6-Pro access point with centered status LED ring; a second switch chassis is partially visible on the left edge.",
            isNetworkedDevice: true,
            extractedIdentifiers: ExtractedDeviceIdentifiers(
                barcode: "810010074512",
                serialNumber: "2245K-U6P-00192",
                modelNumber: "U6-Pro",
                macAddress: "74:AC:B9:12:34:56"
            ),
            candidates: [
                DeviceCandidateMatch(
                    manufacturer: "Ubiquiti",
                    modelNumber: "U6-Pro",
                    displayName: "Ubiquiti UniFi U6-Pro",
                    deviceCategory: "Access Point",
                    confidencePercent: 94,
                    reasoning: "Dual-band Wi-Fi 6 ceiling AP matching chassis diameter and LED ring.",
                    suggestedHostname: "unifi-u6-pro.local",
                    suggestedOsDetails: "UniFi OS 4.0.20",
                    suggestedPackageManager: "apt",
                    goldAlignment: GoldAlignmentInfo(
                        aligned: true,
                        inferredPurl: "pkg:generic/ubiquiti/u6-pro",
                        statusLabel: "GOLD ALIGNED",
                        matchedFeedName: "Ubiquiti UniFi Network",
                        latestGoldRelease: "6.6.77"
                    )
                ),
                DeviceCandidateMatch(
                    manufacturer: "Ubiquiti",
                    modelNumber: "U6-LR",
                    displayName: "Ubiquiti UniFi U6-LR",
                    deviceCategory: "Access Point",
                    confidencePercent: 68,
                    reasoning: "Similar circular form factor; slightly larger diameter.",
                    suggestedHostname: "unifi-u6-lr.local",
                    suggestedOsDetails: "UniFi OS 4.0.20",
                    suggestedPackageManager: "apt"
                )
            ],
            usedLiveGeminiApi: true,
            debugTrace: "Seed Snapshot (Local)",
            multipleDevicesDetected: true,
            multiDeviceWarning: "Multiple devices detected in frame. Candidate #1 targets the central access point."
        )
    }

    private func seedUnsupportedResult() {
        discoveryResult = GeminiDiscoveryTurnResult(
            visualSummary: "Identified a portable Bluetooth speaker with no Ethernet port or Wi-Fi radio.",
            isNetworkedDevice: false,
            outOfScopeReason: "This appears to be a Bluetooth-only speaker with no Wi-Fi or Ethernet radio and is outside SureThingNet Insights' scope.",
            candidates: [],
            usedLiveGeminiApi: true,
            debugTrace: "Seed Snapshot (Local)"
        )
    }

    private func applyClueIdentifiers(_ clue: GoldClueItem) {
        if let model = clue.model, !model.isEmpty {
            accumulatedIdentifiers.modelNumber = model
        }
        if clue.kind == .identifier {
            if let mac = clue.macAddress, !mac.isEmpty { accumulatedIdentifiers.macAddress = mac }
            if let upc = clue.upc, !upc.isEmpty { accumulatedIdentifiers.barcode = upc }
        }
    }

    private func handleCapturedOrPickedImage(_ image: UIImage) {
        capturedImages.append(image)
        extractBarcodesFromImage(image)
    }

    private func loadPhotoPickerImage(_ item: PhotosPickerItem?, runBarcodeExtract: Bool) async {
        guard let item,
              let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else {
            return
        }
        await MainActor.run {
            capturedImages.append(image)
            if runBarcodeExtract {
                extractBarcodesFromImage(image)
            }
        }
    }

    private func extractBarcodesFromImage(_ image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        let request = VNDetectBarcodesRequest { req, _ in
            guard let results = req.results as? [VNBarcodeObservation] else { return }
            for obs in results {
                if let payload = obs.payloadStringValue,
                   let parsed = BarcodeIdentifierParser.parse(rawValue: payload, symbology: obs.symbology) {
                    DispatchQueue.main.async {
                        applyScannedBarcode(parsed)
                    }
                    break
                }
            }
        }
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }

    private func applyScannedBarcode(_ parsed: ParsedBarcodeResult) {
        if parsed.is2DMatrix {
            accumulatedIdentifiers.qrCode = parsed.normalizedValue
        } else {
            accumulatedIdentifiers.barcode = parsed.normalizedValue
        }
        if !scannedBarcodesList.contains(parsed.normalizedValue) {
            scannedBarcodesList.append(parsed.normalizedValue)
        }
        let hits = GoldClueSuggestionRepository.shared.querySuggestions(
            rawQuery: parsed.normalizedValue,
            selected: selectedClues,
            limit: 1
        )
        if let firstHit = hits.first, !selectedClues.contains(where: { $0.id == firstHit.id }) {
            selectedClues.append(firstHit)
            statusBanner = "Barcode matched offline: \(firstHit.title)"
        }
        debugLogs.append("[Barcode] \(parsed.normalizedValue) (2D=\(parsed.is2DMatrix))")
    }

    private func runDeferredDiscoverySearch() async {
        isAnalyzing = true
        defer { isAnalyzing = false }

        let trimmedQuery = clueQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedQuery.isEmpty {
            let clue = GoldClueSuggestionRepository.shared.classifyFreeTextClue(trimmedQuery)
            if !selectedClues.contains(where: { $0.id == clue.id }) {
                selectedClues.append(clue)
            }
            applyClueIdentifiers(clue)
            clueQuery = ""
        }

        if capturedImages.isEmpty,
           let localMatch = GoldClueSuggestionRepository.shared.resolveLocalDiscoveryResult(
               selected: selectedClues,
               accumulatedIdentifiers: accumulatedIdentifiers,
               manualDeviceName: entryMode == .manual ? manualDeviceName : ""
           ) {
            discoveryResult = localMatch
            debugLogs.append("[Gold 0-Turn] Resolved \(localMatch.candidates.first?.displayName ?? "SKU")")
            return
        }

        if !capturedImages.isEmpty {
            if EntitlementGatePolicy.requiresUpgradeForAiPhotoScan(
                tier: repository.entitlementTier,
                scansUsed: repository.aiPhotoScansUsed
            ) {
                manualError = "You've used all \(EntitlementGatePolicy.freeAiPhotoScanLimit) free AI photo scans. Upgrade to Pro Tier 1 for unlimited AI photo identification — or use Barcode / Manual Clues free."
                onOpenUpgrade()
                return
            }
            repository.recordAiPhotoScanUsed()
        }

        let isElastix = (repository.hacsConfig.aiProvider == .elastix)
        let notes = selectedClues.map(\.title)
        let result = await GeminiDeviceDiscoveryService.shared.analyzeDeviceProgressive(
            images: capturedImages,
            accumulatedIdentifiers: accumulatedIdentifiers,
            userClueNotes: notes,
            apiKeyOverride: isElastix ? repository.hacsConfig.elastixApiKey : repository.hacsConfig.geminiApiKey,
            modelName: isElastix ? repository.hacsConfig.elastixModel : repository.hacsConfig.geminiModel,
            providerOverride: repository.hacsConfig.aiProvider.rawValue,
            serverBaseUrl: repository.tuesdayApiBaseUrl,
            debugCapture: repository.isVisionDebugEnabled
        )
        discoveryResult = result
        if let trace = result.debugTrace {
            debugLogs.append("[API] \(trace)")
        }
    }

    private func enrollCandidate(_ candidate: DeviceCandidateMatch) async {
        isSaving = true
        defer { isSaving = false }

        let host = manualDeviceName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? candidate.displayName
            : manualDeviceName
        let state: InventoryConfidenceState = (candidate.goldAlignment?.aligned == true || candidate.confidencePercent >= 80)
            ? .verified
            : .incompleteOrGuessed

        await repository.enrollNode(
            hostname: host,
            osDetails: candidate.suggestedOsDetails,
            packageManager: candidate.resolvedPackageManager,
            agentToken: "local-enroll",
            inventoryState: state,
            discoveredMetadata: DiscoveredDeviceMetadata(
                manufacturer: candidate.manufacturer,
                modelNumber: candidate.modelNumber,
                deviceCategory: candidate.deviceCategory,
                serialNumber: accumulatedIdentifiers.serialNumber,
                macAddress: accumulatedIdentifiers.macAddress,
                barcodeOrQr: accumulatedIdentifiers.barcode ?? accumulatedIdentifiers.qrCode,
                confidenceScore: candidate.confidencePercent,
                discoveryNotes: candidate.reasoning
            )
        )
        _ = await GeminiDeviceDiscoveryService.shared.confirmDeviceDiscovery(
            inferredVendor: candidate.manufacturer,
            inferredModel: candidate.modelNumber,
            confirmedVendor: candidate.manufacturer,
            confirmedModel: candidate.modelNumber,
            wasEdited: !manualDeviceName.isEmpty,
            accumulatedIdentifiers: accumulatedIdentifiers,
            serverBaseUrl: repository.tuesdayApiBaseUrl
        )
        inspectedCandidate = nil
        dismiss()
    }

    private func enrollManually() async {
        let trimmedClue = clueQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        var effectiveClues = selectedClues
        if !trimmedClue.isEmpty {
            let resolved = GoldClueSuggestionRepository.shared.classifyFreeTextClue(trimmedClue)
            if !effectiveClues.contains(where: { $0.id == resolved.id }) {
                effectiveClues.append(resolved)
                selectedClues.append(resolved)
            }
            applyClueIdentifiers(resolved)
            clueQuery = ""
        }

        guard let resolved = ManualEnrollmentResolver.resolve(
            manualHostname: manualDeviceName,
            selectedClues: effectiveClues,
            accumulatedIdentifiers: accumulatedIdentifiers
        ) else {
            manualError = "Enter a name or pick any device type, brand, or rough clue — you can refine details later."
            return
        }

        isSaving = true
        defer { isSaving = false }

        await repository.enrollNode(
            hostname: resolved.hostname,
            osDetails: resolved.osSummary,
            packageManager: .firmware,
            agentToken: "manual-local",
            inventoryState: resolved.inventoryState,
            discoveredMetadata: resolved.metadata
        )
        dismiss()
    }

    private func enrollRoughGuessedDevice(from result: GeminiDiscoveryTurnResult) async {
        let topCandidate = result.candidates.first
        let fallbackManual = ManualEnrollmentResolver.resolve(
            manualHostname: manualDeviceName,
            selectedClues: selectedClues,
            accumulatedIdentifiers: accumulatedIdentifiers
        )
        let roughHostname = fallbackManual?.hostname
            ?? topCandidate.map { "\($0.manufacturer) \($0.deviceCategory ?? "Device")".trimmingCharacters(in: .whitespacesAndNewlines) }
            ?? "Unidentified Device"
        let roughMetadata = fallbackManual?.metadata ?? DiscoveredDeviceMetadata(
            manufacturer: topCandidate?.manufacturer ?? "Manual",
            modelNumber: topCandidate?.deviceCategory ?? roughHostname,
            deviceCategory: topCandidate?.deviceCategory,
            serialNumber: accumulatedIdentifiers.serialNumber,
            macAddress: accumulatedIdentifiers.macAddress,
            barcodeOrQr: accumulatedIdentifiers.barcode
        )
        let roughSummary = fallbackManual?.osSummary ?? "Rough Entry • Refine via Check-Up"

        isSaving = true
        defer { isSaving = false }

        await repository.enrollNode(
            hostname: roughHostname,
            osDetails: roughSummary,
            packageManager: .firmware,
            agentToken: "rough-discovery",
            inventoryState: .incompleteOrGuessed,
            discoveredMetadata: roughMetadata
        )
        dismiss()
    }

    private func applyInitialDeepLinkArgsIfNeeded() {
        guard !didApplyInitialParams else { return }
        didApplyInitialParams = true

        if let mode = initialMode?.lowercased() {
            if mode == "scan" || mode == "barcode" { entryMode = .scan }
            else if mode == "manual" || mode == "clues" { entryMode = .manual }
            else { entryMode = .photo }
        }
        if let q = initialQuery, !q.isEmpty {
            clueQuery = q
        }
        if let csv = initialCluesCsv, !csv.isEmpty {
            for token in csv.split(separator: ",").map({ String($0).trimmingCharacters(in: .whitespacesAndNewlines) }) where !token.isEmpty {
                let hits = GoldClueSuggestionRepository.shared.querySuggestions(rawQuery: token, selected: selectedClues, limit: 1)
                let clue = hits.first ?? GoldClueSuggestionRepository.shared.classifyFreeTextClue(token)
                if !selectedClues.contains(where: { $0.id == clue.id }) {
                    selectedClues.append(clue)
                    applyClueIdentifiers(clue)
                }
            }
        }
        if let preset = initialSynthPreset?.lowercased(), !preset.isEmpty {
            if preset.contains("barcode") {
                entryMode = .scan
                capturedImages.append(GeminiDeviceDiscoveryService.renderSampleHardwareImage(presetName: "barcode-udm-pro"))
                applyScannedBarcode(ParsedBarcodeResult(normalizedValue: "817882027373", is2DMatrix: false))
            } else if preset.contains("qr") {
                entryMode = .scan
                capturedImages.append(GeminiDeviceDiscoveryService.renderSampleHardwareImage(presetName: "qr-ucg-ultra"))
                applyScannedBarcode(
                    ParsedBarcodeResult(
                        normalizedValue: "https://setup.ui.com/entry?sku=UCG-Ultra&mac=74:AC:B9:4E:88:12",
                        is2DMatrix: true
                    )
                )
            } else if preset.contains("iot") || preset.contains("zigbee") {
                entryMode = .photo
                capturedImages.append(GeminiDeviceDiscoveryService.renderSampleHardwareImage(presetName: "zigbee-iot"))
                let hubClue = GoldClueItem(
                    id: "type:hub",
                    kind: .deviceType,
                    typeId: "hub",
                    title: "Smart Hub / Bridge",
                    subtitle: "C8 • Device Type",
                    chipLabel: "Smart Hub / Bridge",
                    categoryCode: "C8"
                )
                if !selectedClues.contains(where: { $0.id == hubClue.id }) {
                    selectedClues.append(hubClue)
                }
            } else if preset.contains("router") {
                entryMode = .photo
                capturedImages.append(GeminiDeviceDiscoveryService.renderSampleHardwareImage(presetName: "router"))
            }
        }
        if autoSearch {
            Task { await runDeferredDiscoverySearch() }
        }
    }
}
