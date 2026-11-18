# Stability audit — 2026-10-14

Source hardening after the packaged 0.2.25 (27) AAB:

- Failed/timed-out startup reads lock writes until a successful read; original saved progress cannot be replaced by an empty session. Home explains that the temporary session is not saved and asks for a restart.
- Malformed optional collection fields are ignored while valid level progress is retained. Invalid JSON is preserved rather than overwritten.
- Removed full progress JSON reconstruction on every gameplay save. ProgressStore still captures immutable JSON synchronously and coalesces queued checkpoints.
- Home Decor gallery builds visible entries lazily, with coverage for 1,000 completed rooms.
- Updated completion test timing for the longer arrow animation; victory golden waits for image decoding instead of capturing the placeholder.

Validation: initial broad regression (excluding exhaustive dense levels 31–6000 catalogue sweep) passed 108 tests; two test fixture failures were corrected (animation timing and image preload). Focused app/decor/storage rerun passed 16 tests; analyzer clean. Additional final decor/storage rerun recorded in the task.

Limits: no Android device stress test, native crash traces, ANR traces, or production telemetry were available in this audit. Dense level generation remains synchronous and requires low-end-device profiling; do not claim this audit proves ANR-free operation. Test background/foreground, ads offline/cancel/failure, completed-level relaunch and long gallery sessions on the actual signed release before production rollout. Existing ads recovery, reward gating, save coalescing and lifecycle tests passed in the broad regression.

The delivered mobile/ArrowNova-0.2.25-play.aab predates these source fixes; it has not been overwritten or re-published. A subsequent release build is required to distribute them.
