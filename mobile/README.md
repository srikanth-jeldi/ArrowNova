# ArrowNova — first playable build

Flutter Android app and local web preview for EpitomeHub Technologies.

The `ios/` runner includes native ad/reminder configuration, keychain entitlements
and ArrowNova icons. iOS test inventory is separate from Android. A Mac/Xcode
build, Apple signing, iPhone validation and iOS live AdMob IDs are still required
before an App Store release. See `ios/RELEASE.md`.

## Play Store signing

Run `./tool/build-store.ps1` to build an upload-signed AAB with live ArrowNova ads.

Release size: runtime artwork uses WebP; original PNG sources remain in the
repository but are not bundled. Store builds retain all Flutter Android ABIs.
Both release build scripts use `--split-debug-info`. Store builds archive native libraries, Dart
symbols and R8 mapping under `build/release-diagnostics/<version>/store/`.
Preserve that directory with each release for crash diagnosis; it is ignored by
Git. The standard AAB retains native metadata and the R8 mapping. The script also
produces `app-release-compact.aab`, signed with the same upload key. Only native
debug metadata and the R8 mapping are detached; runtime modules and all ABIs are
unchanged. When uploading the compact AAB, also upload `native-debug-symbols.zip`
and `mapping.txt` from its diagnostics directory to Play Console for crash reports.
AAB upload size is not the user
download size: measure device splits with bundletool or Play Console.

Measured 0.2.13+15: compact signed AAB 27,976,790 bytes (26.7 MiB), down
from 61,454,005 bytes (58.6 MiB). Bundletool 1.18.3 estimates 13,531,346
bytes (12.9 MiB) downloaded for ARM64, Android 12, English, density 420;
the previous release was 16,183,610 bytes (15.4 MiB) on the same configuration.
These are estimates, not a measurement from a physical phone or Play Console.
It requires local `android/key.properties` and the referenced upload keystore.
These files are ignored by Git; keep a secure backup outside this checkout.
Do not replace an existing upload key during later updates. Ordinary test APKs
continue using test ads and the development signing key. Play App Signing setup
and store review are separate Console steps; building a bundle does not publish it.

## Implemented

- Approved A-and-arrow logo, navy/gold UI, offline bundled fonts.
- Home, 6,000-level journey, tutorial, Classic game, pause, failure and victory.
- Two separate guided practice rounds before Level 1: arrow direction and clear
  exits, then blockers and a practice heart loss. Training grants no coins/stars
  or level completion. An animated hand demonstrates the highlighted arrow without
  auto-playing it. Completion is saved; Settings can replay practice.
- Classic arrow count grows from 30 to 200 over the first 800 levels; levels 801–6,000 continue with new 200-arrow boards and every tenth level is hard.
  Circle, diamond, shield and leaf silhouettes mix short arrows with long straight
  runs and larger bends. Boundary-first generation guarantees a removal order;
  quality gates check shape coverage, path-length variety and dependencies. Every
  tenth level is harder; boards support up to 5x zoom.
- Full-screen crystal-garden victory artwork with faceted gold stars, actual moves
  and active play time, first-win rewards, Next level, Replay and Home.
  Earned stars pop in sequence; three stars trigger a gold/cyan sparkle burst.
  Reduced-motion settings show the completed state immediately.
  Zero rated mistakes earns 3 stars, one earns 2, two earns 1. Pause/tutorial time
  is excluded. Best stars persist per level; replay never reduces a best rating.
- Editable garden: six spots, starter lantern, milestone-gated decorations, point
  purchases, free moving/removal and persistent ownership/placements. First paid
  decorations unlock after 50 completed levels; further items at 100, 150 and 200.
- Retained experimental Live Duel (hidden in the offline release): 60-second server-controlled timer, friend room codes,
  matchmaking, equal board sequences, score validation, reconnect and results.
  Run `dart server/duel_server.dart` from the repository root. Two players must
  use the same server. Public hosting is not configured; see `../server/README.md`.
- Original seeded bent-arrow puzzles, verified solvable by the shared engine.
- Sapphire-blue paths, cyan bevels, faceted arrowheads, depth shadows and animated exits using CustomPainter.
- Three hearts: blocked tap loses one, third mistake locks play, restart resets the same puzzle.
- Empty-space taps are ignored; animation locks suppress duplicate taps; pinch to zoom.
- Optional rewarded-ad hints in Classic; free practice hints, original synthesized sounds and haptics.
- Local completed-level/settings storage. First completion grants 40 coins / 10 garden points;
  replay does not duplicate rewards. Garden purchases use earned points only;
  there are no payments or in-app purchases.

## Run and verify

```powershell
flutter pub get
flutter analyze
flutter test
flutter build web --release --no-web-resources-cdn --no-wasm-dry-run
node tool/serve.cjs
```

Open http://127.0.0.1:8787. Keep this origin/port for browser progress continuity.
The preview server binds only to this computer. Browser storage requires localhost or HTTPS.
For Android, use `flutter run` with a connected device or `./tool/build-android.ps1`.
The script defaults to an optimized ARM64 release APK at
`build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`.
Use `./tool/build-android.ps1 -DebugBuild` only for development debugging.
This local release currently uses the existing debug signing key; Play Store
publishing requires a dedicated upload key. Keep the key consistent for updates.
APK download size differs from installed storage and runtime RAM use.

Tests cover all 6,000 level solutions, path geometry/non-overlap, hearts/restart,
safe hints, hit testing, local progress serialization, duplicate reward prevention,
and widget flows including three wrong taps, rapid-tap suppression, restart, win and next level.
Phone-size golden images are in `test/goldens`.

For a fast full-catalog audit, compile `tool/audit_levels.dart` with
`dart compile exe tool/audit_levels.dart -o build/audit_levels.exe`, then run
`build/audit_levels.exe`. It checks all 6,000 boards for exact uniqueness,
solvability, silhouette coverage, path connectivity, arrow count and hard-level
dependencies. The 2026-10-10 audit passed all 6,000 in 4 minutes 45 seconds.

## Scope and remaining work

The current app is an offline single-player build requiring no VPS or login. The 24-screen design
boards are concept references. Daily puzzles, solo Time Attack, public multiplayer hosting,
Google login/cloud sync, purchasable themes/shop and manual level difficulty curation
remain to implement. Live Duel currently uses unranked in-memory guest sessions.
The current renderer adds depth to a planar puzzle; it is not a
rotatable volumetric 3D world. Levels are solvability-validated but difficulty is not yet
playtested. Native device audio, haptics and performance still need device testing.

The app uses an ArrowNova-only storage namespace and does not connect to ChessVerse production.
Uninstalling/clearing local data can erase progress; there is no cloud backup yet.

## Reuse and assets

The gold button adapts ChessVerseButton's gradient wrapper/disabled-action pattern;
progress storage follows ChessVerse AuthSessionStore's secure-storage approach.
No chess logic or account data was copied. Cormorant Garamond is reused from ChessVerse's
font assets with its OFL license; Roboto is bundled with its license from the Flutter SDK.
Logo is the user-approved generated asset. `tool/generate_audio.cjs` creates original WAV cues.

## Android ads (test inventory)

Google Mobile Ads test banner is displayed in a separate footer outside practice.
Every two newly completed Classic levels makes one interstitial opportunity on
Next level (or when opening a level after returning home). Replays, failed attempts
and practice do not count. The counter persists, resets at the opportunity even if
inventory is unavailable, and never queues a late ad during gameplay. Offline play
continues without waiting for ad downloads. Ads initialize after the first frame,
only on Android, after UMP allows requests. Settings exposes ad privacy choices
when UMP requires them. Web and widget tests do not initialize the native SDK.

ArrowNova has its own AdMob app and three ad units in the existing account:

- App: `ca-app-pub-9061518700917881~3462287102`
- Banner: `ca-app-pub-9061518700917881/4239172993`
- Interstitial: `ca-app-pub-9061518700917881/1696855854`
- Rewarded (1 Hint): `ca-app-pub-9061518700917881/4798496062`

Default builds still use Google test inventory and generate no revenue.
`./tool/build-android.ps1 -LiveAds` selects the real app/ad units together using
`LIVE_ADS=true`. Never use live inventory for manual ad testing. Configure the
ArrowNova privacy message and public privacy policy, publish/link its store listing,
and complete AdMob readiness review before production rollout. Existing ChessVerse
configuration is unchanged. Store upload signing is still a separate release task.

Classic Hint offers an explicit Watch ad / Not now choice. Only the SDK earned-reward
callback awards a safe-arrow highlight; dismissal or missing inventory grants none.
There is no fixed 30-second timer: AdMob controls creative duration. Input and active
play time are paused during the offer/ad. Practice hints remain free. Banner,
interstitial and rewarded inventory all require UMP permission before loading.

References: https://developers.google.com/admob/flutter/privacy and
https://developers.google.com/admob/flutter/interstitial

## Daily challenge and reminders

Daily challenge is available from Home and works offline. A calendar date selects a
solvable rotated board, independently of Classic progression. The first completion
per date earns 40 coins / 10 garden points; replays can improve stars without farming
rewards. Local history and streaks persist in PlayerProgress.

Android reminders are opt-in in Settings and use local notifications around 09:00
in the phone timezone, plus a one-shot reminder after 24 hours away. Scheduling uses inexact alarms (no exact-alarm
permission); Android battery restrictions can delay them. Completing a daily board
reschedules remaining reminders from the next day. No push server or VPS is needed.
Notifications currently open the app, where Daily challenge is on Home. Native
permission, reboot, timezone and delivery behavior still need physical-device checks.

Published pages (10 October 2026), also linked in Settings:
- https://www.epitomehub.com/arrownova-privacy
- https://www.epitomehub.com/arrownova-support
- Contact: contactus@epitomehub.com

Page source copies are in ../design/legal/. The live site uses Hostinger Website
Builder; edit the existing pages there instead of replacing the business website.

European consent message "ArrowNova European consent" is published in AdMob for
ArrowNova only, with Consent / Do not consent / Manage options and the public
privacy URL above. Regional production behavior must still be checked on a test
device with UMP debug geography. Other regional/store disclosures and app review
remain release preparation tasks.

Validated on 10 October 2026: flutter analyze clean; 16 focused tests pass (daily,
rewarded hints, ad cadence, gameplay and animations). ARM64 test-ad release APK:
25,077,288 bytes; ZIP integrity verified; SHA-256
0e1079c207e0d8d4c4b3c451e1d0eaf7c87908450cfccf81cda9cb0a7aff686a.

Chapters: 60 worlds of 100 levels. Chapter 1 starts open. Finish/skip the preceding boundary level, then complete one explicitly chosen rewarded ad to unlock the next chapter. Unlocks persist locally; old saves retain chapters already reached. Chapter rewards reset the interstitial counter to avoid stacked ads. A rewarded skip at the boundary also opens the next chapter.
# Puzzle notifications

In Settings, enable **Puzzle reminders** and allow the phone notification
permission. The preference survives app restarts. A daily reminder is scheduled
for 9 AM in the phone's timezone; finishing today's daily puzzle moves that
reminder to tomorrow. One additional, non-repeating reminder is scheduled for
24 hours after the most recent app visit/schedule refresh. Opening the app
refreshes it. Turning the switch off cancels both, including retired reminder
slots from older builds. Android uses inexact alarms; device power restrictions
or force-stop can delay/prevent delivery. Real-device delivery remains to be
verified. These changes are included in version 0.2.21+23.

## Beginner and Endless puzzles (0.2.21)

Classic levels 1–30 increase from 5 to 30 arrows using short, solvable removal
chains. Existing unfinished early levels retain their original layout until
completed. Levels 31–6000 retain their released geometry.

Home now has a separate Endless puzzles entry. Round seeds generate repeatable
offline boards, growing from 10 to a maximum of 80 arrows, with no 6000-round
limit. Each completed round earns 40 coins and 10 garden points once; the next
round and unfinished board persist independently of Classic and Daily progress.
The result screen offers Next round. Default Level colours rotate blue, green
and graphite; purchased themes still override the default palette.

Classic continuation: after level 6000, Next level opens generated level 6001,
then 6002 and onwards in the same journey. Continue journey resumes that level
and its saved arrows. These levels retain Classic stars and one-time rewards;
there is no extra chapter-unlock ad gate after the original 60 chapters. The
world browser retains the original chapters and offers a continuation button.

## Garden studio (0.2.23)

Twelve decorations include six new transparent sprites: roses, lavender, a jade
jar, a wicker armchair, a sapphire sofa and a lily vase. Flowers, Pots & jars,
Furniture, Landmarks, Owned and Premium filters help browse the collection.
The garden supports twelve placement spots; drag placed objects to adjust their
position. Ownership and custom positions survive restarts. Existing six spots
and existing purchase costs retain their prior meaning.

The sofa and lily vase each require three optional rewarded-ad credits. Only
an earned SDK reward advances the selected item's counter. Dismissed, failed or
unavailable ads leave it unchanged. A busy guard prevents parallel requests;
each ad requires another explicit tap. Credits are saved after each earned ad,
and the third unlocks ownership without spending garden points. No additional
ad is required to place or move an owned item. All progress is device-local.

Uses the existing rewarded ad unit/service and its consent and recovery flow.
New art was generated with built-in image_gen; prompts are recorded in
../docs/garden-art-prompts.json. Original alpha and dimensions are retained in
WebP assets under assets/art/garden/ (approximately 1.4 MB total).
