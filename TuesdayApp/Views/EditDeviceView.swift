import SwiftUI

public struct EditDeviceView: View {
    public let device: RackPortDevice
    public let palette: BrandPalette
    public let isStn: Bool
    public let onSave: (String, String /* shortLabel */, StnHardwareCategory, TrustZone, String, String, String?, String?) -> Void
    public let onDelete: (String) -> Void
    public let onCancel: () -> Void

    @State private var name: String
    @State private var shortLabel: String
    @State private var roomLocation: String
    @State private var category: StnHardwareCategory
    @State private var trustZone: TrustZone
    @State private var version: String
    @State private var serialNumber: String
    @State private var macAddress: String
    @State private var showDeleteConfirm: Bool = false

    public init(
        device: RackPortDevice,
        palette: BrandPalette,
        isStn: Bool,
        onSave: @escaping (String, String, StnHardwareCategory, TrustZone, String, String, String?, String?) -> Void,
        onDelete: @escaping (String) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.device = device
        self.palette = palette
        self.isStn = isStn
        self.onSave = onSave
        self.onDelete = onDelete
        self.onCancel = onCancel
        _name = State(initialValue: device.name)
        _shortLabel = State(initialValue: device.shortLabel)
        _roomLocation = State(initialValue: device.roomLocation)
        _category = State(initialValue: device.category)
        _trustZone = State(initialValue: device.trustZone)
        _version = State(initialValue: device.version)
        _serialNumber = State(initialValue: device.serialNumber ?? "")
        _macAddress = State(initialValue: device.macAddress ?? "")
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    SurfaceListContainer(palette: palette) {
                        VStack(alignment: .leading, spacing: 12) {
                            TuesdayTextField(text: $name, label: "Device Name", placeholder: "e.g. UniFi U7 Pro", palette: palette)
                                .uiSlot("edit-device-name")

                            TuesdayTextField(text: $shortLabel, label: "Short Faceplate Label", placeholder: "e.g. U7-Pro", palette: palette)
                                .uiSlot("edit-device-short-label")

                            TuesdayTextField(text: $roomLocation, label: "Room / Placement", placeholder: "e.g. Basement Closet", palette: palette)
                                .uiSlot("edit-device-room")

                            TuesdayTextField(text: $version, label: "Installed Software / Firmware", placeholder: "e.g. 7.0.66", palette: palette)
                        }
                        .padding(12)
                    }

                    SurfaceListContainer(palette: palette) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("HARDWARE CATEGORY (C1 → C8)")
                                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                                .foregroundColor(palette.textMuted)

                            Picker("Category", selection: $category) {
                                ForEach(StnHardwareCategory.allCases) { cat in
                                    Text("\(cat.code) • \(cat.displayLabel(isStn: isStn))").tag(cat)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(palette.accentText)

                            SurfaceListDivider(palette: palette)

                            Text(isStn ? "NETWORK LANE" : "TRUST ZONE (Z0 → Z4)")
                                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                                .foregroundColor(palette.textMuted)

                            Picker("Trust Zone", selection: $trustZone) {
                                ForEach(TrustZone.allCases) { zone in
                                    Text("\(isStn ? zone.stnTitle : zone.displayTitle) (\(zone.vlanHint))").tag(zone)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(palette.accentText)
                        }
                        .padding(12)
                    }

                    SurfaceListContainer(palette: palette) {
                        VStack(alignment: .leading, spacing: 12) {
                            TuesdayTextField(text: $serialNumber, label: "Serial Number (Optional)", placeholder: "e.g. SN-2409A88192", palette: palette)
                            TuesdayTextField(text: $macAddress, label: "MAC Address (Optional)", placeholder: "e.g. 74:83:C2:9E:11:04", palette: palette)
                        }
                        .padding(12)
                    }

                    Button(action: {
                        onSave(
                            name,
                            shortLabel,
                            category,
                            trustZone,
                            roomLocation,
                            version,
                            serialNumber.isEmpty ? nil : serialNumber,
                            macAddress.isEmpty ? nil : macAddress
                        )
                    }) {
                        Text("Save Device Changes")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(palette.accent)
                            .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard))
                    }
                    .buttonStyle(.plain)
                    .uiAction("saveDeviceEdit")

                    let dangerRed = TuesdayTheme.ledColor(for: .cveKev, isStn: isStn)
                    Button(action: { showDeleteConfirm = true }) {
                        Text("Delete Device")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(dangerRed)
                            .frame(maxWidth: .infinity, minHeight: 46)
                            .background(dangerRed.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard))
                            .overlay(
                                RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard)
                                    .stroke(dangerRed.opacity(0.45), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .uiAction("requestDeleteDevice")
                }
                .padding(14)
            }
            .background(palette.bg.ignoresSafeArea())
            .navigationTitle("Edit Device")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                        .foregroundColor(palette.accentText)
                        .uiAction("cancelDeviceEdit")
                }
            }
            .confirmationDialog(
                "Delete \(device.name)?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete Device", role: .destructive) {
                    onDelete(device.id)
                }
                .uiAction("confirmDeleteDevice")
                Button("Cancel", role: .cancel) {
                    showDeleteConfirm = false
                }
                .uiAction("cancelDeleteDevice")
            } message: {
                Text("This removes the device and its local audit history from this network site.")
            }
        }
        .uiComponent("EditDeviceScreen")
    }
}
