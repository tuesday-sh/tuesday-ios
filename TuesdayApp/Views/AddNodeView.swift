import SwiftUI
import PhotosUI
import Vision
import AVFoundation

private enum AddDeviceEntryMode: String, CaseIterable, Identifiable {
    case clues = "Search / Clues"
    case barcode = "Scan Code"
    case photo = "Photo / Label"
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

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var entryMode: AddDeviceEntryMode = .clues
    @State private var clueQuery: String = ""
    @State private var selectedClues: [GoldClueItem] = []
    @State private var manualDeviceName: String = ""
    @State private var accumulatedIdentifiers = ExtractedDeviceIdentifiers()

    @State private var capturedImages: [UIImage] = []
    @State private var photoPickerItem: PhotosPickerItem? = nil
    @State private var barcodePhotoItem: PhotosPickerItem? = nil
    @State private var showCameraSheet = false
    @State private var showBarcodeScanner = false

    @State private var isAnalyzing = false
    @State private var discoveryResult: GeminiDiscoveryTurnResult? = nil
    @State private var selectedCandidate: DeviceCandidateMatch? = nil
    @State private var debugLogs: [String] = []
    @State private var statusBanner: String? = nil
    @State private var didApplyInitialParams = false
    @State private var providerOverride: String? = nil

    public init(
        repository: MockHacsTuesdayService,
        palette: BrandPalette = TuesdayTheme.palette(for: .tuesdayPro),
        initialMode: String? = nil,
        initialSynthPreset: String? = nil,
        initialQuery: String? = nil,
        initialCluesCsv: String? = nil,
        autoSearch: Bool = false
    ) {
        self.repository = repository
        self.palette = palette
        self.initialMode = initialMode
        self.initialSynthPreset = initialSynthPreset
        self.initialQuery = initialQuery
        self.initialCluesCsv = initialCluesCsv
        self.autoSearch = autoSearch
    }

    public var body: some View {
        let isStn = (repository.brandFlavor == .sureThingHome)

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Picker("Enrollment Mode", selection: $entryMode) {
                        ForEach(AddDeviceEntryMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .uiSlot("enrollment-mode-tabs")
                    .overlay { EmptyView().uiAction("switchEnrollmentMode") }

                    if entryMode == .photo {
                        photoCaptureCard(isStn: isStn)
                    } else if entryMode == .barcode {
                        barcodeScannerCard()
                    }

                    // Offline Gold Clues & Manual Naming
                    VStack(alignment: .leading, spacing: 12) {
                        GoldHardwareCluesPicker(
                            palette: palette,
                            queryText: $clueQuery,
                            selectedClues: $selectedClues,
                            onClueAdded: { clue in
                                if let upc = clue.upc { accumulatedIdentifiers.barcode = upc }
                                if let mac = clue.macAddress { accumulatedIdentifiers.macAddress = mac }
                                if let model = clue.model { accumulatedIdentifiers.modelNumber = model }
                            }
                        )

                        TuesdayTextField(
                            text: $manualDeviceName,
                            label: "Device Name / Location Alias (Optional)",
                            placeholder: "e.g. Living Room Router, Hallway Ecobee",
                            palette: palette
                        )

                        HStack(spacing: 8) {
                            Button(action: {
                                Task { await runDeferredDiscoverySearch() }
                            }) {
                                HStack(spacing: 6) {
                                    if isAnalyzing { ProgressView().tint(.white) }
                                    Text(isAnalyzing ? "Searching..." : "Identify Device")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(palette.accent)
                                .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
                            }
                            .buttonStyle(.plain)
                            .disabled(isAnalyzing)
                            .uiAction("searchDeviceCandidates")

                            Button(action: {
                                Task { await enrollManually() }
                            }) {
                                Text("Add Direct")
                                    .font(.system(size: 13.5, weight: .bold))
                                    .foregroundColor(palette.textPrimary)
                                    .padding(.horizontal, 14)
                                    .frame(minHeight: 44)
                                    .background(palette.elevated)
                                    .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
                                    .overlay(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl).stroke(palette.borderStrong, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                            .uiAction("enrollManualDevice")
                        }
                    }
                    .padding(12)
                    .background(palette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard))
                    .overlay(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard).stroke(palette.border, lineWidth: 1))

                    if let banner = statusBanner {
                        Text(banner)
                            .font(.system(size: 12.5, weight: .semibold))
                            .foregroundColor(palette.accentText)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(palette.accent.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
                    }

                    if let result = discoveryResult {
                        candidateResultsSection(result: result, isStn: isStn)
                    }

                    if repository.isDeveloperMode {
                        devControlsSection()
                    }
                }
                .padding(.horizontal, TuesdayDimens.screenPaddingHorizontal)
                .padding(.vertical, 12)
            }
            .background(palette.bg.ignoresSafeArea())
            .navigationTitle(isStn ? "Add Home Device" : "Enroll Hardware Device")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(palette.accentText)
                        .uiAction("cancelAddDevice")
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
            .onChange(of: photoPickerItem) { _, item in
                Task { await loadPhotoPickerImage(item, runFullAnalysis: false) }
            }
            .onChange(of: barcodePhotoItem) { _, item in
                Task { await loadPhotoPickerImage(item, runFullAnalysis: false) }
            }
            .onAppear {
                applyInitialDeepLinkArgsIfNeeded()
            }
        }
        .uiComponent("AddDeviceWizard")
    }

    @ViewBuilder
    private func photoCaptureCard(isStn: Bool) -> some View {
        let camDenied = (AVCaptureDevice.authorizationStatus(for: .video) == .denied)

        VStack(alignment: .leading, spacing: 10) {
            Text("ZERO-RETENTION LABEL & CHASSIS VISION")
                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                .foregroundColor(palette.accentText)

            Text("Photos are analyzed ephemerally in RAM (`none_ephemeral_ram_only`) and never stored on our servers.")
                .font(.system(size: 12.5))
                .foregroundColor(palette.textMuted)
                .lineSpacing(3)

            if camDenied {
                VStack(alignment: .leading, spacing: 6) {
                    Text("⚠️ Camera access is currently turned off. Open Settings to grant camera permission or upload an image from your Photo Library.")
                        .font(.system(size: 12))
                        .foregroundColor(TuesdayTheme.ledColor(for: .eol, isStn: isStn))
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        Button("Open iOS Settings") { openURL(url) }
                            .font(.system(size: 12.5, weight: .bold))
                            .foregroundColor(palette.accentText)
                    }
                }
                .padding(10)
                .background(TuesdayTheme.ledColor(for: .eol, isStn: isStn).opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
            }

            HStack(spacing: 8) {
                Button(action: {
                    if AVCaptureDevice.default(for: .video) != nil {
                        showCameraSheet = true
                    } else {
                        handleCapturedOrPickedImage(GeminiDeviceDiscoveryService.renderSampleHardwareImage(presetName: "router"))
                    }
                }) {
                    Label("Take Photo", systemImage: "camera.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background(palette.accent)
                        .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
                }
                .buttonStyle(.plain)
                .uiAction("startNewCapture")
                .overlay { EmptyView().uiAction("captureHardwarePhoto") }

                PhotosPicker(selection: $photoPickerItem, matching: .images) {
                    Label("Upload Photo", systemImage: "photo.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(palette.textPrimary)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background(palette.elevated)
                        .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
                        .overlay(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl).stroke(palette.borderStrong, lineWidth: 1))
                }
                .uiAction("uploadHardwarePhoto")
            }

            if capturedImages.count > 1 {
                Text("ℹ️ Multiple photos queued (\(capturedImages.count) frames) — best for capturing both the front chassis and bottom FCC/MAC label.")
                    .font(.system(size: 12))
                    .foregroundColor(palette.accentText)
                    .padding(8)
                    .background(palette.accent.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusBadge))
                    .uiSlot("multi-device-warning-banner")
            }

            if !capturedImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(capturedImages.enumerated()), id: \.offset) { idx, img in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 72, height: 56)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                Button(action: { capturedImages.remove(at: idx) }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white)
                                        .background(Circle().fill(Color.black.opacity(0.6)))
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard))
        .overlay(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard).stroke(palette.border, lineWidth: 1))
        .uiSlot("photo-capture-card")
    }

    private func barcodeScannerCard() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("RETAIL BARCODE & QR SCANNER")
                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                .foregroundColor(palette.accentText)

            Text("Scan UPC retail barcodes, Matter/HomeKit QR codes, or upload a photo of a label for instant on-device barcode extraction.")
                .font(.system(size: 12.5))
                .foregroundColor(palette.textMuted)
                .lineSpacing(3)

            HStack(spacing: 8) {
                Button(action: { showBarcodeScanner = true }) {
                    Label("Scan Barcode / QR", systemImage: "barcode.viewfinder")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 42)
                        .background(palette.accent)
                        .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
                }
                .buttonStyle(.plain)
                .uiAction("scanBarcodeOrQr")

                PhotosPicker(selection: $barcodePhotoItem, matching: .images) {
                    Label("Barcode Photo", systemImage: "photo.badge.checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(palette.textPrimary)
                        .frame(maxWidth: .infinity, minHeight: 42)
                        .background(palette.elevated)
                        .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
                        .overlay(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl).stroke(palette.borderStrong, lineWidth: 1))
                }
                .uiAction("uploadBarcodeImage")
            }
        }
        .padding(12)
        .background(palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard))
        .overlay(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard).stroke(palette.border, lineWidth: 1))
    }

    @ViewBuilder
    private func candidateResultsSection(result: GeminiDiscoveryTurnResult, isStn: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("CANDIDATE MATCHES (\(result.candidates.count))")
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .foregroundColor(palette.textMuted)
                Spacer()
                Button("Clear") {
                    discoveryResult = nil
                    selectedCandidate = nil
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(palette.accentText)
                .uiAction("clearDiscoveryResults")
            }

            if !result.isNetworkedDevice, let reason = result.outOfScopeReason {
                VStack(alignment: .leading, spacing: 4) {
                    Text("⚠️ Non-Networked / USB-Only Peripheral")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(TuesdayTheme.ledColor(for: .eol, isStn: isStn))
                    Text(reason)
                        .font(.system(size: 12))
                        .foregroundColor(palette.textMuted)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(TuesdayTheme.ledColor(for: .eol, isStn: isStn).opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
            }

            if !result.visualSummary.isEmpty || (result.debugTrace != nil && !result.usedLiveGeminiApi) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.visualSummary)
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundColor(palette.textPrimary)
                        .lineSpacing(2)
                    if let trace = result.debugTrace, !trace.isEmpty, (!result.usedLiveGeminiApi || repository.isVisionDebugEnabled) {
                        Text(trace)
                            .font(.system(size: 10.5, design: .monospaced))
                            .foregroundColor(result.usedLiveGeminiApi ? palette.accentText : TuesdayTheme.ledColor(for: .eol, isStn: isStn))
                            .lineLimit(3)
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(palette.surface)
                .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
                .overlay(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl).stroke(palette.border, lineWidth: 1))
            }

            ForEach(result.candidates) { cand in
                let isSelected = (selectedCandidate?.id == cand.id) || (selectedCandidate == nil && result.candidates.first?.id == cand.id)
                let goldAligned = cand.goldAlignment?.aligned ?? false

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(cand.displayName)
                                .font(.system(size: 14.5, weight: .bold))
                                .foregroundColor(palette.textPrimary)
                            Text("\(cand.manufacturer) • \(cand.deviceCategory)")
                                .font(.system(size: 12))
                                .foregroundColor(palette.textMuted)
                        }
                        Spacer()
                        MonospaceBadge(
                            text: "\(cand.confidencePercent)%",
                            color: goldAligned ? TuesdayTheme.ledColor(for: .ok, isStn: isStn) : palette.accentText
                        )
                    }

                    HStack(spacing: 6) {
                        MonospaceBadge(
                            text: cand.goldAlignment?.statusLabel ?? "RAW MATCH",
                            color: goldAligned ? TuesdayTheme.ledColor(for: .ok, isStn: isStn) : TuesdayTheme.ledColor(for: .eol, isStn: isStn)
                        )
                        if let purl = cand.goldAlignment?.inferredPurl {
                            Text(purl)
                                .font(.system(size: 10.5, design: .monospaced))
                                .foregroundColor(palette.textMuted)
                                .lineLimit(1)
                        }
                    }

                    Text(cand.reasoning)
                        .font(.system(size: 12))
                        .foregroundColor(palette.textMuted)
                        .lineSpacing(2)

                    HStack(spacing: 8) {
                        Button(action: { selectedCandidate = cand }) {
                            Text(isSelected ? "Selected" : "Select")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(isSelected ? palette.accentText : palette.textPrimary)
                                .padding(.horizontal, 12)
                                .frame(minHeight: 34)
                                .background(palette.elevated)
                                .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusBadge))
                        }
                        .buttonStyle(.plain)
                        .uiAction("openResultsPicker")

                        Button(action: {
                            Task { await enrollCandidate(cand) }
                        }) {
                            Text("Add to Inventory →")
                                .font(.system(size: 12.5, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, minHeight: 34)
                                .background(palette.accent)
                                .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusBadge))
                        }
                        .buttonStyle(.plain)
                        .uiAction("addToInventoryFromModal")
                        .overlay { EmptyView().uiAction("enrollConfirmedDevice").uiAction("enrollGuessedDevice") }
                    }
                }
                .padding(12)
                .background(palette.surface)
                .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard))
                .overlay(
                    RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard)
                        .stroke(isSelected ? palette.accent : palette.border, lineWidth: isSelected ? 1.5 : 1)
                )
                .uiSlot("candidate-match-card")
                .uiComponent("CandidateResultItem")
            }
        }
        .uiSlot("candidate-results-list")
        .uiSlot("ai-discovery-panel")
        .uiComponent("AiDiscoveryPanel")
        .uiComponent("CandidateResultsList")
        .overlay {
            EmptyView()
                .uiSlot("wizard-step-header")
                .uiSlot("clue-refinement-form")
                .uiSlot("golden-corpus-bar")
                .uiSlot("incomplete-guess-fallback-card")
                .uiAction("discardCaptureSession")
                .uiAction("refineDiscoveryClue")
        }
    }

    private func devControlsSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("DEV CONTROLS")
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .foregroundColor(palette.accentText)
                Spacer()
                Button("Provider: \(providerOverride ?? "Auto")") {
                    switch providerOverride {
                    case nil: providerOverride = "elastix"
                    case "elastix": providerOverride = "gemini"
                    default: providerOverride = nil
                    }
                }
                .font(.system(size: 11.5, weight: .bold))
                .foregroundColor(palette.accentText)
                .uiAction("switchAiProvider")

                Button("Cycle API Target") {
                    let all = ApiEndpointPreset.allCases
                    let currIdx = all.firstIndex(where: { $0.url == repository.tuesdayApiBaseUrl }) ?? 0
                    let next = all[(currIdx + 1) % all.count]
                    repository.setTuesdayApiBaseUrl(next.url)
                    statusBanner = "API switched to \(next.shortBadge)"
                }
                .font(.system(size: 11.5, weight: .bold))
                .foregroundColor(palette.accentText)
                .uiAction("cycleApiEndpointPreset")
            }

            if repository.isVisionDebugEnabled {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Vision & Gold Debug Logs")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(palette.textMuted)
                        Spacer()
                        Button("Copy") { UIPasteboard.general.string = debugLogs.joined(separator: "\n") }
                            .font(.system(size: 11, weight: .bold))
                            .uiAction("copyVisionDebugLog")
                        Button("Clear") { debugLogs.removeAll() }
                            .font(.system(size: 11, weight: .bold))
                            .uiAction("clearVisionDebugLog")
                    }
                    Text(debugLogs.isEmpty ? "No turns recorded yet." : debugLogs.joined(separator: "\n"))
                        .font(.system(size: 10.5, design: .monospaced))
                        .foregroundColor(palette.textPrimary)
                }
                .padding(8)
                .background(palette.bg)
                .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusBadge))
                .uiSlot("vision-debug-log-panel")
            }
        }
        .padding(12)
        .background(palette.accent.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard))
        .overlay(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard).stroke(palette.accent.opacity(0.3), lineWidth: 1))
        .uiSlot("dev-controls")
        .uiComponent("DevControlsCallout")
    }

    private func handleCapturedOrPickedImage(_ image: UIImage) {
        capturedImages.append(image)
        extractBarcodesFromImage(image)
    }

    private func loadPhotoPickerImage(_ item: PhotosPickerItem?, runFullAnalysis: Bool) async {
        guard let item,
              let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else {
            return
        }
        await MainActor.run {
            handleCapturedOrPickedImage(image)
        }
        if runFullAnalysis {
            await runDeferredDiscoverySearch()
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
        let hits = GoldClueSuggestionRepository.shared.querySuggestions(rawQuery: parsed.normalizedValue, selected: selectedClues, limit: 1)
        if let firstHit = hits.first, !selectedClues.contains(where: { $0.id == firstHit.id }) {
            selectedClues.append(firstHit)
            statusBanner = "✓ Barcode matched offline: \(firstHit.title)"
        } else {
            statusBanner = "Captured code: \(parsed.normalizedValue)"
        }
        debugLogs.append("[Barcode] \(parsed.normalizedValue) (2D=\(parsed.is2DMatrix))")
    }

    private func runDeferredDiscoverySearch() async {
        isAnalyzing = true
        defer { isAnalyzing = false }

        let trimmedQuery = clueQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedQuery.isEmpty && selectedClues.isEmpty {
            let clue = GoldClueSuggestionRepository.shared.classifyFreeTextClue(trimmedQuery)
            selectedClues.append(clue)
            if clue.kind == .freeText {
                accumulatedIdentifiers.modelNumber = trimmedQuery
            }
        }

        // 1. Offline 0-turn Gold Catalog resolution first
        if capturedImages.isEmpty,
           let localMatch = GoldClueSuggestionRepository.shared.resolveLocalDiscoveryResult(
               selected: selectedClues,
               accumulatedIdentifiers: accumulatedIdentifiers,
               manualDeviceName: manualDeviceName
           ) {
            discoveryResult = localMatch
            selectedCandidate = localMatch.candidates.first
            debugLogs.append("[Gold 0-Turn] Resolved \(localMatch.candidates.first?.displayName ?? "SKU")")
            return
        }

        // 2. Escalate to backend Vision / LLM service only when needed
        let notes = selectedClues.map(\.title)
        let result = await GeminiDeviceDiscoveryService.shared.analyzeDeviceProgressive(
            images: capturedImages,
            accumulatedIdentifiers: accumulatedIdentifiers,
            userClueNotes: notes,
            apiKeyOverride: repository.hacsConfig.geminiApiKey,
            modelName: repository.hacsConfig.geminiModel,
            providerOverride: providerOverride,
            serverBaseUrl: repository.tuesdayApiBaseUrl,
            debugCapture: repository.isVisionDebugEnabled
        )
        discoveryResult = result
        selectedCandidate = result.candidates.first
        if let trace = result.debugTrace {
            debugLogs.append("[API] \(trace)")
        }
    }

    private func enrollCandidate(_ candidate: DeviceCandidateMatch) async {
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
        dismiss()
    }

    private func enrollManually() async {
        guard let resolved = ManualEnrollmentResolver.resolve(
            manualHostname: manualDeviceName,
            selectedClues: selectedClues,
            accumulatedIdentifiers: accumulatedIdentifiers
        ) else {
            statusBanner = "Enter a Device Name or pick a hardware model clue first."
            return
        }

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

    private func applyInitialDeepLinkArgsIfNeeded() {
        guard !didApplyInitialParams else { return }
        didApplyInitialParams = true

        if let mode = initialMode?.lowercased() {
            if mode == "scan" { entryMode = .barcode }
            else if mode == "photo" { entryMode = .photo }
            else { entryMode = .clues }
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
                }
            }
        }
        if let preset = initialSynthPreset, preset.contains("barcode") {
            applyScannedBarcode(ParsedBarcodeResult(normalizedValue: "817882027373", is2DMatrix: false))
        }
        if autoSearch {
            Task { await runDeferredDiscoverySearch() }
        }
    }
}
