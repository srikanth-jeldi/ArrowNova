import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arrownova/core/reminders.dart';
import 'package:arrownova/game/daily.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const notifications = MethodChannel(
    'dexterous.com/flutter/local_notifications',
  );
  const timezone = MethodChannel('flutter_timezone');
  final calls = <MethodCall>[];
  var permission = true;
  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    calls.clear();
    permission = true;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(timezone, (_) async => 'Asia/Kolkata');
    messenger.setMockMethodCallHandler(notifications, (call) async {
      calls.add(call);
      if (call.method == 'requestNotificationsPermission') return permission;
      if (call.method == 'initialize') return true;
      return null;
    });
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(timezone, null);
    messenger.setMockMethodCallHandler(notifications, null);
  });

  test('Android legacy Calcutta timezone schedules reminders', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(timezone, (_) async => 'Asia/Calcutta');
    expect(await DailyReminders().enable({}), isTrue);
    expect(tz.local.name, 'Asia/Calcutta');
    expect(calls.where((c) => c.method == 'zonedSchedule').length, 2);
  });

  test('permission denial does not schedule notifications', () async {
    permission = false;
    expect(await DailyReminders().enable({}), isFalse);
    expect(calls.where((c) => c.method == 'zonedSchedule'), isEmpty);
  });

  test(
    'daily completion skips today; inactivity reminder is once after 24h',
    () async {
      final reminders = DailyReminders();
      await reminders.initialize();
      final now = tz.TZDateTime.now(tz.local);
      expect(await reminders.enable({dayKey(now)}), isTrue);
      final scheduled = calls
          .where((c) => c.method == 'zonedSchedule')
          .map((c) => c.arguments as Map)
          .toList();
      expect(scheduled.length, 2);
      final daily = scheduled.singleWhere((c) => c['id'] == 9100);
      final nextDay = DateTime(now.year, now.month, now.day + 1, 9);
      expect(DateTime.parse(daily['scheduledDateTime']), nextDay);
      expect(daily.containsKey('matchDateTimeComponents'), isTrue);
      final away = scheduled.singleWhere((c) => c['id'] == 9103);
      expect(away.containsKey('matchDateTimeComponents'), isFalse);
      final hours = DateTime.parse(away['scheduledDateTime'])
          .difference(
            DateTime(
              now.year,
              now.month,
              now.day,
              now.hour,
              now.minute,
              now.second,
            ),
          )
          .inSeconds;
      expect(hours, inInclusiveRange(86400, 86405));
    },
  );

  test('later disable cancels all slots after an overlapping enable', () async {
    final reminders = DailyReminders();
    final enabling = reminders.sync(true, {});
    final disabling = reminders.sync(false, {});
    expect(await enabling, isTrue);
    expect(await disabling, isTrue);
    final tail = calls.skipWhile((c) => c.method != 'zonedSchedule').toList();
    expect(
      tail.sublist(tail.length - 4).every((c) => c.method == 'cancel'),
      isTrue,
    );
    expect(
      tail
          .sublist(tail.length - 4)
          .map((c) => (c.arguments as Map)['id'])
          .toSet(),
      {9100, 9101, 9102, 9103},
    );
  });
}
