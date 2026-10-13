import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arrownova/core/ad_session.dart';

void main() {
  testWidgets('missing show reply recovers once in five seconds', (
    tester,
  ) async {
    var finishes = 0;
    final session = AdSession(() => finishes++);
    await tester.pump(const Duration(seconds: 5));
    expect(finishes, 1);
    session.markShown();
    session.finish();
    await tester.pump(const Duration(seconds: 20));
    expect(finishes, 1);
  });

  testWidgets(
    'visible ad is not cut short; missing dismissal recovers on return',
    (tester) async {
      var finishes = 0;
      final session = AdSession(() => finishes++);
      session.markShown();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(minutes: 2));
      expect(finishes, 0);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(seconds: 1));
      expect(finishes, 1);
      session.finish();
      expect(finishes, 1);
    },
  );

  testWidgets('normal dismissal cancels every recovery timer', (tester) async {
    var finishes = 0;
    final session = AdSession(() => finishes++);
    session.markShown();
    session.finish();
    await tester.pump(const Duration(minutes: 1));
    expect(finishes, 1);
  });

  testWidgets('shown ad has no arbitrary video duration limit', (tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    var finishes = 0;
    final session = AdSession(() => finishes++);
    session.markShown();
    await tester.pump(const Duration(minutes: 3));
    expect(finishes, 0);
    session.finish();
    expect(finishes, 1);
  });
}
