import SwiftUI

/// Device Inventory Wizard with GCP Gemini AI Progressive Photo & Identifier Discovery
public struct AddNodeView: View {
    public enum EnrollmentMode: String, CaseIterable {
        case photoWizard = "AI Photo Wizard"
        case manualAgent = "Manual / Agent"
    }

    @ObservedObject var repository: MockHacsTuesdayService
    @Environment(\.dismiss) private var dismiss

    @State private var mode: EnrollmentMode = .photoWizard

    // Photo Wizard State
    @State private var capturedImages: [UIImage] = []
    @State private var isAnalyzingPhoto: Bool = false
    @State private var discoveryResult: GeminiDiscoveryTurnResult?
    @State private var accumulatedIdentifiers = ExtractedDeviceIdentifiers()
    @State private var userClueNotes: [String] = []
    @State private var selectedClueType: DeviceClueType = .modelNumber
    @State private var clueInputText: String = ""
    @State private var showCameraSheet: Bool = false
    @State private var showPhotoLibrarySheet: Bool = false

    // Manual / Agent State
    @State private var hostname: String = ""
    @State private var osDetails: String = ""
    @State private var packageManager: PackageManagerType = .apt
    @State private var agentToken: String = ""
    @State private var isSaving: Bool = false
    @State private var showScannerSheet: Bool = false
    @State private var validationMessage: String?

    public init(repository: MockHacsTuesdayService) {
        self.repository = repository
    }

    public var body: some View {
        ZStack {
            TuesdayTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    modeSelector

                    if mode == .photoWizard {
                        photoWizardContent
                    } else {
                        manualEnrollmentContent
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Add Device")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showScannerSheet) {
            qrScannerModal
        }
        .sheet(isPresented: $showCameraSheet) {
            CameraImagePicker(sourceType: .camera) { img in
                handleCapturedPhoto(img)
            }
        }
        .sheet(isPresented: $showPhotoLibrarySheet) {
            CameraImagePicker(sourceType: .photoLibrary) { img in
                handleCapturedPhoto(img)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var modeSelector: some View {
        HStack(spacing: 8) {
            ForEach(EnrollmentMode.allCases, id: \.rawValue) { item in
                let isSelected = mode == item
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        mode = item
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: item == .photoWizard ? "camera.viewfinder" : "terminal.fill")
                            .font(.system(size: 12, weight: .bold))
                        Text(item.rawValue)
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundStyle(isSelected ? .black : Color(white: 0.78))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(isSelected ? TuesdayTheme.healthyGreen : TuesdayTheme.cardSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .accessibilityIdentifier(item == .photoWizard ? "mode_photo_wizard_tab" : "mode_manual_agent_tab")
            }
        }
        .padding(4)
        .background(TuesdayTheme.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - AI Photo Wizard Content

    private var photoWizardContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            wizardStepHeader

            photoCaptureCard

            if isAnalyzingPhoto {
                analyzingProgressCard
            }

            if let result = discoveryResult {
                progressiveClueDiscoverySection(result: result)
                candidateMatchesSection(result: result)
                incompleteOrGuessedFallbackCard(result: result)
            }
        }
    }

    private var wizardStepHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(capturedImages.isEmpty ? "STEP 1 OF 3 • CAPTURE HARDWARE" : "STEP 2 OF 3 • PROGRESSIVE DISCOVERY")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(TuesdayTheme.hacsCyan)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(TuesdayTheme.hacsCyan.opacity(0.15))
                    .clipShape(Capsule())

                Spacer()

                Text("GCP Gemini 3.8 Flash")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(Color(white: 0.6))
            }

            Text("Inventory Device by Photo")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
                .accessibilityIdentifier("photo_wizard_title")

            Text("Snap a photo of a router, switch, NAS, or IoT device. Gemini AI will analyze the hardware and progressively narrow candidate models using barcodes, serial numbers, QR codes, models, or MAC addresses.")
                .font(.system(size: 13))
                .foregroundStyle(Color(white: 0.68))
                .lineSpacing(2)
        }
    }

    private var photoCaptureCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            if !capturedImages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(capturedImages.enumerated()), id: \.offset) { idx, img in
                            ZStack(alignment: .bottomLeading) {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 150, height: 105)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(TuesdayTheme.healthyGreen.opacity(0.5), lineWidth: 1)
                                    )

                                Text(idx == 0 ? "Device Photo" : "Clue #\(idx + 1)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color.black.opacity(0.72))
                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                                    .padding(6)
                            }
                        }
                    }
                }
            }

            HStack(spacing: 10) {
                Button {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        showCameraSheet = true
                    } else {
                        handleCapturedPhoto(GeminiDeviceDiscoveryService.renderSampleHardwareImage(presetName: "router"))
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 14, weight: .bold))
                        Text(capturedImages.isEmpty ? "Take Device Photo" : "Snap Sticker / Label")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(TuesdayTheme.healthyGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .accessibilityIdentifier("wizard_take_photo_button")

                Button {
                    showPhotoLibrarySheet = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 14, weight: .bold))
                        Text("Library")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 13)
                    .background(TuesdayTheme.elevatedPill)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .accessibilityIdentifier("wizard_photo_library_button")
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("QUICK PILOT HARDWARE PRESETS (OR USE LIVE CAMERA ABOVE)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color(white: 0.55))
                    .tracking(0.5)

                HStack(spacing: 8) {
                    Button {
                        let sample = GeminiDeviceDiscoveryService.renderSampleHardwareImage(presetName: "router")
                        handleCapturedPhoto(sample)
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "wifi.router.fill")
                                .font(.system(size: 11))
                            Text("Sample Router Photo")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundStyle(TuesdayTheme.hacsCyan)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(TuesdayTheme.hacsCyan.opacity(0.14))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .accessibilityIdentifier("wizard_sample_router_button")

                    Button {
                        let sample = GeminiDeviceDiscoveryService.renderSampleHardwareImage(presetName: "zigbee-iot")
                        userClueNotes.append("Zigbee USB coordinator antenna")
                        handleCapturedPhoto(sample)
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "sensor.tag.radiowaves.forward.fill")
                                .font(.system(size: 11))
                            Text("Sample IoT Dongle")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundStyle(TuesdayTheme.warningAmber)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(TuesdayTheme.warningAmber.opacity(0.14))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .accessibilityIdentifier("wizard_sample_iot_button")
                }
            }
        }
        .padding(16)
        .background(TuesdayTheme.cardSurface)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var analyzingProgressCard: some View {
        HStack(spacing: 12) {
            ProgressView()
                .tint(TuesdayTheme.hacsCyan)
            VStack(alignment: .leading, spacing: 3) {
                Text("Analyzing image with GCP Gemini AI...")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                Text("Inspecting chassis profile, ports, OUI prefix, and printed labels")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(white: 0.65))
            }
            Spacer()
        }
        .padding(14)
        .background(TuesdayTheme.cardSurface)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(TuesdayTheme.hacsCyan.opacity(0.4), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func progressiveClueDiscoverySection(result: GeminiDiscoveryTurnResult) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "sparkles")
                    .foregroundStyle(TuesdayTheme.hacsCyan)
                    .font(.system(size: 16, weight: .bold))

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("GEMINI AI VISUAL ANALYSIS")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(TuesdayTheme.hacsCyan)
                        Spacer()
                        Text(result.usedLiveGeminiApi ? "LIVE GCP AI" : "PILOT HEURISTIC")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(TuesdayTheme.healthyGreen)
                    }

                    Text(result.visualSummary)
                        .font(.system(size: 12))
                        .foregroundStyle(Color(white: 0.82))

                    Divider().background(Color.white.opacity(0.12)).padding(.vertical, 4)

                    Text(result.nextNarrowingQuestion)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .accessibilityIdentifier("wizard_narrowing_question_label")
                }
            }

            if !accumulatedIdentifiers.nonEmptyPairs.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("DISCOVERED IDENTIFIERS")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color(white: 0.55))

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(accumulatedIdentifiers.nonEmptyPairs, id: \.0.rawValue) { clueType, val in
                                HStack(spacing: 4) {
                                    Image(systemName: clueType.systemIcon)
                                        .font(.system(size: 10))
                                    Text("\(clueType.rawValue): \(val)")
                                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                }
                                .foregroundStyle(TuesdayTheme.healthyGreen)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(TuesdayTheme.healthyGreen.opacity(0.14))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("ADD IDENTIFIER TO NARROW CANDIDATES (BARCODE, S/N, QR, MODEL, MAC)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color(white: 0.6))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(DeviceClueType.allCases) { clue in
                            let selected = selectedClueType == clue
                            Button {
                                selectedClueType = clue
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: clue.systemIcon)
                                        .font(.system(size: 11))
                                    Text(clue.rawValue)
                                        .font(.system(size: 11, weight: .bold))
                                }
                                .foregroundStyle(selected ? .black : .white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(selected ? TuesdayTheme.hacsCyan : TuesdayTheme.elevatedPill)
                                .clipShape(Capsule())
                            }
                            .accessibilityIdentifier("clue_chip_\(clue.rawValue)")
                        }
                    }
                }

                HStack(spacing: 8) {
                    TextField(selectedClueType.placeholder, text: $clueInputText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(.white)
                        .padding(11)
                        .background(TuesdayTheme.background)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .accessibilityIdentifier("wizard_clue_input_field")

                    Button {
                        Task {
                            await applyClueAndReanalyze()
                        }
                    } label: {
                        Text("Refine")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 11)
                            .background(TuesdayTheme.hacsCyan)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .disabled(isAnalyzingPhoto)
                    .accessibilityIdentifier("wizard_refine_clue_button")
                }
            }
        }
        .padding(16)
        .background(TuesdayTheme.cardSurface)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(TuesdayTheme.hacsCyan.opacity(0.35), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func candidateMatchesSection(result: GeminiDiscoveryTurnResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CANDIDATE DEVICE MATCHES (\(result.candidates.count))")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color(white: 0.65))
                .tracking(0.8)

            ForEach(Array(result.candidates.enumerated()), id: \.offset) { index, candidate in
                let badgeColor: Color = candidate.confidencePercent >= 80
                    ? TuesdayTheme.healthyGreen
                    : (candidate.confidencePercent >= 50 ? TuesdayTheme.warningAmber : TuesdayTheme.hacsCyan)

                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(candidate.displayName)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(.white)
                            Text("\(candidate.manufacturer) • Model \(candidate.modelNumber) • \(candidate.deviceCategory)")
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundStyle(TuesdayTheme.hacsCyan)
                        }
                        Spacer()
                        Text("\(candidate.confidencePercent)% MATCH")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(badgeColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(badgeColor.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }

                    Text(candidate.reasoning)
                        .font(.system(size: 12))
                        .foregroundStyle(Color(white: 0.72))

                    Button {
                        Task {
                            await enrollCandidate(candidate, state: .verified)
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 13, weight: .bold))
                            Text("Confirm Match & Add to Inventory")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(TuesdayTheme.healthyGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .disabled(isSaving)
                    .accessibilityIdentifier("confirm_candidate_button_\(index)")
                }
                .padding(14)
                .background(TuesdayTheme.cardSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(index == 0 ? badgeColor.opacity(0.45) : Color.white.opacity(0.10), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func incompleteOrGuessedFallbackCard(result: GeminiDiscoveryTurnResult) -> some View {
        let bestGuess = result.candidates.first
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "questionmark.diamond.fill")
                    .foregroundStyle(TuesdayTheme.warningAmber)
                Text("Not Sure or Label Unreadable?")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
            }

            Text("You can stop narrowing at any time and add this device to your Tuesday.sh inventory as an Incomplete / Best-Guess entry to finish auditing later.")
                .font(.system(size: 12))
                .foregroundStyle(Color(white: 0.68))

            Button {
                Task {
                    if let bestGuess {
                        await enrollCandidate(bestGuess, state: .incompleteOrGuessed)
                    } else {
                        await enrollIncompleteFallback()
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "tray.and.arrow.down.fill")
                        .font(.system(size: 13, weight: .bold))
                    Text("Add as Incomplete / Best-Guess Device")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundStyle(TuesdayTheme.warningAmber)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(TuesdayTheme.warningAmber.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(TuesdayTheme.warningAmber.opacity(0.5), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .disabled(isSaving)
            .accessibilityIdentifier("wizard_add_incomplete_button")
        }
        .padding(14)
        .background(TuesdayTheme.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func handleCapturedPhoto(_ image: UIImage) {
        capturedImages.append(image)
        Task {
            await runGeminiDiscovery()
        }
    }

    private func applyClueAndReanalyze() async {
        let trimmed = clueInputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        switch selectedClueType {
        case .barcode:
            accumulatedIdentifiers.barcode = trimmed
        case .serialNumber:
            accumulatedIdentifiers.serialNumber = trimmed
        case .qrCode:
            accumulatedIdentifiers.qrCode = trimmed
        case .modelNumber:
            accumulatedIdentifiers.modelNumber = trimmed
        case .macAddress:
            accumulatedIdentifiers.macAddress = trimmed
        }
        userClueNotes.append("\(selectedClueType.rawValue)=\(trimmed)")
        clueInputText = ""
        await runGeminiDiscovery()
    }

    private func runGeminiDiscovery() async {
        isAnalyzingPhoto = true
        let result = await GeminiDeviceDiscoveryService.shared.analyzeDeviceProgressive(
            images: capturedImages,
            accumulatedIdentifiers: accumulatedIdentifiers,
            userClueNotes: userClueNotes,
            apiKeyOverride: repository.hacsConfig.geminiApiKey,
            modelName: repository.hacsConfig.geminiModel
        )
        accumulatedIdentifiers.merge(result.extractedIdentifiers)
        discoveryResult = result
        isAnalyzingPhoto = false
    }

    private func enrollCandidate(_ candidate: DeviceCandidateMatch, state: InventoryConfidenceState) async {
        isSaving = true
        let resolvedModel = accumulatedIdentifiers.modelNumber ?? candidate.modelNumber
        let metadata = DiscoveredDeviceMetadata(
            manufacturer: candidate.manufacturer,
            modelNumber: resolvedModel,
            deviceCategory: candidate.deviceCategory,
            serialNumber: accumulatedIdentifiers.serialNumber,
            macAddress: accumulatedIdentifiers.macAddress,
            barcodeOrQr: accumulatedIdentifiers.barcode ?? accumulatedIdentifiers.qrCode,
            confidenceScore: candidate.confidencePercent,
            discoveryNotes: state == .incompleteOrGuessed
                ? "Added via AI Photo Wizard as Incomplete/Guessed (\(candidate.confidencePercent)% confidence)"
                : "Verified via Tuesday Hosted AI Proxy (\(candidate.confidencePercent)% confidence)"
        )
        _ = await GeminiDeviceDiscoveryService.shared.confirmDeviceDiscovery(
            inferredVendor: candidate.manufacturer,
            inferredModel: candidate.modelNumber,
            confirmedVendor: candidate.manufacturer,
            confirmedModel: resolvedModel,
            wasEdited: (resolvedModel != candidate.modelNumber) || (state == .incompleteOrGuessed),
            accumulatedIdentifiers: accumulatedIdentifiers
        )
        let hostTitle = state == .incompleteOrGuessed
            ? "\(candidate.suggestedHostname) (guessed)"
            : candidate.suggestedHostname
        await repository.enrollNode(
            hostname: hostTitle,
            osDetails: "\(candidate.displayName) • \(candidate.suggestedOsDetails)",
            packageManager: candidate.resolvedPackageManager,
            agentToken: "tuesday_ai_inventory_\(Int.random(in: 1000...9999))",
            inventoryState: state,
            discoveredMetadata: metadata
        )
        isSaving = false
        dismiss()
    }

    private func enrollIncompleteFallback() async {
        isSaving = true
        let metadata = DiscoveredDeviceMetadata(
            manufacturer: "Unknown Vendor",
            modelNumber: accumulatedIdentifiers.modelNumber ?? "Unidentified Hardware",
            deviceCategory: "Network / IoT Device",
            serialNumber: accumulatedIdentifiers.serialNumber,
            macAddress: accumulatedIdentifiers.macAddress,
            barcodeOrQr: accumulatedIdentifiers.barcode ?? accumulatedIdentifiers.qrCode,
            confidenceScore: 35,
            discoveryNotes: "Added incomplete from photo capture"
        )
        await repository.enrollNode(
            hostname: "unidentified-device.local",
            osDetails: "Unverified Hardware Photo (Pending Audit)",
            packageManager: .firmware,
            agentToken: "tuesday_ai_incomplete",
            inventoryState: .incompleteOrGuessed,
            discoveredMetadata: metadata
        )
        isSaving = false
        dismiss()
    }

    // MARK: - Manual / Agent Enrollment Content

    private var manualEnrollmentContent: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Enroll Tuesday.sh Agent Device")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                Text("Enter the device metadata manually or scan a Tuesday.sh / Home Assistant HACS enrollment QR sticker.")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(white: 0.65))
                    .lineSpacing(3)
            }

            if let validationMessage {
                Text(validationMessage)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(TuesdayTheme.criticalRed)
                    .accessibilityIdentifier("add_node_error_label")
            }

            inputGroup(
                label: "DEVICE HOSTNAME / ALIAS",
                placeholder: "e.g. unifi-gateway, pve-node1, surface95",
                text: $hostname,
                identifier: "add_node_hostname_field"
            )

            inputGroup(
                label: "OS / PLATFORM DETAILS",
                placeholder: "e.g. Debian 12 Bookworm (aarch64)",
                text: $osDetails,
                identifier: "add_node_os_field"
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("PACKAGE MANAGER")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color(white: 0.65))
                    .tracking(0.5)

                Picker("Package Manager", selection: $packageManager) {
                    ForEach(PackageManagerType.allCases) { mgr in
                        Text(mgr.displayName).tag(mgr)
                    }
                }
                .pickerStyle(.menu)
                .tint(TuesdayTheme.healthyGreen)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(TuesdayTheme.cardSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .accessibilityIdentifier("add_node_pkgmgr_picker")
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("AGENT TOKEN / HACS WEBHOOK ID")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color(white: 0.65))
                    .tracking(0.5)

                HStack(spacing: 12) {
                    TextField("e.g. tuesday_node_tok_77a1", text: $agentToken)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundStyle(.white)
                        .padding(14)
                        .background(TuesdayTheme.cardSurface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .accessibilityIdentifier("add_node_token_field")

                    Button {
                        showScannerSheet = true
                    } label: {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(TuesdayTheme.healthyGreen)
                            .frame(width: 50, height: 50)
                            .background(TuesdayTheme.cardSurface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .accessibilityIdentifier("add_node_qr_button")
                }
            }

            Spacer(minLength: 16)

            Button {
                Task {
                    await submitNode()
                }
            } label: {
                HStack {
                    if isSaving {
                        ProgressView()
                            .tint(.black)
                    } else {
                        Text("Save & Register in HACS")
                            .font(.system(size: 16, weight: .bold))
                    }
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(TuesdayTheme.healthyGreen)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(isSaving)
            .accessibilityIdentifier("add_node_submit_button")
        }
    }

    private func inputGroup(
        label: String,
        placeholder: String,
        text: Binding<String>,
        identifier: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color(white: 0.65))
                .tracking(0.5)

            TextField(placeholder, text: text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.system(size: 14))
                .foregroundStyle(.white)
                .padding(14)
                .background(TuesdayTheme.cardSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .accessibilityIdentifier(identifier)
        }
    }

    private var qrScannerModal: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 24) {
                HStack {
                    Text("Scan Tuesday.sh Agent QR")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                    Spacer()
                    Button {
                        showScannerSheet = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Color(white: 0.7))
                    }
                    .accessibilityIdentifier("qr_scanner_close_button")
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(TuesdayTheme.cardSurface)
                        .frame(height: 260)

                    RoundedRectangle(cornerRadius: 12)
                        .stroke(TuesdayTheme.healthyGreen, lineWidth: 2)
                        .frame(width: 220, height: 150)

                    VStack(spacing: 10) {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 48))
                            .foregroundStyle(TuesdayTheme.healthyGreen)
                        Text("Align Tuesday.sh Agent or HACS QR Code")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(white: 0.7))
                    }
                }
                .padding(.horizontal, 20)

                Button {
                    hostname = "unifi-gateway.local"
                    osDetails = "UniFi OS 4.0.20 (Debian apt)"
                    packageManager = .apt
                    agentToken = "tuesday_tok_unifi_8821"
                    showScannerSheet = false
                } label: {
                    Text("Simulate Scanned Node (unifi-gateway.local)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(TuesdayTheme.healthyGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(.horizontal, 20)
                .accessibilityIdentifier("simulate_qr_scan_button")

                Spacer()
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func submitNode() async {
        let trimmedHost = hostname.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedOs = osDetails.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedToken = agentToken.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedHost.isEmpty else {
            validationMessage = "Hostname is required."
            return
        }

        validationMessage = nil
        isSaving = true
        await repository.enrollNode(
            hostname: trimmedHost,
            osDetails: trimmedOs.isEmpty ? "Linux (\(packageManager.rawValue))" : trimmedOs,
            packageManager: packageManager,
            agentToken: trimmedToken.isEmpty ? "tuesday_tok_auto" : trimmedToken
        )
        isSaving = false
        dismiss()
    }
}
