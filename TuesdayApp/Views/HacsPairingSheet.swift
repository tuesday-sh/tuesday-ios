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

public struct HacsPairingSheet: View {
    @ObservedObject public var repository: MockHacsTuesdayService
    public let palette: BrandPalette
    public var onOpenUpgrade: () -> Void = {}
    public let onDismiss: () -> Void

    @State private var baseUrl: String
    @State private var apiToken: String
    @State private var trustedSsid: String
    @State private var requireLocalWifi: Bool
    @State private var showingExporter = false
    @State private var showingImporter = false
    @State private var exportDocument = InventoryJsonDocument()
    @State private var backupStatusMessage: String? = nil

    public init(
        repository: MockHacsTuesdayService,
        palette: BrandPalette,
        onOpenUpgrade: @escaping () -> Void = {},
        onDismiss: @escaping () -> Void
    ) {
        self.repository = repository
        self.palette = palette
        self.onOpenUpgrade = onOpenUpgrade
        self.onDismiss = onDismiss
        _baseUrl = State(initialValue: repository.hacsConfig.baseUrl)
        _apiToken = State(initialValue: repository.hacsConfig.apiToken)
        _trustedSsid = State(initialValue: repository.hacsConfig.trustedSsid)
        _requireLocalWifi = State(initialValue: repository.hacsConfig.requireLocalWifi)
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    // Sovereign Local JSON Backup Card (Local-First Data Portability)
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("SOVEREIGN LOCAL BACKUP")
                                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                                .foregroundColor(palette.accentText)
                            Spacer()
                            MonospaceBadge(text: "ZERO-LOGIN JSON", color: TuesdayTheme.ledColor(for: .ok, isStn: palette.isStn))
                        }

                        Text("Export your entire device inventory, custom names, and audit history as portable plain-text JSON — no account or cloud lock-in required.")
                            .font(.system(size: 13))
                            .foregroundColor(palette.textMuted)
                            .lineSpacing(3)

                        HStack(spacing: 8) {
                            Button(action: {
                                if let data = repository.exportInventoryBackupJSON() {
                                    exportDocument = InventoryJsonDocument(data: data)
                                    showingExporter = true
                                }
                            }) {
                                Label("Export JSON", systemImage: "square.and.arrow.up")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, minHeight: 42)
                                    .background(palette.accent)
                                    .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
                            }
                            .buttonStyle(.plain)
                            .uiAction("exportBackupFile")

                            Button(action: { showingImporter = true }) {
                                Label("Import JSON", systemImage: "square.and.arrow.down")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(palette.textPrimary)
                                    .frame(maxWidth: .infinity, minHeight: 42)
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

                        if let msg = backupStatusMessage {
                            Text(msg)
                                .font(.system(size: 11.5, design: .monospaced))
                                .foregroundColor(palette.textPrimary)
                        }
                    }
                    .padding(12)
                    .background(palette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard))
                    .overlay(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard).stroke(palette.border, lineWidth: 1))

                    // Home Assistant HACS Pairing
                    SurfaceListContainer(palette: palette) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("HOME ASSISTANT (HACS)")
                                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                                .foregroundColor(palette.textMuted)
                                .uiSlot("hacs-bridge-header")

                            TuesdayTextField(text: $baseUrl, label: "Home Assistant URL", placeholder: "http://homeassistant.local:8123", palette: palette)
                            TuesdayTextField(text: $apiToken, label: "Long-Lived Access Token", placeholder: "Bearer token", palette: palette)
                            TuesdayTextField(text: $trustedSsid, label: "Trusted Local Wi-Fi SSID", placeholder: "Home-WiFi", palette: palette)

                            PreferenceToggleRow(
                                title: "Require Trusted Wi-Fi for Local Sync",
                                description: "Shows a guardrail overlay if syncing away from your trusted SSID.",
                                isOn: $requireLocalWifi,
                                palette: palette,
                                actionName: "toggleRequireLocalWifi"
                            )

                            Button(action: {
                                var updated = repository.hacsConfig
                                updated.baseUrl = baseUrl
                                updated.apiToken = apiToken
                                updated.trustedSsid = trustedSsid
                                updated.requireLocalWifi = requireLocalWifi
                                repository.updateHacsConfig(updated)
                                onDismiss()
                            }) {
                                Text("Save HACS Pairing")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, minHeight: 42)
                                    .background(palette.accent)
                                    .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
                            }
                            .buttonStyle(.plain)
                            .uiAction("saveHacsConfig")
                        }
                        .padding(12)
                    }

                    // Family Site Delegation
                    VStack(alignment: .leading, spacing: 10) {
                        Text("FAMILY SITE MANAGEMENT")
                            .font(.system(size: 11, weight: .heavy, design: .monospaced))
                            .foregroundColor(palette.textMuted)

                        Text("Share read-only Check-Up posture summaries or unlock Pro Tier 1 to coordinate patches for parents' homes.")
                            .font(.system(size: 12.5))
                            .foregroundColor(palette.textMuted)
                            .lineSpacing(3)

                        HStack(spacing: 8) {
                            Button(action: {
                                UIPasteboard.general.string = "tuesday://join-site?site=My%20Network"
                                backupStatusMessage = "✓ Copied local site invite link"
                            }) {
                                Text("Copy Site Invite")
                                    .font(.system(size: 12.5, weight: .bold))
                                    .foregroundColor(palette.textPrimary)
                                    .frame(maxWidth: .infinity, minHeight: 38)
                                    .background(palette.elevated)
                                    .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
                            }
                            .buttonStyle(.plain)
                            .uiAction("copyFamilySiteInvite")

                            Button(action: onOpenUpgrade) {
                                Text("Manage / Upgrade")
                                    .font(.system(size: 12.5, weight: .bold))
                                    .foregroundColor(palette.accentText)
                                    .frame(maxWidth: .infinity, minHeight: 38)
                                    .background(palette.accent.opacity(0.14))
                                    .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
                                    .uiAction("openFamilyTier1Upgrade")
                            }
                            .buttonStyle(.plain)
                            .uiAction("manageFamilySites")
                        }
                    }
                    .padding(12)
                    .background(palette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard))
                    .overlay(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard).stroke(palette.border, lineWidth: 1))
                    .uiSlot("family-site-management-panel")
                }
                .padding(14)
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
                    backupStatusMessage = "✓ Exported sovereign JSON backup"
                case .failure(let error):
                    backupStatusMessage = "⚠ Export failed: \(error.localizedDescription)"
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
                            backupStatusMessage = "✓ Restored \(count) device(s) from backup"
                        case .failure(let error):
                            backupStatusMessage = "⚠ Invalid backup JSON: \(error.localizedDescription)"
                        }
                    }
                case .failure(let error):
                    backupStatusMessage = "⚠ Import failed: \(error.localizedDescription)"
                }
            }
        }
        .uiComponent("HacsSettingsSheet")
    }
}
