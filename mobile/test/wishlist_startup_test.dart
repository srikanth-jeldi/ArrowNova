import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:arrownova/app.dart';
import 'package:arrownova/core/progress_store.dart';
import 'package:arrownova/core/update_reminder.dart';
import 'package:arrownova/garden/decor_collection.dart';
import 'package:arrownova/garden/home_decor_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const sofa = DecorPiece(0, 4);
  test(
    'wish does not spend coins; ceiling, switching, rooms, removal, purchase',
    () {
      var p = PlayerProgress(completed: {for (var i = 1; i <= 8; i++) i});
      final room = p.homeDecor.current;
      room.toggleWish(sofa);
      expect(p.wishCost(sofa), (missing: 80, levels: 2));
      expect(p.coins, 320);
      room.toggleWish(const DecorPiece(1, 4));
      expect(p.wishCost(const DecorPiece(1, 4)), (missing: 0, levels: 0));
      room.toggleWish(const DecorPiece(1, 4));
      expect(room.wish, isNull);
      room.toggleWish(sofa);
      p = PlayerProgress.fromJson(p.toJson());
      expect(p.homeDecor.current.wish, sofa.id);
      p.homeDecor.level = 2;
      expect(p.homeDecor.current.wish, isNull);
      p.homeDecor.level = 1;
      p.streakRewards['bonus'] = 1;
      expect(p.wishCost(sofa), (missing: 79, levels: 2));
      p.completed.addAll([9, 10]);
      expect(p.wishCost(sofa), (missing: 0, levels: 0));
      expect(p.buyDecor(sofa), true);
      expect(p.homeDecor.current.wish, isNull);
      expect(p.coins, 1);
    },
  );
  test('large cold-start save keeps last checkpoint and balance', () async {
    final p = PlayerProgress(
      completed: {for (var i = 1; i <= 6000; i++) i},
      runs: {
        'classic/6001': {
          'remaining': [4, 7],
        },
      },
    );
    for (var n = 0; n < 200; n++) {
      p.homeDecor.level = n + 1;
      p.homeDecor.current.toggleWish(sofa);
    }
    final data = jsonEncode(p.toJson());
    expect(data.length, greaterThan(32768));
    final read = await ProgressStore(read: () async => data).read();
    expect(read.coins, p.coins);
    expect(read.runs, p.runs);
    expect(read.homeDecor.current.wish, sofa.id);
  });
  testWidgets(
    'home is drawn before optional services and cold launch does not rewrite a valid save',
    (tester) async {
      final raw = jsonEncode({
        'completed': [1, 2],
        'sound': false,
        'music': false,
        'trainingCompleted': true,
      });
      FlutterSecureStorage.setMockInitialValues({'arrownova.progress.v1': raw});
      final messenger = tester.binding.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(
        UpdateReminder.channel,
        (_) async => null,
      );
      bool homeReady = false;
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            onHomeReady: () {
              homeReady = find.text('Continue journey').evaluate().isNotEmpty;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(homeReady, isTrue);
      expect(
        await const FlutterSecureStorage().read(key: 'arrownova.progress.v1'),
        raw,
      );
      messenger.setMockMethodCallHandler(UpdateReminder.channel, null);
    },
  );
  testWidgets('tapping wishlist shows how many new wins remain', (
    tester,
  ) async {
    final p = PlayerProgress(completed: {for (var i = 1; i <= 8; i++) i});
    var saves = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: HomeDecorScreen(
          progress: p,
          onChanged: () => saves++,
          onBack: () {},
        ),
      ),
    );
    final wish = find.byKey(const ValueKey('wish-decor_0_4'));
    await tester.scrollUntilVisible(
      wish,
      430,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await Scrollable.ensureVisible(tester.element(wish), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(wish);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('80 more coins · 2 new level wins'),
      findsWidgets,
    );
    expect(p.coins, 320);
    expect(saves, 1);
    await Scrollable.ensureVisible(tester.element(wish), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(wish);
    await tester.pumpAndSettle();
    expect(p.homeDecor.current.wish, isNull);
  });
}
