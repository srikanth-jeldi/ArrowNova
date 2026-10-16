import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../game/daily.dart';

DateTime nextReminder(DateTime now, int hour, bool completedToday) {
  var day = DateTime(now.year, now.month, now.day, hour);
  if (completedToday || !day.isAfter(now)) {
    day = DateTime(now.year, now.month, now.day + 1, hour);
  }
  return day;
}

DateTime inactivityReminder(DateTime lastActive) =>
    lastActive.add(const Duration(hours: 24));

class DailyReminders {
  static final instance = DailyReminders();
  final plugin = FlutterLocalNotificationsPlugin();
  Future<bool>? _initialization;
  Future<bool> _queue = Future.value(true);
  bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  Future<bool> initialize() async {
    final ready = await (_initialization ??= _initialize());
    if (!ready) _initialization = null;
    return ready;
  }

  Future<bool> _initialize() async {
    if (!supported) return false;
    try {
      tzdata.initializeTimeZones();
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
      await plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_notification'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      return true;
    } catch (error) {
      debugPrint('Reminder initialization failed: $error');
      return false;
    }
  }

  Future<bool> enable(Set<String> completed) async {
    try {
      if (!await initialize()) return false;
      final allowed = defaultTargetPlatform == TargetPlatform.iOS
          ? await plugin
                    .resolvePlatformSpecificImplementation<
                      IOSFlutterLocalNotificationsPlugin
                    >()
                    ?.requestPermissions(
                      alert: true,
                      badge: false,
                      sound: true,
                    ) ??
                false
          : await plugin
                    .resolvePlatformSpecificImplementation<
                      AndroidFlutterLocalNotificationsPlugin
                    >()
                    ?.requestNotificationsPermission() ??
                false;
      if (!allowed) return false;
      return await sync(true, completed);
    } catch (_) {
      return false;
    }
  }

  Future<bool> sync(bool enabled, Set<String> completed) {
    final snapshot = Set<String>.of(completed);
    // Permission dialogs and lifecycle callbacks may overlap. Apply the latest
    // request last so a pending enable cannot undo a subsequent disable.
    return _queue = _queue.then((_) => _sync(enabled, snapshot));
  }

  Future<bool> _sync(bool enabled, Set<String> completed) async {
    if (!await initialize()) return false;
    try {
      // Refresh timezone when the app resumes, including travel and DST changes.
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
      // Also clear the two retired afternoon/evening reminder slots.
      for (var i = 0; i < 4; i++) {
        await plugin.cancel(id: 9100 + i);
      }
      if (!enabled) return true;
      final now = tz.TZDateTime.now(tz.local);
      final done = completed.contains(dayKey(now));
      const hours = [9];
      const messages = [
        'Your daily arrow puzzle is ready. Take a little focus break.',
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
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentSound: true,
            ),
            android: AndroidNotificationDetails(
              'daily_challenge',
              'Daily challenge reminders',
              channelDescription: 'Optional daily puzzle reminder at 9 AM',
              importance: Importance.defaultImportance,
              priority: Priority.defaultPriority,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: 'daily',
        );
      }
      await plugin.zonedSchedule(
        id: 9103,
        title: 'A little focus break?',
        body: 'Your arrows and crystal garden are waiting. Come back for a puzzle!',
        scheduledDate: tz.TZDateTime.from(inactivityReminder(now), tz.local),
        notificationDetails: const NotificationDetails(
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
          ),
          android: AndroidNotificationDetails(
            'puzzle_return',
            'Return to your puzzle',
            channelDescription: 'One reminder after 24 hours away',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'return',
      );
      return true;
    } catch (error) {
      debugPrint('Reminder scheduling failed: $error');
      return false;
    }
  }
}
