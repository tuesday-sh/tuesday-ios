# App Store Connect Privacy & Review Notes — Tuesday.sh v1.0.0 (Build 9)

- **Legal Entity**: Packablock LLC
- **Apple Developer Team ID**: `C64X2B2J54`
- **Bundle Identifier**: `sh.tuesday.ios`
- **Supported Device Family**: iPhone (`TARGETED_DEVICE_FAMILY = 1`, iOS 18.0+)
- **Marketing Version / Build**: `1.0.0` (Build `9`)
- **Support Contact**: `support@packablock.com` • `https://tuesday.sh/support`
- **Privacy Policy URL**: `https://tuesday.sh/privacy`
- **Terms of Service URL**: `https://tuesday.sh/terms`

---

## 1. App Privacy Questionnaire Summary (`PrivacyInfo.xcprivacy`)
- **Tracking (`NSPrivacyTracking`)**: **No** (`false`). Zero third-party ad SDKs, zero analytics trackers, zero IDFA usage.
- **Photos / Camera Hardware Images**: **Data Not Collected / Not Retained**. Photos captured or selected in **Add Device** are processed strictly in ephemeral server RAM (`X-Tuesday-Image-Retention: none_ephemeral_ram_only`) for model/barcode extraction and discarded immediately after the HTTP response. Barcode/QR scanning uses on-device Apple `AVFoundation` & `Vision` frameworks.
- **Inventory & Audit Data**: Stored locally on-device (`UserDefaults` + user-initiated JSON export/import).
- **Device Identifier (`NSPrivacyCollectedDataTypeDeviceID`)**: Unlinked (`identifierForVendor`), used solely for App Functionality (StoreKit 2 subscription verification against `POST https://api.tuesday.sh/api/v1/billing/verify` and rate-limited hardware identification).
- **Purchases**: Managed natively via StoreKit 2 (`Product.purchase()`, `Transaction.currentEntitlements`, `AppStore.sync()`).
- **Required Reason API (`NSPrivacyAccessedAPICategoryUserDefaults`)**: Reason `CA92.1` (reading/writing app preferences & local inventory state).

---

## 2. In-App Purchase (StoreKit 2) Configuration
| Subscription Product ID | Reference Name | Price (USD) | Billing Period | Subscription Group |
| :--- | :--- | :---: | :---: | :--- |
| `sh.tuesday.pro.tier1.annual` | Tuesday.sh Pro Tier 1 Annual | `$49.00` | 1 Year (`P1Y`, Save 18%) | `Tuesday.sh Pro Tier 1` |
| `sh.tuesday.pro.tier1.monthly` | Tuesday.sh Pro Tier 1 Monthly | `$4.99` | 1 Month (`P1M`) | `Tuesday.sh Pro Tier 1` |

- Auto-renewal disclosure, direct **Restore Purchases** (`AppStore.sync()`), and **Manage Subscription** (`https://apps.apple.com/account/subscriptions`) are surfaced in both the **Tier 1 Upgrade** modal and **Settings → Subscription & Plan**.

---

## 3. App Review Instructions & Demo Flow
No login or account creation is required to evaluate Tuesday.sh:

1. **Explore Empty Day-0 Experience & Instant Sample Data**:
   - Launch the app cleanly to see the Day-0 state (`My Net`).
   - Tap **`seed Forest fleet`** on the Welcome card (or navigate to **Settings → Household Scale Tester & Dev Tools** and tap **`🌲 Forest (12)`**) to populate 12 representative routers, switches, APs, servers, cameras, TVs, and IoT devices across `C1–C8`.
2. **Test Offline Hardware Search & Barcode / Vision Discovery**:
   - Tap the **`+ Add`** button -> **Search / Clues** mode -> type `Ubiquiti`, `UDM-Pro`, `74:83:C2`, or `817882027373` -> tap **Identify Device** to resolve verified hardware locally in `< 1ms` (`0` server turns).
   - Switch to **Scan Code** or **Photo / Label** to test live barcode/QR scanning and photo upload.
3. **Inspect Advisories, Timeline & Local Backup**:
   - Switch tabs across **Bulletins** (interactive Welcome rhythm checklist, security bulletins, Snooze/Ignore preferences), **Timeline** (scrub the 2D hardware lifespan swimlane or tap **Verify** / **Annual Check-In**), **Check-Up** (4-Rhythm posture report + native iOS Share Sheet), and the top-right **Menu (`≡`)** icon for **Sovereign Local JSON Backup** (Export / Import).
4. **Verify StoreKit 2 Subscriptions**:
   - Tap the **Network Site** pill at the top -> scroll to **Add Second Site** -> tap **Unlock Multi-Site with Pro Tier 1**, or visit **Settings → Subscription & Plan** to test selecting `Annual` / `Monthly`, subscribing in Apple Sandbox, or tapping **Restore Purchases**.

### Encryption Export Compliance
- `ITSAppUsesNonExemptEncryption = false` (uses standard iOS HTTPS/TLS only).
