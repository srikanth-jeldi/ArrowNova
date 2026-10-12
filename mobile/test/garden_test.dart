import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arrownova/core/progress_store.dart';
import 'package:arrownova/garden/garden_screen.dart';

void main() {
  test('garden unlocks, costs, ownership, moving and migration', () {
    final old = PlayerProgress.fromJson({
      'completed': [1, 2, 3],
      'sound': false,
    });
    expect(old.owned, {'lantern'});
    expect(old.place('lantern', 0), isTrue);
    expect(old.buy('flowers'), isFalse);
    expect(old.place('flowers', 1), isFalse);
    final p = PlayerProgress(completed: {for (var i = 1; i <= 50; i++) i});
    expect(p.gardenPoints, 500);
    expect(p.buy('flowers'), isTrue);
    expect(p.buy('flowers'), isFalse);
    expect(p.gardenPoints, 380);
    expect(p.buy('tree'), isFalse);
    expect(p.buy('fountain'), isTrue);
    expect(p.gardenPoints, 80);
    expect(p.place('flowers', 2), isTrue);
    expect(p.place('flowers', 5), isTrue);
    expect(p.placements, {5: 'flowers'});
    p.bestStars[1] = 3;
    final loaded = PlayerProgress.fromJson(p.toJson());
    expect(loaded.gardenPoints, 80);
    expect(loaded.placements, {5: 'flowers'});
    expect(loaded.bestStars[1], 3);
    expect(loaded.place('fountain', -1), isFalse);
    loaded.placements.remove(5);
    expect(loaded.owned.contains('flowers'), isTrue);
  });
  testWidgets('place starter decoration and render phone garden', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final font in {
      'ArrowNovaSerif': 'assets/fonts/CormorantGaramond.ttf',
      'ArrowNovaSans': 'assets/fonts/Roboto-Regular.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
    }.entries) {
      await (FontLoader(font.key)..addFont(rootBundle.load(font.value))).load();
    }
    final p = PlayerProgress();
    var saves = 0;
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          fontFamily: 'ArrowNovaSans',
        ),
        home: GardenScreen(progress: p, onChanged: () => saves++),
      ),
    );
    await tester.runAsync(() async {
      final context = tester.element(find.byType(GardenScreen));
      await precacheImage(
        const ResizeImage(
          AssetImage('assets/art/garden-courtyard.webp'),
          width: 1000,
        ),
        context,
      );
      if (!context.mounted) return;
      await precacheImage(
        const ResizeImage(
          AssetImage('assets/art/garden-decorations.webp'),
          width: 1536,
        ),
        context,
      );
    });
    await tester.pumpAndSettle();
    await tester.tap(find.text('Decorate garden'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Place').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Place').first);
    await tester.pumpAndSettle();
    expect(p.placements, {0: 'lantern'});
    expect(saves, 1);
    await tester.drag(find.byType(ListView), const Offset(0, 800));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Done decorating'));
    await tester.tap(find.text('Done decorating'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, 800));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/garden.png'),
    );
    expect(tester.takeException(), isNull);
  });
}
