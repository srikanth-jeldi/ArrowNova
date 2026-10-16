import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:arrownova/app.dart';
import 'package:arrownova/core/progress_store.dart';
import 'package:arrownova/core/update_reminder.dart';
import 'package:arrownova/game/board.dart';
import 'package:arrownova/victory_screen.dart';

void main() {
  testWidgets(
    'real home save path completes level nine and survives reopening',
    (tester) async {
      // This save/reopen test has no Android Play service. Resolve its new
      // background update query explicitly instead of leaving a platform call pending.
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        UpdateReminder.channel,
        (_) async => null,
      );
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(UpdateReminder.channel, null));
      PackageInfo.setMockInitialValues(
        appName: 'ArrowNova',
        packageName: 'com.epitomehub.arrownova',
        version: '0.2.17',
        buildNumber: '19',
        buildSignature: '',
      );
      final seed = PlayerProgress(
        completed: {for (var i = 1; i < 9; i++) i},
        trainingCompleted: true,
        dailyReminders: true,
        sound: false,
        haptics: false,
        music: false,
      );
      FlutterSecureStorage.setMockInitialValues({
        'arrownova.progress.v1': jsonEncode(seed.toJson()),
      });
      await tester.pumpWidget(const ArrowNovaApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue journey'));
      await tester.pumpAndSettle();
      final game = tester.widget<ArrowBoard>(find.byType(ArrowBoard)).game;
      expect(game.puzzle.level, 9);
      for (final id in game.puzzle.solution()) {
        tester.widget<ArrowBoard>(find.byType(ArrowBoard)).onTap(id);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      expect(find.byType(VictoryScreen), findsOneWidget);
      final saved = await ProgressStore().read();
      expect(saved.dailyReminders, isTrue);
      expect(saved.completed, contains(9));
      expect(saved.runs.containsKey('classic/9'), isFalse);
      await tester.ensureVisible(find.text('Next level'));
      await tester.tap(find.text('Next level'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<ArrowBoard>(find.byType(ArrowBoard)).game.puzzle.level,
        10,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await tester.pumpWidget(const ArrowNovaApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue journey'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<ArrowBoard>(find.byType(ArrowBoard)).game.puzzle.level,
        10,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
