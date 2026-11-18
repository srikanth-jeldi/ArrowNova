# ArrowNova 0.2.32 (34)

## Changes

- First 30 new puzzles use short bent paths with alternating exit directions, 5–30 arrows and bounded removal chains. The old lane generator remains available when resuming an existing checkpoint. Released levels 31+ are unchanged.
- Expanded the décor catalogue from 35 to 84 choices: seven free starters, 21 rewarded choices and 56 coin choices across eight collections. Added a coin-only filter. Existing IDs, balances, room ownership and wishlist semantics are preserved.
- New coin choices combine the four existing furniture silhouette sets with coordinated finish variants. These are not 84 newly modelled objects or an unlimited asset library. Existing room-specific purchase rules remain in place.
- Reused existing artwork, avoiding additional large texture downloads.

## Validation

- Beginner tests cover all 30 boards: unique layouts, bends, adjacency, no overlap, arrow counts, bounded dependency depth and complete solutions without losing lives.
- Upgrade test uses real checkpoint fixtures generated from the previous committed generator for levels 1, 5, 10, 20 and 30. Board geometry, removed arrows and elapsed time survive; each resumed board can still be completed.
- Expanded-catalogue test buys every coin choice, rejects duplicate charges, restores balances and ownership, and checks that the next room starts with the intended fresh ownership.
- Existing room removal, premium reward, gallery, shield, wishlist, large-save and purchase UI tests were exercised. An obsolete catalogue-count assertion was updated; purchase UI scrolling was adjusted to target the visible button in the larger catalogue.
- 19 targeted tests passed (18 in the grouped run, the corrected purchase UI test separately), plus the saved-board compatibility test: 20 total.
- Final `flutter analyze --no-pub`: no issues found.

## Limits

No physical-device crash/ANR verification was performed for this release. Automated correctness tests do not establish freedom from future device-specific ANRs, retention improvements or store performance.

The first build attempt failed because a cached Gradle Flutter plugin JAR contained no implementation classes. A targeted cache backup/rebuild was attempted; Windows held some files open. The subsequent build passed plugin loading. Bundle verification is recorded after completion.


## Final artifact

- `mobile/ArrowNova-0.2.32-play.aab`: 30,634,543 bytes (30.6 MB).
- Package: `com.epitomehub.arrownova`, version name `0.2.32`, version code `34`, verified from the generated manifest.
- SHA-256: `73b7779d1ecd8d584cfbea0c7e26fe1f6c9038ce037f52d1f7d05883782d4506`.
- Raw and compact bundles both passed bundletool validation. Existing upload-key signature verified.
- All 425 runtime entries are byte-identical between raw and compact bundles. Live ad unit IDs verified in all three ABI libraries.
- Updated puzzle, catalogue and d�cor UI source files were found verbatim in the latest compiled kernel.
- Flutter reported its native-symbol stripping error after Gradle generated the bundle. The validated compact bundle preserves all runtime files and stores detached diagnostics in `mobile/build/release-diagnostics/0.2.32+34/store/`.
- No store upload or production rollout performed. Phone/emulator runtime verification remains outstanding for this release.
