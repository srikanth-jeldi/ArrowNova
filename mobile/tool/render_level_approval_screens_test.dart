import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arrownova/game/board.dart';
import 'package:arrownova/game/board_themes.dart';
import 'package:arrownova/game/puzzle.dart';

void main() {
  testWidgets('capture Classic and Animal Rescue levels 1–10', (tester) async {
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
    for (var level = 1; level <= 10; level++) {
      await _capture(
        tester,
        'classic-${level.toString().padLeft(2, '0')}.png',
        level,
      );
    }
    await _capture(tester, 'classic-20-hard.png', 20);
    await _capture(tester, 'classic-blocked-edges.png', 6, blockedDemo: true);
    for (var level = 1; level <= 10; level++) {
      final puzzle = RescueCatalog.get(level);
      expect(puzzle.solution().length, puzzle.arrows.length);
      await _capture(
        tester,
        'animal-rescue-${level.toString().padLeft(2, '0')}.png',
        level,
        rescue: true,
      );
    }
    final rescueOne = RescueCatalog.get(1);
    final rescueTwo = RescueCatalog.get(2);
    expect(rescueOne.arrows.length, greaterThanOrEqualTo(50));
    expect(rescueOne.rescueCageIds.length, 4);
    expect(rescueTwo.arrows.length, rescueOne.arrows.length);
    expect(rescueTwo.rescueCageIds.length, 4);
    final occupiedOutsideCage = <Cell>{
      for (final arrow in rescueTwo.arrows)
        if (!rescueTwo.rescueCageIds.contains(arrow.id)) ...arrow.cells,
    };
    for (final arrow in rescueTwo.arrows.where(
      (arrow) => rescueTwo.rescueCageIds.contains(arrow.id),
    )) {
      expect(arrow.cells.toSet().intersection(occupiedOutsideCage), isEmpty);
    }
    final centerX = rescueTwo.width ~/ 2;
    final centerY = rescueTwo.height ~/ 2;
    final animalPocket = {
      for (var y = centerY - 2; y <= centerY + 2; y++)
        for (var x = centerX - 3; x <= centerX + 1; x++) Cell(x, y),
    };
    expect(occupiedOutsideCage.intersection(animalPocket), isEmpty);
  });
}

Future<void> _capture(
  WidgetTester tester,
  String fileName,
  int level, {
  bool rescue = false,
  bool blockedDemo = false,
}) async {
  final game = GameSession(
    rescue ? RescueCatalog.get(level) : LevelCatalog.get(level),
  );
  final mode = rescue ? 'ANIMAL RESCUE' : 'CLASSIC';
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'ArrowNovaSans'),
      home: Scaffold(
        backgroundColor: const Color(0xFF071B33),
        body: Stack(
          fit: StackFit.expand,
          children: [
          SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              children: [
                const Text(
                  'ArrowNova',
                  style: TextStyle(
                    color: Color(0xFFF0D18A),
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$mode  ·  LEVEL ${level.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    color: Color(0xFFB9D8ED),
                    fontSize: 12,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5FAFC),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: const Color(0xFF82DDFF),
                        width: 2,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.favorite_rounded,
                              color: Color(0xFFF34F6C),
                            ),
                            SizedBox(width: 6),
                            Icon(
                              Icons.favorite_rounded,
                              color: Color(0xFFF34F6C),
                            ),
                            SizedBox(width: 6),
                            Icon(
                              Icons.favorite_rounded,
                              color: Color(0xFFF34F6C),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '0 / ${game.puzzle.arrows.length} ARROWS ${rescue ? 'FREED' : 'CLEARED'}',
                          style: const TextStyle(
                            color: Color(0xFF647C8F),
                            fontSize: 11,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: ArrowBoard(
                              theme: boardThemes.first,
                              game: game,
                              activeId: blockedDemo
                                  ? game.puzzle.arrows
                                        .firstWhere(
                                          (arrow) => !game.puzzle.canExit(
                                            arrow.id,
                                            game.removed,
                                          ),
                                        )
                                        .id
                                  : null,
                              blocked: blockedDemo,
                              progress: blockedDemo ? .5 : 0,
                              rescueAnimal: rescue
                                  ? RescueCatalog.animal(level)
                                  : null,
                              onTap: (_) {},
                            ),
                          ),
                        ),
                        Text(
                          rescue
                              ? 'Help me, please! Clear the cage arrows to free me.'
                              : 'Tap a clear path  ·  Pinch to zoom',
                          style: const TextStyle(
                            color: Color(0xFF687F90),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Icon(Icons.restart_alt_rounded, color: Color(0xFFF0D18A)),
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      color: Color(0xFFF0D18A),
                    ),
                    Icon(Icons.volume_up_rounded, color: Color(0xFFF0D18A)),
                    Icon(Icons.skip_next_rounded, color: Color(0xFFF0D18A)),
                  ],
                ),
              ],
            ),
          ),
          ),
          if (blockedDemo)
            const Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: ScreenEdgeGlowPainter(.5)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 100));
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('../../docs/previews/approval/$fileName'),
  );
}
