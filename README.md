# 📱 Tuesday.sh iOS App (`tuesday-ios`)

Native **Swift / SwiftUI** iOS companion application for **Tuesday.sh** (`@tuesday-sh`). Monitors package update telemetry (`apt`, `apk`, `brew`, `yum`, `docker`, `hacs`) across your servers and homelab nodes via a **Tuesday.sh Server** running as a **Home Assistant HACS integration** (or standalone container).

---

## ✨ Key Features

* **"Check Engine Light" Fleet Dashboard**: Instant health triage (`Healthy` `#34C759`, `Warning` `#FF9500`, `Critical` `#FF3B30`) with an animated `CandleGraphView` health bar per host.
* **Home Assistant HACS Integration**: Connects to your Home Assistant HACS Tuesday component (`sensor.tuesday_*` entities and `/api/tuesday/v1/status`) via Long-Lived Access Token or QR code pairing.
* **Expandable Package Update Drawers**: Inspect pending `apt`, `brew`, `apk`, `yum`, `docker`, and `hacs` package updates (`current -> available`) with CVE/security badges and one-tap host check-in triggers.
* **Local Wi-Fi & SSID Guardrails**: Uses `NWPathMonitor` and `NEHotspotNetwork` to verify local network connectivity when communicating with a LAN-only Home Assistant HACS instance, displaying `WifiWarningOverlay` when off Wi-Fi.
* **Interactive Mock HACS Backend (`MockHacsTuesdayService`)**: Pre-seeded with realistic homelab nodes (`homeassistant.local`, `ubuntu-dev`, `lml`, `aaronpro18`) so the iOS UI and XCUITests run standalone before `tuesday-server` HACS endpoints are finalized.

---

## 🛠️ Building & Testing (`aaronpro18` / Xcode 16.4)

Generate the Xcode project using [XcodeGen](https://github.com/yonaskolb/XcodeGen) and run tests via `xcodebuild`:

```bash
xcodegen generate
xcodebuild test \
  -scheme TuesdayApp \
  -destination "platform=iOS Simulator,name=iPhone 16"
```
