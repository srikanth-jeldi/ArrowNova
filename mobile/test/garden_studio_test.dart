import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arrownova/core/ads.dart';
import 'package:arrownova/core/progress_store.dart';
import 'package:arrownova/garden/garden_catalog.dart';
import 'package:arrownova/garden/garden_screen.dart';

void main() {
  test('premium credits persist per item, unlock once and never spend garden points', () {
    var p = PlayerProgress(completed: {1, 2, 3, 4, 5});
    expect(p.buy('sofa'), isFalse);
    expect(p.recordGardenReward('chair'), isFalse);
    expect(p.recordGardenReward('unknown'), isFalse);
    for (var count = 1; count <= 3; count++) {
      expect(p.recordGardenReward('sofa'), isTrue);
      p = PlayerProgress.fromJson(p.toJson());
      expect(p.gardenCredits('sofa'), count);
      expect(p.owned.contains('sofa'), count == 3);
      expect(p.gardenCredits('vase'), 0);
      expect(p.gardenPoints, 50);
    }
    expect(p.recordGardenReward('sofa'), isFalse);
    expect(p.place('sofa', 11), isTrue);
    expect(p.moveGarden(11, .6, .7), isTrue);
    p = PlayerProgress.fromJson(p.toJson());
    expect(p.placements[11], 'sofa');
    expect(p.gardenPositions[11]!.x, .6);
    expect(p.place('sofa', 12), isFalse);
    expect(p.moveGarden(11, double.nan, .4), isFalse);
    expect(p.moveGarden(11, -4, 9), isTrue);
    expect(p.gardenPositions[11]!.x, .17);
    expect(p.gardenPositions[11]!.y, .95);
    expect(
      PlayerProgress.fromJson({
        'placements': {'0': 'missing'},
        'owned': ['missing'],
      }).placements,
      isEmpty,
    );
    expect(
      PlayerProgress.fromJson({
        'gardenAdCredits': {'sofa': -1, 'vase': '3'},
        'gardenPositions': {
          '0': [double.infinity, 0],
        },
      }).gardenPositions,
      isEmpty,
    );
  });

  testWidgets(
    'premium ad flow protects double taps, cancellation and unavailable ads',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final p = PlayerProgress();
      var calls = 0, saves = 0;
      var reward = Completer<HintAdResult>();
      await tester.pumpWidget(
        MaterialApp(
          home: GardenScreen(
            progress: p,
            onChanged: () => saves++,
            showRewardAd: () {
              calls++;
              return reward.future;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Decorate garden'));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -250));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Premium'));
      await tester.tap(find.text('Premium'));
      await tester.pumpAndSettle();
      final button = find.byKey(const ValueKey('garden-action-sofa'));
      Future<void> tapAd() async {
        await tester.ensureVisible(button);
        await tester.pumpAndSettle();
        await tester.tap(button);
        await tester.pump();
      }

      await tapAd();
      await tester.tap(button);
      await tester.pump();
      expect(calls, 1);
      reward.complete(HintAdResult.dismissed);
      await tester.pumpAndSettle();
      expect(p.gardenCredits('sofa'), 0);
      expect(saves, 0);
      reward = Completer<HintAdResult>();
      await tapAd();
      reward.complete(HintAdResult.unavailable);
      await tester.pumpAndSettle();
      expect(p.gardenCredits('sofa'), 0);
      for (var n = 1; n <= gardenPremiumAds; n++) {
        reward = Completer<HintAdResult>();
        await tapAd();
        reward.complete(HintAdResult.earned);
        await tester.pumpAndSettle();
        expect(p.gardenCredits('sofa'), n);
      }
      expect(saves, 3);
      expect(p.owned, contains('sofa'));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(p.placements[0], 'sofa');
      expect(calls, 5);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets('dragged item position survives save and reload', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final p = PlayerProgress(placements: {0: 'lantern'});
    var saves = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: GardenScreen(progress: p, onChanged: () => saves++),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Decorate garden'));
    await tester.tap(find.text('Decorate garden'));
    await tester.pumpAndSettle();
    final item = find.byKey(const ValueKey('garden-item-lantern'));
    await tester.ensureVisible(item);
    await tester.pumpAndSettle();
    await tester.drag(item, const Offset(60, 30));
    await tester.pumpAndSettle();
    expect(saves, greaterThan(0));
    final restored = PlayerProgress.fromJson(p.toJson());
    expect(restored.gardenPositions[0]!.x, greaterThan(gardenSlots[0].dx));
    expect(restored.placements[0], 'lantern');
    expect(tester.takeException(), isNull);
  });
}
