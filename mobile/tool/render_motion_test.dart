import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arrownova/app.dart';
import 'package:arrownova/core/progress_store.dart';
import 'package:arrownova/victory_screen.dart';

// Render finite motion previews: flutter test tool/render_motion_test.dart --update-goldens
void main() {
  testWidgets('render tutorial and victory motion previews', (tester) async {
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
    await tester.pumpWidget(
      ArrowNovaApp(
        initialProgress: PlayerProgress(sound: false, haptics: false),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Play now'));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Let's play"));
    await tester.pump();
    for (var i = 0; i < 24; i++) {
      await expectLater(
        find.byType(ArrowNovaApp),
        matchesGoldenFile(
          '../.build-tmp/motion/hand-${i.toString().padLeft(2, '0')}.png',
        ),
      );
      await tester.pump(const Duration(milliseconds: 150));
    }
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'ArrowNovaSerif'),
        home: VictoryScreen(
          level: 1,
          stars: 3,
          moves: 30,
          elapsed: const Duration(seconds: 42),
          firstCompletion: true,
          onNext: () {},
          onReplay: () {},
          onHome: () {},
        ),
      ),
    );
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/art/victory-garden.png'),
        tester.element(find.byType(VictoryScreen)),
      ),
    );
    await tester.pump();
    for (var i = 0; i < 20; i++) {
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          '../.build-tmp/motion/stars-${i.toString().padLeft(2, '0')}.png',
        ),
      );
      await tester.pump(const Duration(milliseconds: 150));
    }
  });
}
