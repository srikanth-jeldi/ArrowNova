# iOS release status

Native runner prepared on Windows; no claim of a successful iOS build or device test.
Bundle ID: `com.epitomehub.arrownova`. Minimum iOS 15.0. Version 0.2.0 (2).

## On the release Mac

1. Install a supported Flutter SDK, Xcode and CocoaPods; run `flutter doctor` and
   `flutter pub get` in `mobile`. Run `pod install` inside `ios` if required by Flutter.
2. Open `Runner.xcworkspace`, choose the owner's Apple Developer team for Runner,
   and verify Keychain Sharing/signing entitlements. Reserve the same bundle ID in
   App Store Connect and create the app record.
3. Run on a real iPhone with test ads first. Verify consent, rewarded hint/skip/chest,
   background/foreground music, silent switch, haptics and opt-in 9/13/19 reminders.
   Test midnight rollover and saved progress after restart. No background audio mode
   is enabled; notifications are local and do not require an APNs server.
4. Create a separate iOS app and banner/interstitial/rewarded units in AdMob.
   Android ad IDs MUST NOT be reused. Configure the iOS consent message.
5. Put `ADMOB_APP_ID=your-ios-app-id` in ignored `Flutter/Ads.local.xcconfig`.
   Add all applicable SKAdNetwork IDs from Google's current integration documentation.
   The checked-in app ID and ad units are Google's test configuration.
6. Build with `flutter build ipa --release --dart-define=LIVE_ADS=true
   --dart-define=IOS_BANNER_ID=... --dart-define=IOS_INTERSTITIAL_ID=...
   --dart-define=IOS_REWARDED_ID=...`. Missing live IDs disable ad initialization.
   Verify the archived Info.plist contains the real iOS AdMob app ID before upload.
7. Review the archive's privacy manifest/report and complete App Store privacy,
   age rating and export compliance declarations accurately. This build does not
   request ATT or IDFA access. Do not declare tracking permissions without wiring
   the consent/ATT flow. Check current SDK behavior and App Store policies.
8. Upload to TestFlight, finish device testing, then submit for Apple review.

## Reward behavior

Hint ads are required outside practice, including levels above 50. Every tenth
Classic level already uses the harder dependency rules. Skip is Classic-only,
excludes level 800 and awards no completion, stars, coins or garden points.
Skipped puzzles remain playable. Daily Chest unlocks five distinct hard boards
with one rewarded ad until local midnight; regular Daily Challenge remains free.
Reward dismissal, failure or missing inventory never grants an unlock.

References: https://developers.google.com/admob/ios/quick-start and
https://developers.google.com/admob/ios/test-ads
