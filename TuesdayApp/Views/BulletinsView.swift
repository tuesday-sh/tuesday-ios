import SwiftUI

public struct BulletinsView: View {
    public let flavor: AppBrandFlavor
    public let palette: BrandPalette
    public let payload: AssembledBulletinsPayload
    public let onToggleMuteFeed: (String) -> Void
    public let onConfirmModel: (String) -> Void
    public let onRejectModel: () -> Void

    public var body: some View {
        let isStn = (flavor == .sureThingHome)

        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // 1. Top-Level AI Summary Card
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(isStn ? "✨ AI HOME BRIEFING • ACTIVE FEEDS" : "✦ AI BULLETIN DIGEST • UNMUTED FEEDS")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(palette.accent)
                        Spacer()
                        Text("\(payload.activeFeedCount)/\(payload.matchedFeeds.count) Active")
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundColor(palette.textMuted)
                    }

                    if payload.aiBullets.isEmpty {
                        Text("All matched device feeds are currently muted. High-severity alerts still appear in your inbox below.")
                            .font(.system(size: 11))
                            .foregroundColor(palette.textMuted)
                    } else {
                        ForEach(payload.aiBullets, id: \.self) { bullet in
                            HStack(alignment: .top, spacing: 6) {
                                Text("•")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(palette.accent)
                                Text(bullet)
                                    .font(.system(size: 11))
                                    .foregroundColor(palette.textPrimary)
                            }
                        }
                    }

                    HStack {
                        Text("\(payload.mutedFeedCount) Muted • \(payload.provisionalFeedCount) Best-Guess Excluded")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(palette.textMuted)
                        Spacer()
                        if payload.mutedHighSevOverrideCount > 0 || payload.provisionalHighSevCount > 0 {
                            Text("⚡ \(payload.mutedHighSevOverrideCount) Override • ❓ \(payload.provisionalHighSevCount) Guess")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(TuesdayTheme.ledEolAmber)
                        }
                    }
                    .padding(.top, 2)
                }
                .padding(12)
                .background(palette.surface)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(palette.accent.opacity(0.45), lineWidth: 1)
                )

                // 2. Matched Device Feeds Header
                HStack {
                    Text(isStn ? "MATCHED FEEDS FOR YOUR HOME (\(payload.matchedFeeds.count))" : "MATCHED FEEDS (\(payload.matchedFeeds.count) OF 148 BACKEND)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(palette.textMuted)
                    Spacer()
                    Text("141 Unmatched Hidden")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(palette.accent)
                }

                // 3. Matched Feed Cards
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
                }

                // 4. Bulletin Inbox Header
                HStack {
                    Text(isStn ? "HOME BULLETIN INBOX (\(payload.inbox.count))" : "BULLETIN INBOX (\(payload.inbox.count) ITEMS)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(palette.textMuted)
                    Spacer()
                    Text("Gold Lake Snapshot • 0 Live Calls")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(TuesdayTheme.ledOkGreen)
                }
                .padding(.top, 4)

                // 5. Bulletin Inbox Cards
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
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(palette.textPrimary)

                        Text(item.body)
                            .font(.system(size: 10.5))
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

                                Button(action: onRejectModel) {
                                    Text("✕ Not My Model")
                                        .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                                        .foregroundColor(palette.textMuted)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(palette.elevated)
                                        .cornerRadius(4)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.top, 2)
                        }
                    }
                    .padding(10)
                    .background(palette.surface)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(palette.border, lineWidth: 1)
                    )
                }
            }
            .padding(12)
        }
    }
}
