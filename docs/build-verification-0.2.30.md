# ArrowNova 0.2.30 (32) release verification

Signed Google Play AAB: mobile/ArrowNova-0.2.30-play.aab (30,613,624 bytes).
SHA-256: f30825e57e675b7b0fc817ef6c715d33af714a67f48506494c70aa42773bb84d.

The old balance calculation is retained. Only new shop spending is subtracted; pre-existing theme and room ad ownership are preserved. Seven Amber Studio items cost 120–400 coins and are owned per room. The 200-coin shield bridges one missed day without adding a win or rewards. The reminder switch stays opt-in; existing enabled players default to one slot. Settings allow one, two or four eligible reminders. Explicit local dates are scheduled in batches of seven occurrences for repeating slots and refreshed on app use, avoiding Android time-only alarms firing on a suppressed day. Extended absences do not produce indefinite reminders.

Regression checks included legacy balance migration, duplicate buys, insufficient funds, saved room ownership, actual shield/sofa purchase and placement, streak gaps, shield exhaustion, conditional reminders, 4-to-1-to-off alarm cancellation, and save/reopen. The broad run excluded the unchanged exhaustive 6000-level generator. Its three initial failures were the changed shop golden and outdated scheduler expectations; all affected tests passed on rerun. Dart analysis: no issues found. No physical-device upgrade or notification-delivery test was performed.

Flutter reported a post-build native symbol stripping error. The fresh raw and compact AAB passed bundletool validation. Manifest package com.epitomehub.arrownova, version 0.2.30, code 32. Signature verified; 425 runtime entries identical after detaching diagnostics. Production ad IDs checked in all three ABIs. All six modified feature sources were found verbatim in the compiled release kernel; AAB machine code and read-only data sections match the Flutter AOT output for each ABI. No Play submission was performed.
