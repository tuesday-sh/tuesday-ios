import SwiftUI

/// 3-Way Web-to-Native Semantic UI Attribution Contract (`web-native-ui-sync` skill).
///
/// Maps directly to:
///  - Web:     `data-ui-component`, `data-ui-slot`, `data-ui-action`, `data-ui-state`
///  - Android: `Modifier.uiComponent(...)`, `Modifier.uiSlot(...)`, `Modifier.uiAction(...)`
///  - iOS:     `.uiComponent(...)`, `.uiSlot(...)`, `.uiAction(...)`
public extension View {
    func uiComponent(_ name: String, state: String? = nil) -> some View {
        self
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("ui:component:\(name)")
            .accessibilityValue(state ?? "")
    }

    func uiSlot(_ name: String, state: String? = nil) -> some View {
        self
            .accessibilityIdentifier("ui:slot:\(name)")
            .accessibilityValue(state ?? "")
    }

    func uiAction(_ name: String) -> some View {
        self.accessibilityIdentifier("ui:action:\(name)")
    }
}
