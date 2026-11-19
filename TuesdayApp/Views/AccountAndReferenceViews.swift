import SwiftUI

private enum SettingsModalKind: String, Identifiable {
    case network
    case plan
    case reminders
    case feeds
    case preferences
    case developer
    var id: String { rawValue }
}

public struct AccountSettingsView: View {
    @ObservedObject public var repository: MockHacsTuesdayService
    public var storeKitManager: TuesdayStoreKitManager?
    public var notificationManager: TuesdayNotificationManager?
    public let palette: BrandPalette
    public var initialExpandNetwork: Bool = false
    public var initialExpandPlan: Bool = false
    public let onOpenReferenceGuide: () -> Void
    public var onOpenUpgradeModal: () -> Void = {}
    public let onSwitchToFleetTab: () -> Void

    @Environment(\.openURL) private var openURL

    @State private var activeModal: SettingsModalKind? = nil
    @State private var draftNetworkName: String = ""
    @State private var draftApiUrl: String = ""
    @State private var pushSimFeedback: String? = nil
    @State private var didConsumeInitialModal = false

    public init(
        repository: MockHacsTuesdayService,
        storeKitManager: TuesdayStoreKitManager? = nil,
        notificationManager: TuesdayNotificationManager? = nil,
        palette: BrandPalette,
        initialExpandNetwork: Bool = false,
        initialExpandPlan: Bool = false,
        onOpenReferenceGuide: @escaping () -> Void,
        onOpenUpgradeModal: @escaping () -> Void = {},
        onSwitchToFleetTab: @escaping () -> Void
    ) {
        self.repository = repository
        self.storeKitManager = storeKitManager
        self.notificationManager = notificationManager
        self.palette = palette
        self.initialExpandNetwork = initialExpandNetwork
        self.initialExpandPlan = initialExpandPlan
        self.onOpenReferenceGuide = onOpenReferenceGuide
        self.onOpenUpgradeModal = onOpenUpgradeModal
        self.onSwitchToFleetTab = onSwitchToFleetTab
    }

    public var body: some View {
        let isStn = (repository.brandFlavor == .sureThingHome)
        let activeSite = repository.userNetworks.first(where: { $0.id == repository.activeNetworkId })
            ?? repository.userNetworks.first
        let isPro = EntitlementGatePolicy.isProTier1Entitled(repository.entitlementTier)

        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(isStn ? "SETTINGS & ACCOUNT" : "WORKSPACE SETTINGS")
                        .font(.system(size: 11.5, weight: .heavy, design: .monospaced))
                        .foregroundColor(palette.textMuted)
                        .uiSlot("account-header")
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(activeSite?.name ?? "My Network")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(palette.textPrimary)
                    Text("\(repository.visibleRackDevices.count) devices • \(isPro ? "Pro Tier 1" : "Free Tier")")
                        .font(.system(size: 12))
                        .foregroundColor(palette.textMuted)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(palette.surface)
                .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard))
                .overlay(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard).stroke(palette.border, lineWidth: 1))
                .uiSlot("account-profile-summary")

                SurfaceListContainer(palette: palette) {
                    TuesdayListRow(
                        palette: palette,
                        title: isStn ? "Home Network Site" : "Active Network Site",
                        onClick: {
                            draftNetworkName = activeSite?.name ?? "My Network"
                            activeModal = .network
                        },
                        leading: { Image(systemName: "house.fill").foregroundColor(palette.accentText) },
                        subtitle: {
                            Text("\(activeSite?.name ?? "My Network") • \(repository.visibleRackDevices.count) devices")
                                .font(.system(size: 12))
                                .foregroundColor(palette.textMuted)
                        }
                    )

                    SurfaceListDivider(palette: palette)

                    TuesdayListRow(
                        palette: palette,
                        title: "Subscription & Plan",
                        onClick: { activeModal = .plan },
                        leading: { Image(systemName: "crown.fill").foregroundColor(isPro ? TuesdayTheme.ledOkGreen : palette.accentText) },
                        subtitle: {
                            Text(isPro ? "Pro Tier 1 Active (Unlimited Sites)" : "Free Tier • 1 Site Included")
                                .font(.system(size: 12))
                                .foregroundColor(isPro ? TuesdayTheme.ledOkGreen : palette.textMuted)
                        }
                    )
                    .uiSlot("account-plan-entitlement")

                    SurfaceListDivider(palette: palette)

                    TuesdayListRow(
                        palette: palette,
                        title: "Patch Tuesday Reminders",
                        onClick: { activeModal = .reminders },
                        leading: { Image(systemName: "bell.badge.fill").foregroundColor(palette.accentText) },
                        subtitle: {
                            Text(repository.remindersEnabled ? "Monthly reminder ON (2nd Tuesday 10:00 AM)" : "Monthly reminders paused")
                                .font(.system(size: 12))
                                .foregroundColor(palette.textMuted)
                        }
                    )

                    SurfaceListDivider(palette: palette)

                    TuesdayListRow(
                        palette: palette,
                        title: "Advisory Bulletin Feeds",
                        onClick: { activeModal = .feeds },
                        leading: { Image(systemName: "antenna.radiowaves.left.and.right").foregroundColor(palette.accentText) },
                        subtitle: {
                            Text("\(repository.mutedFeedSlugs.count) muted feed(s) • High-Sev Guardrail ON")
                                .font(.system(size: 12))
                                .foregroundColor(palette.textMuted)
                        }
                    )

                    SurfaceListDivider(palette: palette)

                    TuesdayListRow(
                        palette: palette,
                        title: "UI Filter Strip Preferences",
                        onClick: { activeModal = .preferences },
                        leading: { Image(systemName: "slider.horizontal.3").foregroundColor(palette.accentText) },
                        subtitle: {
                            Text("Customize state & zone strips on Home card")
                                .font(.system(size: 12))
                                .foregroundColor(palette.textMuted)
                        }
                    )

                    SurfaceListDivider(palette: palette)

                    TuesdayListRow(
                        palette: palette,
                        title: "Ordinal Spine & Reference Guide",
                        onClick: onOpenReferenceGuide,
                        leading: { Image(systemName: "book.closed.fill").foregroundColor(palette.accentText) },
                        subtitle: {
                            Text("Scale C1–C8, S0–S6, Z0–Z5, R1–R4 & OSI 7+1")
                                .font(.system(size: 12))
                                .foregroundColor(palette.textMuted)
                        }
                    )

                    SurfaceListDivider(palette: palette)

                    TuesdayListRow(
                        palette: palette,
                        title: isStn ? "Household Scale Tester & Dev Tools" : "Developer Mode & State Simulator",
                        onClick: {
                            draftApiUrl = repository.tuesdayApiBaseUrl
                            activeModal = .developer
                        },
                        leading: { Image(systemName: "wrench.and.screwdriver.fill").foregroundColor(repository.isDeveloperMode ? palette.accent : palette.textMuted) },
                        subtitle: {
                            Text(repository.isDeveloperMode ? "Enabled • API: \(repository.tuesdayApiBaseUrl)" : "Seed Pea/Garden/Forest & API diagnostics")
                                .font(.system(size: 12))
                                .foregroundColor(palette.textMuted)
                        }
                    )
                }

                DiscordCommunityCard(palette: palette)
                LegalAndSupportCard(palette: palette)
            }
            .padding(.horizontal, TuesdayDimens.screenPaddingHorizontal)
            .padding(.vertical, 12)
        }
        .background(palette.bg.ignoresSafeArea())
        .uiComponent("AccountSettingsCard")
        .onAppear {
            guard !didConsumeInitialModal else { return }
            didConsumeInitialModal = true
            if initialExpandPlan { activeModal = .plan }
            else if initialExpandNetwork {
                draftNetworkName = activeSite?.name ?? "My Network"
                activeModal = .network
            }
        }
        .overlay {
            if let modal = activeModal {
                modalOverlay(for: modal, isStn: isStn, isPro: isPro)
            }
        }
    }

    @ViewBuilder
    private func modalOverlay(for modal: SettingsModalKind, isStn: Bool, isPro: Bool) -> some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea().onTapGesture { activeModal = nil }

            ScrollView {
                switch modal {
                case .network:
                    TuesdayModalCard(
                        palette: palette,
                        title: "Network Location",
                        componentName: "NetworkLocationModal",
                        closeActionName: "closeNetworkModal",
                        onDismiss: { activeModal = nil },
                        content: {
                            TuesdayTextField(text: $draftNetworkName, label: "Site Name", placeholder: "e.g. Seattle Home", palette: palette)
                                .uiSlot("location-name-editor")
                            Button(action: {
                                repository.renameActiveNetwork(draftNetworkName)
                                activeModal = nil
                            }) {
                                Text("Save Site Name")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, minHeight: 42)
                                    .background(palette.accent)
                                    .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
                            }
                            .buttonStyle(.plain)
                            .uiAction("saveNetworkName")
                        }
                    )

                case .plan:
                    TuesdayModalCard(
                        palette: palette,
                        title: "Plan & Subscription",
                        subtitle: isPro ? "Pro Tier 1 Unlocked" : "Upgrade for multi-site & family management",
                        componentName: "PlanSettingsModal",
                        closeActionName: "closePlanModal",
                        onDismiss: { activeModal = nil },
                        content: {
                            if let store = storeKitManager {
                                PlanOfferSelector(
                                    plans: store.plans,
                                    selectedProductId: store.selectedProductId,
                                    palette: palette,
                                    onSelectPlan: { store.selectPlan($0) }
                                )

                                Button(action: {
                                    Task { await store.purchase(productId: store.selectedProductId) }
                                }) {
                                    Text(store.isPurchasing ? "Processing..." : (isPro ? "Pro Tier 1 Active" : "Upgrade to Pro Tier 1"))
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity, minHeight: 44)
                                        .background(isPro ? TuesdayTheme.ledOkGreen : palette.accent)
                                        .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
                                }
                                .buttonStyle(.plain)
                                .disabled(isPro || store.isPurchasing)
                                .uiAction("upgradeProTier1")

                                Button(action: { Task { await store.restorePurchases() } }) {
                                    Text(store.isRestoring ? "Restoring..." : "Restore Purchases")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(palette.accentText)
                                        .frame(maxWidth: .infinity, minHeight: 36)
                                }
                                .buttonStyle(.plain)
                                .uiAction("restorePurchases")

                                Button(action: {
                                    if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                                        openURL(url)
                                    }
                                }) {
                                    Text("Manage Subscription in Apple Account")
                                        .font(.system(size: 12.5, weight: .semibold))
                                        .foregroundColor(palette.textMuted)
                                        .frame(maxWidth: .infinity, minHeight: 34)
                                }
                                .buttonStyle(.plain)
                                .uiAction("managePlaySubscription")

                                if repository.isDeveloperMode {
                                    Button(action: { repository.downgradeToFreeTier() }) {
                                        Text("🛠️ Dev: Reset Entitlement to Free Tier")
                                            .font(.system(size: 11.5, weight: .bold, design: .monospaced))
                                            .foregroundColor(palette.textMuted)
                                            .frame(maxWidth: .infinity, minHeight: 34)
                                    }
                                    .buttonStyle(.plain)
                                    .uiAction("resetEntitlementFree")
                                }

                                if let msg = store.statusMessage, !msg.isEmpty {
                                    Text(msg)
                                        .font(.system(size: 11.5, design: .monospaced))
                                        .foregroundColor(palette.textPrimary)
                                }

                                SubscriptionLegalDisclosure(palette: palette)
                            }
                        }
                    )

                case .reminders:
                    TuesdayModalCard(
                        palette: palette,
                        title: "Notification Reminders",
                        componentName: "RemindersSettingsModal",
                        closeActionName: "closeRemindersModal",
                        onDismiss: { activeModal = nil },
                        content: {
                            PreferenceToggleRow(
                                title: "Monthly Patch Tuesday Alert",
                                description: "2nd Tuesday at 10:00 AM local reminder.",
                                isOn: Binding(
                                    get: { repository.remindersEnabled },
                                    set: { newVal in
                                        repository.setRemindersEnabled(newVal)
                                        Task { @MainActor in
                                            let mgr = notificationManager ?? TuesdayNotificationManager.shared
                                            await mgr.syncMonthlyPatchTuesdaySchedule(enabled: newVal, isStnFlavor: isStn)
                                        }
                                    }
                                ),
                                palette: palette,
                                actionName: "toggleMonthlyReminders"
                            )
                            .uiAction("toggleMonthlyReminders")
                            SurfaceListDivider(palette: palette)
                            PreferenceToggleRow(
                                title: "CISA KEV & Recall Alerts",
                                description: "Critical safety notices always remain visible in Bulletins.",
                                isOn: Binding(
                                    get: { repository.reminderPreference(for: "critical_cves") },
                                    set: { repository.setReminderPreference(for: "critical_cves", enabled: $0) }
                                ),
                                palette: palette,
                                badgeText: "IN-APP ALWAYS",
                                badgeColor: TuesdayTheme.ledCveRed,
                                actionName: "toggleCriticalReminders"
                            )
                        }
                    )

                case .feeds:
                    TuesdayModalCard(
                        palette: palette,
                        title: "Bulletin Feeds",
                        componentName: "FeedsSettingsModal",
                        closeActionName: "closeFeedsModal",
                        onDismiss: { activeModal = nil },
                        content: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("⚠️ High Severity Guardrail Policy")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(TuesdayTheme.ledCveRed)
                                Text("CISA KEV disclosures and hardware safety recalls break through feed mutes.")
                                    .font(.system(size: 11.5))
                                    .foregroundColor(palette.textMuted)
                            }
                            .padding(10)
                            .background(TuesdayTheme.ledCveRed.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))

                            ForEach(BulletinsAndInventoryEngine.defaultGoldFeeds()) { feed in
                                let isMuted = repository.mutedFeedSlugs.contains(feed.slug)
                                PreferenceToggleRow(
                                    title: isStn ? feed.stnName : feed.proName,
                                    description: isMuted ? "Routine releases muted" : "Subscribed",
                                    isOn: Binding(
                                        get: { !isMuted },
                                        set: { _ in repository.toggleMuteFeed(feed.slug) }
                                    ),
                                    palette: palette,
                                    actionName: "toggleFeed_\(feed.slug)"
                                )
                            }
                        }
                    )

                case .preferences:
                    TuesdayModalCard(
                        palette: palette,
                        title: "UI Filter Preferences",
                        componentName: "PreferencesModal",
                        closeActionName: "closePreferencesModal",
                        onDismiss: { activeModal = nil },
                        content: {
                            VStack(alignment: .leading, spacing: 10) {
                                PreferenceToggleRow(
                                    title: isStn ? "Device Health Filter Strip" : "Lifecycle State Filter Strip",
                                    description: "Shows state filter chips (CVE/KEV, EOL, Guessed, Update, OK) on Home.",
                                    isOn: Binding(
                                        get: { repository.showStateFilterStrip },
                                        set: { repository.toggleShowStateFilterStrip($0) }
                                    ),
                                    palette: palette,
                                    actionName: "toggleShowStateFilterStrip"
                                )
                                .uiSlot("pref-state-filter-row")
                                .overlay { EmptyView().uiAction("toggleShowStateFilterStrip") }

                                SurfaceListDivider(palette: palette)

                                PreferenceToggleRow(
                                    title: isStn ? "Network Lane Filter Strip" : "Trust Zone Filter Strip",
                                    description: "Shows Z0–Z4 network segmentation pills above device cards.",
                                    isOn: Binding(
                                        get: { repository.showZoneFilterStrip },
                                        set: { repository.toggleShowZoneFilterStrip($0) }
                                    ),
                                    palette: palette,
                                    actionName: "toggleShowZoneFilterStrip"
                                )
                                .uiSlot("pref-zone-filter-row")
                                .overlay { EmptyView().uiAction("toggleShowZoneFilterStrip") }
                            }
                            .uiSlot("preferences-toggle-list")
                        }
                    )

                case .developer:
                    TuesdayModalCard(
                        palette: palette,
                        title: isStn ? "Household Scale Tester" : "Developer Mode & Simulators",
                        componentName: "DeveloperSettingsModal",
                        closeActionName: "closeDevModal",
                        onDismiss: { activeModal = nil },
                        content: {
                            PreferenceToggleRow(
                                title: "Developer Mode",
                                description: "Enables seed buttons, raw match logs & custom API targets.",
                                isOn: Binding(
                                    get: { repository.isDeveloperMode },
                                    set: { repository.toggleDeveloperMode($0) }
                                ),
                                palette: palette,
                                actionName: "toggleDeveloperMode"
                            )
                            .uiAction("toggleDeveloperMode")

                            if repository.isDeveloperMode {
                                SurfaceListDivider(palette: palette)

                                PreferenceToggleRow(
                                    title: "🐞 Vision API Debug & Raw Match Logs",
                                    description: "Shows live debug trace & raw JSON inside Add Device.",
                                    isOn: Binding(
                                        get: { repository.isVisionDebugEnabled },
                                        set: { repository.toggleVisionDebugMode($0) }
                                    ),
                                    palette: palette,
                                    actionName: "toggleVisionDebugMode"
                                )
                                .uiSlot("vision-debug-toggle-row")
                                .overlay { EmptyView().uiAction("toggleVisionDebugMode") }

                                PreferenceToggleRow(
                                    title: "Diagnostics Session Retention",
                                    description: "Keep temporary capture diagnostics locally during session.",
                                    isOn: Binding(
                                        get: { repository.isDiagnosticsEnabled },
                                        set: { repository.toggleDiagnosticsMode($0) }
                                    ),
                                    palette: palette,
                                    actionName: "toggleDiagnosticsMode"
                                )
                                .uiSlot("diagnostics-toggle-row")
                                .overlay { EmptyView().uiAction("toggleDiagnosticsMode") }

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("TUESDAY API ENDPOINT TARGET")
                                        .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                                        .foregroundColor(palette.textMuted)
                                    HStack(spacing: 6) {
                                        ForEach(ApiEndpointPreset.allCases) { preset in
                                            Button(action: {
                                                draftApiUrl = preset.url
                                                repository.setTuesdayApiBaseUrl(preset.url)
                                            }) {
                                                Text(preset.shortBadge)
                                                    .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                                                    .foregroundColor(repository.tuesdayApiBaseUrl == preset.url ? .white : palette.textPrimary)
                                                    .frame(maxWidth: .infinity, minHeight: 32)
                                                    .background(repository.tuesdayApiBaseUrl == preset.url ? palette.accent : palette.elevated)
                                                    .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusBadge))
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    HStack(spacing: 6) {
                                        TuesdayTextField(text: $draftApiUrl, label: "Endpoint URL", palette: palette)
                                        Button(action: { repository.setTuesdayApiBaseUrl(draftApiUrl) }) {
                                            Text("Set")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 14)
                                                .frame(minHeight: 38)
                                                .background(palette.accent)
                                                .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
                                        }
                                        .buttonStyle(.plain)
                                        .uiAction("saveApiEndpoint")
                                    }
                                }
                                .uiSlot("dev-api-endpoint-selector")

                                VStack(alignment: .leading, spacing: 6) {
                                    Button(action: {
                                        Task { @MainActor in
                                            let payload = BulletinsAndInventoryEngine.assembleBulletins(
                                                flavor: repository.brandFlavor,
                                                devices: repository.visibleRackDevices,
                                                mutedFeedSlugs: repository.mutedFeedSlugs,
                                                completedBulletinIds: repository.completedBulletinIds
                                            )
                                            let mgr = notificationManager ?? TuesdayNotificationManager.shared
                                            let sent = await mgr.dispatchBulletinNotifications(payload.inbox)
                                            pushSimFeedback = "✓ Dispatched \(sent) local bulletin notification(s)"
                                        }
                                    }) {
                                        Text("🔔 Resend Inventory Notifications")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(palette.accentText)
                                            .frame(maxWidth: .infinity, minHeight: 36)
                                            .background(palette.accent.opacity(0.14))
                                            .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusBadge))
                                    }
                                    .buttonStyle(.plain)
                                    .uiAction("resendInventoryNotifications")

                                    Button(action: {
                                        Task { @MainActor in
                                            repository.triggerMockPatchTuesdayCycle()
                                            let mgr = notificationManager ?? TuesdayNotificationManager.shared
                                            let sent = await mgr.triggerMockPatchTuesdayNotification(isStnFlavor: isStn)
                                            pushSimFeedback = sent ? "✓ Sent Mock Patch Tuesday alert" : "✓ Rhythm card restored (alerts require permission)"
                                        }
                                    }) {
                                        Text("📅 Send Mock Patch Tuesday Bulletin")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(TuesdayTheme.ledOkGreen)
                                            .frame(maxWidth: .infinity, minHeight: 36)
                                            .background(TuesdayTheme.ledOkGreen.opacity(0.14))
                                            .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusBadge))
                                    }
                                    .buttonStyle(.plain)
                                    .uiAction("triggerMockPatchTuesday")

                                    if let msg = pushSimFeedback {
                                        Text(msg)
                                            .font(.system(size: 11, design: .monospaced))
                                            .foregroundColor(palette.textPrimary)
                                    }
                                }
                                .uiSlot("dev-push-notification-simulator")

                                HStack(spacing: 6) {
                                    seedBtn("🔄 Reset (0)", count: 0)
                                    seedBtn("🌱 Pea (1)", count: 1)
                                }
                                HStack(spacing: 6) {
                                    seedBtn("🪴 Garden (7)", count: 7)
                                    seedBtn("🌲 Forest (12)", count: 12)
                                }

                                Button(action: {
                                    _ = repository.purgeGoldenCorpus()
                                    pushSimFeedback = "✓ Purged diagnostic corpus captures"
                                }) {
                                    Text("🗑️ Purge Diagnostic Captures (\(repository.savedCorpusCount) Saved)")
                                        .font(.system(size: 11.5, weight: .bold))
                                        .foregroundColor(TuesdayTheme.ledCveRed)
                                        .frame(maxWidth: .infinity, minHeight: 34)
                                        .background(TuesdayTheme.ledCveRed.opacity(0.12))
                                        .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusBadge))
                                }
                                .buttonStyle(.plain)
                                .uiAction("purgeGoldenCorpus")
                            }
                        }
                    )
                    .uiSlot("developer-mode-card")
                }
            }
            .padding(.top, 48)
        }
    }

    private func seedBtn(_ label: String, count: Int) -> some View {
        Button(action: {
            if count == 0 {
                repository.resetDemoData()
            } else {
                repository.enableDemoMode()
                repository.setSimulatedDeviceCount(count)
            }
            activeModal = nil
            onSwitchToFleetTab()
        }) {
            Text(label)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(palette.textPrimary)
                .frame(maxWidth: .infinity, minHeight: 36)
                .background(palette.elevated)
                .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
                .overlay(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl).stroke(palette.borderStrong, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .uiAction("setSimulatedDeviceCount")
    }
}

public struct NetworkPickerModalSheet: View {
    public let networks: [NetworkSite]
    public let activeNetworkId: String
    public let palette: BrandPalette
    public let onSelectNetwork: (String) -> Void
    public let onCreateNetwork: (String) -> Void
    public var entitlementTier: String = "free"
    public var onOpenUpgrade: () -> Void = {}
    @Environment(\.dismiss) private var dismiss

    public var body: some View {
        SetupNetworkModalView(
            palette: palette,
            networks: networks,
            activeNetworkId: activeNetworkId,
            entitlementTier: entitlementTier,
            onSelectNetwork: onSelectNetwork,
            onCreateNetwork: onCreateNetwork,
            onOpenUpgrade: onOpenUpgrade,
            onOpenNetworkSettings: { dismiss() },
            onDismiss: { dismiss() }
        )
    }
}

public struct ReferenceGuideModalSheet: View {
    public let flavor: AppBrandFlavor
    public let palette: BrandPalette
    @Environment(\.dismiss) private var dismiss

    public init(flavor: AppBrandFlavor, palette: BrandPalette) {
        self.flavor = flavor
        self.palette = palette
    }

    public var body: some View {
        let isStn = (flavor == .sureThingHome)
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    MonospaceBadge(text: "SURETHINGNET STANDARD", color: palette.accentText)

                    Text("SureThingNet Categories (Scale C1 → C8)")
                        .font(.system(size: 17, weight: .heavy))
                        .foregroundColor(palette.textPrimary)

                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                        ForEach(StnHardwareCategory.allCases) { cat in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(cat.displayLabel(isStn: isStn))
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(palette.textPrimary)
                                    Spacer()
                                    MonospaceBadge(text: "\(cat.code)•\(cat.osiLayer)", color: palette.accentText, borderAlpha: 0)
                                }
                                Text(cat.description)
                                    .font(.system(size: 11))
                                    .foregroundColor(palette.textMuted)
                                Text(cat.examples)
                                    .font(.system(size: 10.5, design: .monospaced))
                                    .foregroundColor(palette.accentText)
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(palette.surface)
                            .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
                            .overlay(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl).stroke(palette.border, lineWidth: 1))
                        }
                    }

                    ordinalScaleCard(
                        tag: "Scale S",
                        title: "The 7-Step Vertical Stack (S0 Space → S6 Apps)",
                        rows: [
                            ("S0", "Room & Outlet — Where it lives & powers"),
                            ("S1", "Hardware & Lifespan — Support & EOL tier"),
                            ("S2", "Link & Speed — Upstream Ethernet / Wi-Fi"),
                            ("S3", "Trust Lane — Z0–Z5 segmentation boundary"),
                            ("S4", "Firmware — Bootloader & vendor OTA"),
                            ("S5", "OS & Runtime — Host OS & containers"),
                            ("S6", "Packages & PURLs — Exposed ports & CVEs")
                        ]
                    )

                    ordinalScaleCard(
                        tag: "Scale Z",
                        title: "Inside-Out Trust Rings (Z0 Core → Z4 Guest)",
                        rows: TrustZone.allCases.map { ($0.code, "\(isStn ? $0.stnTitle : $0.displayTitle) (\($0.vlanHint))") }
                    )

                    ordinalScaleCard(
                        tag: "Scale R",
                        title: "4 Operational Rhythms (R1 Event → R4 Annual)",
                        rows: [
                            ("R1", "New Device Intake & Tagging"),
                            ("R2", "Monthly Patch Tuesday Readiness (2nd Tuesday)"),
                            ("R3", "Seasonal Check-Up (90-day drift audit)"),
                            ("R4", "Annual Hardware Lifespan Review")
                        ]
                    )
                }
                .padding(14)
            }
            .background(palette.bg.ignoresSafeArea())
            .navigationTitle("Reference Guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(palette.accentText)
                        .uiAction("closeReferenceGuide")
                }
            }
        }
        .uiComponent("ReferenceGuideModal")
    }

    private func ordinalScaleCard(tag: String, title: String, rows: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                MonospaceBadge(text: tag, color: palette.accentText)
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(palette.textPrimary)
            }
            ForEach(rows, id: \.0) { code, desc in
                HStack(alignment: .top, spacing: 8) {
                    Text(code)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(palette.accentText)
                        .frame(width: 28, alignment: .leading)
                    Text(desc)
                        .font(.system(size: 12))
                        .foregroundColor(palette.textMuted)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard))
        .overlay(RoundedRectangle(cornerRadius: TuesdayDimens.radiusCard).stroke(palette.border, lineWidth: 1))
    }
}
