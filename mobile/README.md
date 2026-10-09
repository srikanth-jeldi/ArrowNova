# ArrowNova — first playable build

Flutter Android app and local web preview for EpitomeHub Technologies.

## Implemented

- Approved A-and-arrow logo, navy/gold UI, offline bundled fonts.
- Home, 500-level journey, tutorial, Classic game, pause, failure and victory.
- First three levels are hand-authored interactive lessons: exits, blockers/hearts,
  then clearing dependencies. Level 2's required practice mistake costs a heart
  but is excluded from the star rating. Later mistakes follow the normal rules.
- Full-screen crystal-garden victory artwork with faceted gold stars, actual moves
  and active play time, first-win rewards, Next level, Replay and Home.
  Zero rated mistakes earns 3 stars, one earns 2, two earns 1. Pause/tutorial time
  is excluded. Best stars persist per level; replay never reduces a best rating.
- Editable garden: six spots, starter lantern, milestone-gated decorations, point
  purchases, free moving/removal and persistent ownership/placements. First paid
  decorations unlock after 50 completed levels; further items at 100, 150 and 200.
- Anonymous Live Duel: 60-second server-controlled timer, friend room codes,
  matchmaking, equal board sequences, score validation, reconnect and results.
  Run `dart server/duel_server.dart` from the repository root. Two players must
  use the same server. Public hosting is not configured; see `../server/README.md`.
- Original seeded bent-arrow puzzles, verified solvable by the shared engine.
- Shallow 3D bevels, shadows, highlights and animated path exits using CustomPainter.
- Three hearts: blocked tap loses one, third mistake locks play, restart resets the same puzzle.
- Empty-space taps are ignored; animation locks suppress duplicate taps; pinch to zoom.
- Free safe-path hints for this prototype, optional original synthesized sounds and haptics.
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

Tests cover all 500 level solutions, path geometry/non-overlap, hearts/restart,
safe hints, hit testing, local progress serialization, duplicate reward prevention,
and widget flows including three wrong taps, rapid-tap suppression, restart, win and next level.
Phone-size golden images are in `test/goldens`.

## Scope and remaining work

This is a playable Classic foundation, not the complete release. The 24-screen design
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
