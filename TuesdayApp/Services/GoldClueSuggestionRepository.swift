import Foundation

public enum GoldClueKind: String, Codable, Equatable, Hashable {
    case deviceType = "DEVICE_TYPE"
    case brand = "BRAND"
    case model = "MODEL"
    case identifier = "IDENTIFIER"
    case freeText = "FREE_TEXT"
}

public struct GoldClueItem: Identifiable, Codable, Equatable, Hashable {
    public let id: String
    public let kind: GoldClueKind
    public let typeId: String?
    public let title: String
    public let subtitle: String
    public let chipLabel: String
    public let vendor: String?
    public let model: String?
    public let categoryCode: String?
    public let canonicalPurl: String?
    public let macAddress: String?
    public let upc: String?
    public let fccId: String?
    public let warningNote: String?

    public init(
        id: String,
        kind: GoldClueKind,
        typeId: String? = nil,
        title: String,
        subtitle: String = "",
        chipLabel: String,
        vendor: String? = nil,
        model: String? = nil,
        categoryCode: String? = nil,
        canonicalPurl: String? = nil,
        macAddress: String? = nil,
        upc: String? = nil,
        fccId: String? = nil,
        warningNote: String? = nil
    ) {
        self.id = id
        self.kind = kind
        self.typeId = typeId
        self.title = title
        self.subtitle = subtitle
        self.chipLabel = chipLabel
        self.vendor = vendor
        self.model = model
        self.categoryCode = categoryCode
        self.canonicalPurl = canonicalPurl
        self.macAddress = macAddress
        self.upc = upc
        self.fccId = fccId
        self.warningNote = warningNote
    }
}

public struct GoldTypeEntry: Equatable {
    public let id: String
    public let label: String
    public let categoryCode: String
    public let aliases: [String]
    public let normLabel: String
}

public struct GoldBrandEntry: Equatable {
    public let name: String
    public let rank: Int
    public let count: Int
    public let cats: [String]
    public let aliases: [String]
    public let normName: String
}

public struct GoldModelEntry: Equatable {
    public let vendor: String
    public let model: String
    public let catNum: Int
    public let categoryCode: String
    public let upc: String
    public let fccId: String
    public let typeId: String
    public let normVendor: String
    public let normModel: String
}

public struct GoldFccGrantee: Equatable {
    public let grantee: String
    public let vendor: String
    public let catNum: Int
    public let typeFlag: String
    public let name: String

    public var categoryCode: String { "C\(catNum)" }
}

public final class GoldClueIndexData {
    public let etag: String
    public let datalakeVersion: String
    public let types: [GoldTypeEntry]
    public let brands: [GoldBrandEntry]
    public let models: [GoldModelEntry]
    public let fccGrantees: [String: GoldFccGrantee]
    public let ouiMap: [String: String]

    private let modelsByUpc: [String: [GoldModelEntry]]
    private let modelsByVendorNorm: [String: [GoldModelEntry]]

    public init(
        etag: String,
        datalakeVersion: String,
        types: [GoldTypeEntry],
        brands: [GoldBrandEntry],
        models: [GoldModelEntry],
        fccGrantees: [String: GoldFccGrantee],
        ouiMap: [String: String]
    ) {
        self.etag = etag
        self.datalakeVersion = datalakeVersion
        self.types = types
        self.brands = brands
        self.models = models
        self.fccGrantees = fccGrantees
        self.ouiMap = ouiMap

        var upcIdx: [String: [GoldModelEntry]] = [:]
        var vendorIdx: [String: [GoldModelEntry]] = [:]
        for entry in models {
            if !entry.upc.isEmpty {
                upcIdx[entry.upc, default: []].append(entry)
            }
            vendorIdx[entry.normVendor, default: []].append(entry)
        }
        self.modelsByUpc = upcIdx
        self.modelsByVendorNorm = vendorIdx
    }

    public static func normalizeAlnum(_ raw: String) -> String {
        String(raw.lowercased().unicodeScalars.filter { CharacterSet.alphanumerics.contains($0) })
    }

    public static func normalizeHex(_ raw: String) -> String {
        let hexChars = CharacterSet(charactersIn: "0123456789ABCDEFabcdef")
        return String(raw.uppercased().unicodeScalars.filter { hexChars.contains($0) })
    }

    public static func slugify(_ raw: String) -> String {
        let lower = raw.lowercased()
        var out = ""
        var prevDash = false
        for scalar in lower.unicodeScalars {
            if CharacterSet.alphanumerics.contains(scalar) {
                out.unicodeScalars.append(scalar)
                prevDash = false
            } else if !prevDash && !out.isEmpty {
                out.append("-")
                prevDash = true
            }
        }
        return out.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }

    public static func parseGzipData(_ gzipData: Data) throws -> GoldClueIndexData {
        let jsonData = try GzipDecoder.decompress(gzipData)
        return try parseUncompressedJson(jsonData)
    }

    public static func parseUncompressedJson(_ data: Data) throws -> GoldClueIndexData {
        guard let root = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            throw NSError(domain: "GoldClueIndexData", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON root in gold_clue_index.gci"])
        }

        let etag = (root["etag"] as? String) ?? "unknown"
        let version = (root["datalakeVersion"] as? String) ?? "2.0.0"

        let rawTypes = (root["types"] as? [[String: Any]]) ?? []
        let types: [GoldTypeEntry] = rawTypes.compactMap { obj in
            guard let id = obj["id"] as? String, let label = obj["label"] as? String else { return nil }
            let cat = (obj["cat"] as? String) ?? "C8"
            let aliases = (obj["aliases"] as? [String]) ?? []
            return GoldTypeEntry(
                id: id,
                label: label,
                categoryCode: cat,
                aliases: aliases,
                normLabel: normalizeAlnum(label)
            )
        }

        let rawBrands = (root["brands"] as? [[String: Any]]) ?? []
        let brands: [GoldBrandEntry] = rawBrands.compactMap { obj in
            guard let name = obj["name"] as? String else { return nil }
            let rank = (obj["rank"] as? Int) ?? 999
            let count = (obj["count"] as? Int) ?? 0
            let cats = (obj["cats"] as? [String]) ?? []
            let aliases = (obj["aliases"] as? [String]) ?? []
            return GoldBrandEntry(
                name: name,
                rank: rank,
                count: count,
                cats: cats,
                aliases: aliases,
                normName: normalizeAlnum(name)
            )
        }.sorted { $0.rank < $1.rank }

        let brandRankMap: [String: Int] = Dictionary(uniqueKeysWithValues: brands.map { ($0.name.lowercased(), $0.rank) })

        let rawHw = (root["hw"] as? [String: [[Any]]]) ?? [:]
        var models: [GoldModelEntry] = []
        models.reserveCapacity(12_000)
        for (vendor, tuples) in rawHw {
            let normV = normalizeAlnum(vendor)
            for row in tuples {
                guard row.count >= 5, let model = row[0] as? String else { continue }
                let catNum = (row[1] as? Int) ?? 8
                let upc = (row[2] as? String) ?? ""
                let fccId = (row[3] as? String) ?? ""
                let typeId = (row[4] as? String) ?? ""
                models.append(
                    GoldModelEntry(
                        vendor: vendor,
                        model: model,
                        catNum: catNum,
                        categoryCode: "C\(catNum)",
                        upc: upc,
                        fccId: fccId,
                        typeId: typeId,
                        normVendor: normV,
                        normModel: normalizeAlnum(model)
                    )
                )
            }
        }
        models.sort {
            let lr = brandRankMap[$0.vendor.lowercased()] ?? 9999
            let rr = brandRankMap[$1.vendor.lowercased()] ?? 9999
            if lr != rr { return lr < rr }
            if $0.vendor != $1.vendor { return $0.vendor < $1.vendor }
            return $0.model < $1.model
        }

        let rawFcc = (root["fcc"] as? [String: [String: Any]]) ?? [:]
        var fccMap: [String: GoldFccGrantee] = [:]
        fccMap.reserveCapacity(rawFcc.count)
        for (grantee, obj) in rawFcc {
            let vendor = (obj["v"] as? String) ?? ""
            let cat = (obj["c"] as? Int) ?? 8
            let typeFlag = (obj["t"] as? String) ?? "H"
            let name = (obj["n"] as? String) ?? vendor
            fccMap[grantee.uppercased()] = GoldFccGrantee(
                grantee: grantee.uppercased(),
                vendor: vendor,
                catNum: cat,
                typeFlag: typeFlag,
                name: name
            )
        }

        let rawOui = (root["oui"] as? [String: String]) ?? [:]
        var ouiNormalized: [String: String] = [:]
        ouiNormalized.reserveCapacity(rawOui.count)
        for (prefix, vendor) in rawOui {
            ouiNormalized[prefix.uppercased()] = vendor
        }

        return GoldClueIndexData(
            etag: etag,
            datalakeVersion: version,
            types: types,
            brands: brands,
            models: models,
            fccGrantees: fccMap,
            ouiMap: ouiNormalized
        )
    }

    public func classifyFreeTextClue(_ rawQuery: String) -> GoldClueItem {
        let trimmed = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if let firstHit = querySuggestions(rawQuery: trimmed, selected: [], limit: 1).first,
           firstHit.chipLabel.caseInsensitiveCompare(trimmed) == .orderedSame {
            return firstHit
        }
        return GoldClueItem(
            id: "free-\(Self.normalizeAlnum(trimmed))",
            kind: .freeText,
            title: trimmed,
            subtitle: "Custom hardware clue",
            chipLabel: trimmed
        )
    }

    public func querySuggestions(
        rawQuery: String,
        selected: [GoldClueItem] = [],
        limit: Int = 18
    ) -> [GoldClueItem] {
        let trimmed = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return contextualQuickPicks(selected, limit: limit)
        }

        let lower = trimmed.lowercased()
        let normQ = Self.normalizeAlnum(trimmed)
        let selectedBrand = selected.last(where: { $0.kind == .brand })
        let selectedType = selected.last(where: { $0.kind == .deviceType })

        var results: [GoldClueItem] = []
        var seenIds = Set<String>()

        func appendUnique(_ item: GoldClueItem) {
            guard seenIds.insert(item.id).inserted else { return }
            results.append(item)
        }

        // 1. Exact/prefix UPC retail barcode match (numeric >= 6 digits)
        let digitsOnly = String(trimmed.unicodeScalars.filter { CharacterSet.decimalDigits.contains($0) })
        if digitsOnly.count >= 6 && digitsOnly.count == trimmed.count {
            let candidateUpcs = [digitsOnly, digitsOnly.count == 13 && digitsOnly.hasPrefix("0") ? String(digitsOnly.dropFirst()) : digitsOnly]
            for code in candidateUpcs {
                for entry in modelsByUpc[code] ?? [] {
                    appendUnique(modelClue(from: entry))
                }
            }
            if results.count >= limit { return Array(results.prefix(limit)) }
        }

        // 2. MAC Address / OUI Prefix lookup
        let hexClean = Self.normalizeHex(trimmed)
        let looksLikeMac = hexClean.count >= 6 && (trimmed.contains(":") || trimmed.contains("-") || hexClean.count == 6 || hexClean.count == 12)
        if looksLikeMac {
            let ouiPrefix = String(hexClean.prefix(6))
            if let vendor = ouiMap[ouiPrefix] {
                appendUnique(
                    GoldClueItem(
                        id: "oui-\(ouiPrefix)",
                        kind: .identifier,
                        title: "\(vendor) (MAC OUI \(ouiPrefix))",
                        subtitle: "IEEE OUI Hardware Manufacturer Match",
                        chipLabel: vendor,
                        vendor: vendor,
                        macAddress: trimmed
                    )
                )
            }
        }

        // 3. FCC ID lookup (either "GRANTEE-PRODUCT" or 3-5 char grantee token)
        if let fccHit = matchFccGrantee(trimmed) {
            appendUnique(fccHit)
        }

        // 4. Device Type clues
        for entry in types {
            let aliasMatch = entry.aliases.contains { $0.lowercased() == lower || $0.lowercased().contains(lower) }
            if entry.id == lower || entry.label.lowercased().contains(lower) || aliasMatch {
                appendUnique(typeClue(from: entry))
            }
        }

        // 5. Brand clues (match full normalized name, prefix, or whole word starts — avoids substring noise like manufactuRING)
        for brand in brands {
            let wordMatches = brand.name.lowercased()
                .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
                .contains { $0.hasPrefix(lower) }
            let normMatches = brand.normName == normQ || (normQ.count >= 2 && brand.normName.hasPrefix(normQ))
            let aliasMatches = brand.aliases.contains {
                let al = $0.lowercased()
                return al == lower || al.hasPrefix(lower) || al.split(separator: " ").contains { $0.hasPrefix(lower) }
            }
            if normMatches || wordMatches || aliasMatches {
                appendUnique(brandClue(from: brand))
            }
            if results.count >= limit { break }
        }

        // 6. Specific Gold Model SKUs
        let searchPool: [GoldModelEntry]
        if let selectedBrand, let v = selectedBrand.vendor {
            searchPool = modelsByVendorNorm[Self.normalizeAlnum(v)] ?? models
        } else {
            searchPool = models
        }

        let thinClientTokens = ["t520", "t620", "t630", "elitedesk", "prodesk", "optiplex", "thinkcentre"]
        var exactMatches: [GoldModelEntry] = []
        var prefixMatches: [GoldModelEntry] = []
        var substringMatches: [GoldModelEntry] = []

        let qTokens = lower
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map(String.init)
            .filter { !$0.isEmpty }

        for entry in searchPool {
            if let t = selectedType?.typeId, !t.isEmpty, entry.typeId != t {
                continue
            }
            if selectedType?.typeId == "printer" && thinClientTokens.contains(where: { entry.normModel.contains($0) }) {
                continue
            }
            let combinedNorm = entry.normVendor + entry.normModel
            let vendorWords = entry.vendor.lowercased().split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            let modelWords = entry.model.lowercased().split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            let allWords = vendorWords + modelWords

            if entry.normModel == normQ || combinedNorm == normQ {
                exactMatches.append(entry)
            } else if entry.normModel.hasPrefix(normQ) || modelWords.contains(where: { $0.hasPrefix(lower) }) {
                prefixMatches.append(entry)
            } else if qTokens.count >= 2 && qTokens.allSatisfy({ tok in allWords.contains(where: { $0.hasPrefix(tok) }) || entry.normModel.contains(tok) }) {
                prefixMatches.append(entry)
            } else if qTokens.count == 1 && vendorWords.contains(where: { $0.hasPrefix(lower) }) {
                prefixMatches.append(entry)
            } else if normQ.count >= 3 && (entry.normModel.contains(normQ) || entry.model.lowercased().contains(lower)) {
                substringMatches.append(entry)
            }
        }

        for entry in (exactMatches + prefixMatches + substringMatches) {
            appendUnique(modelClue(from: entry))
            if results.count >= limit { break }
        }

        return Array(results.prefix(limit))
    }

    public func contextualQuickPicks(
        _ selected: [GoldClueItem],
        limit: Int = 10
    ) -> [GoldClueItem] {
        let selectedType = selected.last(where: { $0.kind == .deviceType })
        let selectedBrand = selected.last(where: { $0.kind == .brand })

        if selectedType == nil && selectedBrand == nil {
            let priorityTypeIds = ["router", "ap", "switch", "nas", "camera", "doorbell", "printer", "modem", "thermostat", "ups"]
            var ordered: [GoldTypeEntry] = []
            for id in priorityTypeIds {
                if let match = types.first(where: { $0.id == id }) {
                    ordered.append(match)
                }
            }
            for t in types where !ordered.contains(where: { $0.id == t.id }) {
                ordered.append(t)
            }
            return ordered.prefix(limit).map(typeClue(from:))
        }

        if let selectedType, selectedBrand == nil {
            let matchingModels = models.filter { $0.typeId == selectedType.typeId }
            var vendorCounts: [String: Int] = [:]
            for m in matchingModels {
                vendorCounts[m.vendor, default: 0] += 1
            }
            let sortedBrands = brands.filter { (vendorCounts[$0.name] ?? 0) > 0 }
                .sorted { lhs, rhs in
                    let lc = vendorCounts[lhs.name] ?? 0
                    let rc = vendorCounts[rhs.name] ?? 0
                    if lc != rc { return lc > rc }
                    return lhs.rank < rhs.rank
                }
            return sortedBrands.prefix(limit).map(brandClue(from:))
        }

        if let selectedBrand, let vendor = selectedBrand.vendor {
            let thinClientTokens = ["t520", "t620", "t630", "elitedesk", "prodesk", "optiplex", "thinkcentre"]
            let vendorModels = modelsByVendorNorm[Self.normalizeAlnum(vendor)] ?? []
            let filtered = vendorModels.filter { entry in
                if let t = selectedType?.typeId, !t.isEmpty {
                    guard entry.typeId == t else { return false }
                }
                if selectedType?.typeId == "printer" && thinClientTokens.contains(where: { entry.normModel.contains($0) }) {
                    return false
                }
                return true
            }
            let pool = filtered.isEmpty ? vendorModels : filtered
            return pool.prefix(limit).map(modelClue(from:))
        }

        return []
    }

    public func resolveLocalDiscoveryResult(
        selected: [GoldClueItem],
        accumulatedIdentifiers: ExtractedDeviceIdentifiers,
        manualDeviceName: String = ""
    ) -> GeminiDiscoveryTurnResult? {
        let modelClue = selected.last(where: { $0.kind == .model })
        let brandClue = selected.last(where: { $0.kind == .brand })
        let typeClue = selected.last(where: { $0.kind == .deviceType })

        let cleanHost = manualDeviceName.trimmingCharacters(in: .whitespacesAndNewlines)

        // 1. Exact Model clue or UPC match -> 0-turn 99% resolution
        var exactEntry: GoldModelEntry?
        if let modelClue, let v = modelClue.vendor, let m = modelClue.model {
            let vNorm = Self.normalizeAlnum(v)
            let mNorm = Self.normalizeAlnum(m)
            exactEntry = (modelsByVendorNorm[vNorm] ?? []).first(where: { $0.normModel == mNorm })
                ?? GoldModelEntry(
                    vendor: v,
                    model: m,
                    catNum: Int(modelClue.categoryCode?.replacingOccurrences(of: "C", with: "") ?? "") ?? 8,
                    categoryCode: modelClue.categoryCode ?? "C6",
                    upc: modelClue.upc ?? "",
                    fccId: modelClue.fccId ?? "",
                    typeId: modelClue.typeId ?? "",
                    normVendor: vNorm,
                    normModel: mNorm
                )
        } else if let barcode = accumulatedIdentifiers.barcode, !barcode.isEmpty {
            let digits = String(barcode.unicodeScalars.filter { CharacterSet.decimalDigits.contains($0) })
            let upcCandidates = [digits, digits.count == 13 && digits.hasPrefix("0") ? String(digits.dropFirst()) : digits]
            exactEntry = upcCandidates.compactMap { modelsByUpc[$0]?.first }.first
        } else if let typedModel = accumulatedIdentifiers.modelNumber, !typedModel.isEmpty {
            let normM = Self.normalizeAlnum(typedModel)
            if let bv = brandClue?.vendor {
                exactEntry = (modelsByVendorNorm[Self.normalizeAlnum(bv)] ?? []).first(where: { $0.normModel == normM })
            } else {
                let hits = models.filter { $0.normModel == normM }
                if hits.count == 1 { exactEntry = hits.first }
            }
        }

        if let entry = exactEntry {
            let purl = "pkg:generic/\(Self.slugify(entry.vendor))/\(Self.slugify(entry.model))"
            let typeLabel = types.first(where: { $0.id == entry.typeId })?.label ?? "Network Hardware"
            let candidate = DeviceCandidateMatch(
                manufacturer: entry.vendor,
                modelNumber: entry.model,
                displayName: "\(entry.vendor) \(entry.model)",
                deviceCategory: typeLabel,
                confidencePercent: 99,
                reasoning: "Verified directly against offline Gold Catalog index (0 cloud LLM turns).",
                suggestedHostname: cleanHost.isEmpty ? Self.slugify("\(entry.vendor)-\(entry.model)") : cleanHost,
                suggestedOsDetails: "\(entry.vendor) Embedded Firmware",
                suggestedPackageManager: "firmware",
                goldAlignment: GoldAlignmentInfo(
                    aligned: true,
                    inferredPurl: purl,
                    catalogItemId: "gold-\(Self.slugify(entry.vendor))-\(Self.slugify(entry.model))",
                    statusLabel: "GOLD ALIGNED"
                )
            )
            return GeminiDiscoveryTurnResult(
                visualSummary: "Instant offline Gold Catalog match: \(entry.vendor) \(entry.model)",
                isNetworkedDevice: true,
                nextNarrowingQuestion: "Gold Catalog exact match verified. Review and tap Add Device.",
                recommendedClueTypes: [],
                extractedIdentifiers: accumulatedIdentifiers,
                candidates: [candidate],
                usedLiveGeminiApi: false,
                debugTrace: "Offline Gold 0-turn SKU match"
            )
        }

        // 2. Narrowed Type + Brand -> resolve matching candidates locally
        if let typeClue, let brandClue, let vendor = brandClue.vendor, let tId = typeClue.typeId {
            let matches = (modelsByVendorNorm[Self.normalizeAlnum(vendor)] ?? []).filter { $0.typeId == tId }
            if !matches.isEmpty {
                let candidates: [DeviceCandidateMatch] = matches.prefix(5).map { entry in
                    let purl = "pkg:generic/\(Self.slugify(entry.vendor))/\(Self.slugify(entry.model))"
                    return DeviceCandidateMatch(
                        manufacturer: entry.vendor,
                        modelNumber: entry.model,
                        displayName: "\(entry.vendor) \(entry.model)",
                        deviceCategory: typeClue.title,
                        confidencePercent: matches.count == 1 ? 94 : 82,
                        reasoning: "Matched \(vendor) \(typeClue.title) in offline Gold Catalog.",
                        suggestedHostname: cleanHost.isEmpty ? Self.slugify("\(entry.vendor)-\(entry.model)") : cleanHost,
                        suggestedOsDetails: "\(entry.vendor) Embedded Firmware",
                        suggestedPackageManager: "firmware",
                        goldAlignment: GoldAlignmentInfo(
                            aligned: true,
                            inferredPurl: purl,
                            catalogItemId: "gold-\(Self.slugify(entry.vendor))-\(Self.slugify(entry.model))",
                            statusLabel: "GOLD ALIGNED"
                        )
                    )
                }
                return GeminiDiscoveryTurnResult(
                    visualSummary: "Narrowed \(matches.count) \(vendor) \(typeClue.title) model(s) offline.",
                    isNetworkedDevice: true,
                    nextNarrowingQuestion: "Pick the exact \(vendor) model below or scan a barcode to narrow further.",
                    recommendedClueTypes: ["Barcode", "Model"],
                    extractedIdentifiers: accumulatedIdentifiers,
                    candidates: candidates,
                    usedLiveGeminiApi: false,
                    debugTrace: "Offline Gold Type+Brand narrowing"
                )
            }
        }

        // Unknown SKU or free text with no deterministic Gold match -> return nil so caller queries backend AI
        return nil
    }

    public func reconcileDiscoveryResult(_ turn: GeminiDiscoveryTurnResult) -> GeminiDiscoveryTurnResult {
        var out = turn
        let usbOnlyKeywords = ["usb-only", "usb only", "no wi-fi", "no wifi", "no ethernet"]
        let falseIrKeywords = ["ir remote", "infrared"]

        let combinedOutOfScope = ((out.outOfScopeReason ?? "") + " " + out.visualSummary).lowercased()
        let isExplicitUsbOnly = usbOnlyKeywords.contains(where: { combinedOutOfScope.contains($0) })

        var updatedCandidates: [DeviceCandidateMatch] = []
        var reconciledAnyGold = false

        for var cand in out.candidates {
            // Strip position bracket noise e.g. "[Center] Sharp MX-M453N..."
            cand.displayName = cand.displayName
                .replacingOccurrences(of: #"^\[(Center|Left|Right|Top|Bottom)\]\s*"#, with: "", options: .regularExpression)

            let candidateReasoningLower = cand.reasoning.lowercased()
            let candidateUsbOnly = isExplicitUsbOnly || usbOnlyKeywords.contains(where: { candidateReasoningLower.contains($0) })

            if candidateUsbOnly {
                cand.goldAlignment = GoldAlignmentInfo(
                    aligned: false,
                    inferredPurl: cand.goldAlignment?.inferredPurl,
                    statusLabel: "UNALIGNED RAW MATCH"
                )
                updatedCandidates.append(cand)
                continue
            }

            let vNorm = Self.normalizeAlnum(cand.manufacturer)
            let mNorm = Self.normalizeAlnum(cand.modelNumber)
            let directMatch = (modelsByVendorNorm[vNorm] ?? []).first(where: {
                $0.normModel == mNorm || (!mNorm.isEmpty && ($0.normModel.contains(mNorm) || mNorm.contains($0.normModel)))
            }) ?? models.first(where: { !mNorm.isEmpty && $0.normModel == mNorm })

            if let entry = directMatch {
                reconciledAnyGold = true
                let purl = "pkg:generic/\(Self.slugify(entry.vendor))/\(Self.slugify(entry.model))"
                let typeLabel = types.first(where: { $0.id == entry.typeId })?.label ?? cand.deviceCategory
                cand.manufacturer = entry.vendor
                cand.modelNumber = entry.model
                cand.deviceCategory = typeLabel

                if falseIrKeywords.contains(where: { cand.displayName.lowercased().contains($0) }) {
                    cand.displayName = "\(entry.vendor) \(entry.model) (\(typeLabel))"
                }
                if falseIrKeywords.contains(where: { cand.reasoning.lowercased().contains($0) }) {
                    cand.reasoning = "Confirmed networked \(entry.vendor) \(entry.model) (\(typeLabel)) in Gold Catalog."
                }
                cand.goldAlignment = GoldAlignmentInfo(
                    aligned: true,
                    inferredPurl: purl,
                    catalogItemId: "gold-\(Self.slugify(entry.vendor))-\(Self.slugify(entry.model))",
                    statusLabel: "GOLD ALIGNED"
                )
            }
            updatedCandidates.append(cand)
        }

        out.candidates = updatedCandidates

        if reconciledAnyGold && !isExplicitUsbOnly {
            out.isNetworkedDevice = true
            out.outOfScopeReason = nil
            if out.visualSummary.lowercased().contains("small square") || falseIrKeywords.contains(where: { out.visualSummary.lowercased().contains($0) }) {
                if let top = updatedCandidates.first {
                    out.visualSummary = "\(top.manufacturer) \(top.modelNumber) (\(top.deviceCategory)) verified against Gold Catalog."
                }
            }
        }

        return out
    }

    private func matchFccGrantee(_ rawQuery: String) -> GoldClueItem? {
        let cleaned = rawQuery.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return nil }
        let candidatePrefixes: [String]
        if let dashIdx = cleaned.firstIndex(of: "-") {
            let beforeDash = String(cleaned[..<dashIdx])
            candidatePrefixes = [beforeDash, String(beforeDash.prefix(3)), String(beforeDash.prefix(5))]
        } else if cleaned.count >= 3 && cleaned.count <= 14 {
            candidatePrefixes = [cleaned, String(cleaned.prefix(5)), String(cleaned.prefix(3))]
        } else {
            return nil
        }

        for prefix in candidatePrefixes {
            if let grantee = fccGrantees[prefix] {
                let isRadioModule = grantee.typeFlag == "R"
                return GoldClueItem(
                    id: "fcc-\(grantee.grantee)-\(Self.normalizeAlnum(cleaned))",
                    kind: .identifier,
                    title: "\(grantee.vendor) (FCC \(grantee.grantee))",
                    subtitle: grantee.name,
                    chipLabel: "FCC \(cleaned)",
                    vendor: grantee.vendor,
                    categoryCode: grantee.categoryCode,
                    fccId: cleaned,
                    warningNote: isRadioModule
                        ? "FCC Grantee \(grantee.grantee) is a radio Wi-Fi/BLE module inside many appliances (\(grantee.name)). Enter the appliance brand/model on the front chassis for an exact match."
                        : nil
                )
            }
        }
        return nil
    }

    private func typeClue(from entry: GoldTypeEntry) -> GoldClueItem {
        GoldClueItem(
            id: "type-\(entry.id)",
            kind: .deviceType,
            typeId: entry.id,
            title: entry.label,
            subtitle: "\(entry.categoryCode) Hardware Category",
            chipLabel: entry.label,
            categoryCode: entry.categoryCode
        )
    }

    private func brandClue(from entry: GoldBrandEntry) -> GoldClueItem {
        GoldClueItem(
            id: "brand-\(entry.normName)",
            kind: .brand,
            title: entry.name,
            subtitle: "\(entry.count) Gold Catalog SKU(s)",
            chipLabel: entry.name,
            vendor: entry.name,
            categoryCode: entry.cats.first
        )
    }

    private func modelClue(from entry: GoldModelEntry) -> GoldClueItem {
        let typeLabel = types.first(where: { $0.id == entry.typeId })?.label ?? entry.categoryCode
        return GoldClueItem(
            id: "model-\(entry.normVendor)-\(entry.normModel)",
            kind: .model,
            typeId: entry.typeId,
            title: "\(entry.vendor) \(entry.model)",
            subtitle: "\(typeLabel) • \(entry.categoryCode)",
            chipLabel: "\(entry.vendor) \(entry.model)",
            vendor: entry.vendor,
            model: entry.model,
            categoryCode: entry.categoryCode,
            canonicalPurl: "pkg:generic/\(Self.slugify(entry.vendor))/\(Self.slugify(entry.model))",
            upc: entry.upc.isEmpty ? nil : entry.upc,
            fccId: entry.fccId.isEmpty ? nil : entry.fccId
        )
    }
}

public final class GoldClueSuggestionRepository {
    public static let shared = GoldClueSuggestionRepository()

    private let lock = NSLock()
    private var cachedIndex: GoldClueIndexData?
    private let cacheFileName = "gold_clue_index_cache.gci"

    private init() {}

    public var index: GoldClueIndexData {
        lock.lock()
        if let existing = cachedIndex {
            lock.unlock()
            return existing
        }
        lock.unlock()

        let loaded = loadBestAvailableIndex()
        lock.lock()
        cachedIndex = loaded
        lock.unlock()
        return loaded
    }

    public func preload() {
        _ = index
    }

    public func querySuggestions(
        rawQuery: String,
        selected: [GoldClueItem] = [],
        limit: Int = 18
    ) -> [GoldClueItem] {
        index.querySuggestions(rawQuery: rawQuery, selected: selected, limit: limit)
    }

    public func contextualQuickPicks(
        _ selected: [GoldClueItem],
        limit: Int = 10
    ) -> [GoldClueItem] {
        index.contextualQuickPicks(selected, limit: limit)
    }

    public func classifyFreeTextClue(_ rawQuery: String) -> GoldClueItem {
        index.classifyFreeTextClue(rawQuery)
    }

    public func resolveLocalDiscoveryResult(
        selected: [GoldClueItem],
        accumulatedIdentifiers: ExtractedDeviceIdentifiers,
        manualDeviceName: String = ""
    ) -> GeminiDiscoveryTurnResult? {
        index.resolveLocalDiscoveryResult(
            selected: selected,
            accumulatedIdentifiers: accumulatedIdentifiers,
            manualDeviceName: manualDeviceName
        )
    }

    public func reconcileDiscoveryResult(_ turn: GeminiDiscoveryTurnResult) -> GeminiDiscoveryTurnResult {
        index.reconcileDiscoveryResult(turn)
    }

    /// Background ETag-conditional refresh against GET /api/v1/catalog/clue-index.
    public func refreshFromServerIfNeeded(baseUrl: String) async {
        let trimmed = baseUrl.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: "\(trimmed)/api/v1/catalog/clue-index") else { return }

        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.setValue("ios", forHTTPHeaderField: "X-Tuesday-Client-Platform")
        let currentEtag = index.etag
        if !currentEtag.isEmpty && currentEtag != "empty" {
            request.setValue(currentEtag, forHTTPHeaderField: "If-None-Match")
        }

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse,
              http.statusCode == 200,
              !data.isEmpty else {
            return
        }

        guard let parsed = try? GoldClueIndexData.parseGzipData(data) else { return }
        saveCacheFile(data)
        setCachedIndex(parsed)
    }

    private func setCachedIndex(_ parsed: GoldClueIndexData) {
        lock.lock()
        cachedIndex = parsed
        lock.unlock()
    }

    private func loadBestAvailableIndex() -> GoldClueIndexData {
        if let cacheUrl = cachedIndexUrl(),
           let data = try? Data(contentsOf: cacheUrl),
           let parsed = try? GoldClueIndexData.parseGzipData(data) {
            return parsed
        }
        if let bundleUrl = Bundle.main.url(forResource: "gold_clue_index", withExtension: "gci"),
           let data = try? Data(contentsOf: bundleUrl),
           let parsed = try? GoldClueIndexData.parseGzipData(data) {
            return parsed
        }
        return GoldClueIndexData(
            etag: "empty",
            datalakeVersion: "0.0.0",
            types: [],
            brands: [],
            models: [],
            fccGrantees: [:],
            ouiMap: [:]
        )
    }

    private func cachedIndexUrl() -> URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("tuesday", isDirectory: true)
            .appendingPathComponent(cacheFileName)
    }

    private func saveCacheFile(_ data: Data) {
        guard let url = cachedIndexUrl() else { return }
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: url, options: .atomic)
    }
}
