import 'package:arrownova/core/ads.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_mobile_ads/src/ad_instance_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late GameAds ads;
  late DateTime now;
  late List<int> breaks;
  late List<int> rewards;
  late List<int> disposed;

  setUp(() {
    now = DateTime.utc(2026, 10, 16);
    ads = GameAds.forTesting(now: () => now);
    ads.ready.value = true;
    breaks = [];
    rewards = [];
    disposed = [];
    messenger.setMockMethodCallHandler(instanceManager.channel, (call) async {
      final id = (call.arguments as Map?)?['adId'] as int?;
      if (call.method == 'loadInterstitialAd') {
        breaks.add(id!);
        final ad = instanceManager.adFor(id) as InterstitialAd;
        ad.adLoadCallback.onAdLoaded(ad);
      } else if (call.method == 'loadRewardedAd') {
        rewards.add(id!);
        final ad = instanceManager.adFor(id) as RewardedAd;
        ad.rewardedAdLoadCallback.onAdLoaded(ad);
      } else if (call.method == 'disposeAd') {
        disposed.add(id!);
      }
      return null;
    });
  });

  tearDown(() async {
    ads.didChangeAppLifecycleState(AppLifecycleState.paused);
    for (final id in [...breaks, ...rewards]) {
      await instanceManager.adFor(id)?.dispose();
    }
    messenger.setMockMethodCallHandler(instanceManager.channel, null);
    ads.ready.dispose();
    ads.privacyRequired.dispose();
  });

  test(
    'preload reuses fresh ads and refreshes expired ads of both formats',
    () async {
      await ads.preload();
      await ads.preloadReward();
      final oldBreak = breaks.single;
      final oldReward = rewards.single;
      now = now.add(const Duration(minutes: 55));
      await ads.preload();
      await ads.preloadReward();
      expect(breaks, hasLength(1));
      expect(rewards, hasLength(1));
      now = now.add(const Duration(seconds: 1));
      await ads.preload();
      await ads.preloadReward();
      expect(breaks, hasLength(2));
      expect(rewards, hasLength(2));
      expect(disposed, containsAll([oldBreak, oldReward]));
      await ads.preload();
      await ads.preloadReward();
      expect(breaks, hasLength(2));
      expect(rewards, hasLength(2));
    },
  );

  test('expired inventory cannot trigger requests without consent or in background', () async {
    await ads.preload();
    await ads.preloadReward();
    now = now.add(const Duration(minutes: 56));
    ads.ready.value = false;
    await ads.preload();
    await ads.preloadReward();
    expect(breaks, hasLength(1));
    expect(rewards, hasLength(1));
    ads.ready.value = true;
    ads.didChangeAppLifecycleState(AppLifecycleState.paused);
    await ads.preload();
    await ads.preloadReward();
    expect(breaks, hasLength(1));
    expect(rewards, hasLength(1));
    ads.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await ads.preload();
    await ads.preloadReward();
    expect(breaks, hasLength(2));
    expect(rewards, hasLength(2));
  });
}
