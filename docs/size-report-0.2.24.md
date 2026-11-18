# ArrowNova 0.2.24 (26) size report

Measured against the delivered 0.2.23 files. MiB = 1,048,576 bytes.

| Artifact | Previous bytes | New bytes | Change |
| --- | ---: | ---: | --- |
| ARM64 test APK | 25,047,574 | 15,221,384 | 39.23% smaller |
| Signed compact Play AAB | 29,672,742 | 29,345,476 | 1.10% smaller |
| Estimated Play download, Android 12 ARM64, English, 420 dpi | 15,037,219 | 14,711,056 | 2.17% smaller |

The Play download is a bundletool estimate for the saved device specification in `mobile/build/size-tools/android12-arm64.json`, not a measurement on a physical phone. Other device configurations can differ. The full AAB is an upload artifact, not a single user's download.

## Changes

- Compress native libraries in direct sideload APKs. Store builds retain uncompressed native loading to avoid an additional extracted native-library copy on the device. APK file reduction is not an equivalent reduction in installed storage.
- Remove the unused ArrowNovaSerif font from the shipped bundle. Legacy store-art preview tools load that font directly from its retained source file.
- Preserve all supported Play ABIs and all gameplay, room, garden, image and audio content. All 18 retained source assets in the APK are byte-identical to the prior build.

## Verification

- Flutter analysis: no issues.
- 17 relevant Home Decor, garden, app and chapter tests passed. An initial garden test referenced the removed bundled font; unused test font loads were corrected before rerunning.
- APK: ZIP integrity, compressed native libraries, test ad IDs, version 0.2.24 (split APK code 2026), and signature verified.
- AAB: version 0.2.24 (code 26), live ad IDs in all three ABIs, bundletool validation and upload signature verified.
- The known Flutter native-symbol post-processing error occurred after Gradle produced the raw bundle. The raw bundle was validated, diagnostic metadata was detached with the existing compact-bundle script, and the result was re-signed and validated. All 415 runtime entries match the raw bundle byte-for-byte. Diagnostics are retained under `mobile/build/release-diagnostics/0.2.24+26/store`.
- Physical phone installation, runtime performance and live ads were not tested in this pass.

## Delivered files

- `mobile/ArrowNova-0.2.24-test.apk`: test ads, debug signing, ARM64.
- `mobile/ArrowNova-0.2.24-play.aab`: live ads, upload signing, all supported ABIs.

Use the AAB through Play internal testing to test an update over a Play-installed app; the test APK uses a different signing key.
