import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arrownova/app.dart';
import 'package:arrownova/core/progress_store.dart';
import 'package:arrownova/victory_screen.dart';
import 'package:arrownova/daily_chest_screen.dart';

void main() {
  testWidgets('render real app screens for the store', (tester) async {
    tester.view.physicalSize = const Size(432, 768);
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
    final boundary = GlobalKey();
    Future<void> capture(String name) async {
      final render =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await render.toImage(pixelRatio: 2.5);
      await expectLater(
        image,
        matchesGoldenFile('../../design/store/$name.png'),
      );
      image.dispose();
    }

    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: ArrowNovaApp(
          initialProgress: PlayerProgress(
            completed: {1, 2, 3},
            sound: false,
            haptics: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/branding/logo.png'),
        tester.element(find.byType(HomeScreen)),
      ),
    );
    await tester.pumpAndSettle();
    await capture('screen-1-home');
    await tester.tap(find.text('Continue journey'));
    await tester.pumpAndSettle();
    await capture('screen-2-puzzle');
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: ArrowNovaApp(
          initialProgress: PlayerProgress(sound: false, haptics: false),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Play now'));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Let's play"));
    await tester.pump(const Duration(milliseconds: 500));
    await capture('screen-3-tutorial');
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: MaterialApp(
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
      ),
    );
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/art/victory-garden.png'),
        tester.element(find.byType(VictoryScreen)),
      ),
    );
    await tester.pumpAndSettle();
    await capture('screen-4-stars');
    final chestProgress = PlayerProgress();
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xff041729),
            fontFamily: 'ArrowNovaSerif',
          ),
          home: DailyChestScreen(
            progress: chestProgress,
            onChanged: () {},
            now: () => DateTime(2026, 10, 10),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await capture('screen-5-chest');
  });
  testWidgets('render store branding from approved app assets', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await (FontLoader(
      'ArrowNovaSerif',
    )..addFont(rootBundle.load('assets/fonts/CormorantGaramond.ttf'))).load();
    await (FontLoader(
      'ArrowNovaSans',
    )..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'))).load();
    tester.view.physicalSize = const Size(512, 512);
    const logo = AssetImage('assets/branding/logo.png');
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Image(image: logo, fit: BoxFit.cover),
      ),
    );
    await tester.runAsync(
      () => precacheImage(logo, tester.element(find.byType(Image))),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../design/store/icon-512.png'),
    );
    tester.view.physicalSize = const Size(1024, 500);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xff041021), Color(0xff123b55)],
              ),
            ),
            padding: const EdgeInsets.all(48),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(62),
                  child: const Image(image: logo, width: 310, height: 310),
                ),
                const SizedBox(width: 50),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'ArrowNova',
                        style: TextStyle(
                          fontFamily: 'ArrowNovaSerif',
                          fontSize: 76,
                          color: Color(0xfff5dc98),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'THINK. MOVE. SOLVE.',
                        style: TextStyle(
                          fontFamily: 'ArrowNovaSans',
                          fontSize: 21,
                          letterSpacing: 3,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 35),
                      Text(
                        '6,000 arrow puzzles\nA daily challenge. Your garden.',
                        style: TextStyle(
                          fontFamily: 'ArrowNovaSans',
                          fontSize: 22,
                          height: 1.6,
                          color: Color(0xffb7d8e6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../design/store/feature-1024x500.png'),
    );
  });
}
