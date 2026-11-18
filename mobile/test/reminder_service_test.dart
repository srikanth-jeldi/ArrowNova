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
      if (call.method == 'pendingNotificationRequests') return [];
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
    expect(calls.where((c) => c.method == 'zonedSchedule').length, 7);
  });

  test('four-slot alarms respect local dates and switching off removes them', () async {
    final pending=<int,Map>{};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(notifications,(call) async {
      if(call.method=='initialize') return true;
      if(call.method=='pendingNotificationRequests') return [for(final id in pending.keys){'id':id,'title':'ArrowNova'}];
      if(call.method=='zonedSchedule') {final a=call.arguments as Map;pending[a['id'] as int]=Map.of(a);}
      if(call.method=='cancel') pending.remove((call.arguments as Map)['id']);
      return null;
    });
    final reminders=DailyReminders();
    await reminders.initialize();
    final now=tz.TZDateTime.now(tz.local);
    expect(await reminders.sync(true,{dayKey(now)},limit:4,unfinished:true,streak:3),true);
    final counts=<String,int>{};
    for(final a in pending.values) {
      expect(a.containsKey('matchDateTimeComponents'),false);
      final d=DateTime.parse(a['scheduledDateTime']);
      final k=dayKey(d);
      counts[k]=(counts[k]??0)+1;
      if(d.hour==9 || d.hour==20) expect(k,isNot(dayKey(now)));
    }
    expect(pending.length,22);expect(counts.values.every((v)=>v<=4),true);
    expect(await reminders.sync(true,{},limit:1),true);
    expect(pending.length,7);
    expect(await reminders.sync(false,{}),true);
    expect(pending,isEmpty);
  });

  test('permission denial does not schedule notifications', () async {
    permission = false;
    expect(await DailyReminders().enable({}), isFalse);
    expect(calls.where((c) => c.method == 'zonedSchedule'), isEmpty);
  });

  test('daily completion skips today with the one-per-day limit', () async {
    final reminders = DailyReminders();
    await reminders.initialize();
    final now = tz.TZDateTime.now(tz.local);
    expect(await reminders.enable({dayKey(now)}), isTrue);
    final scheduled = calls
        .where((c) => c.method == 'zonedSchedule')
        .map((c) => c.arguments as Map)
        .toList();
    expect(scheduled.length, 7);
    final daily = scheduled.first;
    expect(
      DateTime.parse(daily['scheduledDateTime']),
      DateTime(now.year, now.month, now.day + 1, 9),
    );
    expect(daily.containsKey('matchDateTimeComponents'), false);
  });

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
