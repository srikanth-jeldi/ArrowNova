import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

enum HintAdResult { earned, dismissed, unavailable }

/// Local builds use test inventory; LIVE_ADS is an explicit publishing switch.
class GameAds {
  GameAds._();
  static final instance = GameAds._();
  static const liveAds = bool.fromEnvironment('LIVE_ADS');
  static const bannerId = liveAds
      ? 'ca-app-pub-9061518700917881/4239172993'
      : 'ca-app-pub-3940256099942544/9214589741';
  static const interstitialId = liveAds
      ? 'ca-app-pub-9061518700917881/1696855854'
      : 'ca-app-pub-3940256099942544/1033173712';
  static const rewardedId = liveAds
      ? 'ca-app-pub-9061518700917881/4798496062'
      : 'ca-app-pub-3940256099942544/5224354917';
  RewardedAd? _rewarded;
  DateTime? _rewardedAt;
  bool _rewardLoading = false;
  final ready = ValueNotifier(false);
  final privacyRequired = ValueNotifier(false);
  InterstitialAd? _interstitial;
  DateTime? _loadedAt;
  bool _started = false,
      _initializing = false,
      _loading = false,
      _showing = false;
  int _consentEpoch = 0;

  Future<void> initialize() async {
    if (_started || kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }
    _started = true;
    try {
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () => unawaited(_gatherConsent()),
        (_) => unawaited(_refreshConsent()),
      );
    } catch (_) {
      // Offline/SDK failure never prevents playing.
    }
  }

  Future<void> _gatherConsent() async {
    try {
      await ConsentForm.loadAndShowConsentFormIfRequired((_) {
        unawaited(_refreshConsent());
      });
    } catch (_) {
      await _refreshConsent();
    }
  }

  Future<void> _refreshConsent() async {
    try {
      privacyRequired.value =
          await ConsentInformation.instance
              .getPrivacyOptionsRequirementStatus() ==
          PrivacyOptionsRequirementStatus.required;
      final allowed = await ConsentInformation.instance.canRequestAds();
      if (!allowed) {
        ready.value = false;
        _consentEpoch++;
        _interstitial?.dispose();
        _interstitial = null;
        _rewarded?.dispose();
        _rewarded = null;
        return;
      }
      if (!ready.value && !_initializing) {
        _initializing = true;
        try {
          await MobileAds.instance.initialize();
          ready.value = true;
        } finally {
          _initializing = false;
        }
      }
      preload();
      preloadReward();
    } catch (_) {
      // No consent/no connection: continue without ads.
    }
  }

  Future<void> privacyOptions() async {
    ready.value = false;
    _consentEpoch++;
    _interstitial?.dispose();
    _interstitial = null;
    _rewarded?.dispose();
    _rewarded = null;
    try {
      await ConsentForm.showPrivacyOptionsForm(
        (_) => unawaited(_refreshConsent()),
      );
    } catch (_) {
      await _refreshConsent();
    }
  }

  Future<void> preload() async {
    if (!ready.value || _loading || _interstitial != null || _showing) return;
    _loading = true;
    final epoch = _consentEpoch;
    try {
      await InterstitialAd.load(
        adUnitId: interstitialId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _loading = false;
            if (!ready.value || epoch != _consentEpoch) {
              ad.dispose();
              return;
            }
            _interstitial = ad;
            _loadedAt = DateTime.now();
          },
          onAdFailedToLoad: (_) {
            _loading = false;
          },
        ),
      );
    } catch (_) {
      _loading = false;
    }
  }

  Future<void> preloadReward() async {
    if (!ready.value || _rewardLoading || _rewarded != null || _showing) return;
    _rewardLoading = true;
    final epoch = _consentEpoch;
    try {
      await RewardedAd.load(
        adUnitId: rewardedId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardLoading = false;
            if (!ready.value || epoch != _consentEpoch) {
              ad.dispose();
              return;
            }
            _rewarded = ad;
            _rewardedAt = DateTime.now();
          },
          onAdFailedToLoad: (_) {
            _rewardLoading = false;
          },
        ),
      );
    } catch (_) {
      _rewardLoading = false;
    }
  }

  Future<HintAdResult> showHintAd() async {
    if (_showing) return HintAdResult.unavailable;
    final ad = _rewarded;
    _rewarded = null;
    if (!ready.value || ad == null) {
      ad?.dispose();
      unawaited(preloadReward());
      return HintAdResult.unavailable;
    }
    if (_rewardedAt == null ||
        DateTime.now().difference(_rewardedAt!) > const Duration(minutes: 55)) {
      ad.dispose();
      unawaited(preloadReward());
      return HintAdResult.unavailable;
    }
    _showing = true;
    var earned = false;
    final done = Completer<HintAdResult>();
    void finish({bool failed = false}) {
      if (done.isCompleted) return;
      ad.dispose();
      _showing = false;
      done.complete(
        earned
            ? HintAdResult.earned
            : failed
            ? HintAdResult.unavailable
            : HintAdResult.dismissed,
      );
      unawaited(preloadReward());
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (_) => finish(),
      onAdFailedToShowFullScreenContent: (_, _) => finish(failed: true),
    );
    try {
      await ad.show(
        onUserEarnedReward: (_, _) {
          earned = true;
        },
      );
    } catch (_) {
      finish(failed: true);
    }
    return done.future;
  }

  /// Never waits for inventory and never shows a late ad during a puzzle.
  Future<void> showAtBreak() async {
    if (_showing) return;
    final ad = _interstitial;
    _interstitial = null;
    if (!ready.value || ad == null) {
      unawaited(preload());
      return;
    }
    if (_loadedAt == null ||
        DateTime.now().difference(_loadedAt!) > const Duration(minutes: 55)) {
      ad.dispose();
      unawaited(preload());
      return;
    }
    _showing = true;
    final done = Completer<void>();
    void finish() {
      if (done.isCompleted) return;
      ad.dispose();
      _showing = false;
      done.complete();
      unawaited(preload());
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (_) => finish(),
      onAdFailedToShowFullScreenContent: (_, _) => finish(),
    );
    try {
      await ad.show();
    } catch (_) {
      finish();
    }
    await done.future;
  }
}

/// A reserved footer, separated from controls. Loading never shifts the puzzle.
class GameBanner extends StatelessWidget {
  const GameBanner({super.key});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: GameAds.instance.ready,
    builder: (_, ready, _) {
      if (!GameAds.instance._started ||
          MediaQuery.sizeOf(context).width < 340) {
        return const SizedBox.shrink();
      }
      return ready
          ? const _BannerSlot()
          : const SafeArea(top: false, child: SizedBox(height: 82));
    },
  );
}

class _BannerSlot extends StatefulWidget {
  const _BannerSlot();
  @override
  State<_BannerSlot> createState() => _BannerSlotState();
}

class _BannerSlotState extends State<_BannerSlot> {
  BannerAd? ad;
  bool loaded = false;
  @override
  void initState() {
    super.initState();
    ad = BannerAd(
      size: AdSize.banner,
      adUnitId: GameAds.bannerId,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => loaded = true);
        },
        onAdFailedToLoad: (failed, _) {
          failed.dispose();
          ad = null;
        },
      ),
    );
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      await ad?.load();
    } catch (_) {
      ad?.dispose();
      ad = null;
    }
  }

  @override
  void dispose() {
    ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: SizedBox(
      height: 82,
      child: Column(
        children: [
          const SizedBox(height: 12),
          const Text(
            'Advertisement',
            style: TextStyle(fontSize: 9, color: Colors.white54),
          ),
          const SizedBox(height: 5),
          SizedBox(
            width: 320,
            height: 50,
            child: loaded && ad != null ? AdWidget(ad: ad!) : null,
          ),
        ],
      ),
    ),
  );
}
