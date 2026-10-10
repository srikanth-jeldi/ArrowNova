import 'package:flutter_test/flutter_test.dart';
import 'package:arrownova/core/ad_pacing.dart';

void main() {
  test(
    'automatic ads wait two minutes from session start and last dismissal',
    () {
      var now = DateTime(2026, 10, 11);
      final pacing = AdPacing(now: () => now);
      expect(pacing.canShowInterstitial, isFalse);
      now = now.add(const Duration(seconds: 119));
      expect(pacing.canShowInterstitial, isFalse);
      now = now.add(const Duration(seconds: 1));
      expect(pacing.canShowInterstitial, isTrue);
      pacing.fullscreenClosed();
      expect(pacing.canShowInterstitial, isFalse);
      now = now.add(const Duration(minutes: 2));
      expect(pacing.canShowInterstitial, isTrue);
    },
  );

  test('an opted-in reward restarts the automatic-ad cooldown', () {
    var now = DateTime(2026, 10, 11);
    final pacing = AdPacing(now: () => now);
    now = now.add(const Duration(minutes: 5));
    expect(pacing.canShowInterstitial, isTrue);
    pacing.fullscreenClosed();
    now = now.add(const Duration(seconds: 90));
    expect(pacing.canShowInterstitial, isFalse);
    now = now.add(const Duration(seconds: 30));
    expect(pacing.canShowInterstitial, isTrue);
  });
}
