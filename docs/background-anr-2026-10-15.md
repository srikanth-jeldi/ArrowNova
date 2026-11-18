# Background ANR and ad recovery investigation

Date: 15 October 2026
Device: Samsung SM-F415F, Android 12, installed Play package com.epitomehub.arrownova 0.2.26 (28).

## Evidence

Device DropBox contains two ANRs for version 28 at 00:45 and 11:31. Both concern SCREEN_OFF broadcast delivery. Main thread is Runnable in MessageQueue.enqueueMessage / Handler.post / FlutterJNI.handlePlatformMessage. One report shows app CPU at 169 percent. During this session a cpuinfo sample reached 156 percent around backgrounding after entering the saved puzzle; a later sample settled to 0.4 percent. These samples are not a sustained CPU benchmark.

The app called MusicService.setEnabled on every save, which queued another resume even while playing. Installed audioplayers 6.8.1 uses FramePositionUpdater by default: start invokes another tick/schedule chain without checking whether a chain is already running. This provides a concrete mechanism for growing native platform position calls. The ANR stack is consistent with it; the trace alone does not label the channel, so it is not proof of every reported freeze's sole cause.

Production ad logs show creative setup followed by a video preload timeout with a 300000 ms limit. This proves a failed creative download during the observed attempt, not an AdMob account restriction. Existing code discarded LoadAdError details and did not retry failed banner/startup initialization. Live-ad account Policy centre could not be inspected because the browser automation runtime failed to start twice.

## Changes

Music and effects no longer poll playback position (there is no scrubber). Music settings and lifecycle transitions are idempotent; a currently playing player is not resumed again. Audio disposal errors are caught.

Ad startup retries on foreground return and at 30-second foreground intervals without bypassing consent. Failed banner loads retry at 30-second intervals; no new retry requests while backgrounded. Full-screen load errors now log code/domain/message. Missing fullscreen load callbacks are retired after six minutes (beyond the observed five-minute media preload timeout), with request tokens rejecting stale callbacks. Existing ad display sessions keep their separate two-second opening recovery; gameplay never waits six minutes for inventory.

The dynamically referenced ic_notification resource is retained after a production log reported that shrinking removed it.

## Automated validation

11 focused music, audio, ad-session and completion recovery tests passed. New music regression covers 500 repeated settings/save updates and 20 background/resume cycles. A separate offline-consent recovery test passed, including no retry while backgrounded and no ad readiness without consent. Final device results are recorded below when completed.

Existing 0.2.26 production AAB is unchanged. Fixes require a new release to reach Play users.

## Physical QA build and device check

Final release-mode arm64 QA APK: mobile/ArrowNova-background-fix-QA.apk (separate com.epitomehub.arrownova.audit package, DEVICE_AUDIT=true, LIVE_ADS=false). Installed successfully on the connected Samsung. Original Play app data was not cleared or replaced. Final flutter analyze --no-pub: no issues.

Both practice boards completed, then classic level 1 completed in five moves and displayed the result screen with 40 coins and 10 garden points. The test banner was visibly labelled Test Ad and rendered successfully. Next Level was tapped and five HOME/background-return cycles brought the existing task forward. The subsequent SCREEN_OFF test disconnected wireless ADB before the final screen/exit-info capture; reconnect to the previously advertised address was refused, so screen-off recovery and absence of fresh ANRs are not yet verified. The successful short checks are not a guarantee against future crashes. Rewarded playback and live ad inventory remain unverified.

The AdMob browser runtime retry also failed to start (trusted Node process exited unexpectedly). Account Policy centre restrictions must still be inspected through a working browser session or a user-provided screenshot.

## Follow-up stability audit

Additional fixes: asynchronous native ad disposal errors are contained and logged; stale interstitial inventory is disposed even when consent becomes unavailable. Consent recovery/resume cannot stack another form while a consent/privacy form is open. Native haptic errors no longer escape an unawaited future. Audio stop/disposal attempts every output even if one fails; repeated disposal is ignored.

Focused failure-injection suite: 12 tests passed (ad cleanup, long consent form, haptic failure, independent audio cleanup, repeated music lifecycle and offline consent recovery). A separate gameplay lifecycle stress test passed: background during an arrow exit, 30 background/resume cycles, preserved removed-arrow checkpoint, complete the puzzle and open level 2. Static analysis: no issues.

A local JIT generation timing sample for levels 31, 300, 800, 1000, 3500, 6000 and 6001 ranged from 3 to 291 milliseconds on this development computer; this is not a mobile-device performance guarantee. The generator has bounded attempts and caches at most 24 classic layouts. No native app-owned blocking work was found in MainActivity (plain FlutterActivity).

Full existing suite (including every dense layout 31–6000) and updated QA APK build were started. Final results follow. Device is disconnected, so new physical screen-off/recovery checks remain pending; no claim of zero future crashes or production release readiness is made.

Updated QA APK built successfully after the follow-up fixes (release mode, arm64, separate QA package/test ads). SHA-256: 1FCB52C38FD4403D81A50CA80C198213F13206AAA408F48EF2EAD10F6EA01B45. This replaces the earlier QA artifact on disk; it has not been installed because the device remains disconnected. The prior QA build is still the last build installed on the phone.

Final regression result: 120 tests passed in 96 seconds using flutter test --no-pub --name '^(?!dense levels 31 through 6000)'. This runs the functional suite and sampled/end-point puzzle checks, excluding only the unchanged exhaustive dense-layout enumeration. The earlier exhaustive run was deliberately interrupted while still running; it is not reported as passed. Final analyzer was clean and git diff --check reported no whitespace errors.

Release gate remains physical-device verification of the latest artifact: cold start, idle/game backgrounding, screen lock/unlock, repeated rewarded-test-ad dismissal, and fresh ANR/crash logs. Wireless ADB still reports no devices. No new production AAB was published or generated in this follow-up.
