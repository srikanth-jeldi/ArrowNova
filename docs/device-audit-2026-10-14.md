# Samsung F41 device smoke test — 2026-10-14

Device: Samsung SM-F415F, Android 12, wireless ADB.
Installed application at start: com.epitomehub.arrownova, 0.2.24 (26).

Observed checks:
- Cold launcher activity startup: 598 ms; restart: 773 ms (ADB activity timing, not a full frame-render benchmark).
- Resumed level 46 at 32/39 cleared; completed remaining arrows; victory screen reached.
- Next level opened level 47.
- Force stop and relaunch retained 46 completed levels, level 47 and 1900 coins (previously 45 completed / 1860 coins).
- Home/garden screen opened.
- No new crash buffer entries or ANR events during the test window beginning 22:31 local device time. Current process log showed no FATAL/Unhandled/E-flutter entries in the inspected filter.
- App PSS approximately 178 MiB at home and 246 MiB after navigation; this is a short observation, not proof of no leaks.
- Crash buffer contained historical October 10 WorkDatabase initialization crashes. Existing source ProGuard rules retain RoomDatabase constructors. These old records are not current-test failures.

Evidence: mobile/.build-tmp/device-audit/ (screenshots, exit history and current-session log).
Latest-source QA application testing pending; the above only validates installed 0.2.24 behavior.

## Latest-source QA build

Built release-mode APK with DEVICE_AUDIT=true and test ads, installed under com.epitomehub.arrownova.audit (ArrowNova QA), version 0.2.25 (27). Main app retained. APK saved as mobile/ArrowNova-0.2.25-device-QA.apk; this is a separate QA package, not for Play upload.

First launch reached the home screen. ADB activity start was 2185 ms. Log showed one startup Choreographer warning for 97 skipped frames; this requires further startup profiling and is not classified as an ANR. No FATAL/Unhandled/E-flutter entries appeared in that inspected process filter.

Wireless ADB disconnected before QA gameplay and new Home Decor checks. Both `adb devices -l` and `adb mdns services` became empty. User was asked to reconnect. Latest-source gameplay, save, bounce animation and 2D decor physical-device testing remain incomplete.

## Reconnected QA session (22:53–22:59)

- QA cold activity launch: 461 ms; subsequent cold launches 547 ms and 553 ms (activity timing only).
- Started at level 4, 3 levels completed / 120 coins (user had already played the QA app).
- One blocked tap consumed exactly one heart; two safe arrows cleared.
- Force-stop/relaunch restored exactly 2/7 cleared and 2 hearts.
- Completed remaining five arrows; victory showed level 4 complete, 160 coins. Next-level action and relaunch retained 4 completed levels / 160 coins.
- Opened 2D Home Decor, browsed catalogue, placed free sofa and backgrounded/resumed successfully.
- Current QA process filter had no FATAL, Unhandled, E/flutter or skipped-frame messages during this reconnect session. Crash buffer and event-buffer am_anr/am_crash checks for the session were empty. Exit history contained user-requested shutdowns and unused isolated-process cleanup, not crash/ANR reasons.
- PSS after decor/background/resume: 223401 KiB (~218 MiB). This is a smoke test, not a sustained leak benchmark.
- Startup 97-frame warning from first installation remains a profiling observation; it did not recur in the inspected reconnect-session filter.
- No exhaustive dense-level, long-duration soak, premium three-ad unlock or broad device matrix test performed.

During testing the user requested a Perfect emoji. Source now shows a pulsing glowing-star symbol next to Perfect; 7 animation/fireworks tests passed. That last UI edit is not in the installed QA APK or previously delivered production AAB.
