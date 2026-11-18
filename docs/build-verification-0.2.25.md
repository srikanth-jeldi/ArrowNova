# Release 0.2.25 (27)

Artifact: mobile/ArrowNova-0.2.25-play.aab
Size: 30,424,053 bytes (29.01 MiB)
SHA-256: a716411c8945a4b3b3902afb041b04fd177a0e42c0a152b26ea0e3b5e31c380b

Contains 2D Home Decor and smooth arrow exit/blocked return animations.

Validation: bundletool validates both raw and compact AAB; manifest version 0.2.25 / 27; jarsigner verifies upload signature. All 422 runtime entries match the raw bundle byte-for-byte. Live ad IDs verified in all three ABIs; all seven decor assets present. Recent focused animation/touch/ad-recovery tests: 8 passed. Flutter analyzer clean. Earlier Home Decor regression results are documented in home-studio-2d.md.

Flutter reported its known post-Gradle native debug-symbol stripping failure. The generated raw bundle passed validation; tool/compact-bundle.ps1 detached diagnostics and re-signed without changing runtime entries. Diagnostics remain in mobile/build/release-diagnostics/0.2.25+27/store (mapping.txt, native-debug-symbols.zip, Dart symbols). No physical-device or live-ad smoke test performed for this release. Not uploaded or published to Google Play by this task.
