import SwiftUI

private enum ExpandedBulletinModal {
    case inbox(BulletinInboxView, isCompleted: Bool)
    case welcome(isCompleted: Bool)
    case feed(MatchedFeedView)
}

/// Flow-wrapping row layout for multi-candidate hardware disambiguation chips.
private struct WrappingHStackLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var usedWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth > 0 && rowWidth + spacing + size.width > maxWidth {
                totalHeight += rowHeight + spacing
                usedWidth = max(usedWidth, rowWidth)
                rowWidth = size.width
                rowHeight = size.height
            } else {
                rowWidth = rowWidth > 0 ? rowWidth + spacing + size.width : size.width
                rowHeight = max(rowHeight, size.height)
            }
        }
        totalHeight += rowHeight
        usedWidth = max(usedWidth, rowWidth)
        return CGSize(width: proposal.width ?? usedWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX && x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

public struct BulletinsView: View {
    @ObservedObject public var repository: MockHacsTuesdayService
    public let palette: BrandPalette
    public let payload: AssembledBulletinsPayload
    public let notificationManager: TuesdayNotificationManager?
    public let onTapAddDevice: () -> Void
    public let onTapReferenceGuide: () -> Void
    public var onOpenFeedsSettings: () -> Void
    public var onInspectDevice: (String) -> Void
    public var onNavigateToCheckUp: () -> Void
    public var initialBulletinId: String?
    public var onConsumeInitialBulletin: () -> Void

    @Environment(\.openURL) private var openURL
    @State private var showingPreferencesDialog = false
    @State private var expandedModal: ExpandedBulletinModal? = nil

    public init(
        repository: MockHacsTuesdayService,
        palette: BrandPalette,
        payload: AssembledBulletinsPayload,
        notificationManager: TuesdayNotificationManager? = nil,
        onTapAddDevice: @escaping () -> Void,
        onTapReferenceGuide: @escaping () -> Void = {},
        onOpenFeedsSettings: @escaping () -> Void = {},
        onInspectDevice: @escaping (String) -> Void = { _ in },
        onNavigateToCheckUp: @escaping () -> Void = {},
        initialBulletinId: String? = nil,
        onConsumeInitialBulletin: @escaping () -> Void = {}
    ) {
        self.repository = repository
        self.palette = palette
        self.payload = payload
        self.notificationManager = notificationManager
        self.onTapAddDevice = onTapAddDevice
        self.onTapReferenceGuide = onTapReferenceGuide
        self.onOpenFeedsSettings = onOpenFeedsSettings
        self.onInspectDevice = onInspectDevice
        self.onNavigateToCheckUp = onNavigateToCheckUp
        self.initialBulletinId = initialBulletinId
        self.onConsumeInitialBulletin = onConsumeInitialBulletin
    }

    public var body: some View {
        let isStn = (repository.brandFlavor == .sureThingHome)
        let okGreen = TuesdayTheme.ledColor(for: .ok, isStn: isStn)
        let step1Done = !repository.visibleRackDevices.isEmpty
        let step2Done = repository.remindersEnabled
        let step3Done = repository.dispatchSubscribed
        let allStepsDone = step1Done && step2Done && step3Done
        let isComplete = allStepsDone || repository.bulletinDismissed
        let showActiveWelcome = !repository.bulletinDismissed && !repository.bulletinSnoozed && !repository.bulletinMuted && !isComplete
        let completedCount = (isComplete ? 1 : 0) + payload.completedBulletins.count

        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    // Retired passive AiSummaryCard parity anchor (off-loop, zero visible chrome)
                    ZStack {
                        Color.clear
                            .frame(width: 0, height: 0)
                            .uiSlot("ai-summary-card")
                    }
                    .frame(width: 0, height: 0)
                    .uiComponent("AiSummaryCard")

                    // Section 1: Bulletin Inbox
                    HStack {
                        SectionHeading(text: "Bulletin Inbox", palette: palette)
                        Spacer()
                    }
                    .padding(.horizontal, 2)
                    .padding(.vertical, 2)
                    .uiComponent("BulletinInboxList")

                    if repository.bulletinMuted {
                        RhythmSnoozeOrMuteBanner(
                            palette: palette,
                            slotMeta: "id=bul-00-rhythm;type=muted",
                            badgeText: "🔕 MUTED",
                            title: "Patch Tuesday Monthly Rhythm Muted",
                            description: "Monthly checklist reminders are muted. High-severity CVEs and hardware recalls will continue to alert you.",
                            actionLabel: "Unmute →",
                            onAction: {
                                repository.setBulletinMuted(false)
                                repository.setBulletinDismissed(false)
                                repository.setBulletinSnoozed(false)
                            }
                        )
                    } else if repository.bulletinSnoozed {
                        RhythmSnoozeOrMuteBanner(
                            palette: palette,
                            slotMeta: "id=bul-00-rhythm;type=snoozed",
                            badgeText: "💤 SNOOZED",
                            title: "Patch Tuesday Readiness Reminder",
                            description: "Snoozed until tomorrow at 10:00 AM. Tap resume to see your 3 readiness actions.",
                            actionLabel: "Resume →",
                            onAction: {
                                repository.setBulletinSnoozed(false)
                                repository.setBulletinDismissed(false)
                            }
                        )
                    }

                    if showActiveWelcome || !payload.inbox.isEmpty {
                        BulletinListView(
                            palette: palette,
                            items: payload.inbox,
                            isCompleted: false,
                            showWelcomeRow: showActiveWelcome,
                            onSelectWelcome: { expandedModal = .welcome(isCompleted: false) },
                            onSelectBulletin: { item in expandedModal = .inbox(item, isCompleted: false) }
                        )
                    }

                    // Section 2: Matched Feeds
                    TuesdayListSection(
                        palette: palette,
                        items: payload.matchedFeeds,
                        id: \.id,
                        layoutStyle: .surfaceGrouped,
                        sectionSpacing: 8,
                        title: "Matched Feeds",
                        showHeader: true,
                        showHeaderTrailing: true,
                        showEmpty: true,
                        headerTrailing: {
                            Button(action: onOpenFeedsSettings) {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(palette.textPrimary)
                                    .frame(width: TuesdayDimens.hitTargetCompact, height: TuesdayDimens.hitTargetCompact)
                                    .background(palette.elevated)
                                    .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusBadge))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: TuesdayDimens.radiusBadge)
                                            .stroke(palette.border, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Feeds settings")
                            .uiAction("openFeedsSettings")
                        },
                        itemContent: { feed in
                            MatchedFeedListRow(
                                palette: palette,
                                feed: feed,
                                onClick: { expandedModal = .feed(feed) }
                            )
                        },
                        emptyContent: {
                            TuesdayListEmptyBanner(
                                message: "Add devices to your inventory to get feeds",
                                palette: palette
                            )
                            .uiSlot("matched-feeds-empty-banner")
                        }
                    )
                    .padding(.top, 14)
                    .uiComponent("MatchedFeedsSection")

                    // Section 3: Completed
                    if completedCount > 0 {
                        HStack {
                            SectionHeading(text: "Completed", palette: palette)
                            Spacer()
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 4)

                        VStack(alignment: .leading, spacing: 0) {
                            BulletinListView(
                                palette: palette,
                                items: payload.completedBulletins,
                                isCompleted: true,
                                showWelcomeRow: isComplete,
                                onSelectWelcome: { expandedModal = .welcome(isCompleted: true) },
                                onSelectBulletin: { item in expandedModal = .inbox(item, isCompleted: true) }
                            )
                        }
                        .uiSlot("completed-bulletins-section")
                    }
                }
                .padding(.horizontal, TuesdayDimens.screenPaddingHorizontal)
                .padding(.vertical, 12)
            }
            .background(palette.bg.ignoresSafeArea())
            .uiComponent("BulletinsScreen")

            if let modal = expandedModal {
                DetailModalDialog(palette: palette, onDismiss: { expandedModal = nil }) {
                    VStack(spacing: 0) {
                        switch modal {
                        case .inbox(let item, let completed):
                            VStack(alignment: .leading, spacing: 10) {
                                InboxItemNotchCard(
                                    palette: palette,
                                    item: item,
                                    isCompleted: completed,
                                    onClick: {
                                        expandedModal = nil
                                        onInspectDevice(item.affectedDeviceIds.first ?? item.externalId)
                                    },
                                    onConfirmModel: { chosen in
                                        expandedModal = nil
                                        repository.confirmProvisionalDeviceModel(chosen)
                                    },
                                    onRejectModel: {
                                        expandedModal = nil
                                        repository.rejectProvisionalDeviceModel()
                                    }
                                )

                                if !completed {
                                    Button(action: {
                                        repository.markBulletinCompleted(item.externalId)
                                        expandedModal = nil
                                    }) {
                                        Text("✓ Mark Remediated & Update Device Status")
                                            .font(.system(size: 13.5, weight: .bold))
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity, minHeight: 42)
                                            .background(okGreen)
                                            .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                        case .welcome(let completed):
                            welcomeNotchModal(
                                isCompleted: completed,
                                step1Done: step1Done,
                                step2Done: step2Done,
                                step3Done: step3Done,
                                allStepsDone: allStepsDone,
                                isStn: isStn,
                                okGreen: okGreen
                            )

                        case .feed(let feed):
                            MatchedFeedCard(
                                palette: palette,
                                feed: feed,
                                onToggleMuteFeed: { slug in
                                    expandedModal = nil
                                    repository.toggleMuteFeed(slug)
                                },
                                onConfirmModel: { model in
                                    expandedModal = nil
                                    repository.confirmProvisionalDeviceModel(model)
                                },
                                onRejectModel: {
                                    expandedModal = nil
                                    repository.rejectProvisionalDeviceModel()
                                }
                            )
                        }
                    }
                    .uiComponent("BulletinDetailModal")
                }
            }

            if showingPreferencesDialog {
                BulletinPreferencesDialog(
                    palette: palette,
                    onDismiss: { showingPreferencesDialog = false },
                    onConfirmMute: {
                        showingPreferencesDialog = false
                        repository.setBulletinMuted(true)
                        repository.setBulletinDismissed(true)
                    },
                    onConfirmIgnoreUntilNextMonth: {
                        showingPreferencesDialog = false
                        repository.setBulletinSnoozed(true)
                        repository.setBulletinDismissed(true)
                    }
                )
            }
        }
        .onAppear { handleInitialBulletinIfNeeded() }
        .onChange(of: initialBulletinId) { _, _ in handleInitialBulletinIfNeeded() }
    }

    private func handleInitialBulletinIfNeeded() {
        guard let targetId = initialBulletinId, !targetId.isEmpty else { return }
        if let activeMatch = payload.inbox.first(where: { $0.externalId == targetId }) {
            expandedModal = .inbox(activeMatch, isCompleted: false)
        } else if let completedMatch = payload.completedBulletins.first(where: { $0.externalId == targetId }) {
            expandedModal = .inbox(completedMatch, isCompleted: true)
        }
        onConsumeInitialBulletin()
    }

    @ViewBuilder
    private func welcomeNotchModal(
        isCompleted: Bool,
        step1Done: Bool,
        step2Done: Bool,
        step3Done: Bool,
        allStepsDone: Bool,
        isStn: Bool,
        okGreen: Color
    ) -> some View {
        let steps: [BulletinChecklistStep] = [
            BulletinChecklistStep(
                id: "step1",
                num: "1",
                title: "Inventory Your Network",
                description: "Kick off Plug & Tag intake to map active routers, switches, NAS, and IoT nodes.",
                linkText: (isCompleted || step1Done) ? "✓ Added" : "Add Device →",
                isDone: isCompleted || step1Done,
                onClick: {
                    expandedModal = nil
                    onTapAddDevice()
                }
            ),
            BulletinChecklistStep(
                id: "step2",
                num: "2",
                title: "Enable Push Reminders",
                description: "Receive an alert at 10:00 AM PT on Patch Tuesday with your prioritized triage list.",
                linkText: (isCompleted || step2Done) ? "✓ Active" : "Enable →",
                isDone: isCompleted || step2Done,
                onClick: {
                    Task { @MainActor in
                        let mgr = notificationManager ?? TuesdayNotificationManager.shared
                        _ = await mgr.requestAuthorizationIfNeeded()
                        await mgr.syncMonthlyPatchTuesdaySchedule(enabled: true, isStnFlavor: isStn)
                        repository.setRemindersEnabled(true)
                    }
                }
            ),
            BulletinChecklistStep(
                id: "step3",
                num: "3",
                title: "Subscribe to the Dispatch",
                description: "Get human-curated patch analysis and firmware changelogs delivered every cycle.",
                linkText: (isCompleted || step3Done) ? "✓ Subscribed" : "Dispatch ↗",
                isDone: isCompleted || step3Done,
                onClick: {
                    repository.setDispatchSubscribed(true)
                    if let url = URL(string: "https://tuesday.sh/dispatch") {
                        openURL(url)
                    }
                }
            ),
        ]

        if isCompleted {
            NotchBulletinCard(
                palette: palette,
                title: "Patch Tuesday Check-Up • Complete",
                description: "Enrolled & monitored. Inventory mapped, 10:00 AM PT push alerts enabled, monthly dispatch active.",
                leftNotchLabel: "CHECK-UP COMPLETE",
                leftNotchDotColor: okGreen,
                rightNotchLabel: "CHECK-UP",
                onRightNotchClick: {
                    expandedModal = nil
                    onNavigateToCheckUp()
                },
                steps: steps,
                allStepsDone: true,
                primaryActionLabel: "Completed",
                completeActionLabel: "Completed",
                secondaryActionLabel: "Reopen",
                onPrimaryAction: {},
                onSecondaryAction: {
                    expandedModal = nil
                    repository.setBulletinDismissed(false)
                    repository.setBulletinSnoozed(false)
                }
            )
        } else {
            NotchBulletinCard(
                palette: palette,
                title: "Patch Tuesday Readiness",
                description: "Get your perimeter cataloged before vendors push critical firmware and OS fixes.",
                leftNotchLabel: "BULLETIN",
                rightNotchLabel: "CHECK-UP",
                onRightNotchClick: {
                    expandedModal = nil
                    onNavigateToCheckUp()
                },
                steps: steps,
                allStepsDone: allStepsDone,
                primaryActionLabel: "Snooze 24h",
                completeActionLabel: "Mark Complete",
                secondaryActionLabel: "Ignore",
                onPrimaryAction: {
                    expandedModal = nil
                    if allStepsDone {
                        repository.setBulletinDismissed(true)
                    } else {
                        repository.setBulletinSnoozed(true)
                    }
                },
                onSecondaryAction: {
                    expandedModal = nil
                    showingPreferencesDialog = true
                }
            )
        }
    }
}

private struct RhythmSnoozeOrMuteBanner: View {
    let palette: BrandPalette
    let slotMeta: String
    let badgeText: String
    let title: String
    let description: String
    let actionLabel: String
    let onAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                MonospaceBadge(text: badgeText, color: palette.textMuted)
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(palette.textPrimary)
                    .lineLimit(1)
                Spacer(minLength: 4)
                Button(action: onAction) {
                    Text(actionLabel)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(palette.accentText)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .frame(minHeight: 28)
                        .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusBadge))
                        .overlay(
                            RoundedRectangle(cornerRadius: TuesdayDimens.radiusBadge)
                                .stroke(palette.accent, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .uiAction("resumeRhythmBulletin")
            }

            Text(description)
                .font(.system(size: 11.5))
                .foregroundColor(palette.textMuted)
                .lineSpacing(3.5)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.surface.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
        .overlay(
            RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl)
                .stroke(palette.border, lineWidth: 1)
        )
        .uiSlot("bulletin-rhythm-status-banner", state: slotMeta)
    }
}

private struct BulletinListView: View {
    let palette: BrandPalette
    let items: [BulletinInboxView]
    let isCompleted: Bool
    var showWelcomeRow: Bool = false
    var onSelectWelcome: () -> Void = {}
    let onSelectBulletin: (BulletinInboxView) -> Void

    var body: some View {
        SurfaceListContainer(palette: palette) {
            if showWelcomeRow {
                WelcomeBulletinListRow(
                    palette: palette,
                    isCompleted: isCompleted,
                    onClick: onSelectWelcome
                )
                if !items.isEmpty {
                    SurfaceListDivider(palette: palette)
                }
            }
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                BulletinListRow(
                    palette: palette,
                    item: item,
                    isCompleted: isCompleted,
                    onClick: { onSelectBulletin(item) }
                )
                if index < items.count - 1 {
                    SurfaceListDivider(palette: palette)
                }
            }
        }
    }
}

private struct WelcomeBulletinListRow: View {
    let palette: BrandPalette
    let isCompleted: Bool
    let onClick: () -> Void

    var body: some View {
        let okGreen = TuesdayTheme.ledColor(for: .ok, isStn: palette.isStn)
        let accentColor = isCompleted ? okGreen : palette.accentText
        StatusListRow(
            palette: palette,
            dotColor: isCompleted ? okGreen : palette.accent,
            title: isCompleted ? "Patch Tuesday Check-Up • Complete" : "Patch Tuesday Readiness",
            onClick: onClick
        ) {
            Text(isCompleted ? "CHECK-UP COMPLETE" : "BULLETIN • CHECK-UP")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(accentColor)
        }
        .accessibilityLabel("Expand welcome bulletin")
        .uiSlot("bulletin-inbox-item", state: "id=bul-00-rhythm;type=welcome;completed=\(isCompleted)")
    }
}

private struct BulletinListRow: View {
    let palette: BrandPalette
    let item: BulletinInboxView
    let isCompleted: Bool
    let onClick: () -> Void

    var body: some View {
        let okGreen = TuesdayTheme.ledColor(for: .ok, isStn: palette.isStn)
        let eolAmber = TuesdayTheme.ledColor(for: .eol, isStn: palette.isStn)
        let accentColor: Color = {
            if isCompleted { return okGreen }
            switch item.bulletinType.lowercased() {
            case "recall", "cisa_kev", "cve":
                return TuesdayTheme.ledColor(for: .cveKev, isStn: palette.isStn)
            case "eol":
                return eolAmber
            default:
                return TuesdayTheme.ledColor(for: .update, isStn: palette.isStn)
            }
        }()

        StatusListRow(
            palette: palette,
            dotColor: accentColor,
            title: item.title,
            onClick: onClick
        ) {
            HStack(spacing: 6) {
                Text(item.bulletinType.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(accentColor)
                if isCompleted {
                    Text("• RESOLVED")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(okGreen)
                } else if item.brokeThroughMute {
                    Text("• HIGH-SEV")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(eolAmber)
                }
            }
        }
        .accessibilityLabel("Expand bulletin")
        .uiSlot("bulletin-inbox-item", state: "id=\(item.externalId);type=\(item.bulletinType);completed=\(isCompleted)")
    }
}

private struct MatchedFeedListRow: View {
    let palette: BrandPalette
    let feed: MatchedFeedView
    let onClick: () -> Void

    var body: some View {
        let isProvisional = (feed.matchMode == .provisionalGuess)
        let dotColor: Color = {
            if isProvisional { return TuesdayTheme.ledGuessedGrey }
            if feed.isMuted { return palette.textMuted }
            return TuesdayTheme.ledColor(for: .ok, isStn: palette.isStn)
        }()

        StatusListRow(
            palette: palette,
            dotColor: dotColor,
            title: feed.name,
            onClick: onClick
        ) {
            Text("Matched: \(feed.matchedPorts.joined(separator: ", "))")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(palette.textMuted)
                .lineLimit(1)
        }
        .accessibilityLabel("Expand feed")
        .uiSlot("matched-feed-row", state: "slug=\(feed.slug);muted=\(feed.isMuted)")
    }
}

private struct MatchedFeedCard: View {
    let palette: BrandPalette
    let feed: MatchedFeedView
    let onToggleMuteFeed: (String) -> Void
    let onConfirmModel: (String) -> Void
    let onRejectModel: () -> Void

    var body: some View {
        let isProvisional = (feed.matchMode == .provisionalGuess)
        let eolAmber = TuesdayTheme.ledColor(for: .eol, isStn: palette.isStn)

        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 8) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(feed.name)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(palette.textPrimary)
                        if isProvisional {
                            MonospaceBadge(text: "❓ 72% GUESS", color: palette.textMuted)
                        }
                    }
                    Text("Matched: \(feed.matchedPorts.joined(separator: ", "))")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(palette.textMuted)
                }

                Spacer(minLength: 4)

                if isProvisional {
                    MonospaceBadge(text: "⚡ High-Sev Only", color: palette.textMuted)
                } else {
                    Button(action: { onToggleMuteFeed(feed.slug) }) {
                        Text(feed.isMuted ? "🔕 Muted" : "🔔 Active")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(feed.isMuted ? eolAmber : palette.textPrimary)
                            .lineLimit(1)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .frame(minHeight: 28)
                            .background(feed.isMuted ? eolAmber.opacity(0.16) : palette.elevated)
                            .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusBadge))
                            .overlay(
                                RoundedRectangle(cornerRadius: TuesdayDimens.radiusBadge)
                                    .stroke(feed.isMuted ? eolAmber : palette.border, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .uiAction("toggleMuteFeed")
                }
            }

            if isProvisional && !feed.candidateModels.isEmpty {
                if feed.candidateModels.count == 1, let candidate = feed.candidateModels.first {
                    CandidateDisambiguationStrip(
                        candidateModel: candidate,
                        palette: palette,
                        onConfirmModel: onConfirmModel,
                        onRejectModel: onRejectModel
                    )
                } else {
                    WrappingHStackLayout(spacing: 6) {
                        ForEach(feed.candidateModels, id: \.self) { candidate in
                            Button(action: { onConfirmModel(candidate) }) {
                                Text("✓ \(candidate)")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(palette.accentText)
                                    .lineLimit(1)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 5)
                                    .frame(minHeight: 28)
                                    .background(palette.accent.opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusBadge))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: TuesdayDimens.radiusBadge)
                                            .stroke(palette.accent, lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                            .uiAction("confirmGuessedModel")
                        }

                        Button(action: onRejectModel) {
                            Text("✕ Not Mine")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(palette.textMuted)
                                .lineLimit(1)
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
                        .uiAction("rejectGuessedModel")
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard))
        .overlay(
            RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard)
                .stroke(isProvisional ? TuesdayTheme.ledGuessedGrey : palette.border, lineWidth: 1)
        )
    }
}
