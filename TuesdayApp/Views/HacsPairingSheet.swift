import SwiftUI
import UniformTypeIdentifiers

public struct InventoryJsonDocument: FileDocument {
    public static var readableContentTypes: [UTType] { [.json] }
    public var data: Data

    public init(data: Data = Data()) {
        self.data = data
    }

    public init(configuration: ReadConfiguration) throws {
        self.data = configuration.file.regularFileContents ?? Data()
    }

    public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

public struct DossierExportDocument: FileDocument {
    public static var readableContentTypes: [UTType] { [.pdf, .commaSeparatedText, .plainText] }
    public var data: Data

    public init(data: Data = Data()) {
        self.data = data
    }

    public init(configuration: ReadConfiguration) throws {
        self.data = configuration.file.regularFileContents ?? Data()
    }

    public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

public struct HacsPairingSheet: View {
    @ObservedObject public var repository: MockHacsTuesdayService
    public let palette: BrandPalette
    public var onOpenUpgrade: () -> Void = {}
    public var onOpenNetworkPicker: () -> Void = {}
    public let onDismiss: () -> Void

    @State private var showingExporter = false
    @State private var showingImporter = false
    @State private var exportDocument = InventoryJsonDocument()
    @State private var showingDossierExporter = false
    @State private var dossierDocument = DossierExportDocument()
    @State private var dossierContentType: UTType = .pdf
    @State private var dossierDefaultFilename: String = "tuesday_dossier.pdf"
    @State private var backupStatusMessage: String? = nil
    @State private var isSuccessStatus: Bool = true
    @State private var familyInviteFeedback: String? = nil

    public init(
        repository: MockHacsTuesdayService,
        palette: BrandPalette,
        onOpenUpgrade: @escaping () -> Void = {},
        onOpenNetworkPicker: @escaping () -> Void = {},
        onDismiss: @escaping () -> Void
    ) {
        self.repository = repository
        self.palette = palette
        self.onOpenUpgrade = onOpenUpgrade
        self.onOpenNetworkPicker = onOpenNetworkPicker
        self.onDismiss = onDismiss
    }

    public var body: some View {
        let isProTier1 = EntitlementGatePolicy.isProTier1Entitled(repository.entitlementTier)
        let okGreen = TuesdayTheme.ledColor(for: .ok, isStn: palette.isStn)
        let activeNetworkName = repository.userNetworks.first(where: { $0.id == repository.activeNetworkId })?.name ?? "My Network"

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // HACS Bridge Header
                    HStack(spacing: 12) {
                        Circle()
                            .fill(palette.accent.opacity(0.15))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: "house.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(palette.accent)
                            )
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Home Assistant Integration")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(palette.textPrimary)
                            Text("Tuesday.sh Bridge")
                                .font(.system(size: 12))
                                .foregroundColor(palette.accentText)
                        }
                        Spacer()
                    }
                    .padding(16)
                    .background(palette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusModalCard))
                    .overlay(
                        RoundedRectangle(cornerRadius: TuesdayDimens.radiusModalCard)
                            .stroke(palette.border, lineWidth: 1)
                    )
                    .uiSlot("hacs-bridge-header")

                    // Portable Local Backup Info
                    VStack(spacing: 6) {
                        Text("Portable JSON Inventory")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(palette.textPrimary)
                            .multilineTextAlignment(.center)
                        Text("Your network inventory is stored locally on this device. Export or restore a standard JSON backup below at any time.")
                            .font(.system(size: 12))
                            .foregroundColor(palette.textMuted)
                            .lineSpacing(3)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 22)
                    .padding(.horizontal, 18)
                    .frame(maxWidth: .infinity)
                    .background(palette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusModalCard))
                    .overlay(
                        RoundedRectangle(cornerRadius: TuesdayDimens.radiusModalCard)
                            .stroke(palette.border, lineWidth: 1)
                    )
                    .uiSlot("hacs-coming-soon-notice")

                    // Local Network Backup & Restore + Clipboard Copy
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "externaldrive.badge.checkmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(okGreen)
                            Text("Local Network Backup & Restore")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(palette.textPrimary)
                        }

                        Text("Save your full network inventory, device aliases, port allocations, and settings off-device (iCloud Drive, Files, local storage) without creating an account.")
                            .font(.system(size: 12))
                            .foregroundColor(palette.textMuted)
                            .lineSpacing(3)

                        HStack(spacing: 8) {
                            Button(action: {
                                if let data = repository.exportInventoryBackupJSON() {
                                    exportDocument = InventoryJsonDocument(data: data)
                                    showingExporter = true
                                }
                            }) {
                                Label("Export JSON", systemImage: "square.and.arrow.down")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(palette.textPrimary)
                                    .frame(maxWidth: .infinity, minHeight: 40)
                                    .background(palette.elevated)
                                    .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl)
                                            .stroke(palette.borderStrong, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                            .uiAction("exportBackupFile")

                            Button(action: { showingImporter = true }) {
                                Label("Import JSON", systemImage: "square.and.arrow.up")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(palette.textPrimary)
                                    .frame(maxWidth: .infinity, minHeight: 40)
                                    .background(palette.elevated)
                                    .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl)
                                            .stroke(palette.borderStrong, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                            .uiAction("importBackupFile")
                        }

                        Button(action: {
                            if let data = repository.exportInventoryBackupJSON(),
                               let jsonText = String(data: data, encoding: .utf8) {
                                UIPasteboard.general.string = jsonText
                                backupStatusMessage = "Copied JSON payload to clipboard"
                                isSuccessStatus = true
                            }
                        }) {
                            HStack {
                                Text("Copy Backup to Clipboard")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(palette.textPrimary)
                                Spacer()
                                Text("COPY")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(palette.accentText)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .frame(minHeight: TuesdayDimens.hitTargetCompact)
                            .background(palette.bg)
                            .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusBadge))
                            .overlay(
                                RoundedRectangle(cornerRadius: TuesdayDimens.radiusBadge)
                                    .stroke(palette.border, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .uiAction("copyBackupToClipboard")

                        if let msg = backupStatusMessage {
                            Text(msg)
                                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                .foregroundColor(isSuccessStatus ? okGreen : TuesdayTheme.ledColor(for: .cveKev, isStn: palette.isStn))
                        }

                        Divider().overlay(palette.border.opacity(0.6))

                        HStack {
                            Text("Home & Rack Dossier Exports")
                                .font(.system(size: 12.5, weight: .bold))
                                .foregroundColor(palette.textPrimary)
                            Spacer()
                            MonospaceBadge(
                                text: isProTier1 ? "PRO • UNLOCKED" : "PRO TIER 1",
                                color: isProTier1 ? okGreen : palette.accentText
                            )
                        }

                        Text("Export a printable insurance/disaster-recovery PDF, spreadsheet CSV, or Markdown rack spec sheet.")
                            .font(.system(size: 11.5))
                            .foregroundColor(palette.textMuted)
                            .lineSpacing(2)

                        let safeSlug = activeNetworkName.lowercased()
                            .components(separatedBy: CharacterSet.alphanumerics.inverted)
                            .filter { !$0.isEmpty }
                            .joined(separator: "_")
                        let slugPrefix = safeSlug.isEmpty ? "network" : safeSlug

                        HStack(spacing: 6) {
                            Button(action: {
                                if isProTier1 {
                                    dossierDocument = DossierExportDocument(
                                        data: RackDossierExporter.renderPdfData(siteName: activeNetworkName, devices: repository.visibleRackDevices)
                                    )
                                    dossierContentType = .pdf
                                    dossierDefaultFilename = "tuesday_dossier_\(slugPrefix).pdf"
                                    showingDossierExporter = true
                                } else {
                                    onDismiss()
                                    onOpenUpgrade()
                                }
                            }) {
                                Text(isProTier1 ? "PDF" : "⚡ PDF")
                                    .font(.system(size: 11.5, weight: .bold))
                                    .foregroundColor(palette.textPrimary)
                                    .frame(maxWidth: .infinity, minHeight: 34)
                                    .background(palette.elevated)
                                    .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
                                    .overlay(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl).stroke(palette.borderStrong, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                            .uiAction("exportDossierPdf")

                            Button(action: {
                                if isProTier1 {
                                    let csv = RackDossierExporter.formatCsv(siteName: activeNetworkName, devices: repository.visibleRackDevices)
                                    dossierDocument = DossierExportDocument(data: Data(csv.utf8))
                                    dossierContentType = .commaSeparatedText
                                    dossierDefaultFilename = "tuesday_dossier_\(slugPrefix).csv"
                                    showingDossierExporter = true
                                } else {
                                    onDismiss()
                                    onOpenUpgrade()
                                }
                            }) {
                                Text(isProTier1 ? "CSV" : "⚡ CSV")
                                    .font(.system(size: 11.5, weight: .bold))
                                    .foregroundColor(palette.textPrimary)
                                    .frame(maxWidth: .infinity, minHeight: 34)
                                    .background(palette.elevated)
                                    .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
                                    .overlay(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl).stroke(palette.borderStrong, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                            .uiAction("exportDossierCsv")

                            Button(action: {
                                if isProTier1 {
                                    let md = RackDossierExporter.formatMarkdown(siteName: activeNetworkName, devices: repository.visibleRackDevices)
                                    dossierDocument = DossierExportDocument(data: Data(md.utf8))
                                    dossierContentType = .plainText
                                    dossierDefaultFilename = "tuesday_dossier_\(slugPrefix).md"
                                    showingDossierExporter = true
                                } else {
                                    onDismiss()
                                    onOpenUpgrade()
                                }
                            }) {
                                Text(isProTier1 ? "Markdown" : "⚡ MD")
                                    .font(.system(size: 11.5, weight: .bold))
                                    .foregroundColor(palette.textPrimary)
                                    .frame(maxWidth: .infinity, minHeight: 34)
                                    .background(palette.elevated)
                                    .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
                                    .overlay(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl).stroke(palette.borderStrong, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                            .uiAction("exportDossierMarkdown")
                        }
                    }
                    .padding(16)
                    .background(palette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusModalCard))
                    .overlay(
                        RoundedRectangle(cornerRadius: TuesdayDimens.radiusModalCard)
                            .stroke(palette.border, lineWidth: 1)
                    )
                    .uiSlot("local-backup-panel")

                    // Multi-Site & 128-Device Capacity
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "person.2.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(isProTier1 ? okGreen : palette.accent)
                                Text("Multi-Site & 128-Device Capacity")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(palette.textPrimary)
                            }
                            Spacer()
                            MonospaceBadge(
                                text: isProTier1 ? "PRO TIER 1 • ACTIVE" : "PRO TIER 1",
                                color: isProTier1 ? okGreen : palette.accentText
                            )
                        }

                        Text(
                            isProTier1
                                ? "Included with your Pro Tier 1 entitlement. Track up to 128 devices per site and manage unlimited household, cabin, or homelab locations alongside '\(activeNetworkName.isEmpty ? "My Network" : activeNetworkName)'."
                                : "Free accounts include 1 primary network and up to 15 devices. Upgrade to Pro Tier 1 to unlock up to 128 devices per site and unlimited network locations."
                        )
                        .font(.system(size: 12))
                        .foregroundColor(palette.textMuted)
                        .lineSpacing(3)

                        if isProTier1 {
                            Button(action: {
                                onDismiss()
                                onOpenNetworkPicker()
                            }) {
                                Text("Manage Sites")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, minHeight: 38)
                                    .background(palette.accent)
                                    .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
                            }
                            .buttonStyle(.plain)
                            .uiAction("manageFamilySites")
                        } else {
                            Button(action: {
                                onDismiss()
                                onOpenUpgrade()
                            }) {
                                Text("⚡ Unlock with Pro Tier 1")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, minHeight: 40)
                                    .background(palette.accent)
                                    .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
                            }
                            .buttonStyle(.plain)
                            .uiAction("openFamilyTier1Upgrade")
                        }
                    }
                    .padding(16)
                    .background(palette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusModalCard))
                    .overlay(
                        RoundedRectangle(cornerRadius: TuesdayDimens.radiusModalCard)
                            .stroke((isProTier1 ? okGreen : palette.accent).opacity(0.45), lineWidth: 1)
                    )
                    .uiSlot("family-site-management-panel")

                    Button(action: onDismiss) {
                        Text("Done")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(palette.accentText)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(palette.accent.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
                    }
                    .buttonStyle(.plain)
                    .uiAction("saveHacsConfig")
                }
                .padding(16)
            }
            .background(palette.bg.ignoresSafeArea())
            .navigationTitle("Integrations & Backup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done", action: onDismiss)
                        .foregroundColor(palette.accentText)
                }
            }
            .fileExporter(
                isPresented: $showingExporter,
                document: exportDocument,
                contentType: .json,
                defaultFilename: "tuesday-inventory-backup.json"
            ) { result in
                switch result {
                case .success:
                    backupStatusMessage = "Backup exported successfully!"
                    isSuccessStatus = true
                case .failure(let error):
                    backupStatusMessage = "Export failed: \(error.localizedDescription)"
                    isSuccessStatus = false
                }
            }
            .fileExporter(
                isPresented: $showingDossierExporter,
                document: dossierDocument,
                contentType: dossierContentType,
                defaultFilename: dossierDefaultFilename
            ) { result in
                switch result {
                case .success:
                    backupStatusMessage = "Dossier exported successfully!"
                    isSuccessStatus = true
                case .failure(let error):
                    backupStatusMessage = "Dossier export failed: \(error.localizedDescription)"
                    isSuccessStatus = false
                }
            }
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    let secured = url.startAccessingSecurityScopedResource()
                    defer { if secured { url.stopAccessingSecurityScopedResource() } }
                    if let data = try? Data(contentsOf: url) {
                        switch repository.importInventoryBackupJSON(data) {
                        case .success(let count):
                            backupStatusMessage = "Restored \(count) device(s) from backup!"
                            isSuccessStatus = true
                        case .failure(let error):
                            backupStatusMessage = "Invalid backup JSON: \(error.localizedDescription)"
                            isSuccessStatus = false
                        }
                    }
                case .failure(let error):
                    backupStatusMessage = "Import failed: \(error.localizedDescription)"
                    isSuccessStatus = false
                }
            }
        }
        .uiComponent("HacsSettingsSheet")
    }
}
