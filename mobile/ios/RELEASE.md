# ArrowNova iOS release

Read the [Mac handover document](../../docs/ArrowNova-iOS-Mac-Handover.docx)
in order. It covers account access, Mac setup, signing, physical-device checks,
IPA export, TestFlight, iOS advertising, store submission and troubleshooting.

Current source: **0.2.10+12**. Bundle ID: `com.epitomehub.arrownova`.
Minimum deployment target: iOS 15.0. Flutter baseline: 3.47.4 / Dart 3.13.3.

## Validation status

The release helper tests, shell syntax, plist parsing, icon format and Flutter
analysis passed on Windows. A native Xcode archive, Apple signing and physical
iPhone run have **not** been verified. Complete the Mac guide before release.

## Build on the Mac

From `mobile`, after following the guide's account and Xcode setup:

```bash
export ARROWNOVA_TEAM_ID="YOUR10CHARTEAMID"
python3 tool/test_ios_release.py
bash tool/build-ios.sh test "$ARROWNOVA_TEAM_ID" 13
```

Replace the placeholder with the owner's actual 10-character Apple Team ID.
Use an unused build number; 13 is an example. The helper checks for an iOS SDK
of at least 26, prepares signing and test-ad configuration, builds the archive
and IPA, and verifies the archived bundle and AdMob app ID. It does not upload.

For a live-ad candidate, create separate **iOS** AdMob app/unit IDs, copy
`ads.ios.example.json` to ignored `ads.ios.local.json`, fill all four values, then:

```bash
bash tool/build-ios.sh store "$ARROWNOVA_TEAM_ID" 14
```

Do not reuse Android IDs. Keep local signing/ad configuration, certificates and
generated archives out of Git. Save the IPA, archive and dSYMs before rebuilding.
See the guide for upload, consent, privacy and final submission steps.

## Device checks

Test launch, both practice rounds, levels 5–7, dense arrow touch targets, all
three hearts, error and victory sounds, mute/silent mode, progress persistence,
garden, consent and rewarded-ad completion/failure. Test iPad layout too.
Daily reminders and the settings sound-test panel are currently disabled.

The current app has no explicit ATT request flow. Review the actual SDK data use
and complete Apple's privacy/export declarations accurately. UMP consent alone
does not replace ATT authorization when tracking is used.
