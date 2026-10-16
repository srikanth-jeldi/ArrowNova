import 'dart:async';

import 'package:arrownova/core/update_reminder.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  late BuildContext homeContext;
  late UpdateReminder reminder;
  late List<MethodCall> calls;

  Future<void> mount(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            homeContext = context;
            return const Scaffold(body: Text('Play puzzle'));
          },
        ),
      ),
    );
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  }

  setUp(() {
    reminder = UpdateReminder();
    calls = [];
  });
  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      UpdateReminder.channel,
      null,
    );
  });

  testWidgets(
    'available update offers Later and only prompts once per session',
    (tester) async {
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        UpdateReminder.channel,
        (call) async {
          calls.add(call);
          return call.method == 'check' ? 31 : null;
        },
      );
      await mount(tester);
      final pending = reminder.check(homeContext, ready: () => true);
      await tester.pumpAndSettle();
      expect(find.text('A new update is ready!'), findsOneWidget);
      expect(find.text('Update'), findsOneWidget);
      expect(calls.last.arguments, {'version': 31});
      await tester.tap(find.text('Later'));
      await tester.pumpAndSettle();
      await pending;
      await reminder.check(homeContext, ready: () => true);
      expect(calls.where((call) => call.method == 'check'), hasLength(1));
      expect(find.text('Play puzzle'), findsOneWidget);
    },
  );

  testWidgets('no update or Play failure leaves game usable', (tester) async {
    await mount(tester);
    for (final fail in [false, true]) {
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        UpdateReminder.channel,
        (call) async {
          if (fail) throw PlatformException(code: 'UNAVAILABLE');
          return null;
        },
      );
      final pending = UpdateReminder().check(homeContext, ready: () => true);
      await tester.pumpAndSettle();
      await pending;
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Play puzzle'), findsOneWidget);
    }
  });

  testWidgets('late check never interrupts a puzzle or marks reminder shown', (
    tester,
  ) async {
    final response = Completer<int?>();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      UpdateReminder.channel,
      (call) {
        calls.add(call);
        return response.future;
      },
    );
    await mount(tester);
    final pending = reminder.check(homeContext, ready: () => true);
    unawaited(
      Navigator.of(homeContext).push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Puzzle running')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    response.complete(31);
    await tester.pumpAndSettle();
    await pending;
    expect(find.byType(AlertDialog), findsNothing);
    expect(calls.where((call) => call.method == 'shown'), isEmpty);
  });

  testWidgets('stalled check times out without blocking startup', (
    tester,
  ) async {
    final response = Completer<int?>();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      UpdateReminder.channel,
      (_) => response.future,
    );
    await mount(tester);
    final pending = reminder.check(homeContext, ready: () => true);
    await tester.pump(const Duration(seconds: 4));
    await pending;
    response.complete(31);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Play puzzle'), findsOneWidget);
  });
}
