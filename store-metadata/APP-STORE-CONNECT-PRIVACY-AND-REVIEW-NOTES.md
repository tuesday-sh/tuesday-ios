# App Store Connect Privacy & Review Notes — Tuesday.sh v1.0.0 (Build 14)

- **Legal Entity**: Packablock LLC
- **Apple Developer Team ID**: `C64X2B2J54`
- **Bundle Identifier**: `sh.tuesday.pro` (Apple ID `6834146916`, SKU `sh.tuesday.pro`)
- **Supported Device Family**: iPhone (`TARGETED_DEVICE_FAMILY = 1`, iOS 18.0+)
- **Marketing Version / Build**: `1.0.0` (Build `14`)
- **Support Contact**: `support@packablock.com` • `https://tuesday.sh/support`
- **Privacy Policy URL**: `https://tuesday.sh/privacy`
- **Terms of Service URL**: `https://tuesday.sh/terms`

---

## 1. App Privacy Questionnaire Summary (`PrivacyInfo.xcprivacy`)
- **Tracking (`NSPrivacyTracking`)**: **No** (`false`). Zero third-party ad SDKs, zero analytics trackers, zero IDFA usage.
- **Photos / Camera Hardware Images**: **Data Not Collected / Not Retained**. Photos captured or selected in **Add Device** are processed strictly in ephemeral server RAM (`X-Tuesday-Image-Retention: none_ephemeral_ram_only`) for model/barcode extraction and discarded immediately after the HTTP response. Barcode/QR scanning uses on-device Apple `AVFoundation` & `Vision` frameworks.
- **Inventory & Audit Data**: Stored locally on-device (`UserDefaults` + user-initiated JSON export/import).
- **Device Identifier (`NSPrivacyCollectedDataTypeDeviceID`)**: Unlinked (`identifierForVendor`), used solely for App Functionality (StoreKit 2 subscription verification against `POST https://api.tuesday.sh/api/v1/billing/verify` and rate-limited hardware identification).
- **Purchase History**: Unlinked, used solely for App Functionality via StoreKit 2 (`Product.purchase()`, `Transaction.currentEntitlements`, `AppStore.sync()`).
- **Required Reason API (`NSPrivacyAccessedAPICategoryUserDefaults`)**: Reason `CA92.1` (reading/writing app preferences & local inventory state).

---

## 2. In-App Purchase (StoreKit 2) Configuration
| Subscription Product ID | Reference Name | Price (USD) | Billing Period | Subscription Group |
| :--- | :--- | :---: | :---: | :--- |
| `sh.tuesday.pro.tier1.annual` | Tuesday.sh Pro Tier 1 Annual | `$29.00` | 1 Year (`P1Y`, Save 19%) | `Tuesday.sh Pro Tier 1` (`22616719`) |
| `sh.tuesday.pro.tier1.monthly` | Tuesday.sh Pro Tier 1 Monthly | `$2.99` | 1 Month (`P1M`) | `Tuesday.sh Pro Tier 1` (`22616719`) |

- Auto-renewal disclosure, direct **Restore Purchases** (`AppStore.sync()`), and **Manage Subscription** (`https://apps.apple.com/account/subscriptions`) are surfaced in both the **Tier 1 Upgrade** modal and **Settings → Plan & Subscription**.

---

## 3. App Review Instructions & Demo Flow
No account or login is required to evaluate Tuesday.sh.

1. **Sample Data**: On the Welcome card, tap `"Enable Demo Mode (add example devices)"` (or open **Settings → Developer Mode → Seed Forest**) to load a sample home/homelab inventory.
2. **Hardware Discovery**: Tap **`+ Add Device`** → tap **Clues** and enter `Ubiquiti`, `UDM-Pro`, or `74:83:C2` for instant offline matching, or test **Scan** / **Photo** discovery.
3. **Advisories, Timeline & Backup**: Explore **Bulletins**, **Timeline**, and **Check-Up**, and tap the top-right **Menu (`≡`)** for **Sovereign Local JSON Backup**.
4. **Subscriptions (StoreKit 2)**: Open **Settings → Plan & Subscription** (or tap the **Network** pill → **Add a network**) to test Founding Member Monthly (`$2.99/mo`) / Annual (`$29.00/yr`) in Sandbox and **Restore Purchases**.

### Encryption Export Compliance
- `ITSAppUsesNonExemptEncryption = false` (uses standard iOS HTTPS/TLS only).
