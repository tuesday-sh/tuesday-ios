import SwiftUI

public struct GoldHardwareCluesPicker: View {
    public let palette: BrandPalette
    @Binding public var queryText: String
    @Binding public var selectedClues: [GoldClueItem]
    public var onClueAdded: (GoldClueItem) -> Void = { _ in }
    public var onClueRemoved: (GoldClueItem) -> Void = { _ in }

    public init(
        palette: BrandPalette,
        queryText: Binding<String>,
        selectedClues: Binding<[GoldClueItem]>,
        onClueAdded: @escaping (GoldClueItem) -> Void = { _ in },
        onClueRemoved: @escaping (GoldClueItem) -> Void = { _ in }
    ) {
        self.palette = palette
        self._queryText = queryText
        self._selectedClues = selectedClues
        self.onClueAdded = onClueAdded
        self.onClueRemoved = onClueRemoved
    }

    public var body: some View {
        let trimmed = queryText.trimmingCharacters(in: .whitespacesAndNewlines)
        let suggestions: [GoldClueItem] = trimmed.isEmpty
            ? []
            : GoldClueSuggestionRepository.shared.querySuggestions(rawQuery: trimmed, selected: selectedClues, limit: 8)
        let quickPicks = GoldClueSuggestionRepository.shared.contextualQuickPicks(selectedClues, limit: 8)
            .filter { pick in !selectedClues.contains(where: { $0.id == pick.id }) }
        let warningClue = selectedClues.last(where: { !($0.warningNote ?? "").isEmpty })

        VStack(alignment: .leading, spacing: 10) {
            Text("SHARED HARDWARE CLUES (OFFLINE GOLD INDEX)")
                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                .foregroundColor(palette.accentText)

            HStack(spacing: 8) {
                TuesdayTextField(
                    text: $queryText,
                    label: "Brand, Type, Model, MAC, FCC or UPC",
                    placeholder: "e.g. Ubiquiti, UDM-Pro, 74:83:C2, 2AC7Z...",
                    palette: palette
                )
                .uiSlot("gold-clue-autocomplete")

                Button(action: {
                    guard !trimmed.isEmpty else { return }
                    let clue = suggestions.first ?? GoldClueSuggestionRepository.shared.classifyFreeTextClue(trimmed)
                    appendClue(clue)
                    queryText = ""
                }) {
                    Text("+ Add")
                        .font(.system(size: 12.5, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .frame(minHeight: 40)
                        .background(trimmed.isEmpty ? palette.borderStrong : palette.accent)
                        .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
                }
                .buttonStyle(.plain)
                .disabled(trimmed.isEmpty)
                .padding(.top, 18)
                .uiAction("addClue")
            }

            if !suggestions.isEmpty {
                SurfaceListContainer(palette: palette) {
                    ForEach(Array(suggestions.enumerated()), id: \.element.id) { idx, hit in
                        if idx > 0 { SurfaceListDivider(palette: palette) }
                        TuesdayListRow(
                            palette: palette,
                            title: hit.title,
                            onClick: {
                                appendClue(hit)
                                queryText = ""
                            },
                            leading: {
                                MonospaceBadge(text: hit.kind.rawValue, color: palette.accentText, borderAlpha: 0)
                            },
                            subtitle: {
                                Text(hit.subtitle)
                                    .font(.system(size: 11.5))
                                    .foregroundColor(palette.textMuted)
                            },
                            trailing: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(palette.accent)
                            }
                        )
                        .uiAction("pickGoldClue")
                    }
                }
                .uiSlot("gold-clue-suggestions")
            }

            if !quickPicks.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("QUICK PICKS")
                        .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                        .foregroundColor(palette.textMuted)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(quickPicks) { pick in
                                Button(action: { appendClue(pick) }) {
                                    Text("+ \(pick.chipLabel)")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(palette.textPrimary)
                                        .padding(.horizontal, 10)
                                        .frame(minHeight: 32)
                                        .background(palette.elevated)
                                        .clipShape(Capsule())
                                        .overlay(Capsule().stroke(palette.borderStrong, lineWidth: 1))
                                }
                                .buttonStyle(.plain)
                                .uiAction("quickPickGoldClue")
                            }
                        }
                    }
                }
                .uiSlot("gold-quick-pick-chips")
            }

            if !selectedClues.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(selectedClues) { clue in
                            RemovableAttachmentChip(
                                label: clue.chipLabel,
                                palette: palette,
                                onRemove: {
                                    selectedClues.removeAll { $0.id == clue.id }
                                    onClueRemoved(clue)
                                }
                            )
                        }
                    }
                }
                .uiSlot("selected-clue-chips")
            }

            if let note = warningClue?.warningNote {
                HStack(alignment: .top, spacing: 8) {
                    Text("⚠️").font(.system(size: 14))
                    Text(note)
                        .font(.system(size: 12))
                        .foregroundColor(TuesdayTheme.ledColor(for: .eol, isStn: palette.isStn))
                        .lineSpacing(3)
                }
                .padding(10)
                .background(TuesdayTheme.ledColor(for: .eol, isStn: palette.isStn).opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: TuesdayDimens.radiusControl))
            }
        }
        .uiSlot("shared-hardware-clues")
    }

    private func appendClue(_ clue: GoldClueItem) {
        guard !selectedClues.contains(where: { $0.id == clue.id }) else { return }
        selectedClues.append(clue)
        onClueAdded(clue)
    }
}
