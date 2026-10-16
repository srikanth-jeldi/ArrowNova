import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arrownova/core/progress_store.dart';
import 'package:arrownova/garden/garden_screen.dart';
import 'package:arrownova/garden/garden_catalog.dart';

void main() {
  testWidgets('render decorated garden and premium collection', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final font in {
      'ArrowNovaSans': 'assets/fonts/Roboto-Regular.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
    }.entries) {
      await (FontLoader(font.key)..addFont(rootBundle.load(font.value))).load();
    }
    final p = PlayerProgress(
      completed: {for (var n = 1; n <= 100; n++) n},
      owned: {
        'roses',
        'lavender',
        'jar',
        'chair',
        'sofa',
        'curtains',
        'royal_rug',
        'table',
        'crystal_lamp',
        'gallery',
      },
      homePlacements: {
        0: 'curtains',
        1: 'royal_rug',
        2: 'sofa',
        3: 'chair',
        4: 'crystal_lamp',
        5: 'table',
        6: 'roses',
        7: 'gallery',
      },
      homePositions: {
        0: const GardenPosition(.5, .46),
        1: const GardenPosition(.5, .90),
        2: const GardenPosition(.5, .68),
        3: const GardenPosition(.23, .8),
        4: const GardenPosition(.80, .64),
        5: const GardenPosition(.52, .84),
        6: const GardenPosition(.82, .89),
        7: const GardenPosition(.80, .35),
      },
      gardenAdCredits: {'sofa': 3, 'vase': 1},
      placements: {
        0: 'roses',
        1: 'chair',
        2: 'jar',
        3: 'lavender',
        4: 'sofa',
        5: 'lantern',
      },
    );
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          fontFamily: 'ArrowNovaSans',
        ),
        home: GardenScreen(progress: p, onChanged: () {}),
      ),
    );
    await tester.runAsync(() async {
      final context = tester.element(find.byType(GardenScreen));
      for (final asset in [
        'roses',
        'lavender',
        'jar',
        'chair',
        'sofa',
        'vase',
      ]) {
        if (!context.mounted) return;
        await precacheImage(
          ResizeImage(AssetImage('assets/art/garden/$asset.webp'), width: 320),
          context,
        );
      }
      if (!context.mounted) return;
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
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../design/previews/garden-studio.png'),
    );
    await tester.tap(find.text('Home Decor'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../design/previews/home-studio-empty.png'),
    );
    await tester.tap(find.byTooltip('Back to garden'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Decorate garden'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -250));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Premium'));
    await tester.tap(find.text('Premium'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('garden-action-vase')),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../design/previews/garden-premium.png'),
    );
    expect(tester.takeException(), isNull);
  });
}
