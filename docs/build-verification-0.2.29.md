# ArrowNova 0.2.29 (31)

- Artifact: mobile/ArrowNova-0.2.29-play.aab
- Size: 30,578,064 bytes.
- SHA-256: 5534dd77c93626926b13d64a5c6abecc9b45ddcba37dfbd3a832e063560f6dec
- Manifest verified: com.epitomehub.arrownova, versionName 0.2.29, versionCode 31.
- Raw and compact AAB passed bundletool validation. Compact signature verified using the existing upload key. All 425 runtime entries match the raw bundle; live ad unit IDs verified in all three ABIs.
- Adds optional Play update reminder after home loading, Update/Later buttons, 24-hour per-version reminder cooldown, safe offline/late-response handling. Includes prior board fireworks, home decoration and lifecycle/save fixes committed with this release.

## Verification

- Update integration analyzer: no issues. Native release Kotlin compilation passed.
- Broad regression run passed 123 tests before the unchanged exhaustive 6000-level test was stopped intentionally. One save/reopen test initially left an unmocked Play query timeout pending; its test fixture now mocks that platform channel. Save/reopen plus all update-reminder tests then passed (5 tests).
- Remaining quick puzzle regressions passed (6 tests). The exhaustive generator test was not completed this time; the unchanged generator passed that test in the previous documented stability audit.
- This release has not been exercised on a physical phone or through a live Play update rollout. See docs/update-reminder.md for the Play testing procedure.

## Toolchain limitation

Flutter returned its known post-build debug-symbol stripping error after creating the fresh release bundle. Independent manifest, bundletool, signing and runtime-comparison checks passed. Detached native symbols, mapping and Dart symbols are preserved in mobile/build/release-diagnostics/0.2.29+31/store.
