# Optional update reminder

Implemented after the 0.2.28 (30) AAB was generated. That existing AAB does not contain this change; include it in the next versioned store build.

After saved progress finishes loading and the home screen renders, query Google Play asynchronously. Only an update available to the current Play account/device/track triggers the dialog. Update opens the app listing (with browser fallback); Later or dismissal continues playing. The same available version is reminded at most once every 24 hours, persisted in Android preferences. A newer available version can prompt sooner. One check per home-screen session; no polling during gameplay.

The check times out after three seconds without blocking loading or gameplay. A late result is ignored if another route is open, the app is backgrounded, or a puzzle is opening. No forced updates are implemented.

Existing installed versions without this feature cannot show this custom prompt retroactively.

Validation: update_reminder_test.dart covers available updates/Later, one check per session, no update, Play service failure, late results after navigation, and timeout. To validate real eligibility and reminder persistence, install a lower version containing this integration from a Play testing track, publish a higher version accessible to the same account, and verify Update opens the listing. Also test Later followed by restart, backgrounding during the query, and offline launch.

Official API: https://developer.android.com/guide/playcore/in-app-updates/kotlin-java
