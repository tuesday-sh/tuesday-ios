# App Store Connect Provisioning, Privacy Nutrition Labels & App Review Guide (`sh.tuesday.app` v1.0.0)

## 1. Bundle ID & Export Compliance Configuration
- **Bundle Identifier**: `sh.tuesday.app`
- **Apple Developer Team ID**: `GWBBWC9V34` (Packablock LLC)
- **Version**: `1.0.0` (`Build 1`)
- **Export Compliance (`ITSAppUsesNonExemptEncryption`)**: Set to `false` in `project.yml` / `Info.plist` (uses only standard iOS HTTPS/TLS networking), enabling immediate TestFlight Internal Testing distribution without manual export compliance prompts.
- **Privacy Manifest (`PrivacyInfo.xcprivacy`)**: Bundled at `TuesdayApp/PrivacyInfo.xcprivacy` declaring `CA92.1` (`UserDefaults`) and `NSPrivacyTracking = false`.

---

## 2. Apple Privacy Nutrition Labels (App Store Connect -> App Privacy)

- **Do you or your third-party partners collect data from this app?** `Yes`
- **Data Types Collected**:
  1. **Identifiers $\rightarrow$ Device ID**:
     - *Collected for*: **App Functionality** (rate limiting & anonymous site scoping via `X-Tuesday-Device-ID`).
     - *Linked to the user's identity?* **No**
     - *Used for tracking across apps/websites?* **No**
- **Why Photos/Videos Are NOT Listed as Collected**:
  - Per Apple's App Privacy guidelines, data processed strictly in ephemeral memory during a single request and never stored on servers is not disclosed as collected data. Camera frames captured during **Plug & Tag** hardware discovery are transmitted over TLS 1.3 with `X-Tuesday-Image-Retention: none_ephemeral_ram_only`, processed in ephemeral RAM, and immediately wiped in an `ensure` block (`0` photos stored on disk, database, or object storage).

---

## 3. StoreKit 2 Subscription Group (`TuesdayProducts.storekit`)

- **Subscription Group Name**: `Tuesday.sh Pro`
- **Products**:
  - `sh.tuesday.pro.monthly` — **$4.99 / month** (Family Shareable)
  - `sh.tuesday.pro.yearly` — **$49.00 / year** (Family Shareable)

---

## 4. App Store Review Notes (Copy/Paste into App Store Connect -> App Review Information -> Notes)

> **Testing Instructions (No Physical Hardware or Login Required):**
> 1. Launch Tuesday.sh. On the **Welcome to Tuesday.sh** card at the top of the **Rack** tab, tap the **"Explore 12-Device Demo Lab"** button.
> 2. This immediately loads a complete 12-device homelab and smart-home network across the **24-Port Managed Switch Grid** (`UDM-Pro`, `USW-Pro-24`, `Synology DS923+`, `Home Assistant Yellow`, `LG OLED`, `Owlet Cam 2`, etc.).
> 3. Tap any active port in the 24-Port Switch Grid to open the **Node Detail Sheet** and inspect its PURL software inventory, Trust Zone (`Z0`–`Z4`), and security advisories.
> 4. Switch to the **Bulletins** tab to review matched CISA KEV, CPSC Safety Recall, and End-of-Life (EOL) notices, filter between **Confirmed** and **Guessed** models, or tap **+ Add Node** to test camera/manual hardware discovery.
