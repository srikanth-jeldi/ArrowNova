import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../game/daily.dart';

DateTime nextReminder(DateTime now, int hour, bool completedToday) {
  var day = DateTime(now.year, now.month, now.day, hour);
  if (completedToday || !day.isAfter(now)) {
    day = DateTime(now.year, now.month, now.day + 1, hour);
  }
  return day;
}

class DailyReminders {
  static final instance = DailyReminders();
  final plugin = FlutterLocalNotificationsPlugin();
  Future<bool>? _initialization;
  bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  Future<bool> initialize() => _initialization ??= _initialize();
  Future<bool> _initialize() async {
    if (!supported) return false;
    try {
      tzdata.initializeTimeZones();
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
      await plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_notification'),
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> enable(Set<String> completed) async {
    if (!await initialize()) return false;
    final allowed =
        await plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission() ??
        false;
    if (!allowed) return false;
    return sync(true, completed);
  }

  Future<bool> sync(bool enabled, Set<String> completed) async {
    if (!await initialize()) return false;
    try {
      // Refresh timezone when the app resumes, including travel and DST changes.
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
      for (var i = 0; i < 3; i++) {
        await plugin.cancel(id: 9100 + i);
      }
      if (!enabled) return true;
      final now = tz.TZDateTime.now(tz.local);
      final done = completed.contains(dayKey(now));
      const hours = [9, 13, 19];
      const messages = [
        'Your daily arrow puzzle is ready. Take a little focus break.',
        'A few quiet moves? Your daily challenge is waiting.',
        'Unwind with today’s ArrowNova puzzle and grow your garden.',
      ];
      for (var i = 0; i < hours.length; i++) {
        final next = nextReminder(now, hours[i], done);
        await plugin.zonedSchedule(
          id: 9100 + i,
          title: 'ArrowNova Daily Challenge',
          body: messages[i],
          scheduledDate: tz.TZDateTime(
            tz.local,
            next.year,
            next.month,
            next.day,
            next.hour,
          ),
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'daily_challenge',
              'Daily challenge reminders',
              channelDescription: 'Optional reminders at 9 AM, 1 PM and 7 PM',
              importance: Importance.defaultImportance,
              priority: Priority.defaultPriority,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: 'daily',
        );
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
