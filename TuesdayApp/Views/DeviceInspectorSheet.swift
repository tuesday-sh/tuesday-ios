import SwiftUI

public struct DeviceInspectorSheet: View {
    public let device: RackPortDevice
    public let flavor: AppBrandFlavor
    public let palette: BrandPalette
    public let onDismiss: () -> Void
    public let onEditDevice: (RackPortDevice) -> Void

    @Environment(\.openURL) private var openURL

    public init(
        device: RackPortDevice,
        flavor: AppBrandFlavor,
        palette: BrandPalette,
        onDismiss: @escaping () -> Void,
        onEditDevice: @escaping (RackPortDevice) -> Void
    ) {
        self.device = device
        self.flavor = flavor
        self.palette = palette
        self.onDismiss = onDismiss
        self.onEditDevice = onEditDevice
    }

    public var body: some View {
        let isStn = (flavor == .sureThingHome)
        let stateColor = TuesdayTheme.ledColor(for: device.portState, isStn: isStn)
        let matchingBulletins = BulletinsAndInventoryEngine.findBulletinsForDevice(device)

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    // Header Identity
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: TuesdayDimens.radiusModalCard)
                            .fill(stateColor.opacity(0.16))
                            .frame(width: 48, height: 48)
                            .overlay(
                                HardwareCategoryIcon(category: device.category, tint: stateColor, size: 26)
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(device.name)
                                .font(.system(size: 18, weight: .heavy))
                                .foregroundColor(palette.textPrimary)
                            HStack(spacing: 6) {
                                MonospaceBadge(
                                    text: (isStn ? device.portState.stnLabel : device.portState.badgeLabel).uppercased(),
                                    color: stateColor
                                )
                                Text("\(device.category.code) • \(device.category.displayLabel(isStn: isStn))")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(palette.textMuted)
                            }
                        }
                        Spacer()
                    }
                    .padding(14)
                    .background(palette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard))
                    .overlay(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard).stroke(palette.border, lineWidth: 1))
                    .uiSlot("inspector-header")

                    if isStn {
                        // Homeowner Plain-English Guidance ("What to Do Next")
                        VStack(alignment: .leading, spacing: 8) {
                            Text("WHAT TO DO NEXT")
                                .font(.system(size: 11.5, weight: .heavy, design: .monospaced))
                                .foregroundColor(palette.accentText)
                            Text(device.stnHeadline)
                                .font(.system(size: 15.5, weight: .bold))
                                .foregroundColor(palette.textPrimary)
                            Text(device.s6Remediation)
                                .font(.system(size: 14))
                                .foregroundColor(palette.textMuted)
                                .lineSpacing(4)
                                .uiSlot("remediation-cta")
                                .uiAction("markRemediationComplete")
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(palette.surface)
                        .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard))
                        .overlay(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard).stroke(stateColor.opacity(0.45), lineWidth: 1))
                    }

                    // Condensed Timeline Lifespan Card (shown across both Pro & Home)
                    VStack(alignment: .leading, spacing: 0) {
                        CondensedCandlestickCard(
                            candle: BulletinsAndInventoryEngine.toOperationalCandle(device),
                            palette: palette,
                            showHeader: true
                        )
                    }
                    .uiSlot("candlestick-chart")

                    // Active Bulletins Stack
                    if !matchingBulletins.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ACTIVE BULLETINS (\(matchingBulletins.count))")
                                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                                .foregroundColor(palette.textMuted)

                            ForEach(matchingBulletins) { b in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(isStn ? b.stnTitle : b.proTitle)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(palette.textPrimary)
                                    Text(isStn ? b.stnBody : b.proBody)
                                        .font(.system(size: 13))
                                        .foregroundColor(palette.textMuted)
                                        .lineSpacing(3)
                                    if let urlStr = b.sourceUrl, let url = URL(string: urlStr) {
                                        Button(action: { openURL(url) }) {
                                            Text("↗ View Advisory Source")
                                                .font(.system(size: 11.5, weight: .bold, design: .monospaced))
                                                .foregroundColor(palette.accentText)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(palette.surface)
                                .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard))
                                .overlay(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard).stroke(stateColor.opacity(0.35), lineWidth: 1))
                            }
                        }
                        .uiSlot("device-active-bulletins-stack")
                    }

                    // Device Details (S0 -> S6 Scale)
                    SurfaceListContainer(palette: palette) {
                        detailRow(label: isStn ? "Room & Network" : "S0 • Location & Zone", value: device.roomLocation.isEmpty ? device.trustZone.displayTitle : "\(device.roomLocation) • \(isStn ? device.trustZone.stnTitle : device.trustZone.displayTitle)")
                        SurfaceListDivider(palette: palette)
                        detailRow(label: isStn ? "Firmware Version" : "S2 • Software / PURL", value: device.version.isEmpty ? (device.canonicalPurl ?? "Tracked") : "\(device.version) • \(device.canonicalPurl ?? "")")
                        SurfaceListDivider(palette: palette)
                        detailRow(label: isStn ? "Support Status" : "S3 • Support Runway", value: device.s3Lifecycle.isEmpty ? device.lifecycleTier : device.s3Lifecycle)
                        SurfaceListDivider(palette: palette)
                        detailRow(label: isStn ? "Advisories" : "S4 • Advisories", value: device.s4Advisories.isEmpty ? "No open CVEs" : device.s4Advisories)
                        if !isStn {
                            SurfaceListDivider(palette: palette)
                            detailRow(label: "S6 • Remediation", value: device.s6Remediation)
                        }
                    }
                    .uiSlot("device-details-stack")
                    .uiSlot("s0-s6-stack")
                }
                .padding(14)
            }
            .background(palette.bg.ignoresSafeArea())
            .navigationTitle(isStn ? "Device Details" : "Device Inspector")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done", action: onDismiss)
                        .foregroundColor(palette.accentText)
                        .uiAction("closeDeviceInspector")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Edit Device") {
                        onEditDevice(device)
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(palette.accentText)
                    .uiAction("editDevice")
                }
            }
        }
        .uiComponent("DeviceInspectorSheet", state: "device=\(device.id);state=\(device.portState.rawValue)")
    }

    private func detailRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(palette.textMuted)
            Text(value)
                .font(.system(size: 13.5, weight: .medium))
                .foregroundColor(palette.textPrimary)
                .lineSpacing(2)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}
