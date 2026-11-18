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
  String? _scheduledSignature;
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

  Future<bool> enable(
    Set<String> completed, {
    int limit = 1,
    bool unfinished = false,
    int streak = 0,
  }) async {
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
      return await sync(
        true,
        completed,
        limit: limit,
        unfinished: unfinished,
        streak: streak,
      );
    } catch (_) {
      return false;
    }
  }

  Future<bool> sync(
    bool enabled,
    Set<String> completed, {
    int limit = 1,
    bool unfinished = false,
    int streak = 0,
  }) {
    final snapshot = Set<String>.of(completed);
    // Permission dialogs and lifecycle callbacks may overlap. Apply the latest
    // request last so a pending enable cannot undo a subsequent disable.
    return _queue = _queue.then(
      (_) => _sync(
        enabled,
        snapshot,
        limit: limit,
        unfinished: unfinished,
        streak: streak,
      ),
    );
  }

  Future<bool> _sync(
    bool enabled,
    Set<String> completed, {
    int limit = 1,
    bool unfinished = false,
    int streak = 0,
  }) async {
    if (!await initialize()) return false;
    try {
      // Refresh timezone when the app resumes, including travel and DST changes.
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
      final now = tz.TZDateTime.now(tz.local);
      final done = completed.contains(dayKey(now));
      final slots = reminderPlan(
        now,
        done: done,
        limit: limit,
        unfinished: unfinished,
        streak: streak,
      );
      // Android resolves repeating time-only alarms relative to *today*, even
      // when their requested start date is tomorrow. Schedule explicit dates instead.
      final planned = <int, ReminderSlot>{};
      if (enabled) {
        for (final slot in slots) {
          for (var i = 0; i < (slot.repeat ? 7 : 1); i++) {
            final d = DateTime(
              slot.at.year,
              slot.at.month,
              slot.at.day + i,
              slot.at.hour,
              slot.at.minute,
            );
            final id = 9200 + 4 * (d.weekday - 1) + slot.id;
            planned[id] = (id: slot.id, at: d, repeat: false, text: slot.text);
          }
        }
      }
      final signature =
          '${zone.identifier}:${planned.entries.map((e) => "${e.key}:${e.value.at}:${e.value.text}").join("|")}';
      if (signature == _scheduledSignature) return true;
      _scheduledSignature = null;
      final pending = await plugin.pendingNotificationRequests();
      for (final request in pending) {
        if (request.id >= 9200 &&
            request.id < 9228 &&
            !planned.containsKey(request.id)) {
          await plugin.cancel(id: request.id);
        }
      }
      for (var id = 9100; id <= 9103; id++) {
        await plugin.cancel(id: id);
      }
      for (final entry in planned.entries) {
        final slot = entry.value;
        final d = slot.at;
        await plugin.zonedSchedule(
          id: entry.key,
          title: 'ArrowNova',
          body: slot.text,
          scheduledDate: tz.TZDateTime(
            tz.local,
            d.year,
            d.month,
            d.day,
            d.hour,
            d.minute,
          ),
          notificationDetails: const NotificationDetails(
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentSound: true,
            ),
            android: AndroidNotificationDetails(
              'daily_challenge',
              'Puzzle reminders',
              importance: Importance.defaultImportance,
              priority: Priority.defaultPriority,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,

          payload: slot.id == 0 || slot.id == 3 ? 'daily' : 'return',
        );
      }
      _scheduledSignature = signature;
      return true;
    } catch (error) {
      debugPrint('Reminder scheduling failed: $error');
      return false;
    }
  }
}

typedef ReminderSlot = ({int id, DateTime at, bool repeat, String text});
List<ReminderSlot> reminderPlan(
  DateTime now, {
  required bool done,
  required int limit,
  required bool unfinished,
  required int streak,
}) {
  if (!const {1, 2, 4}.contains(limit)) return [];
  DateTime at(int offset, int hour, [int minute = 0]) =>
      DateTime(now.year, now.month, now.day + offset, hour, minute);
  final slots = <ReminderSlot>[
    (
      id: 0,
      at: nextReminder(now, 9, done),
      repeat: true,
      text: 'Your daily arrow puzzle is ready.',
    ),
  ];
  if (limit == 1) return slots;
  if (limit == 4 && unfinished) {
    slots.add((
      id: 1,
      at: nextReminder(now, 13, false),
      repeat: true,
      text: 'Pick up your unfinished puzzle where you left off.',
    ));
  }
  final streakAt = at(done ? 1 : 0, 20, 30);
  final remindStreak = streak > 0 && streakAt.isAfter(now);
  if (limit == 4 || !remindStreak) {
    final away = inactivityReminder(now);
    final evening = at(1, 18);
    slots.add((
      id: 2,
      at: evening.isBefore(away) ? at(2, 18) : evening,
      repeat: true,
      text: 'Let’s play! Your next arrow puzzle is ready.',
    ));
  }
  if (remindStreak) {
    slots.add((
      id: 3,
      at: streakAt,
      repeat: false,
      text: 'Play the Daily Puzzle to keep your $streak-day streak.',
    ));
  }
  return slots;
}
