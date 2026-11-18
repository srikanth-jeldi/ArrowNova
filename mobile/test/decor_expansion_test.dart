import 'package:flutter_test/flutter_test.dart';
import 'package:arrownova/core/progress_store.dart';
import 'package:arrownova/garden/decor_collection.dart';

void main() {
  test(
    'expanded catalogue buys once, persists and preserves prior ownership',
    () {
      final p = PlayerProgress(completed: {for (var n = 1; n <= 6000; n++) n});
      final starting = p.coins;
      var spent = 0;
      expect(decorPieces.map((e) => e.id).toSet().length, 84);
      expect(decorPieces.where((e) => e.coinItem).length, 56);
      for (final item in decorPieces.where((e) => e.coinItem)) {
        expect(item.sourceCollection, inInclusiveRange(0, 3));
        expect(p.buyDecor(item), true);
        expect(p.buyDecor(item), false);
        spent += item.price;
        expect(p.homeDecor.current.place(item), true);
      }
      final restored = PlayerProgress.fromJson(p.toJson());
      expect(restored.coins, starting - spent);
      for (final item in decorPieces.where((e) => e.coinItem)) {
        expect(restored.homeDecor.current.owns(item), true);
      }
      expect(restored.homeDecor.current.complete, true);
      expect(restored.homeDecor.finish(), true);
      expect(restored.homeDecor.next(), true);
      expect(restored.homeDecor.current.bought, isEmpty);
      expect(restored.coins, starting - spent);
    },
  );
}
