import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arrownova/game/board.dart';
import 'package:arrownova/game/puzzle.dart';
import 'package:arrownova/victory_screen.dart';

void main() {
  testWidgets(
    'hand demonstration never taps and does not intercept real taps',
    (tester) async {
      final game = GameSession(TrainingCatalog.get(1));
      game.hinted = game.puzzle.solution().first;
      final id = game.hinted!;
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 300,
              height: 400,
              child: ArrowBoard(game: game, showGuide: true, onTap: game.tap),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(TutorialHand), findsOneWidget);
      expect(game.removed, isEmpty);
      expect(game.lives, 3);
      final finder = find.byType(ArrowBoard);
      final box = tester.renderObject<RenderBox>(finder);
      final geometry = BoardGeometry(game.puzzle, tester.getSize(finder));
      await tester.tapAt(
        box.localToGlobal(
          geometry.point(game.puzzle.arrows.firstWhere((a) => a.id == id).head),
        ),
      );
      expect(game.removed, {id});
      await tester.pumpAndSettle();
      expect(game.lives, 3);
    },
  );

  testWidgets(
    'stars reveal in sequence and perfect burst requires three earned stars',
    (tester) async {
      Widget scene(int stars, {bool reduced = false}) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: Center(child: StarCelebration(stars: stars)),
        ),
      );
      await tester.pumpWidget(scene(3));
      double scale(int i) => tester
          .widget<Transform>(find.byKey(ValueKey('earned-star-$i')))
          .transform
          .storage[0];
      await tester.pump(const Duration(milliseconds: 600));
      expect(scale(0), greaterThan(scale(2)));
      expect(scale(2), lessThan(.1));
      await tester.pumpAndSettle();
      expect(scale(2), closeTo(1, .01));
      expect(find.byKey(const ValueKey('perfect-star-burst')), findsOneWidget);
      await tester.pumpWidget(scene(1));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('earned-star-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('earned-star-1')), findsNothing);
      expect(find.byKey(const ValueKey('perfect-star-burst')), findsNothing);
      await tester.pumpWidget(scene(3, reduced: true));
      await tester.pump();
      expect(scale(2), closeTo(1, .01));
      expect(tester.takeException(), isNull);
    },
  );
}
