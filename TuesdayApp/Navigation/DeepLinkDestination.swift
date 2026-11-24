import Foundation

/// Deep-link navigation targets for the `tuesday://` URL scheme.
/// Matches Android's `DeepLinkDestination` routing contract across tabs, modals, and demo states.
public enum DeepLinkDestination: Equatable {
    case tab(String)
    case device(deviceId: String)
    case addDevice(
        mode: String? = nil,
        synthPreset: String? = nil,
        clueQuery: String? = nil,
        cluesCsv: String? = nil,
        autoSearch: Bool = false
    )
    case hacsSettings
    case networkPicker
    case upgradePrompt(source: String = "network", sku: String? = nil)
    case referenceGuide
    case seedFleet(count: Int)
    case toggleFlavor
    case setFlavor(AppBrandFlavor)
    case resetDemo
    case timelineAction(scenario: String? = nil, modal: String? = nil)
    case triggerMockPatchTuesday
    case setApiEndpoint(String)
    case visionDebug(Bool)

    public static func fromUri(_ uriString: String?) -> DeepLinkDestination? {
        guard let uriString else { return nil }
        return parse(uriString)
    }

    public static func parse(_ urlString: String) -> DeepLinkDestination? {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let url = URL(string: trimmed) else {
            return nil
        }
        return parse(url)
    }

    public static func parse(_ url: URL) -> DeepLinkDestination? {
        guard let scheme = url.scheme?.lowercased(), scheme == "tuesday" else {
            return nil
        }

        let host = (url.host ?? "").lowercased()
        guard !host.isEmpty else { return nil }
        let pathSegments = url.pathComponents.filter { $0 != "/" && !$0.isEmpty }
        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []

        func query(_ name: String) -> String? {
            queryItems.first(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame })?.value
        }

        switch host {
        case "tab":
            let target = (pathSegments.first ?? "status").lowercased()
            return .tab(normalizeTabSlug(target))

        case "status", "home", "fleet", "bulletins", "alerts", "checkup", "account-dev", "settings":
            return .tab(normalizeTabSlug(host))

        case "account":
            let sub = pathSegments.first?.lowercased()
            if sub == "dev" { return .tab("account-dev") }
            if sub == "plan" { return .upgradePrompt(source: "account", sku: nil) }
            return .tab("account")

        case "timeline", "lifespan", "swimlane":
            let modalQuery = query("modal")?.lowercased().nilIfBlank
            if let sub = pathSegments.first?.lowercased() {
                switch sub {
                case "decommissioned", "retired", "zombie", "runway", "standard":
                    let subModal = pathSegments.dropFirst().first?.lowercased() ?? modalQuery
                    return .timelineAction(scenario: sub, modal: subModal)
                case "checkin", "check-in", "status", "update-status":
                    return .timelineAction(scenario: nil, modal: sub)
                default:
                    break
                }
            }
            if let modalQuery {
                return .timelineAction(scenario: nil, modal: modalQuery)
            }
            return .tab("timeline")

        case "device", "inspect":
            guard let id = pathSegments.first, !id.isEmpty else { return nil }
            return .device(deviceId: id)

        case "add-device":
            let mode = query("mode")?.nilIfBlank
            let synth = query("synth")?.nilIfBlank
            let q = (query("query") ?? query("q"))?.nilIfBlank
            let clues = query("clues")?.nilIfBlank
            let autoFlag = query("autosearch")?.lowercased()
            let autoSearch = (autoFlag == "true" || autoFlag == "1" || autoFlag == "yes")
            return .addDevice(
                mode: mode,
                synthPreset: synth,
                clueQuery: q,
                cluesCsv: clues,
                autoSearch: autoSearch
            )

        case "synth":
            let preset = pathSegments.first?.lowercased() ?? "barcode"
            if preset == "barcode" {
                return .addDevice(mode: "scan", synthPreset: "barcode-udm-pro", autoSearch: false)
            }
            return .addDevice(mode: "photo", synthPreset: preset, autoSearch: false)

        case "hacs":
            return .hacsSettings

        case "networks", "network-picker", "join-site":
            return .networkPicker

        case "upgrade", "paywall":
            let seg = pathSegments.first?.lowercased()
            let source = query("source")?.lowercased().nilIfBlank ?? "modal"
            let explicitSku = query("sku")?.nilIfBlank
            let skuFromSeg: String? = {
                switch seg {
                case "monthly": return TuesdayStoreKitManager.skuProTier1Monthly
                case "annual": return TuesdayStoreKitManager.skuProTier1Annual
                default: return nil
                }
            }()
            return .upgradePrompt(source: source, sku: explicitSku ?? skuFromSeg)

        case "reference", "reference-guide":
            return .referenceGuide

        case "seed":
            guard let rawCount = pathSegments.first, let count = Int(rawCount) else {
                return .seedFleet(count: 12)
            }
            return .seedFleet(count: max(0, count))

        case "flavor":
            let arg = pathSegments.first?.lowercased()
            switch arg {
            case "home", "stn", "surething":
                return .setFlavor(.sureThingHome)
            case "pro", "tuesday":
                return .setFlavor(.tuesdayPro)
            default:
                return .toggleFlavor
            }

        case "toggle-flavor":
            return .toggleFlavor

        case "reset", "reset-demo":
            return .resetDemo

        case "patch-tuesday":
            return .triggerMockPatchTuesday

        case "api-endpoint":
            let target = pathSegments.first?.lowercased() ?? "prod"
            switch target {
            case "local", "dev", "tailscale": return .setApiEndpoint(ApiEndpointPreset.localDev.url)
            default: return .setApiEndpoint(ApiEndpointPreset.prodGcp.url)
            }

        case "vision-debug":
            let flag = pathSegments.first?.lowercased() ?? "on"
            return .visionDebug(flag != "off" && flag != "false" && flag != "0")

        default:
            return nil
        }
    }

    private static func normalizeTabSlug(_ raw: String) -> String {
        switch raw.lowercased() {
        case "home", "fleet": return "status"
        case "alerts": return "bulletins"
        case "settings": return "account"
        default: return raw.lowercased()
        }
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
