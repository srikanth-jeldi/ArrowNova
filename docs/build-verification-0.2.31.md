# ArrowNova 0.2.31 (33) — cold launch and décor wishlist

AAB: mobile/ArrowNova-0.2.31-play.aab · 30,621,402 bytes.
SHA-256: 133d6b72932d3265415c7a167e24eabbca1693c73a51713ac12d3601329f5a19.

## Report and changes

Samsung SM-F415F was running the Play-installed 0.2.29 (31). Its retrieved historical exit records included system kills and user-requested exits but no recorded ArrowNova ANR or ANR stack. The device disconnected before reproduction. The exact cause of the reported cold-launch popup is unconfirmed.

Moved Play update setup/preferences lookup off Android's input thread. Home renders before optional startup services; a normal launch no longer rewrites unmodified progress or initialises disabled reminders. Large saves are decoded outside the UI isolate. Ad startup respects foreground state, including late consent callbacks. These changes address identifiable startup work, not a proven fix for a specific customer stack.

Each room can remember one unpurchased coin décor item. Remaining coins and first-time level wins are recalculated from the real balance and the 40-coin first-win reward, rounding up. Wishlist selection is free and reversible; buying the item clears the wish.

## Verification

Static analysis: no issues. Broad suite excluding the unchanged exhaustive level generator: 137 passed, one ad test initially assumed the app was foreground without setting the lifecycle. Its corrected paused-launch/resume test passed separately. All four wishlist/startup tests passed after settling and centring the widget before tapping. Includes large existing save, no startup rewrite, home rendered before optional service callback, room-specific persistence, exact/remainder/affordable cost cases, purchase clearing, and real add/remove UI.

The signed AAB passed bundletool validation, manifest/version verification and jarsigner verification; all 425 runtime entries match the raw bundle. Production ad IDs checked in all three ABIs. Flutter reported its known native-symbol stripping failure after producing the raw bundle; debug symbols and mapping are stored separately in mobile/build/release-diagnostics/0.2.31+33/store.

## Device verification limit

API 33 read-only emulator upgraded from build 31 to build 33 using APKs derived from their AABs. Build 31's first launch timed out on an overloaded system. Build 33 installed and reached the actual ArrowNova home. A build 33 launch was logged as displayed at 6.301 seconds. The emulator itself had multiple system/service ANRs, including Pixel Launcher and System UI dialogs obscuring the app. The final cold launch reached home, then the UI automation command failed while reading the screen after the rewards tap. No complete three-cycle interaction result and no reliable speed comparison. No ArrowNova-specific ANR was present in the captured filtered event log. This is not confirmation that the Samsung issue is fixed. Run build 33 via internal testing on the affected phone before production; retain its Play Vitals ANR stack and timestamp if it recurs.
