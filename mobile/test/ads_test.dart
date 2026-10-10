import 'package:flutter_test/flutter_test.dart';
import 'package:arrownova/core/progress_store.dart';
import 'package:arrownova/core/ads.dart';

void main() {
  test('ad break is due only after two completions and survives restart', () {
    var progress = PlayerProgress();
    expect(progress.consumeAdBreak(), isFalse);
    for (var i = 0; i < 1; i++) {
      progress.recordAdCompletion();
      expect(progress.consumeAdBreak(), isFalse);
    }
    progress = PlayerProgress.fromJson(progress.toJson());
    progress.recordAdCompletion();
    expect(progress.consumeAdBreak(), isTrue);
    expect(progress.consumeAdBreak(), isFalse);
    for (var i = 0; i < 2; i++) {
      progress.recordAdCompletion();
    }
    expect(progress.consumeAdBreak(), isTrue);
  });
  test(
    'old saves do not immediately show ads; malformed counters are bounded',
    () {
      expect(
        PlayerProgress.fromJson({
          'completed': [1, 2, 3],
        }).consumeAdBreak(),
        isFalse,
      );
      expect(
        PlayerProgress.fromJson({'levelsSinceAdBreak': -4}).levelsSinceAdBreak,
        0,
      );
      expect(
        PlayerProgress.fromJson({'levelsSinceAdBreak': 900}).levelsSinceAdBreak,
        2,
      );
      expect(
        PlayerProgress.fromJson({'levelsSinceAdBreak': 'bad'})
            .levelsSinceAdBreak,
        0,
      );
    },
  );
  test(
    'missing inventory continues immediately without initializing the SDK',
    () async {
      await GameAds.instance.showAtBreak();
      expect(GameAds.instance.ready.value, isFalse);
    },
  );
}
