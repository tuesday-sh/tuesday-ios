import SwiftUI

public struct BulletinsView: View {
    @ObservedObject public var repository: MockHacsTuesdayService
    public let palette: BrandPalette
    public let payload: AssembledBulletinsPayload
    public let notificationManager: TuesdayNotificationManager?
    public let onTapAddDevice: () -> Void
    public let onTapReferenceGuide: () -> Void

    @State private var showingPreferencesDialog = false
    @State private var selectedBulletin: BulletinInboxView? = nil

    public init(
        repository: MockHacsTuesdayService,
        palette: BrandPalette,
        payload: AssembledBulletinsPayload,
        notificationManager: TuesdayNotificationManager? = nil,
        onTapAddDevice: @escaping () -> Void,
        onTapReferenceGuide: @escaping () -> Void
    ) {
        self.repository = repository
        self.palette = palette
        self.payload = payload
        self.notificationManager = notificationManager
        self.onTapAddDevice = onTapAddDevice
        self.onTapReferenceGuide = onTapReferenceGuide
    }

    public var body: some View {
        let isStn = (repository.brandFlavor == .sureThingHome)
        let devices = repository.visibleRackDevices
        let hasDevice = !devices.isEmpty

        let steps: [BulletinChecklistStep] = [
            BulletinChecklistStep(
                id: 1,
                title: isStn ? "Add your Wi-Fi router or first device" : "Enroll core gateway / first hardware",
                completed: hasDevice,
                ctaLabel: "Add Device",
                onTap: onTapAddDevice
            ),
            BulletinChecklistStep(
                id: 2,
                title: isStn ? "Turn on monthly Patch Tuesday reminders" : "Enable 10:00 AM PT Patch Tuesday alerts",
                completed: repository.remindersEnabled,
                ctaLabel: "Enable",
                onTap: {
                    Task { @MainActor in
                        let mgr = notificationManager ?? TuesdayNotificationManager.shared
                        _ = await mgr.requestAuthorizationIfNeeded()
                        await mgr.syncMonthlyPatchTuesdaySchedule(enabled: true, isStnFlavor: isStn)
                        repository.setRemindersEnabled(true)
                    }
                }
            ),
            BulletinChecklistStep(
                id: 3,
                title: isStn ? "Subscribe to safety dispatch feed" : "Activate Gold CVE / KEV dispatch stream",
                completed: repository.dispatchSubscribed,
                ctaLabel: "Subscribe",
                onTap: { repository.setDispatchSubscribed(true) }
            )
        ]

        let allComplete = steps.allSatisfy(\.completed)
        let shouldShowWelcomeCard = (!repository.bulletinDismissed && !repository.bulletinMuted) || !allComplete

        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(isStn ? "HOME SAFETY BULLETINS" : "UPSTREAM SECURITY BULLETINS")
                        .font(.system(size: 11.5, weight: .heavy, design: .monospaced))
                        .foregroundColor(palette.textMuted)
                    Spacer()
                    MonospaceBadge(
                        text: "\(payload.activeFeedCount) ACTIVE • \(payload.mutedFeedCount) MUTED",
                        color: palette.accentText
                    )
                }

                if shouldShowWelcomeCard {
                    NotchBulletinCard(
                        palette: palette,
                        statusLabel: "BULLETIN",
                        linkLabel: "RHYTHM",
                        headline: isStn
                            ? "Get ready for Patch Tuesday in 3 steps"
                            : "R2 Monthly Patch Tuesday Readiness",
                        bodyText: isStn
                            ? "Once a month we check your router and home gear for vendor security fixes — no constant spam."
                            : "Prepare your local hardware inventory and Gold PURL streams before the 2nd Tuesday upstream bulletin window.",
                        checklistSteps: steps,
                        allComplete: allComplete,
                        isSnoozed: repository.bulletinSnoozed,
                        onTapRhythmInfo: onTapReferenceGuide,
                        onSnoozeOrComplete: {
                            if allComplete {
                                repository.setBulletinDismissed(true)
                            } else {
                                repository.setBulletinSnoozed(!repository.bulletinSnoozed)
                            }
                        },
                        onIgnore: {
                            showingPreferencesDialog = true
                        }
                    )
                }

                if !payload.aiBullets.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("AI BULLETINS DIGEST")
                                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                                .foregroundColor(palette.accentText)
                            Spacer()
                            Button("Feeds") {
                                showingPreferencesDialog = true
                            }
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(palette.accentText)
                            .uiAction("openFeedsSettings")
                        }
                        ForEach(payload.aiBullets, id: \.self) { bullet in
                            Text("• \(bullet)")
                                .font(.system(size: 12.5))
                                .foregroundColor(palette.textPrimary)
                        }
                    }
                    .padding(12)
                    .background(palette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard))
                    .overlay(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard).stroke(palette.border, lineWidth: 1))
                    .uiSlot("ai-summary-card")
                    .uiComponent("AiSummaryCard")
                }

                if payload.inbox.isEmpty && payload.completedBulletins.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(hasDevice ? "No active bulletins for your devices" : "No hardware enrolled yet")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(palette.textPrimary)
                        Text(hasDevice
                             ? "Your enrolled hardware has no unaddressed CVEs, recalls, or vendor cutoff notices."
                             : "Add your Wi-Fi router or smart devices on the Home tab to match upstream vendor bulletins.")
                            .font(.system(size: 13))
                            .foregroundColor(palette.textMuted)
                            .lineSpacing(3)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(palette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard))
                    .overlay(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard).stroke(palette.border, lineWidth: 1))
                } else {
                    if !payload.inbox.isEmpty {
                        Text("ACTIONABLE INBOX (\(payload.inbox.count))")
                            .font(.system(size: 11, weight: .heavy, design: .monospaced))
                            .foregroundColor(palette.textMuted)

                        ForEach(payload.inbox) { item in
                            InboxItemNotchCard(
                                palette: palette,
                                item: item,
                                isCompleted: false,
                                onClick: { selectedBulletin = item },
                                onConfirmModel: { chosen in repository.confirmProvisionalDeviceModel(chosen) },
                                onRejectModel: { repository.rejectProvisionalDeviceModel() }
                            )
                        }
                        .uiComponent("BulletinInboxList")
                    }

                    if !payload.matchedFeeds.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("MATCHED ADVISORY STREAMS (\(payload.matchedFeeds.count))")
                                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                                .foregroundColor(palette.textMuted)
                            ForEach(payload.matchedFeeds) { feed in
                                HStack {
                                    Text(feed.name)
                                        .font(.system(size: 12.5, weight: .semibold))
                                        .foregroundColor(palette.textPrimary)
                                    Spacer()
                                    Text(feed.isMuted ? "Muted" : "Active")
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(palette.textMuted)
                                        .uiAction("toggleMuteFeed")
                                }
                                .padding(.vertical, 4)
                                .uiSlot("matched-feed-row")
                            }
                        }
                        .padding(12)
                        .background(palette.surface)
                        .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard))
                        .uiComponent("MatchedFeedsSection")
                    }

                    if !payload.completedBulletins.isEmpty {
                        Text("REMEDIATED (\(payload.completedBulletins.count))")
                            .font(.system(size: 11, weight: .heavy, design: .monospaced))
                            .foregroundColor(palette.textMuted)

                        ForEach(payload.completedBulletins) { item in
                            InboxItemNotchCard(
                                palette: palette,
                                item: item,
                                isCompleted: true,
                                onClick: { selectedBulletin = item }
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, TuesdayDimens.screenPaddingHorizontal)
            .padding(.vertical, 12)
        }
        .background(palette.bg.ignoresSafeArea())
        .uiComponent("BulletinsScreen")
        .overlay {
            if showingPreferencesDialog {
                BulletinPreferencesDialog(
                    palette: palette,
                    onDismiss: { showingPreferencesDialog = false },
                    onConfirmMute: {
                        repository.setBulletinMuted(true)
                        showingPreferencesDialog = false
                    },
                    onConfirmIgnoreUntilNextMonth: {
                        repository.setBulletinDismissed(true)
                        showingPreferencesDialog = false
                    }
                )
            }
        }
        .sheet(item: $selectedBulletin) { item in
            ZStack {
                palette.bg.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 14) {
                    Text(item.title)
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundColor(palette.textPrimary)
                    Text(item.body)
                        .font(.system(size: 14))
                        .foregroundColor(palette.textMuted)
                        .lineSpacing(4)
                    if !repository.completedBulletinIds.contains(item.externalId) {
                        Button(action: {
                            repository.markBulletinCompleted(item.externalId)
                            selectedBulletin = nil
                        }) {
                            Text("✓ Mark Remediated & Update Device Status")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(TuesdayTheme.ledColor(for: .ok, isStn: isStn))
                                .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                }
                .padding(16)
            }
        }
    }
}
