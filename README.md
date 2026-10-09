# ArrowNova

A Flutter arrow puzzle game by EpitomeHub Technologies, with a local Dart
WebSocket service for anonymous two-player duels.

## Included

- 500 solvability-validated Classic levels and three interactive tutorial levels.
- Raised glass-style arrow paths, three hearts, hints and retry.
- Crystal-garden victory screen, performance stars and local progress storage.
- Garden decorations, milestone unlocks and earned-point purchases.
- 60-second guest duels with friend codes, matchmaking, server-validated moves,
  reconnect handling and results.

## Run

From `mobile/`, run `flutter pub get` then `flutter run` with a supported device.
For the local browser preview:

```powershell
cd mobile
flutter build web --release --no-web-resources-cdn --no-wasm-dry-run
node tool/serve.cjs
```

Open http://127.0.0.1:8787. From the repository root, start the duel server:

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
has not been manually curated. Daily mode, solo Time Attack, cloud accounts,
and paid themes/shop are not implemented. Sessions are unranked and in-memory;
progress and garden saves are local to each device.

Generated builds, credentials, caches and local logs are excluded from Git.
