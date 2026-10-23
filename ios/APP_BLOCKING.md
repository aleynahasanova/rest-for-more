# iOS app blocking

The iOS implementation uses FamilyControls (individual authorization), the native
FamilyActivityPicker, ManagedSettings shields and a DeviceActivity monitor
extension.

## Build and signing (Mac required)

1. Run `flutter pub get` and open the iOS project in Xcode.
2. Select your paid Apple Developer team for **Runner** and **FocusActivityMonitor**.
   Change both bundle identifiers to identifiers registered to that team; the
   extension identifier must start with the app identifier followed by a dot.
3. Confirm **Family Controls** is enabled for both targets. Both targets already
   reference entitlements files and the extension is embedded by Runner.
4. Build on a physical iPhone. Accept Screen Time authorization, then select apps,
   categories or websites using the Apple picker. Selections persist locally.
5. Before TestFlight/App Store distribution, request Apple's Family Controls
   distribution entitlement for **both** bundle identifiers and regenerate signing
   profiles. See https://developer.apple.com/documentation/familycontrols/requesting-the-family-controls-entitlement.

No App Group is needed: selections stay in Runner's UserDefaults and each session
uses a named ManagedSettingsStore shared with the extension by the system.

## Behavior and device acceptance checks

- Deny authorization: show an error and keep the focus timer stopped. Retry and
  approve: picker opens. Cancel preserves the previous selection; Save with no
  selections disables Start. Restart the app and confirm the selection count.
- Start focus: selected apps/categories/websites show Apple's shield. Pause clears
  shields; Resume reapplies them for the remaining duration. Stop clears them.
- Test 1-minute, 15-minute and 3-hour sessions, including across midnight, with the
  app backgrounded, force-closed and relaunched. DeviceActivity needs at least a
  15-minute interval, so short sessions use an interval starting in the past.
  Verify that behavior on supported device/OS versions before release.
- iOS delivers monitor callbacks when the device is in use; they are not a precise
  background timer. Runner also clears expired shields on launch/status checks.
- A different store is used for each session so an old end callback cannot unblock
  a newer session. Verify rapid pause/resume and repeated sessions on device.
- The UI displays a count of Screen Time selections, not Android app identities.
  Category counts are counts of categories, not the number of apps inside them.
  The session manager explains how to pause all selections. Individual temporary
  unblocking from the Android package-name list is not exposed on iOS.

## Verification

Run `flutter analyze` and `flutter test`. Service tests cover platform routing,
permission denial, selection summaries and duration forwarding. Native compilation,
signing, picker interaction, shields and background expiry require Xcode and a
physical device; Dart tests cannot validate those Apple APIs.
