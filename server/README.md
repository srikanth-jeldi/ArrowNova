# ArrowNova Live Duel

Anonymous, unranked 60-second WebSocket duels. No ChessVerse account or production
service is used. Start with the installed Dart SDK:

```powershell
dart server/duel_server.dart
dart server/duel_server_test.dart
```

Default address is `ws://127.0.0.1:8788/duel`; health is `/health`.
The server binds localhost by default. Two browser tabs on this computer can use
Find opponent, or Create friend room / Join friend with a six-character code.
For a USB Android phone, `adb reverse tcp:8788 tcp:8788` exposes the same server
to the phone without a firewall change. Both players must use the same server.

The server owns puzzle geometry, allowed moves, score, countdown, deadline and result.
Both players receive the same ordered boards and advance independently. A clear arrow
is one point; a blocked tap imposes a one-second cooldown. No Classic hearts or hints.
Equal scores draw. Replayed sequences, duplicate arrows, stale boards and post-deadline
taps do not score. Client-provided scores are ignored. Reconnect with the opaque guest
token restores progress; the clock keeps running and 15 seconds disconnected forfeits.
Leaving explicitly forfeits immediately. No bots fill empty queues.

Session tokens exist only in memory on each client and must not be logged or shared.
Rooms/results expire after five minutes. Server restart loses sessions. Each connection
has an application message limit and a hello deadline; this is a single-process playtest
service, without persistent accounts, ranked leaderboards or multi-instance coordination.
Automated solving is not prevented; this service does not claim competitive anti-cheat.

## Hosting handoff

Public hosting is not configured. Container build from repository root:

```text
docker build -f server/Dockerfile -t arrownova-duel .
```

Set HOST=0.0.0.0 and PORT to the hosting platform's assigned port. Put the service behind
HTTPS with WebSocket upgrades and a timeout longer than a match. Build clients with
`--dart-define=DUEL_URL=wss://YOUR_DOMAIN/duel`. Release clients require wss for public
hosts. Debug Android permits cleartext only to support local testing; the main manifest
does not globally enable cleartext. Validate two real clients, reconnect and restart
behavior on the selected host before calling it publicly available.

Integration tests exercise real sockets, private rooms, invalid codes, identical boards,
score authority, duplicate/late taps, reconnect, matchmaking, disconnect forfeits and draws.

## Isolated VPS pilot (not deployed)

`compose.pilot.yml` defines a separate `arrownova` Compose project. It has no
ChessVerse networks, volumes, database connections or Docker socket mounts. It binds
only host loopback port 8788 and applies an initial 0.5 CPU / 512 MiB memory cap,
64-process limit, capped logs, non-root user and read-only filesystem. These limits
are a starting point for testing, not a measured capacity or a no-crash guarantee.

Use a prebuilt image via ARROWNOVA_IMAGE; do not compile images on the live shared
VPS during peak traffic. This configuration has not been validated on that VPS.
Before starting it, inspect actual memory availability, peak CPU, existing container
limits/health, OOM events and whether port 8788 is free. Record ChessVerse health
before and during the pilot. Stop only the ArrowNova service if ChessVerse health
or latency degrades. Do not run a shared Compose down, Docker prune, server reboot,
or change ChessVerse containers to deploy ArrowNova.

Public routing is intentionally absent. Inspect the existing reverse proxy first,
then add a separate hostname and validate its configuration before a graceful reload.
Resource limits reduce contention but cannot eliminate shared-host or proxy risks.
