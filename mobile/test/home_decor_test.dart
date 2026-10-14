import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arrownova/core/progress_store.dart';
import 'package:arrownova/garden/garden_screen.dart';

void main() {
  test(
    'home and garden layouts persist independently with shared ownership',
    () {
      var p = PlayerProgress(owned: {'chair', 'linen', 'rug'});
      expect(p.place('chair', 0), isTrue);
      expect(p.place('chair', 4, home: true), isTrue);
      p.moveGarden(0, .3, .7);
      p.moveGarden(4, .7, .8, home: true);
      expect(p.place('linen', 0, home: true), isTrue);
      p.moveGarden(0, .5, .8, home: true);
      expect(p.place('linen', 1), isFalse);
      expect(p.place('tree', 1, home: true), isFalse);
      expect(p.buy('royal_rug'), isFalse);
      for (var i = 0; i < 3; i++) {
        p.recordGardenReward('royal_rug');
        p = PlayerProgress.fromJson(p.toJson());
      }
      expect(p.owned, contains('royal_rug'));
      expect(p.placements[0], 'chair');
      expect(p.homePlacements, {4: 'chair', 0: 'linen'});
      expect(p.gardenPositions[0]!.x, .3);
      expect(p.homePositions[4]!.x, .7);
      expect(p.homePositions[0]!.y, .48);
      p.homePlacements.remove(4);
      expect(p.placements[0], 'chair');
      expect(
        PlayerProgress.fromJson({
          'owned': ['chair'],
        }).homePlacements,
        isEmpty,
      );
    },
  );

  testWidgets(
    'room offers regular and premium decor and renders carpet underneath furniture',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final p = PlayerProgress(
        owned: {'chair', 'rug', 'linen', 'lamp'},
        homePlacements: {0: 'chair', 1: 'rug', 2: 'linen', 3: 'lamp'},
      );
      p.moveGarden(2, .5, .43, home: true);
      await tester.pumpWidget(
        MaterialApp(
          home: GardenScreen(progress: p, onChanged: () {}),
        ),
      );
      await tester.tap(find.text('Home Decor'));
      await tester.pumpAndSettle();
      expect(find.text('Decorate room'), findsOneWidget);
      final layers = tester
          .widget<Stack>(find.byKey(const ValueKey('garden-scene')))
          .children
          .whereType<Positioned>()
          .toList();
      expect(layers[1].key, const ValueKey('garden-slot-1'));
      await tester.tap(find.text('Decorate room'));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -250));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Regular'));
      await tester.tap(find.text('Regular'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('garden-action-royal_rug')),
        findsNothing,
      );
      await tester.ensureVisible(find.text('Premium'));
      await tester.tap(find.text('Premium'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('garden-action-royal_rug')),
        250,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(
        find.byKey(const ValueKey('garden-action-royal_rug')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
