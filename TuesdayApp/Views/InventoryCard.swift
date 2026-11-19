import SwiftUI

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

    @State private var matrixPage: Int = 0
    @State private var expandedCategory: StnHardwareCategory? = nil
    @State private var popoverArrowX: Double = 0.5

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
        onSeedDemoFleet: @escaping () -> Void
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
        let okCount = devices.filter { $0.portState == .ok }.count

        VStack(alignment: .leading, spacing: 12) {
            if tier == .DAY_ZERO {
                welcomeDayZeroCard(isStn: isStn)
            } else {
                // Main Inventory Matrix & Category Faceplate Card
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(isStn ? "HOME NETWORK" : "NETWORK HARDWARE")
                            .font(.system(size: 11.5, weight: .heavy, design: .monospaced))
                            .foregroundColor(palette.textMuted)
                            .uiSlot("inventory-title")
                        Spacer()
                        MonospaceBadge(
                            text: "\(tier.badgeText) • \(devices.count)",
                            color: palette.accentText
                        )
                    }
                    .uiSlot("inventory-header")

                    if tier.showPortDiagramStrip {
                        TabView(selection: $matrixPage) {
                            categoryFaceplateStrip(isStn: isStn)
                                .tag(0)

                            led128GridView(slots: ledSlots, tier: tier)
                                .tag(1)
                        }
                        .tabViewStyle(.page(indexDisplayMode: .automatic))
                        .frame(height: 126)

                        if let cat = expandedCategory {
                            categoryPopoverView(for: cat, isStn: isStn)
                        }
                    }

                    if showZoneFilterStrip && tier.showTrustZonePills {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                SelectableFilterChip(
                                    label: isStn ? "All Areas" : "All Zones",
                                    selected: zoneFilter == nil,
                                    palette: palette,
                                    action: { onSelectZoneFilter(nil) }
                                )
                                .uiAction("filterZone")
                                ForEach(TrustZone.allCases) { zone in
                                    SelectableFilterChip(
                                        label: isStn ? zone.stnTitle : zone.displayTitle,
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

                    if showStateFilterStrip && tier.showFilterChips {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                SelectableFilterChip(
                                    label: "All",
                                    selected: portStateFilter == nil && includeOkDevices,
                                    palette: palette,
                                    action: {
                                        onTogglePortStateFilter(nil)
                                        if !includeOkDevices { onToggleIncludeOk() }
                                    }
                                )
                                .uiAction("filterPortState")

                                ForEach([PortLifecycleState.cveKev, .eol, .guessed, .update, .ok]) { st in
                                    SelectableFilterChip(
                                        label: isStn ? st.stnLabel : st.badgeLabel,
                                        selected: portStateFilter == st,
                                        palette: palette,
                                        tintColor: TuesdayTheme.ledColor(for: st, isStn: isStn),
                                        action: { onTogglePortStateFilter(portStateFilter == st ? nil : st) }
                                    )
                                    .uiAction("toggleLegendStateFilter")
                                }
                            }
                        }
                        .uiSlot("state-filter-strip")
                        .uiSlot("legend-row")
                    }

                    if tier == .FOREST {
                        trackedHardwareProfilesCard(isStn: isStn)
                    }
                }
                .padding(12)
                .background(palette.surface)
                .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard))
                .overlay(
                    RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard)
                        .stroke(palette.border, lineWidth: 1)
                )
                .uiComponent("InventoryCard", state: "tier=\(tier.rawValue);count=\(devices.count)")

                // Device Action List
                let listTitle: String = {
                    if let filter = portStateFilter {
                        return "FILTERED: \((isStn ? filter.stnLabel : filter.badgeLabel).uppercased()) (\(actionDevices.count))"
                    }
                    if !tier.showFilterChips {
                        return "YOUR DEVICES (\(devices.count))"
                    }
                    return includeOkDevices ? "ALL DEVICES (\(actionDevices.count))" : "NEEDS ATTENTION (\(actionDevices.count))"
                }()

                HStack {
                    Text(listTitle)
                        .font(.system(size: 11.5, weight: .heavy, design: .monospaced))
                        .foregroundColor(palette.textMuted)
                        .uiSlot("action-list-header")
                    Spacer()
                    if tier.showFilterChips && portStateFilter == nil && okCount > 0 {
                        Button(action: onToggleIncludeOk) {
                            Text(includeOkDevices ? "Hide OK" : "Show OK (+\(okCount))")
                                .font(.system(size: 11.5, weight: .bold))
                                .foregroundColor(palette.accentText)
                        }
                        .buttonStyle(.plain)
                        .uiAction("toggleIncludeOk")
                    }
                }

                let rowsToRender = tier.showFilterChips ? actionDevices : devices
                VStack(spacing: 8) {
                    ForEach(rowsToRender) { dev in
                        cleanDeviceRow(dev, isStn: isStn)
                    }
                }

                if tier == .PEA || tier == .GARDEN {
                    Button(action: { onAddDeviceWithClues(nil) }) {
                        Text("+ Add Another Device")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(palette.accentText)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(palette.accent.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard))
                            .overlay(
                                RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard)
                                    .stroke(palette.accent.opacity(0.45), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .uiSlot("add-another-device-cta")
                }
            }
        }
    }

    private func welcomeDayZeroCard(isStn: Bool) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                MonospaceBadge(text: "DAY 0 • EMPTY", color: palette.accentText)
                Spacer()
                Button(action: onSeedDemoFleet) {
                    Text("seed Forest fleet")
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundColor(palette.accentText)
                        .underline()
                        .uiAction("enableDemoMode")
                }
                .buttonStyle(.plain)
                .uiSlot("enable-demo-cta")
            }

            Text(isStn ? "Guard your home Wi-Fi & smart devices" : "Map your network hardware & firmware CVEs")
                .font(.system(size: 19, weight: .heavy))
                .foregroundColor(palette.textPrimary)

            Text(isStn
                 ? "Add your Wi-Fi router, smart TV, printer, or security camera. Tuesday checks manufacturer support cutoffs and Patch Tuesday bulletins locally on your iPhone."
                 : "Enroll your gateway, switches, APs, servers, or IoT bridges via offline Gold Catalog clues, barcode UPC, or camera label vision.")
                .font(.system(size: 15))
                .foregroundColor(palette.textMuted)
                .lineSpacing(4)
                .uiSlot("router-advisory-tip")

            HStack(spacing: 8) {
                Button(action: { onAddDeviceWithClues("Router / Gateway") }) {
                    Text("+ Add Wi-Fi Router")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(palette.accent)
                        .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
                }
                .buttonStyle(.plain)
                .uiSlot("add-router-cta")

                Button(action: { onAddDeviceWithClues(nil) }) {
                    Text("+ Add Any Device")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(palette.textPrimary)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(palette.elevated)
                        .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
                        .overlay(
                            RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl)
                                .stroke(palette.borderStrong, lineWidth: 1)
                        )
                        .uiSlot("add-device-cta")
                }
                .buttonStyle(.plain)
                .uiSlot("add-any-device-cta")
            }

            BotanicalGridOverlay(scaleTier: .DAY_ZERO, deviceCount: 0, palette: palette)
                .frame(height: 82)
                .background(palette.chassisRecessed)
                .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
                .overlay(
                    RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl)
                        .stroke(palette.border, lineWidth: 1)
                )
        }
        .padding(14)
        .background(palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard))
        .overlay(
            RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard)
                .stroke(palette.border, lineWidth: 1)
        )
        .uiComponent("WelcomeCard", state: "tier=DAY_ZERO;active=0")
    }

    private func categoryFaceplateStrip(isStn: Bool) -> some View {
        let tileBg = isStn ? TuesdayTheme.stnBgElevated : palette.elevated
        let borderIdle = palette.borderStrong
        return GeometryReader { geo in
            HStack(spacing: 5) {
                ForEach(Array(StnHardwareCategory.allCases.enumerated()), id: \.element.id) { idx, cat in
                    let count = devices.filter { $0.category == cat }.count
                    let worst = TimelineStatusEvaluator.worstCategoryState(category: cat, devices: devices)
                    let tint = worst.map { TuesdayTheme.ledColor(for: $0, isStn: isStn) } ?? palette.textMuted
                    let isExpanded = (expandedCategory == cat)

                    Button(action: {
                        if expandedCategory == cat {
                            expandedCategory = nil
                        } else {
                            let fraction = (Double(idx) + 0.5) / Double(StnHardwareCategory.allCases.count)
                            popoverArrowX = TimelineStatusEvaluator.clampPopoverArrowFraction(
                                anchorXInStripPx: fraction * geo.size.width,
                                stripWidthPx: geo.size.width
                            )
                            expandedCategory = cat
                        }
                    }) {
                        VStack(spacing: 4) {
                            HardwareCategoryIcon(category: cat, tint: count > 0 ? tint : palette.textMuted, size: 18)
                                .frame(height: 22)

                            Text(cat.code)
                                .font(.system(size: 10, weight: .heavy, design: .monospaced))
                                .foregroundColor(count > 0 ? tint : palette.textMuted)

                            Text("\(count)")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(count > 0 ? palette.textPrimary : palette.textMuted)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 3)
                                .background(count > 0 ? tint.opacity(0.16) : palette.bg)
                                .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusMicro))
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 3)
                        .frame(maxWidth: .infinity)
                        .background(isExpanded ? palette.accent.opacity(0.14) : tileBg)
                        .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
                        .overlay(
                            RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl)
                                .stroke(isExpanded ? palette.accent : (count > 0 ? tint.opacity(0.45) : borderIdle), lineWidth: isExpanded ? 1.5 : 1)
                        )
                        .uiSlot("category-col")
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(height: 82)
        .uiSlot("c1-c8-strip")
        .uiComponent("CategoryFaceplateStrip")
    }

    private func led128GridView(slots: [LedSlot], tier: InventoryScaleTier) -> some View {
        ZStack {
            BotanicalGridOverlay(scaleTier: tier, deviceCount: devices.count, palette: palette)
                .uiSlot("botanical-overlay")
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 16), spacing: 3) {
                ForEach(slots) { slot in
                    let color = TuesdayTheme.ledColor(for: slot.state, isStn: palette.isStn)
                    if let dev = slot.device {
                        Button(action: { onInspectDevice(dev) }) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(color)
                                .frame(height: 9)
                        }
                        .buttonStyle(.plain)
                    } else {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(color.opacity(0.65))
                            .frame(height: 9)
                    }
                }
            }
            .padding(6)
        }
        .background(palette.chassisRecessed)
        .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
        .overlay(
            RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl)
                .stroke(palette.border, lineWidth: 1)
        )
        .uiSlot("led-grid-128")
        .uiComponent("InventoryLedGrid")
    }

    private func categoryPopoverView(for category: StnHardwareCategory, isStn: Bool) -> some View {
        let matching = devices.filter { $0.category == category }
        return VStack(alignment: .leading, spacing: 10) {
            GeometryReader { geo in
                Path { p in
                    let cx = max(14, min(geo.size.width - 14, geo.size.width * popoverArrowX))
                    p.move(to: CGPoint(x: cx - 7, y: 7))
                    p.addLine(to: CGPoint(x: cx, y: 0))
                    p.addLine(to: CGPoint(x: cx + 7, y: 7))
                }
                .fill(palette.elevated)
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
                            .background(palette.surface)
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
                                Button(action: { onInspectDevice(dev) }) {
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
                                .overlay { EmptyView().uiAction("inspectCategoryDevice") }
                            }
                        }
                    }
                    .uiSlot("category-popover-gallery")
                }

                Button(action: { onAddDeviceWithClues(category.discoveryClueLabel) }) {
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
            .background(palette.elevated)
            .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard))
            .overlay(
                RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard)
                    .stroke(palette.borderStrong, lineWidth: 1)
            )
        }
        .uiComponent("CategoryPopover")
    }

    private func trackedHardwareProfilesCard(isStn: Bool) -> some View {
        let featured = Array(BulletinsAndInventoryEngine.sortDevicesByRecentChanges(devices).prefix(6))
        return VStack(alignment: .leading, spacing: 6) {
            Rectangle().fill(palette.border).frame(height: 1)
            Text("Tracked Hardware Profiles")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(palette.textMuted)
                .uiSlot("tracked-profiles-header")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(featured) { dev in
                        let tint = TuesdayTheme.ledColor(for: dev.portState, isStn: isStn)
                        Button(action: { onInspectDevice(dev) }) {
                            VStack(spacing: 4) {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(tint.opacity(0.14))
                                    .frame(width: 42, height: 42)
                                    .overlay(
                                        HardwareCategoryIcon(category: dev.category, tint: tint, size: 22)
                                    )
                                    .uiSlot("tracked-profile-squircle")
                                Text(dev.shortLabel)
                                    .font(.system(size: 10.5, weight: .medium))
                                    .foregroundColor(palette.textMuted)
                                    .lineLimit(1)
                                    .frame(width: 56)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .uiSlot("tracked-profiles-strip")
        }
        .uiComponent("TrackedHardwareProfilesCard")
    }

    private func cleanDeviceRow(_ dev: RackPortDevice, isStn: Bool) -> some View {
        let stateColor = TuesdayTheme.ledColor(for: dev.portState, isStn: isStn)
        let headline = isStn ? dev.stnHeadline : dev.proHeadline

        return Button(action: { onInspectDevice(dev) }) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl)
                    .fill(stateColor.opacity(0.14))
                    .frame(width: 36, height: 36)
                    .overlay(
                        HardwareCategoryIcon(category: dev.category, tint: stateColor, size: 20)
                    )
                    .uiSlot("device-row")

                VStack(alignment: .leading, spacing: 3) {
                    Text(dev.name)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(palette.textPrimary)
                        .lineLimit(1)

                    Text(headline)
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundColor(stateColor)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                if isStn {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(palette.textMuted)
                } else {
                    RiskMeterDots(state: dev.portState, palette: palette)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(palette.surface)
            .overlay(alignment: .leading) {
                if isStn {
                    Rectangle()
                        .fill(stateColor)
                        .frame(width: 3)
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
