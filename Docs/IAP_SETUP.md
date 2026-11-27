# Real in-app purchases: setup and testing

## What is in the project
- Plugin: **GodotGooglePlayBilling 3.3.0** (official, `addons/GodotGooglePlayBilling/`), bundles Google Play Billing Library **9.1.0**. Enabled in Project Settings > Plugins (`project.godot` `editor_plugins`). Needs **Use Gradle Build** (already on). No extra checkbox in the export preset.
- `Scripts/Monetization/GooglePlayBillingProvider.gd` is the store adapter. It is loaded by path only when `Engine.has_singleton("GodotGooglePlayBilling")`, so PC runs and builds without the plugin keep working.
- Debug builds on PC use the mock store. **Android builds (debug and release) always use the real store.** A release build can never get the mock.

## Before the first upload (cannot be changed later)
1. `export_presets.cfg` / Export > Android > `package/unique_name` is still `com.example.$genname`. Set the real package id (e.g. `com.moonowlgames.armyascension`). It must be identical in Play Console and in the AdMob app (AdMob > App settings > link the app to the Play listing).
2. Play requires an **AAB**: set `gradle_build/export_format` to *Export AAB* for the upload build. APK is only for your own phone.
3. Sign the release build with your own keystore (Export > Android > Keystore > Release). Keep the keystore and password safe; Play App Signing holds the final key.
4. Raise `version/code` for every upload.

## Play Console (after the account is verified)
1. Create the app with the package id above. Upload the first AAB to **Internal testing**. In-app products can be created once a build is uploaded.
2. Monetize > Products > **In-app products** > create these, status **Active**. IDs must match exactly:

| Product id | What it is | Handling in the app |
|---|---|---|
| `gold_s`, `gold_m`, `gold_l` | gold packs (500 / 1500 / 5000) | consumed after delivery (buy again any time) |
| `gems_s`, `gems_m`, `gems_l` | gem packs (40 / 150 / 500) | consumed after delivery |
| `starter_bundle` | once: 1000 gold + 30 shards + chest | acknowledged after delivery |
| `remove_ads` | once: NO RANDOM ADS | acknowledged after delivery |

3. Prices are set in Play Console per country; the shop shows the localized price the store returns (cards keep their default text until the store has answered).
4. Setup > **License testing**: add your tester Gmail accounts. They buy without being charged.
5. Testing > Internal testing: add testers, open the opt-in link on the phone, install **from Play**. Test the purchase on that install (a sideloaded APK with a different signature cannot buy).
6. An unacknowledged purchase is refunded automatically by Google after 3 days. The app acknowledges / consumes only after the reward is saved.

## What to test on the phone
1. Buy `gold_s`: progress overlay, Google sheet, reward popup, gold +500, price on the card is localized.
2. Cancel the Google sheet: toast "Purchase canceled", no reward, shop usable.
3. Buy `remove_ads`: card shows OWNED. Buy `starter_bundle`: soldier picker, reward, OWNED.
4. Kill the app during the Google sheet / right after paying, reopen: the purchase is delivered by itself ("Purchase delivered" toast).
5. Uninstall, reinstall, Shop > **RESTORE PURCHASES**: `remove_ads` / `starter_bundle` show OWNED, no second reward.
6. Airplane mode: buying says "No connection to Google Play"; leaving airplane mode and resuming the app retries.
7. Check `adb logcat -s godot` for `GooglePlayBilling:` warnings (they contain only product ids and response codes).

## Security: what this does and does not do
- The client checks purchase state, product id, package name and required fields (`PurchaseVerifier`) and never grants the same token twice (SHA-256 hash stored, never the raw token).
- **This is not secure against a modified APK or a rooted phone.** The reward is still granted by code on the phone. Before real money matters, add server verification (Phase B): the app sends `product_id` + `purchase_token` to a Vercel API route that calls the Google Play Developer API (`purchases.products.get`) with a service account, checks `purchaseState == 0`, the package and that the token was not used, and answers yes / no. Implement it by subclassing `PurchaseVerifier` (its `verify()` may be awaited). The service account key must live only on the server.
- Refunds are not revoked automatically (a false revoke on a network error costs more than a refund). Real-time developer notifications on the server are the clean way to do it later.

## Known limits
- `PurchaseVerifier` reads the app package through the Android runtime. If that lookup returns nothing, only the package check is skipped.
- Product details dictionary keys and the purchase dictionary were read from the plugin's compiled classes, not its source. Everything is read defensively, and the unit tests feed the same dictionary shape, but the first real run on a phone is the final proof.
