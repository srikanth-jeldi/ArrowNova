# ArrowNova 0.2.27 (29) release verification

Date: 16 October 2026

## Changes included

- Prevent repeated music resume calls and overlapping audio position polling during progress saves and lifecycle changes.
- Contain native audio, ad-disposal and haptic failures; finish cleanup of independent resources even if one fails.
- Retry ad initialization and banner loading in the foreground, refresh expired cached ads, and recover from failed fullscreen opening. Consent forms cannot be stacked by resume callbacks.
- Preserve completion/save recovery and result-screen navigation regression coverage.
- Fix reminder initialization for Android's legacy Asia/Calcutta timezone by including timezone aliases. This was discovered in emulator logs and is covered by a new regression test.

## Automated checks

- Full suite: 123 tests passed, including exhaustive dense puzzle levels 31 through 6000. Log: mobile/.build-tmp/full-test-2026-10-16.log.
- After the timezone change: all 4 reminder-service tests passed, including the newly added legacy timezone case. The entire exhaustive suite was not rerun after this isolated database import change.
- Final static analysis: no issues. Log: mobile/.build-tmp/analyze-final-2026-10-16.log.
- Existing failure-injection/lifecycle tests cover repeated music settings, 30 widget background/resume cycles, arrow-exit/save recovery, completion and next-level navigation, ad cleanup and consent recovery.

## Build validation

Flutter/Gradle produces the release bundle but Flutter subsequently reports a native debug-symbol stripping failure. The release workflow separately validates the newly produced bundle, extracts diagnostic metadata, signs the compact bundle with the existing upload key, and verifies runtime-entry equality. A successful Gradle output alone is not treated as validation.

Native symbols and R8 mapping are kept under mobile/build/release-diagnostics/0.2.27+29/store. Dart symbol files are in its dart subdirectory. Preserve these for diagnosing this exact build.

## Device testing constraints

Two local emulator configurations were attempted. The API 36.1 emulator encountered System UI stalls and its emulator process exited. The initial API 33 emulator also recorded Google/System UI service ANRs under host memory pressure. These are not evidence of an ArrowNova crash, but they invalidate a clean device stability claim. An ArrowNova QA home screen was observed; initial game interactions were blocked by the system/input state. The completed build daemon was stopped and an isolated emulator configuration adjusted for further checks.

Live AdMob account policy status and live rewarded inventory have not been verified. Browser automation was unavailable in the earlier investigation. A release artifact and unit tests cannot establish an ad account's serving eligibility.

## Final artifact validation

- Final AAB: mobile/ArrowNova-0.2.27-play.aab, 30,552,576 bytes.
- SHA-256: B87B88E6D2E027D1E3931E2E033AC9F87880501B97B32969188DD333389A670C.
- Package com.epitomehub.arrownova; versionName 0.2.27; versionCode 29; minSdk 24; targetSdk 36.
- bundletool validates both the fresh raw bundle and the compact bundle; jarsigner verifies the final signature.
- All 424 runtime entries are byte-identical before and after diagnostic extraction. Production ad unit IDs verified in all three libapp.so ABIs.
- The final raw bundle was converted with bundletool to a debug-signed universal APK solely for emulator installation. Installation succeeded; app process started and SDK logs identify the emulator as a test device. The timezone initialization error is absent in this final app run.
- No Play Console upload or publication was performed.

## Final emulator stress result and remaining gate

On the final bundle-derived app, 20 HOME/background/foreground cycles retained PID 4566. Screen-off/wake recovery also retained PID 4566, and activity inspection showed MainActivity as the top resumed activity. The saved lifecycle-cycles.csv records all 20 cycles. Captured lifecycle-final.txt contains no ArrowNova ANR, fatal exception or fatal signal. exit-final.txt contains no crash/ANR exit for that process (an earlier empty process-start record occurred during installation).

The collection helper was interrupted after cycle/exit capture because its original PowerShell helper interpreted logcat's -d as a PowerShell common parameter. Argument forwarding was corrected, and final logs/exit information were collected directly with adb. This was an audit-script issue, not an app fix.

The emulator's display/screencap operation remained stalled, despite changing renderer and memory configuration. Therefore these checks establish process survival only; they do not verify responsive gameplay, actual reward completion, visible result-screen progression, or a physical phone's lock/unlock behaviour. Automated widget tests cover those gameplay paths, but do not replace device verification. No cloud-device run was performed.

Recommendation: use this AAB for internal testing first. Production sign-off still requires a responsive phone/device run of complete-level -> Next Level, close/reopen saved progress, and rewarded-ad completion/dismissal. Zero future crashes/ANRs is not guaranteed by these checks.
