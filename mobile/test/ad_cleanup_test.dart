import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:arrownova/core/ads.dart';

class BrokenAd extends Ad {
  BrokenAd() : super(adUnitId: 'test');
  @override
  Future<void> dispose() async => throw StateError('native cleanup failed');
}

void main() {
  test('native ad cleanup errors are contained', () async {
    await disposeAdSafely(BrokenAd());
    await disposeAdSafely(null);
  });
}
