# ArrowNova 0.2.28 (30) release verification

- Deliverable: mobile/ArrowNova-0.2.28-play.aab
- Size: 30,562,842 bytes (30.56 MB)
- SHA-256: 0c4d31001bda406bd81fd69c81965fbb011c9cece61800a2f73c3ff32a0b7c45
- Manifest verified: com.epitomehub.arrownova, versionName 0.2.28, versionCode 30.
- Raw and compact bundles passed bundletool validation. Compact bundle signed with existing upload key; jarsigner verification passed.
- All 424 runtime entries byte-identical between raw and compact bundles. Production ad unit IDs verified in all three ABI libraries.
- Flutter analyzer: no issues found.
- Latest visual work: board fireworks, stable random happy emoji/praise, two-second completion celebration, red blocked-arrow feedback. Previous stars screen preserved.
- Relevant widget, completion/recovery and golden tests passed during feature work. Physical-device and emulator tests were not rerun for this release; earlier stability testing is documented in build-verification-0.2.27.md.

## Build tool limitation
Flutter returned a post-build native debug-symbol stripping error after Gradle produced the fresh bundle. The fresh manifest and bundle were independently validated. Diagnostic metadata was detached using tool/compact-bundle.ps1 and the compact bundle was re-signed and independently validated. Native symbols and mapping are saved under mobile/build/release-diagnostics/0.2.28+30/store for separate upload.
