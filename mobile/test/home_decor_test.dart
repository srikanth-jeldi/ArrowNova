import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arrownova/core/progress_store.dart';
import 'package:arrownova/garden/garden_screen.dart';
import 'package:arrownova/garden/room_3d.dart';
import 'package:arrownova/garden/garden_catalog.dart';

void main() {
  testWidgets('3D furniture drag persists and pinch changes camera zoom', (
    tester,
  ) async {
    final p = PlayerProgress(
      owned: {'chair'},
      homePlacements: {0: 'chair'},
      homePositions: {0: const GardenPosition(.5, .775)},
    );
    var saves = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              height: 400,
              child: StatefulBuilder(
                builder: (context, setState) => Room3DScene(
                  progress: p,
                  editing: true,
                  selected: 0,
                  onSelect: (_) {},
                  onMove: (i, x, y) =>
                      setState(() => p.moveGarden(i, x, y, home: true)),
                  onSave: () => saves++,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Move items'));
    await tester.pumpAndSettle();
    final state = tester.state<Room3DSceneState>(find.byType(Room3DScene));
    final origin = tester.getTopLeft(
      find.byKey(const ValueKey('room-3d-viewport')),
    );
    final local = state.camera.project(
      const Vec3(0, .8, .3),
      const Size(400, 400),
    );
    expect(state.hit(local, const Size(400, 400)), 0);
    final g = await tester.startGesture(origin + local);
    await g.moveBy(const Offset(25, 0));
    await tester.pump();
    await g.moveBy(const Offset(35, 0));
    await tester.pump();
    await g.up();
    await tester.pumpAndSettle();
    expect(saves, 1);
    expect(p.homePositions[0]!.x, isNot(.5));
    final saved = PlayerProgress.fromJson(p.toJson());
    expect(saved.homePositions[0]!.x, p.homePositions[0]!.x);
    final first = await tester.startGesture(
      origin + const Offset(160, 200),
      pointer: 1,
    );
    final second = await tester.startGesture(
      origin + const Offset(240, 200),
      pointer: 2,
    );
    await first.moveBy(const Offset(-25, 0));
    await second.moveBy(const Offset(25, 0));
    await tester.pump();
    await first.moveBy(const Offset(-25, 0));
    await second.moveBy(const Offset(25, 0));
    await tester.pump();
    await first.up();
    await second.up();
    await tester.pumpAndSettle();
    expect(state.camera.distance, lessThan(15));
    expect(tester.takeException(), isNull);
  });
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
      final state = tester.state<Room3DSceneState>(find.byType(Room3DScene));
      final before = state.camera.project(
        const Vec3(2, 1, 0),
        const Size(350, 350),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('room-3d-viewport'))),
      );
      await gesture.moveBy(const Offset(30, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(70, 0));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(
        state.camera.project(const Vec3(2, 1, 0), const Size(350, 350)),
        isNot(before),
      );
      final faces = furnitureMesh(p).faces;
      expect(
        faces
            .where((f) => f.slot == 1)
            .expand((f) => f.points)
            .every((v) => v.y < .1),
        isTrue,
      );
      await tester.tap(find.text('Decorate room'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Regular'),
        200,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
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
  test('3D camera ground projection round-trips at different angles and catalogue variants persist', () {
    for (final yaw in [0.0, 1.5, 3.1, 4.5, 6.2]) {
      final c = RoomCamera(yaw: yaw);
      final p = c.intersect(
        c.project(const Vec3(1, 0, -1), const Size(400, 400)),
        const Size(400, 400),
      )!;
      expect(p.x, closeTo(1, .0001));
      expect(p.z, closeTo(-1, .0001));
    }
    expect(gardenItems.length, 216);
    expect(gardenItems.map((i) => i.id).toSet().length, 216);
    final p = PlayerProgress(owned: {'room_bed_0'});
    expect(p.place('room_bed_0', 11, home: true), isTrue);
    expect(
      PlayerProgress.fromJson(p.toJson()).homePlacements[11],
      'room_bed_0',
    );
    expect(furnitureMesh(p).faces, isNotEmpty);
    expect(p.place('room_bed_0', 0), isFalse);
  });
}
