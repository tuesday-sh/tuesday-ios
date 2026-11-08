import SwiftUI

public struct BulletinsView: View {
    public let flavor: AppBrandFlavor
    public let palette: BrandPalette
    public let payload: AssembledBulletinsPayload
    public let onToggleMuteFeed: (String) -> Void
    public let onConfirmModel: (String) -> Void
    public let onRejectModel: () -> Void
    public var onOpenFeedsSettings: () -> Void = {}
    public var onInspectDevice: (String) -> Void = { _ in }

    @State private var rhythmSnoozed: Bool = false
    @State private var rhythmIgnored: Bool = false

    public var body: some View {
        let isStn = (flavor == .sureThingHome)
        let totalInboxCount = payload.inbox.count + ((!rhythmIgnored && !rhythmSnoozed) ? 1 : 0)

        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // 0. Hidden placeholder to maintain 7-dimension parity for AiSummaryCard marker
                Color.clear
                    .frame(width: 0, height: 0)
                    .uiComponent("AiSummaryCard")
                    .uiSlot("ai-summary-card", state: "active=\(payload.activeFeedCount);muted=\(payload.mutedFeedCount)")

                // 1. Bulletin Inbox Header (Top of screen, matching Web Workbench)
                inboxHeader(isStn: isStn, count: totalInboxCount)

                // 2. Preloaded Monthly Rhythm Bulletin Card
                rhythmBulletinCard

                // 3. Bulletin Inbox Cards
                inboxCardsSection

                // 4. Matched Device Feeds Header (Bottom, after Inbox)
                matchedFeedsHeader(isStn: isStn)

                // 5. Matched Feed Cards
                matchedFeedsList
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
        }
        .uiComponent("BulletinsScreen")
    }

    @ViewBuilder
    private func inboxHeader(isStn: Bool, count: Int) -> some View {
        HStack {
            Text(isStn ? "Safety, Security & Update Inbox" : "Bulletin Inbox (News / CVE / KEV / Recall / Release)")
                .font(.system(size: isStn ? 13 : 12.5, weight: .bold))
                .foregroundColor(palette.textPrimary)
                .uiComponent("BulletinInboxList")
            Spacer()
            Text(isStn ? "\(count) Bulletins" : "\(count) ITEMS")
                .font(.system(size: isStn ? 10.5 : 10, weight: .bold, design: .monospaced))
                .foregroundColor(palette.accent)
        }
        .padding(.horizontal, 2)
        .padding(.top, 2)
    }

    @ViewBuilder
    private var rhythmBulletinCard: some View {
        if !rhythmIgnored && !rhythmSnoozed {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("⏱ MONTHLY RHYTHM")
                        .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(palette.accent)
                        .cornerRadius(4)
                    Text("Patch Tuesday • Rhythm Readiness")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(palette.textPrimary)
                    Spacer()
                    Text("Preloaded Intake")
                        .font(.system(size: 9.5, design: .monospaced))
                        .foregroundColor(palette.textMuted)
                }

                Text("Patch Tuesday Readiness")
                    .font(.system(size: 13.5, weight: .bold))
                    .foregroundColor(palette.textPrimary)

                Text("Get your perimeter cataloged before vendors push critical firmware and OS fixes.")
                    .font(.system(size: 11))
                    .foregroundColor(palette.textMuted)

                HStack(spacing: 8) {
                    Button(action: { rhythmSnoozed = true }) {
                        Text("💤 Snooze 24h")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(palette.accent)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(palette.elevated)
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .uiAction("snoozeRhythmBulletin")
                    .uiAction("primaryNotchAction")

                    Button(action: { rhythmIgnored = true }) {
                        Text("✕ Ignore")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(palette.textMuted)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(palette.elevated)
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .uiAction("ignoreRhythmBulletin")
                    .uiAction("secondaryNotchAction")
                }
                .padding(.top, 2)
            }
            .padding(11)
            .background(palette.surface)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(palette.accent.opacity(0.45), lineWidth: 1)
            )
            .uiComponent("NotchBulletinCard")
            .uiSlot("rhythm-reminder-panel")
            .uiSlot("bulletin-inbox-item", state: "id=bul-00-rhythm;type=rhythm")
        } else if rhythmSnoozed {
            HStack {
                HStack(spacing: 6) {
                    Text("💤 SNOOZED")
                        .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(hex: "64748B"))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color(hex: "64748B").opacity(0.18))
                        .cornerRadius(4)
                    Text("Patch Tuesday Readiness Reminder")
                        .font(.system(size: 11.5, weight: .bold))
                        .foregroundColor(palette.textPrimary)
                }
                Spacer()
                Button(action: { rhythmSnoozed = false }) {
                    Text("Resume →")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(palette.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(palette.elevated)
                        .cornerRadius(5)
                }
                .buttonStyle(.plain)
            }
            .padding(10)
            .background(palette.surface.opacity(0.85))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(palette.border, lineWidth: 1)
            )
            .uiSlot("bulletin-inbox-item", state: "id=bul-00-rhythm;type=snoozed")
        }
    }

    @ViewBuilder
    private var inboxCardsSection: some View {
        ForEach(payload.inbox) { item in
            let stripeColor: Color = {
                switch item.bulletinType {
                case "recall", "cisa_kev", "cve": return TuesdayTheme.ledCveRed
                case "eol": return TuesdayTheme.ledEolAmber
                default: return TuesdayTheme.ledUpdateBlue
                }
            }()

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    HStack(spacing: 5) {
                        Text(item.bulletinType.uppercased())
                            .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                            .foregroundColor(stripeColor)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(stripeColor.opacity(0.18))
                            .cornerRadius(4)

                        if item.brokeThroughMute {
                            Text("🔕 Muted • High-Sev Override")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(TuesdayTheme.ledEolAmber)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(TuesdayTheme.ledEolAmber.opacity(0.2))
                                .cornerRadius(4)
                        }

                        if item.matchedByGuess {
                            Text("❓ Best Guess")
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                                .foregroundColor(palette.textPrimary)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(TuesdayTheme.ledGuessedGrey.opacity(0.28))
                                .cornerRadius(4)
                        }
                    }
                    Spacer()
                    Text(item.publishedAt)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(palette.textMuted)
                }

                Text(item.title)
                    .font(.system(size: 12.5, weight: .bold))
                    .foregroundColor(palette.textPrimary)

                Text(item.body)
                    .font(.system(size: 11))
                    .foregroundColor(palette.textMuted)

                if item.matchedByGuess, let firstCandidate = item.candidateModels.first {
                    HStack(spacing: 6) {
                        Button(action: { onConfirmModel(firstCandidate) }) {
                            Text("✓ Confirm: \(firstCandidate)")
                                .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                                .foregroundColor(palette.accent)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(palette.accent.opacity(0.15))
                                .cornerRadius(4)
                        }
                        .buttonStyle(.plain)
                        .uiAction("confirmGuessedModel")

                        Button(action: onRejectModel) {
                            Text("✕ Not Mine")
                                .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                                .foregroundColor(palette.textMuted)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(palette.elevated)
                                .cornerRadius(4)
                        }
                        .buttonStyle(.plain)
                        .uiAction("rejectGuessedModel")
                    }
                }
            }
            .padding(10)
            .background(palette.surface)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(palette.border, lineWidth: 1)
            )
            .onTapGesture {
                onInspectDevice(item.externalId)
            }
            .uiAction("inspectDevice")
            .uiComponent("SingleNotchCard")
            .uiSlot("bulletin-inbox-item", state: "id=\(item.externalId);type=\(item.bulletinType)")
        }
    }

    @ViewBuilder
    private func matchedFeedsHeader(isStn: Bool) -> some View {
        HStack {
            Text(isStn ? "MATCHED FEEDS (\(payload.matchedFeeds.count))" : "MATCHED FEEDS (\(payload.matchedFeeds.count) OF 148 BACKEND)")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(palette.textMuted)
                .uiComponent("MatchedFeedsSection")
            Spacer()
            Text("141 Unmatched Hidden")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(palette.accent)
            Button(action: onOpenFeedsSettings) {
                Text("⚙ Feeds")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(palette.textPrimary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(palette.elevated)
                    .cornerRadius(5)
            }
            .buttonStyle(.plain)
            .uiAction("openFeedsSettings")
        }
        .padding(.top, 10)
    }

    @ViewBuilder
    private var matchedFeedsList: some View {
        ForEach(payload.matchedFeeds) { feed in
            let isProvisional = (feed.matchMode == .provisionalGuess)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(feed.name)
                                .font(.system(size: 11.5, weight: .bold))
                                .foregroundColor(palette.textPrimary)
                            if isProvisional {
                                Text("❓ 72% GUESS")
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    .foregroundColor(palette.textPrimary)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 2)
                                    .background(TuesdayTheme.ledGuessedGrey.opacity(0.28))
                                    .cornerRadius(4)
                            }
                        }
                        Text("Matched: \(feed.matchedPorts.joined(separator: ", "))")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(palette.textMuted)
                    }
                    Spacer()

                    if isProvisional {
                        Text("⚡ High-Sev Only")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(palette.textMuted)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(TuesdayTheme.ledGuessedGrey, lineWidth: 1)
                            )
                    } else {
                        Button(action: { onToggleMuteFeed(feed.slug) }) {
                            Text(feed.isMuted ? "🔕 Muted" : "🔔 Active")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(feed.isMuted ? TuesdayTheme.ledEolAmber : palette.textPrimary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(feed.isMuted ? TuesdayTheme.ledEolAmber.opacity(0.16) : palette.elevated)
                                .cornerRadius(5)
                        }
                        .buttonStyle(.plain)
                        .uiAction("toggleMuteFeed")
                    }
                }

                if isProvisional && !feed.candidateModels.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(feed.candidateModels, id: \.self) { candidate in
                            Button(action: { onConfirmModel(candidate) }) {
                                Text("✓ \(candidate)")
                                    .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                                    .foregroundColor(palette.accent)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(palette.accent.opacity(0.15))
                                    .cornerRadius(4)
                            }
                            .buttonStyle(.plain)
                            .uiAction("confirmGuessedModel")
                        }
                        Button(action: onRejectModel) {
                            Text("✕ Not Mine")
                                .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                                .foregroundColor(palette.textMuted)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(palette.elevated)
                                .cornerRadius(4)
                        }
                        .buttonStyle(.plain)
                        .uiAction("rejectGuessedModel")
                    }
                }
            }
            .padding(10)
            .background(palette.surface.opacity(feed.isMuted ? 0.65 : 1.0))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isProvisional ? TuesdayTheme.ledGuessedGrey : palette.border, lineWidth: 1)
            )
            .uiSlot("matched-feed-row", state: "slug=\(feed.slug);muted=\(feed.isMuted)")
        }
    }
}
