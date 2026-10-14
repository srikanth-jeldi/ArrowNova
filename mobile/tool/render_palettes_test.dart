import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arrownova/game/board.dart';
import 'package:arrownova/game/board_themes.dart';
import 'package:arrownova/game/puzzle.dart';

void main() {
  testWidgets('render level arrow colour variants', (tester) async {
    tester.view.physicalSize = const Size(1050, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final boundary = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: RepaintBoundary(
          key: boundary,
          child: Row(
            children: [
              for (final theme in levelPalettes)
                Expanded(
                  child: ColoredBox(
                    color: theme.background,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: ArrowBoard(
                        theme: theme,
                        game: GameSession(LevelCatalog.get(4)),
                        onTap: (_) {},
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final render =
        boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await render.toImage();
    await expectLater(
      image,
      matchesGoldenFile('../../design/previews/arrow-palettes.png'),
    );
    image.dispose();
  });
}
