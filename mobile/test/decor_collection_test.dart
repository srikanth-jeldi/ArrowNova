import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arrownova/core/ads.dart';
import 'package:arrownova/core/progress_store.dart';
import 'package:arrownova/garden/decor_collection.dart';
import 'package:arrownova/garden/home_decor_screen.dart';

void main() {
  test('removal persists without losing premium ownership', () {
    final room = DecorRoom();
    const item = DecorPiece(1, 1);
    for (var i = 0; i < 3; i++) {
      room.reward(item);
    }
    room.place(item);
    expect(room.remove(item.category), true);
    final restored = DecorRoom.fromJson(room.toJson());
    expect(restored.placed, isEmpty);
    expect(restored.owns(item), true);
    expect(restored.place(item), true);
    restored.finished = true;
    expect(restored.remove(item.category), false);
  });
  testWidgets('placed item can be removed from scene and its plus returns', (
    tester,
  ) async {
    final p = PlayerProgress();
    p.homeDecor.current.place(const DecorPiece(1, 0));
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
    await tester.pumpAndSettle();
    final pillow = find.descendant(
      of: find.byType(DecorRoomScene),
      matching: find.byType(DecorSprite),
    );
    await tester.tap(
      find.ancestor(of: pillow, matching: find.byType(GestureDetector)).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Remove'));
    await tester.pumpAndSettle();
    expect(p.homeDecor.current.placed, isEmpty);
    expect(saves, 1);
    expect(find.byKey(const ValueKey('decor-add-1')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('decor-add-1')));
    await tester.pumpAndSettle();
    expect(find.text('Woven ivory'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('earned ads survive reload, unlock only that item and room, finished designs stay', () {
    var p = PlayerProgress();
    const sofa = DecorPiece(0, 1);
    expect(p.homeDecor.current.place(sofa), false);
    for (var n = 1; n <= 3; n++) {
      expect(p.homeDecor.current.reward(sofa), true);
      p = PlayerProgress.fromJson(p.toJson());
      expect(p.homeDecor.current.adsFor(sofa), n);
      expect(p.homeDecor.current.owns(sofa), n == 3);
    }
    expect(p.homeDecor.current.owns(const DecorPiece(0, 2)), false);
    expect(p.homeDecor.current.reward(sofa), false);
    expect(p.homeDecor.current.place(sofa), true);
    expect(p.homeDecor.finish(), false);
    for (var i = 1; i < 7; i++) {
      p.homeDecor.current.place(DecorPiece(i, 0));
    }
    expect(p.homeDecor.finish(), true);
    expect(p.homeDecor.next(), true);
    p = PlayerProgress.fromJson(p.toJson());
    expect(p.homeDecor.level, 2);
    expect(p.homeDecor.current.credits, isEmpty);
    expect(p.homeDecor.current.owns(sofa), false);
    expect(p.homeDecor.rooms[1]!.placed['Sofas'], sofa.id);
    expect(p.homeDecor.rooms[1]!.finished, true);
    expect(p.homeDecor.rooms[1]!.place(const DecorPiece(0, 0)), false);
  });
  test(
    'all seven starters free on every level; corrupt data and old saves safe',
    () {
      final p = PlayerProgress.fromJson({
        'owned': ['sofa'],
        'homePlacements': {'0': 'sofa'},
      });
      expect(p.homePlacements[0], 'sofa');
      for (var level = 1; level <= 3; level++) {
        for (var i = 0; i < 7; i++) {
          expect(p.homeDecor.current.place(DecorPiece(i, 0)), true);
        }
        expect(p.homeDecor.finish(), true);
        expect(p.homeDecor.next(), true);
      }
      final corrupt = DecorRoom.fromJson({
        'credits': {'decor_0_1': 900, 'bad': 3},
        'placed': {'Sofas': 'decor_0_2'},
        'finished': true,
      });
      expect(corrupt.adsFor(const DecorPiece(0, 1)), 3);
      expect(corrupt.placed, isEmpty);
      expect(corrupt.finished, false);
      expect(decorPieces.map((i) => i.id).toSet().length, 28);
    },
  );
  testWidgets('large gallery builds only visible room scenes', (tester) async {
    final p = PlayerProgress();
    for (var level = 1; level <= 1000; level++) {
      final room = DecorRoom();
      for (var category = 0; category < 7; category++) {
        room.place(DecorPiece(category, 0));
      }
      room.finished = true;
      p.homeDecor.rooms[level] = room;
    }
    await tester.pumpWidget(
      MaterialApp(
        home: HomeDecorScreen(progress: p, onChanged: () {}, onBack: () {}),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Finished rooms'));
    await tester.pumpAndSettle();
    expect(find.text('Your finished rooms'), findsOneWidget);
    expect(find.byType(DecorRoomScene).evaluate().length, lessThan(10));
    expect(find.textContaining('Room 1000'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'reward opt-in, duplicate taps, dismissal and unavailable leave correct room state',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final p = PlayerProgress();
      var saves = 0, calls = 0;
      var pending = Completer<HintAdResult>();
      await tester.pumpWidget(
        MaterialApp(
          home: HomeDecorScreen(
            progress: p,
            onChanged: () => saves++,
            onBack: () {},
            showRewardAd: () {
              calls++;
              return pending.future;
            },
          ),
        ),
      );
      final action = find.byKey(const ValueKey('decor-action-decor_0_1'));
      await tester.scrollUntilVisible(
        action,
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(action);
      await tester.pump();
      await tester.tap(action);
      await tester.pump();
      expect(calls, 1);
      pending.complete(HintAdResult.dismissed);
      await tester.pumpAndSettle();
      expect(p.homeDecor.current.credits, isEmpty);
      expect(saves, 0);
      for (final outcome in [
        HintAdResult.unavailable,
        HintAdResult.earned,
        HintAdResult.earned,
        HintAdResult.earned,
      ]) {
        pending = Completer<HintAdResult>();
        await tester.scrollUntilVisible(
          action,
          220,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(action);
        await tester.pump();
        pending.complete(outcome);
        await tester.pumpAndSettle();
      }
      expect(saves, 3);
      expect(p.homeDecor.current.owns(const DecorPiece(0, 1)), true);
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(p.homeDecor.current.placed['Sofas'], 'decor_0_1');
      expect(saves, 4);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'finish and next save a gallery snapshot and reset room unlocks',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final p = PlayerProgress();
      for (var i = 0; i < 7; i++) {
        p.homeDecor.current.place(DecorPiece(i, 0));
      }
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
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('decor-finish')),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('decor-finish')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('decor-finish')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('decor-next')));
      await tester.tap(find.byKey(const ValueKey('decor-next')));
      await tester.pumpAndSettle();
      expect(p.homeDecor.level, 2);
      expect(p.homeDecor.rooms[1]!.complete, true);
      expect(p.homeDecor.current.placed, isEmpty);
      expect(saves, 2);
      expect(tester.takeException(), isNull);
    },
  );
}
