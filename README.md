# ArrowNova

An offline single-player Flutter arrow puzzle game by EpitomeHub Technologies.
Levels, tutorials and garden decoration need no login or VPS. Multiplayer
source is retained for future development but has no app entry point.

Platform status: Android and web builds are supported. The iOS runner now includes
icons, keychain configuration, test ads and opt-in local reminders. iOS has not
been compiled or tested on a Mac/iPhone; signing and App Store submission remain
pending. See `mobile/ios/RELEASE.md` for the native release requirements.

## Included

- 800 Classic levels and two separate guided practice rounds before Level 1.
- Raised glass-style arrow paths, three hearts, hints and retry.
- Crystal-garden victory screen, performance stars and local progress storage.
- Garden decorations, milestone unlocks and earned-point purchases.
- 30–200 arrows per level, with mixed short/long paths in four silhouette shapes.
- Experimental duel source retained separately for future development.
- Rewarded hints and Classic skips (skips grant no stars or currency).
- Daily Chest: one rewarded ad unlocks five hard puzzles until local midnight.
- Original ambient music with a separate toggle, lifecycle/ad pause, and move sounds.

## Run

From `mobile/`, run `flutter pub get` then `flutter run` with a supported device.
For the local browser preview:

```powershell
cd mobile
flutter build web --release --no-web-resources-cdn --no-wasm-dry-run
node tool/serve.cjs
```

Open http://127.0.0.1:8787. Solo play needs no server.
For multiplayer development only, from the repository root:

```powershell
dart server/duel_server.dart
```

Two clients use `ws://127.0.0.1:8788/duel` by default. See
[server setup](server/README.md) for USB phone connections and hosting configuration.

## Verify

```powershell
cd mobile
flutter analyze
flutter test
cd ..
dart server/duel_server_test.dart
dart analyze server
```

## Project layout

- [mobile](mobile/README.md): app source, assets, tests and build helper scripts.
- [server](server/README.md): local multiplayer service and real-socket tests.
- `design/`: approved visual references and screen specifications.

This is a development build. Public multiplayer hosting is not configured.
Physical-device performance/haptics testing remains pending. Puzzle difficulty
has not been manually curated. Solo Time Attack, cloud accounts,
and paid themes/shop are not implemented. Sessions are unranked and in-memory;
progress and garden saves are local to each device.

Generated builds, credentials, caches and local logs are excluded from Git.
