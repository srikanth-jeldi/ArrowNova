import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arrownova/app.dart';
import 'package:arrownova/core/progress_store.dart';
import 'package:arrownova/game/board.dart';
import 'package:arrownova/game/puzzle.dart';

void main() {
  test(
    'bent arrows retain their length and move continuously beyond each edge',
    () {
      for (final direction in [
        const Offset(1, 0),
        const Offset(-1, 0),
        const Offset(0, 1),
        const Offset(0, -1),
      ]) {
        final head = const Offset(150, 150);
        final normal = Offset(-direction.dy, direction.dx);
        final tail = head - direction * 50 - normal * 60;
        final bend = head - direction * 50;
        final path = Path()
          ..moveTo(tail.dx, tail.dy)
          ..lineTo(bend.dx, bend.dy)
          ..lineTo(head.dx, head.dy);
        var last = 0.0;
        for (var frame = 0; frame <= 60; frame++) {
          final sample = ArrowExitFrame.sample(
            path,
            head,
            direction,
            const Size(300, 300),
            20,
            frame / 60,
          );
          expect(sample.body.computeMetrics().first.length, closeTo(110, .02));
          expect(sample.travel, greaterThanOrEqualTo(last));
          expect(sample.travel - last, lessThan(10));
          last = sample.travel;
          if (frame == 15) {
            expect(sample.head.dx.abs(), lessThan(300));
            expect(sample.head.dy.abs(), lessThan(300));
          }
          if (frame == 60) {
            final bounds = sample.body.getBounds();
            expect(bounds.overlaps(const Rect.fromLTWH(0, 0, 300, 300)), false);
          }
        }
      }
    },
  );
  testWidgets(
    'successful tap stays visible in flight instead of vanishing immediately',
    (tester) async {
      final progress = PlayerProgress(
        completed: {1},
        trainingCompleted: true,
        sound: false,
        music: false,
        haptics: false,
      );
      await tester.pumpWidget(ArrowNovaApp(initialProgress: progress));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue journey'));
      await tester.pumpAndSettle();
      ArrowBoard board() => tester.widget<ArrowBoard>(find.byType(ArrowBoard));
      final id = board().game.puzzle.solution().first;
      board().onTap(id);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        board().game.removed,
        contains(id),
      ); // Save immediately, animate separately.
      expect(board().activeId, id);
      expect(board().progress, greaterThan(0));
      expect(board().progress, lessThan(.6));
      await tester.pumpAndSettle();
      expect(board().activeId, isNull);
      expect(tester.takeException(), isNull);
    },
  );
  test('longer arrows get readable bounded duration', () {
    expect(
      ArrowExitFrame.duration(
        ArrowPath(0, [const Cell(0, 0), const Cell(1, 0)]),
      ).inMilliseconds,
      568,
    );
    expect(
      ArrowExitFrame.duration(
        ArrowPath(0, List.generate(100, (i) => Cell(i, 0))),
      ).inMilliseconds,
      850,
    );
  });
}
