import SwiftUI

public struct GoldHardwareCluesPicker: View {
    public let palette: BrandPalette
    @Binding public var queryText: String
    @Binding public var selectedClues: [GoldClueItem]
    public var onClueAdded: (GoldClueItem) -> Void = { _ in }
    public var onClueRemoved: (GoldClueItem) -> Void = { _ in }
    public var inferredFromDeviceName: GoldClueItem? = nil

    @State private var isCluesExpanded: Bool = false

    public init(
        palette: BrandPalette,
        queryText: Binding<String>,
        selectedClues: Binding<[GoldClueItem]>,
        onClueAdded: @escaping (GoldClueItem) -> Void = { _ in },
        onClueRemoved: @escaping (GoldClueItem) -> Void = { _ in },
        inferredFromDeviceName: GoldClueItem? = nil
    ) {
        self.palette = palette
        self._queryText = queryText
        self._selectedClues = selectedClues
        self.onClueAdded = onClueAdded
        self.onClueRemoved = onClueRemoved
        self.inferredFromDeviceName = inferredFromDeviceName
    }

    public var body: some View {
        let trimmed = queryText.trimmingCharacters(in: .whitespacesAndNewlines)
        let suggestions: [GoldClueItem] = trimmed.isEmpty
            ? []
            : GoldClueSuggestionRepository.shared.querySuggestions(rawQuery: trimmed, selected: selectedClues, limit: 6)
        let quickPicks = GoldClueSuggestionRepository.shared.contextualQuickPicks(selectedClues, limit: 8)
            .filter { pick in !selectedClues.contains(where: { $0.id == pick.id }) }

        VStack(alignment: .leading, spacing: 10) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.15)) {
                    isCluesExpanded.toggle()
                }
            }) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(palette.textMuted)
                        Text("CLUES")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(0.6)
                            .foregroundColor(palette.textMuted)
                        if !isCluesExpanded {
                            Text(selectedClues.isEmpty ? "(Tap to add)" : "(\(selectedClues.count) selected · Tap to add)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(palette.accentText)
                        }
                    }
                    Spacer()
                    Image(systemName: isCluesExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(palette.textMuted)
                }
                .frame(minHeight: 32)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isCluesExpanded {
                let version = GoldClueSuggestionRepository.shared.datalakeVersion
                Text("Choose context clues to help identify your device. Clues are retrieved from SureThingNet Insights v\(version).")
                    .font(.system(size: 12))
                    .foregroundColor(palette.textMuted)
                    .lineSpacing(3)

                if let inferred = inferredFromDeviceName {
                    Button(action: { appendClue(inferred) }) {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(TuesdayTheme.ledColor(for: .ok, isStn: palette.isStn))
                            Text("Link Gold SKU: \(inferred.vendor ?? "") \(inferred.title) (\(inferred.categoryCode ?? ""))")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(palette.textPrimary)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(TuesdayTheme.ledColor(for: .ok, isStn: palette.isStn).opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
                        .overlay(
                            RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl)
                                .stroke(TuesdayTheme.ledColor(for: .ok, isStn: palette.isStn).opacity(0.45), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }

                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(palette.accent)

                    TextField("Type router, switch, printer, doorbell, Google...", text: $queryText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13.5))
                        .foregroundColor(palette.textPrimary)
                        .submitLabel(.done)
                        .onSubmit { commitTypedText(trimmed: trimmed) }

                    if !trimmed.isEmpty {
                        Button(action: { commitTypedText(trimmed: trimmed) }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(palette.accent)
                                .frame(width: 28, height: 28)
                        }
                        .buttonStyle(.plain)
                        .uiAction("addClue")
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(palette.bg)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(palette.border, lineWidth: 1)
                )
                .uiSlot("gold-clue-autocomplete")

                if !suggestions.isEmpty {
                    SurfaceListContainer(palette: palette) {
                        ForEach(Array(suggestions.enumerated()), id: \.element.id) { idx, hit in
                            if idx > 0 { SurfaceListDivider(palette: palette) }
                            let hasWarn = !(hit.warningNote ?? "").isEmpty
                            let accent = clueColor(kind: hit.kind, hasWarning: hasWarn)
                            let rowTitle: String = {
                                if hit.kind == .model, let v = hit.vendor, !v.isEmpty {
                                    return "\(v) • \(hit.title)"
                                }
                                if hit.kind == .freeText {
                                    return "Add \"\(hit.title)\""
                                }
                                return hit.title
                            }()

                            TuesdayListRow(
                                palette: palette,
                                title: rowTitle,
                                onClick: {
                                    appendClue(hit)
                                    queryText = ""
                                },
                                leading: {
                                    Image(systemName: clueIcon(kind: hit.kind, hasWarning: hasWarn))
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(accent)
                                },
                                subtitle: {
                                    Text(hit.warningNote ?? hit.subtitle)
                                        .font(.system(size: 11.5))
                                        .foregroundColor(hasWarn ? TuesdayTheme.ledColor(for: .eol, isStn: palette.isStn) : palette.textMuted)
                                        .lineLimit(1)
                                },
                                trailing: {
                                    MonospaceBadge(
                                        text: hit.categoryCode ?? clueKindBadge(hit.kind),
                                        color: accent,
                                        borderAlpha: 0
                                    )
                                }
                            )
                            .uiAction("pickGoldClue")
                        }
                    }
                    .uiSlot("gold-clue-suggestions")
                }

                if !quickPicks.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(quickPicks) { pick in
                                Button(action: { appendClue(pick) }) {
                                    HStack(spacing: 5) {
                                        Image(systemName: "plus")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(clueColor(kind: pick.kind, hasWarning: false))
                                        Text(pick.title)
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(palette.textPrimary)
                                    }
                                    .padding(.horizontal, 10)
                                    .frame(minHeight: 32)
                                    .background(palette.surface)
                                    .clipShape(Capsule())
                                    .overlay(Capsule().stroke(palette.border, lineWidth: 1))
                                }
                                .buttonStyle(.plain)
                                .uiAction("quickPickGoldClue")
                            }
                        }
                    }
                    .uiSlot("gold-quick-pick-chips")
                }
            }
        }
        .uiSlot("shared-hardware-clues")
    }

    private func commitTypedText(trimmed: String) {
        guard !trimmed.isEmpty else { return }
        let clue = GoldClueSuggestionRepository.shared.classifyFreeTextClue(trimmed)
        appendClue(clue)
        queryText = ""
    }

    private func appendClue(_ clue: GoldClueItem) {
        guard !selectedClues.contains(where: { $0.id == clue.id }) else { return }
        selectedClues.append(clue)
        onClueAdded(clue)
    }

    private func clueIcon(kind: GoldClueKind, hasWarning: Bool) -> String {
        if hasWarning { return "exclamationmark.triangle.fill" }
        switch kind {
        case .deviceType: return "square.grid.2x2.fill"
        case .brand: return "building.2.fill"
        case .model: return "checkmark.seal.fill"
        case .identifier: return "qrcode"
        case .freeText: return "tag.fill"
        }
    }

    private func clueColor(kind: GoldClueKind, hasWarning: Bool) -> Color {
        if hasWarning { return TuesdayTheme.ledColor(for: .eol, isStn: palette.isStn) }
        switch kind {
        case .deviceType: return palette.accentText
        case .brand: return TuesdayTheme.ledUpdateBlue
        case .model: return TuesdayTheme.ledColor(for: .ok, isStn: palette.isStn)
        case .identifier: return TuesdayTheme.ledColor(for: .eol, isStn: palette.isStn)
        case .freeText: return palette.textPrimary
        }
    }

    private func clueKindBadge(_ kind: GoldClueKind) -> String {
        switch kind {
        case .deviceType: return "TYPE"
        case .brand: return "BRAND"
        case .model: return "SKU"
        case .identifier: return "ID"
        case .freeText: return "CUSTOM"
        }
    }
}
