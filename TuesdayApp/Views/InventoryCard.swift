import SwiftUI

/// Primary Home / Inventory canvas matching Android's cross-platform Design System hierarchy:
/// always-visible `InventoryCard` (header + C1–C8 faceplate strip + 16x8 LED grid + PNW overlay + 5-bar legend),
/// followed below by either the Day 0 `WelcomeCard` callout or populated filters & device rows.
public struct InventoryCardView: View {
    public let flavor: AppBrandFlavor
    public let palette: BrandPalette
    public let devices: [RackPortDevice]
    public let zoneFilter: TrustZone?
    public let portStateFilter: PortLifecycleState?
    public let includeOkDevices: Bool
    public let showStateFilterStrip: Bool
    public let showZoneFilterStrip: Bool
    public let onSelectZoneFilter: (TrustZone?) -> Void
    public let onTogglePortStateFilter: (PortLifecycleState?) -> Void
    public let onToggleIncludeOk: () -> Void
    public let onInspectDevice: (RackPortDevice) -> Void
    public let onAddDeviceWithClues: (String?) -> Void
    public let onSeedDemoFleet: () -> Void
    public let onOpenReferenceGuide: () -> Void

    @State private var expandedCategory: StnHardwareCategory? = nil
    @State private var stripWidth: CGFloat = 330

    public init(
        flavor: AppBrandFlavor,
        palette: BrandPalette,
        devices: [RackPortDevice],
        zoneFilter: TrustZone?,
        portStateFilter: PortLifecycleState?,
        includeOkDevices: Bool,
        showStateFilterStrip: Bool,
        showZoneFilterStrip: Bool,
        onSelectZoneFilter: @escaping (TrustZone?) -> Void,
        onTogglePortStateFilter: @escaping (PortLifecycleState?) -> Void,
        onToggleIncludeOk: @escaping () -> Void,
        onInspectDevice: @escaping (RackPortDevice) -> Void,
        onAddDeviceWithClues: @escaping (String?) -> Void,
        onSeedDemoFleet: @escaping () -> Void,
        onOpenReferenceGuide: @escaping () -> Void = {}
    ) {
        self.flavor = flavor
        self.palette = palette
        self.devices = devices
        self.zoneFilter = zoneFilter
        self.portStateFilter = portStateFilter
        self.includeOkDevices = includeOkDevices
        self.showStateFilterStrip = showStateFilterStrip
        self.showZoneFilterStrip = showZoneFilterStrip
        self.onSelectZoneFilter = onSelectZoneFilter
        self.onTogglePortStateFilter = onTogglePortStateFilter
        self.onToggleIncludeOk = onToggleIncludeOk
        self.onInspectDevice = onInspectDevice
        self.onAddDeviceWithClues = onAddDeviceWithClues
        self.onSeedDemoFleet = onSeedDemoFleet
        self.onOpenReferenceGuide = onOpenReferenceGuide
    }

    public var body: some View {
        let isStn = (flavor == .sureThingHome)
        let tier = InventoryScaleTier.forCount(devices.count)
        let ledSlots = BulletinsAndInventoryEngine.build128LedMatrix(devices: devices, zoneFilter: zoneFilter)
        let actionDevices = BulletinsAndInventoryEngine.filterActionFirstDevices(
            devices: devices,
            includeOk: includeOkDevices,
            zoneFilter: zoneFilter,
            portStateFilter: portStateFilter
        )

        VStack(alignment: .leading, spacing: 10) {
            // 1. Always-visible Inventory Card (including Day 0 empty state)
            VStack(alignment: .leading, spacing: 8) {
                inventoryHeaderRow()

                inventoryChassisCard(isStn: isStn, tier: tier, ledSlots: ledSlots)

                if !devices.isEmpty && showZoneFilterStrip {
                    zoneFilterStrip(isStn: isStn)
                }
            }
            .padding(10)
            .background(palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard))
            .overlay(
                RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard)
                    .stroke(palette.border, lineWidth: 1)
            )
            .uiComponent("InventoryCard", state: "tier=\(tier.rawValue);active=\(devices.count)")

            // 2. Day 0 Conditional Callout Card below InventoryCard
            if devices.isEmpty {
                welcomeDayZeroCard()
            } else {
                // 3. Tracked Hardware Profiles Strip (Forest Tier >= 8 devices on STN-Pro)
                if tier == .FOREST && !isStn {
                    trackedHardwareProfilesCard(isStn: isStn)
                }

                // 4. Lifecycle State Filter Strip
                if showStateFilterStrip {
                    stateFilterStrip(isStn: isStn)
                }

                // 5. Action-First Header + Show/Hide OK Toggle (Forest Tier)
                if tier.showFilterChips {
                    actionListHeader(isStn: isStn)
                }

                // 6. Device Rows
                let rowsToRender: [RackPortDevice] = tier.showFilterChips
                    ? actionDevices
                    : devices
                        .filter { zoneFilter == nil || $0.trustZone == zoneFilter }
                        .filter { portStateFilter == nil || $0.portState == portStateFilter }

                VStack(spacing: 8) {
                    ForEach(rowsToRender) { dev in
                        cleanDeviceRow(dev, isStn: isStn)
                    }
                }

                // 7. Secondary "+ Add Another Device" CTA (Pea & Garden tiers)
                if !tier.showFilterChips {
                    Button(action: { onAddDeviceWithClues(nil) }) {
                        Text("+ Add Another Device")
                            .font(.system(size: 12.5, weight: .bold))
                            .foregroundColor(palette.textPrimary)
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
                            .overlay(
                                RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl)
                                    .stroke(palette.borderStrong, lineWidth: 1)
                            )
                            .uiSlot("add-another-device-cta")
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                    .uiAction("openAddDevice")
                }
            }
        }
    }

    private func inventoryHeaderRow() -> some View {
        HStack {
            Text("Inventory")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(palette.textPrimary)
                .uiSlot("inventory-title")

            Spacer()

            HStack(spacing: 6) {
                Button(action: { onAddDeviceWithClues(nil) }) {
                    HStack(spacing: 5) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                        Text("+ Add Device")
                            .font(.system(size: 11.5, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .uiSlot("add-device-cta")
                    }
                    .padding(.horizontal, 10)
                    .frame(minHeight: 36)
                    .background(palette.accent)
                    .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
                }
                .buttonStyle(.plain)
                .uiAction("openAddDevice")

                ZStack {
                    HelpIconButton(
                        palette: palette,
                        accessibilityLabel: "Inventory Reference Guide",
                        onClick: onOpenReferenceGuide
                    )
                }
                .uiSlot("help-button")
            }
        }
        .uiSlot("inventory-header")
    }

    private func inventoryChassisCard(
        isStn: Bool,
        tier: InventoryScaleTier,
        ledSlots: [LedSlot]
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            categoryFaceplateStrip(isStn: isStn)

            if let cat = expandedCategory {
                categoryPopoverView(for: cat, isStn: isStn)
            }

            led128GridView(slots: ledSlots, tier: tier)

            ledLegendStrip(isStn: isStn)
        }
        .padding(8)
        .background(palette.chassisRecessed)
        .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
        .overlay(
            RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl)
                .stroke(palette.border, lineWidth: 1)
        )
    }

    private func categoryFaceplateStrip(isStn: Bool) -> some View {
        let colWidth = max(24, (stripWidth - 35) / 8.0)
        let iconSize = max(14, colWidth * 0.56)

        return HStack(spacing: 5) {
            ForEach(StnHardwareCategory.allCases) { cat in
                let count = devices.filter { $0.category == cat }.count
                let hasDevices = count > 0
                let worst = TimelineStatusEvaluator.worstCategoryState(category: cat, devices: devices)
                let stateColor = worst.map { TuesdayTheme.ledColor(for: $0, isStn: isStn) } ?? palette.textMuted
                let isExpanded = (expandedCategory == cat)

                let iconBoxBg = isExpanded ? palette.accent.opacity(0.22) : palette.elevated
                let iconBorder = isExpanded
                    ? palette.accent
                    : (hasDevices ? stateColor.opacity(0.53) : palette.borderStrong)
                let tickColor = hasDevices ? stateColor.opacity(0.53) : palette.borderStrong
                let tileBg = hasDevices ? stateColor : palette.border
                let tileTextColor: Color = {
                    if !hasDevices { return palette.textMuted }
                    if !isStn && (worst == .ok || worst == .eol) {
                        return Color(hex: "090D0A")
                    }
                    return .white
                }()

                Button(action: {
                    expandedCategory = (expandedCategory == cat) ? nil : cat
                }) {
                    VStack(spacing: 0) {
                        // Top 1:1 hardware silhouette tile
                        RoundedRectangle(cornerRadius: TuesdayDimens.radiusBadge)
                            .fill(iconBoxBg)
                            .aspectRatio(1, contentMode: .fit)
                            .overlay(
                                RoundedRectangle(cornerRadius: TuesdayDimens.radiusBadge)
                                    .stroke(iconBorder, lineWidth: isExpanded ? 1.5 : 1)
                            )
                            .overlay(
                                HardwareCategoryIcon(category: cat, tint: stateColor, size: iconSize)
                            )
                            .uiSlot("category-col")

                        // Vertical connector tick
                        Rectangle()
                            .fill(tickColor)
                            .frame(width: 1, height: 6)
                            .padding(.vertical, 2)

                        // Bottom 1:1 count tile
                        RoundedRectangle(cornerRadius: TuesdayDimens.radiusMicro)
                            .fill(tileBg)
                            .aspectRatio(1, contentMode: .fit)
                            .overlay(
                                Text("\(count)")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(tileTextColor)
                                    .lineLimit(1)
                            )
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .uiAction("inspectCategoryDevice")
            }
        }
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { stripWidth = $0 }
        .uiSlot("c1-c8-strip")
        .uiComponent("CategoryFaceplateStrip")
    }

    private func led128GridView(slots: [LedSlot], tier: InventoryScaleTier) -> some View {
        ZStack {
            VStack(spacing: 3) {
                ForEach(0..<8, id: \.self) { rowIdx in
                    HStack(spacing: 3) {
                        ForEach(0..<16, id: \.self) { colIdx in
                            let slotIdx = rowIdx * 16 + colIdx
                            let slot = slotIdx < slots.count ? slots[slotIdx] : LedSlot(portIndex: slotIdx + 1, state: .unassigned, device: nil)
                            let color = TuesdayTheme.ledColor(for: slot.state, isStn: palette.isStn)
                            let alpha: Double = {
                                if let activeFilter = portStateFilter {
                                    if slot.state == activeFilter { return 1.0 }
                                    if slot.state == .unassigned { return 0.30 }
                                    return 0.18
                                }
                                switch slot.state {
                                case .unassigned: return 0.55
                                case .ok: return 0.85
                                default: return 1.0
                                }
                            }()

                            if let dev = slot.device {
                                Button(action: { onInspectDevice(dev) }) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(color.opacity(alpha))
                                        .aspectRatio(1, contentMode: .fit)
                                }
                                .buttonStyle(.plain)
                                .uiAction("inspectDevice")
                            } else {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(color.opacity(alpha))
                                    .aspectRatio(1, contentMode: .fit)
                            }
                        }
                    }
                }
            }
            .uiSlot("led-grid-128")

            BotanicalGridOverlay(scaleTier: tier, deviceCount: devices.count, palette: palette)
        }
        .uiComponent("InventoryLedGrid")
    }

    private func ledLegendStrip(isStn: Bool) -> some View {
        let entries: [(PortLifecycleState, String)] = [
            (.ok, "OK"),
            (.cveKev, isStn ? "Alert" : "CVE/KEV"),
            (.eol, "EOL"),
            (.guessed, "Guessed"),
            (.update, "Update")
        ]

        return HStack(alignment: .top, spacing: 5) {
            ForEach(entries, id: \.0.id) { state, label in
                let isSelected = !devices.isEmpty && portStateFilter == state
                let isDimmed = devices.isEmpty || (portStateFilter != nil && !isSelected)
                let color = TuesdayTheme.ledColor(for: state, isStn: isStn)

                Button(action: {
                    if !devices.isEmpty {
                        onTogglePortStateFilter(isSelected ? nil : state)
                    }
                }) {
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(isDimmed ? color.opacity(0.25) : color)
                            .frame(maxWidth: .infinity)
                            .frame(height: isSelected ? 4.5 : 3.5)

                        Text(label)
                            .font(.system(size: 11, weight: isSelected ? .bold : .semibold, design: .monospaced))
                            .foregroundColor(
                                isSelected
                                ? palette.textPrimary
                                : (isDimmed ? palette.textMuted.opacity(0.45) : palette.textMuted)
                            )
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                    }
                    .padding(.vertical, 2)
                }
                .buttonStyle(.plain)
                .disabled(devices.isEmpty)
                .uiAction("toggleLegendStateFilter")
            }
        }
        .padding(.top, 2)
        .uiSlot("legend-row")
    }

    private func zoneFilterStrip(isStn: Bool) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 5) {
                SelectableFilterChip(
                    label: "All Zones",
                    selected: zoneFilter == nil,
                    palette: palette,
                    action: { onSelectZoneFilter(nil) }
                )
                .uiAction("filterZone")

                ForEach(TrustZone.allCases) { zone in
                    SelectableFilterChip(
                        label: isStn ? zone.stnLabel : "\(zone.code) \(zone.stnLabel)",
                        selected: zoneFilter == zone,
                        palette: palette,
                        tintColor: TuesdayTheme.zoneColor(for: zone, isStn: isStn),
                        action: { onSelectZoneFilter(zoneFilter == zone ? nil : zone) }
                    )
                    .uiAction("filterZone")
                }
            }
        }
        .uiSlot("zone-filter-strip")
    }

    private func stateFilterStrip(isStn: Bool) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 5) {
                SelectableFilterChip(
                    label: "All",
                    selected: portStateFilter == nil,
                    palette: palette,
                    action: { onTogglePortStateFilter(nil) }
                )
                .uiAction("filterPortState")

                ForEach([PortLifecycleState.cveKev, .eol, .guessed, .update, .ok]) { st in
                    SelectableFilterChip(
                        label: isStn ? st.stnLabel : st.proLabel,
                        selected: portStateFilter == st,
                        palette: palette,
                        tintColor: TuesdayTheme.ledColor(for: st, isStn: isStn),
                        action: { onTogglePortStateFilter(portStateFilter == st ? nil : st) }
                    )
                    .uiAction("filterPortState")
                }
            }
        }
        .uiSlot("state-filter-strip")
    }

    private func actionListHeader(isStn: Bool) -> some View {
        let title: String = {
            if let filter = portStateFilter {
                return "FILTERED: \((isStn ? filter.stnLabel : filter.proLabel).uppercased())"
            }
            return includeOkDevices ? "ALL NAMED DEVICES" : "NEEDS ATTENTION"
        }()

        return HStack {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(palette.textMuted)
                .uiSlot("action-list-header")

            Spacer()

            if portStateFilter == nil {
                Button(action: onToggleIncludeOk) {
                    Text(includeOkDevices ? "Hide OK Devices" : "Show OK Devices")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(palette.accentText)
                        .padding(.horizontal, 8)
                        .frame(minHeight: 28)
                        .background(palette.elevated)
                        .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusBadge))
                        .overlay(
                            RoundedRectangle(cornerRadius: TuesdayDimens.radiusBadge)
                                .stroke(palette.border, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .uiAction("toggleIncludeOk")
            }
        }
    }

    private func welcomeDayZeroCard() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text("💡 Best place to start: Your Router")
                    .font(.system(size: 13.5, weight: .bold))
                    .foregroundColor(palette.accentText)

                Text("Your router is the front door to your home network and the single highest-impact device to keep updated.")
                    .font(.system(size: 12.5))
                    .foregroundColor(palette.textPrimary.opacity(0.88))
                    .lineSpacing(3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .uiSlot("router-advisory-tip")

            Button(action: { onAddDeviceWithClues("Router / Gateway") }) {
                Text("Add Your Router (Recommended) →")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(palette.accent)
                    .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
                    .uiSlot("add-router-cta")
            }
            .buttonStyle(.plain)
            .uiAction("openAddDevice")

            Button(action: { onAddDeviceWithClues(nil) }) {
                Text("+ Add Any Device")
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundColor(palette.textPrimary)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
                    .overlay(
                        RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl)
                            .stroke(palette.borderStrong, lineWidth: 1)
                    )
                    .uiSlot("add-any-device-cta")
            }
            .buttonStyle(.plain)
            .uiAction("openAddDevice")

            Button(action: onSeedDemoFleet) {
                Text("Enable Demo Mode (add example devices)")
                    .font(.system(size: 12.5, weight: .bold))
                    .foregroundColor(palette.accentText)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .uiSlot("enable-demo-cta")
            }
            .buttonStyle(.plain)
            .uiAction("enableDemoMode")
        }
        .padding(14)
        .background(palette.accent.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard))
        .overlay(
            RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard)
                .stroke(palette.accent.opacity(0.35), lineWidth: 1)
        )
        .uiComponent("WelcomeCard", state: "visible=true;tier=day0")
    }

    private func categoryPopoverView(for category: StnHardwareCategory, isStn: Bool) -> some View {
        let idx = StnHardwareCategory.allCases.firstIndex(of: category) ?? 0
        let fraction = (Double(idx) + 0.5) / Double(StnHardwareCategory.allCases.count)
        let pointerFraction = TimelineStatusEvaluator.clampPopoverArrowFraction(
            anchorXInStripPx: fraction * stripWidth,
            stripWidthPx: max(stripWidth, 1)
        )
        let matching = devices.filter { $0.category == category }

        return VStack(alignment: .leading, spacing: 0) {
            GeometryReader { geo in
                Path { p in
                    let cx = max(14, min(geo.size.width - 14, geo.size.width * pointerFraction))
                    p.move(to: CGPoint(x: cx - 7, y: 7))
                    p.addLine(to: CGPoint(x: cx, y: 0))
                    p.addLine(to: CGPoint(x: cx + 7, y: 7))
                    p.closeSubpath()
                }
                .fill(palette.surface)
            }
            .frame(height: 7)

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("\(category.code) • \(category.displayLabel(isStn: isStn))")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(palette.textPrimary)
                        .uiSlot("category-popover-title")
                    Spacer()
                    Button(action: { expandedCategory = nil }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(palette.textMuted)
                            .frame(width: 28, height: 28)
                            .background(palette.elevated)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .uiSlot("category-popover-close")
                    .uiAction("closeCategoryPopover")
                }
                .uiSlot("category-popover-header")

                if matching.isEmpty {
                    Text("No devices assigned to this category yet.")
                        .font(.system(size: 12))
                        .foregroundColor(palette.textMuted)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(matching) { dev in
                                let tint = TuesdayTheme.ledColor(for: dev.portState, isStn: isStn)
                                Button(action: {
                                    expandedCategory = nil
                                    onInspectDevice(dev)
                                }) {
                                    VStack(spacing: 5) {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(tint.opacity(0.14))
                                            .frame(width: 52, height: 52)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(tint.opacity(0.55), lineWidth: 1.5)
                                            )
                                            .overlay(
                                                HardwareCategoryIcon(category: dev.category, tint: tint, size: 26)
                                            )
                                        Text(dev.shortLabel)
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(palette.textPrimary)
                                            .lineLimit(1)
                                            .frame(width: 64)
                                    }
                                }
                                .buttonStyle(.plain)
                                .uiAction("inspectPopoverDevice")
                            }
                        }
                    }
                    .uiSlot("category-popover-gallery")
                }

                Button(action: {
                    expandedCategory = nil
                    onAddDeviceWithClues(category.discoveryClueLabel)
                }) {
                    Text("+ Add \(category.shortLabel)")
                        .font(.system(size: 12.5, weight: .bold))
                        .foregroundColor(palette.accentText)
                        .frame(maxWidth: .infinity, minHeight: 36)
                        .background(palette.accent.opacity(0.14))
                        .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
                }
                .buttonStyle(.plain)
                .uiSlot("category-popover-add-cta")
                .uiAction("addCategoryDevice")
            }
            .padding(12)
            .background(palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusModalCard))
            .overlay(
                RoundedRectangle(cornerRadius: TuesdayDimens.radiusModalCard)
                    .stroke(palette.borderStrong, lineWidth: 1)
            )
        }
        .uiComponent("CategoryPopover")
    }

    private func trackedHardwareProfilesCard(isStn: Bool) -> some View {
        let featured = Array(BulletinsAndInventoryEngine.sortDevicesByRecentChanges(devices).prefix(6))
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Tracked Hardware Profiles")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(palette.textMuted)
                Spacer()
                Text("Recent changes")
                    .font(.system(size: 11))
                    .foregroundColor(palette.textMuted)
            }
            .uiSlot("tracked-profiles-header")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(featured.enumerated()), id: \.element.id) { idx, dev in
                        let tint = TuesdayTheme.ledColor(for: dev.portState, isStn: isStn)
                        let isSelected = (idx == 0)
                        Button(action: { onInspectDevice(dev) }) {
                            VStack(spacing: 4) {
                                RoundedRectangle(cornerRadius: 11)
                                    .fill(isSelected ? palette.accent.opacity(0.14) : palette.elevated)
                                    .frame(width: 42, height: 42)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 11)
                                            .stroke(isSelected ? palette.accent : tint.opacity(0.35), lineWidth: 1)
                                    )
                                    .overlay(
                                        HardwareCategoryIcon(category: dev.category, tint: tint, size: 19)
                                    )
                                    .uiSlot("tracked-profile-squircle")
                                Text(dev.shortLabel)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(palette.textPrimary)
                                    .lineLimit(1)
                                    .frame(width: 58)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .uiSlot("tracked-profiles-strip")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard))
        .overlay(
            RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard)
                .stroke(palette.border, lineWidth: 1)
        )
        .uiComponent("TrackedHardwareProfilesCard")
    }

    private func cleanDeviceRow(_ dev: RackPortDevice, isStn: Bool) -> some View {
        let stateColor = TuesdayTheme.ledColor(for: dev.portState, isStn: isStn)
        let topBulletin = BulletinsAndInventoryEngine.findTopBulletinForDevice(dev)
        let noticeCount = BulletinsAndInventoryEngine.countBulletinsForDevice(dev)
        let catLabel = isStn ? dev.category.stnLabel : dev.category.proLabel
        let detailBlurb: String = {
            if let b = topBulletin {
                return isStn ? b.stnTitle : b.proTitle
            }
            return "\(catLabel) • \(dev.roomLocation)"
        }()

        return Button(action: { onInspectDevice(dev) }) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: TuesdayDimens.radiusBadge)
                    .fill(stateColor.opacity(0.16))
                    .frame(width: 36, height: 36)
                    .overlay(
                        RoundedRectangle(cornerRadius: TuesdayDimens.radiusBadge)
                            .stroke(stateColor.opacity(0.5), lineWidth: 1)
                    )
                    .overlay(
                        HardwareCategoryIcon(category: dev.category, tint: stateColor, size: 20)
                    )
                    .uiSlot("device-row")

                VStack(alignment: .leading, spacing: 2) {
                    Text(dev.name)
                        .font(.system(size: 13.5, weight: .bold))
                        .foregroundColor(palette.textPrimary)
                        .lineLimit(1)

                    Text(detailBlurb)
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundColor(topBulletin != nil ? stateColor : palette.textMuted)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 6)

                if isStn {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(palette.textMuted)
                } else {
                    RiskMeterDots(state: dev.portState, palette: palette, noticeCount: noticeCount)
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(palette.surface)
            .overlay(alignment: .leading) {
                if isStn {
                    Rectangle()
                        .fill(stateColor)
                        .frame(width: 4)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard))
            .overlay(
                RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard)
                    .stroke(palette.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .uiAction("inspectDevice")
    }
}
