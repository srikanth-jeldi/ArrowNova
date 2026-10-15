import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'music_service.dart';
import 'ad_pacing.dart';
import 'ad_session.dart';

/// Native cleanup must not leave an unhandled asynchronous platform error.
Future<void> disposeAdSafely(Ad? ad) async {
  try {
    await ad?.dispose();
  } catch (error) {
    debugPrint('ArrowNova ad cleanup: $error');
  }
}

enum HintAdResult { earned, dismissed, unavailable }

/// Local builds use test inventory; LIVE_ADS is an explicit publishing switch.
class GameAds with WidgetsBindingObserver {
  GameAds._() : _now = DateTime.now;
  @visibleForTesting
  GameAds.forTesting({DateTime Function()? now}) : _now = now ?? DateTime.now;
  final DateTime Function() _now;
  static final instance = GameAds._();
  static const liveAds = bool.fromEnvironment('LIVE_ADS');
  static bool get ios => defaultTargetPlatform == TargetPlatform.iOS;
  static const iosBanner = String.fromEnvironment('IOS_BANNER_ID');
  static const iosInterstitial = String.fromEnvironment('IOS_INTERSTITIAL_ID');
  static const iosRewarded = String.fromEnvironment('IOS_REWARDED_ID');
  static String get bannerId => ios
      ? (liveAds ? iosBanner : 'ca-app-pub-3940256099942544/2934735716')
      : liveAds
      ? 'ca-app-pub-9061518700917881/4239172993'
      : 'ca-app-pub-3940256099942544/9214589741';
  static String get interstitialId => ios
      ? (liveAds ? iosInterstitial : 'ca-app-pub-3940256099942544/4411468910')
      : liveAds
      ? 'ca-app-pub-9061518700917881/1696855854'
      : 'ca-app-pub-3940256099942544/1033173712';
  static String get rewardedId => ios
      ? (liveAds ? iosRewarded : 'ca-app-pub-3940256099942544/1712485313')
      : liveAds
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
  Timer? _recovery;
  bool _foreground = true, _consentBusy = false, _consentFormOpen = false;
  DateTime? _consentRequestedAt, _rewardRequestedAt, _breakRequestedAt;
  int _rewardRequest = 0, _breakRequest = 0;

  void _scheduleRecovery() {
    _recovery?.cancel();
    if (!_foreground) return;
    _recovery = Timer(const Duration(seconds: 30), () {
      if (!ready.value) {
        unawaited(initialize());
      } else {
        final now = _now();
        if (_rewardLoading &&
            _rewardRequestedAt != null &&
            now.difference(_rewardRequestedAt!) >= const Duration(minutes: 6)) {
          _rewardRequest++;
          _rewardLoading = false;
        }
        if (_loading &&
            _breakRequestedAt != null &&
            now.difference(_breakRequestedAt!) >= const Duration(minutes: 6)) {
          _breakRequest++;
          _loading = false;
        }
        unawaited(preload());
        unawaited(preloadReward());
      }
      _scheduleRecovery();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      if (!ready.value) unawaited(initialize());
      _scheduleRecovery();
    } else {
      _recovery?.cancel();
    }
  }

  final _pacing = AdPacing();

  bool get canShowBreakNow =>
      ready.value &&
      !_showing &&
      _pacing.canShowInterstitial &&
      _interstitial != null &&
      _loadedAt != null &&
      _now().difference(_loadedAt!) <= const Duration(minutes: 55);

  void deferAutomaticAds() => _pacing.fullscreenClosed();

  Future<void> initialize() async {
    if (ready.value ||
        kIsWeb ||
        (!ios && defaultTargetPlatform != TargetPlatform.android)) {
      return;
    }
    // Android IDs must never be reused for an iOS release.
    if (ios &&
        liveAds &&
        [iosBanner, iosInterstitial, iosRewarded].any((id) => id.isEmpty)) {
      return;
    }
    if (!_started) {
      _started = true;
      WidgetsBinding.instance.addObserver(this);
      _scheduleRecovery();
    }
    if (!_foreground ||
        _consentFormOpen ||
        (_consentBusy &&
            _consentRequestedAt != null &&
            _now().difference(_consentRequestedAt!) <
                const Duration(seconds: 30))) {
      return;
    }
    _consentBusy = true;
    _consentRequestedAt = _now();
    try {
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () {
          _consentBusy = false;
          if (_foreground) unawaited(_gatherConsent());
        },
        (error) {
          _consentBusy = false;
          debugPrint(
            'ArrowNova consent update: ${error.errorCode} ${error.message}',
          );
          unawaited(_refreshConsent());
        },
      );
    } catch (error) {
      _consentBusy = false;
      debugPrint("ArrowNova consent initialization: $error");
      // Offline/SDK failure never prevents playing.
    }
  }

  Future<void> _gatherConsent() async {
    if (_consentFormOpen) return;
    _consentFormOpen = true;
    try {
      await ConsentForm.loadAndShowConsentFormIfRequired((_) {
        _consentFormOpen = false;
        unawaited(_refreshConsent());
      });
    } catch (_) {
      _consentFormOpen = false;
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
        disposeAdSafely(_interstitial);
        _interstitial = null;
        disposeAdSafely(_rewarded);
        _rewarded = null;
        return;
      }
      if (!ready.value && !_initializing) {
        _initializing = true;
        try {
          await MobileAds.instance.initialize().timeout(
            const Duration(seconds: 15),
          );
          ready.value = true;
        } finally {
          _initializing = false;
        }
      }
      preload();
      preloadReward();
    } catch (error) {
      debugPrint("ArrowNova ads initialization: $error");
      // No consent/no connection: continue without ads.
    }
  }

  Future<void> privacyOptions() async {
    if (_consentFormOpen) return;
    _consentFormOpen = true;
    ready.value = false;
    _consentEpoch++;
    disposeAdSafely(_interstitial);
    _interstitial = null;
    disposeAdSafely(_rewarded);
    _rewarded = null;
    try {
      await ConsentForm.showPrivacyOptionsForm((_) {
        _consentFormOpen = false;
        unawaited(_refreshConsent());
      });
    } catch (_) {
      _consentFormOpen = false;
      await _refreshConsent();
    }
  }

  Future<void> preload() async {
    if (!_foreground || !ready.value || _showing) return;
    // Refresh stale inventory before the next level break needs it.
    if (_interstitial != null &&
        (_loadedAt == null ||
            _now().difference(_loadedAt!) > const Duration(minutes: 55))) {
      final expired = _interstitial;
      _interstitial = null;
      _loadedAt = null;
      unawaited(disposeAdSafely(expired));
    }
    if (!_foreground ||
        !ready.value ||
        _loading ||
        _interstitial != null ||
        _showing) {
      return;
    }
    _loading = true;
    _breakRequestedAt = _now();
    final request = ++_breakRequest;
    final epoch = _consentEpoch;
    try {
      await InterstitialAd.load(
        adUnitId: interstitialId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            if (request != _breakRequest) {
              disposeAdSafely(ad);
              return;
            }
            _loading = false;
            if (!ready.value || epoch != _consentEpoch) {
              disposeAdSafely(ad);
              return;
            }
            _interstitial = ad;
            _loadedAt = _now();
          },
          onAdFailedToLoad: (error) {
            if (request != _breakRequest) return;
            debugPrint(
              'ArrowNova interstitial load: ${error.code} ${error.domain} ${error.message}',
            );
            _loading = false;
          },
        ),
      );
    } catch (error) {
      if (request == _breakRequest) _loading = false;
      debugPrint('ArrowNova interstitial request: $error');
    }
  }

  Future<void> preloadReward() async {
    if (!_foreground || !ready.value || _showing) return;
    // A hint request should not be the first time expired inventory is noticed.
    if (_rewarded != null &&
        (_rewardedAt == null ||
            _now().difference(_rewardedAt!) > const Duration(minutes: 55))) {
      final expired = _rewarded;
      _rewarded = null;
      _rewardedAt = null;
      unawaited(disposeAdSafely(expired));
    }
    if (!_foreground ||
        !ready.value ||
        _rewardLoading ||
        _rewarded != null ||
        _showing) {
      return;
    }
    _rewardLoading = true;
    _rewardRequestedAt = _now();
    final request = ++_rewardRequest;
    final epoch = _consentEpoch;
    try {
      await RewardedAd.load(
        adUnitId: rewardedId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            if (request != _rewardRequest) {
              disposeAdSafely(ad);
              return;
            }
            _rewardLoading = false;
            if (!ready.value || epoch != _consentEpoch) {
              disposeAdSafely(ad);
              return;
            }
            _rewarded = ad;
            _rewardedAt = _now();
          },
          onAdFailedToLoad: (error) {
            if (request != _rewardRequest) return;
            debugPrint(
              'ArrowNova rewarded load: ${error.code} ${error.domain} ${error.message}',
            );
            _rewardLoading = false;
          },
        ),
      );
    } catch (error) {
      if (request == _rewardRequest) _rewardLoading = false;
      debugPrint('ArrowNova rewarded request: $error');
    }
  }

  Future<HintAdResult> showHintAd() async {
    if (!_foreground || _showing) return HintAdResult.unavailable;
    final ad = _rewarded;
    _rewarded = null;
    if (!ready.value || ad == null) {
      disposeAdSafely(ad);
      unawaited(preloadReward());
      return HintAdResult.unavailable;
    }
    if (_rewardedAt == null ||
        _now().difference(_rewardedAt!) > const Duration(minutes: 55)) {
      disposeAdSafely(ad);
      unawaited(preloadReward());
      return HintAdResult.unavailable;
    }
    _showing = true;
    MusicService.instance.setAd(true);
    var earned = false;
    var shown = false;
    final done = Completer<HintAdResult>();
    var failed = false;
    void finish() {
      if (done.isCompleted) return;
      disposeAdSafely(ad);
      _showing = false;
      if (shown || earned) _pacing.fullscreenClosed();
      MusicService.instance.setAd(false);
      done.complete(
        earned
            ? HintAdResult.earned
            : failed
            ? HintAdResult.unavailable
            : HintAdResult.dismissed,
      );
      unawaited(preloadReward());
    }

    final session = AdSession(() {
      if (!shown && !earned) failed = true;
      finish();
    });
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        if (session.finished) return;
        shown = true;
        session.markShown();
      },
      onAdDismissedFullScreenContent: (_) => session.finish(),
      onAdFailedToShowFullScreenContent: (_, _) {
        failed = true;
        session.finish();
      },
    );
    // A missing platform reply must not bypass session recovery.
    unawaited(() async {
      try {
        await ad.show(
          onUserEarnedReward: (_, _) {
            if (!session.finished) earned = true;
          },
        );
      } catch (_) {
        failed = true;
        session.finish();
      }
    }());
    return done.future;
  }

  /// Never waits for inventory and never shows a late ad during a puzzle.
  Future<void> showAtBreak() async {
    if (!_foreground || _showing || !_pacing.canShowInterstitial) return;
    final ad = _interstitial;
    _interstitial = null;
    if (!ready.value || ad == null) {
      disposeAdSafely(ad);
      unawaited(preload());
      return;
    }
    if (_loadedAt == null ||
        _now().difference(_loadedAt!) > const Duration(minutes: 55)) {
      disposeAdSafely(ad);
      unawaited(preload());
      return;
    }
    _showing = true;
    MusicService.instance.setAd(true);
    final done = Completer<void>();
    var shown = false;
    void finish() {
      if (done.isCompleted) return;
      disposeAdSafely(ad);
      _showing = false;
      if (shown) _pacing.fullscreenClosed();
      MusicService.instance.setAd(false);
      done.complete();
      unawaited(preload());
    }

    final session = AdSession(finish);
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        if (session.finished) return;
        shown = true;
        session.markShown();
      },
      onAdDismissedFullScreenContent: (_) => session.finish(),
      onAdFailedToShowFullScreenContent: (_, _) => session.finish(),
    );
    unawaited(() async {
      try {
        await ad.show();
      } catch (_) {
        session.finish();
      }
    }());
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

class _BannerSlotState extends State<_BannerSlot> with WidgetsBindingObserver {
  Timer? retry;
  bool foreground = true;
  BannerAd? ad;
  bool loaded = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    createBanner();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    foreground = state == AppLifecycleState.resumed;
    if (!foreground) {
      retry?.cancel();
    } else if (ad == null) {
      createBanner();
    }
  }

  void scheduleRetry() {
    retry?.cancel();
    if (mounted && foreground) {
      retry = Timer(const Duration(seconds: 30), createBanner);
    }
  }

  void createBanner() {
    if (!mounted || !foreground || ad != null) return;
    ad = BannerAd(
      size: AdSize.banner,
      adUnitId: GameAds.bannerId,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (loadedAd) {
          if (mounted && identical(ad, loadedAd)) {
            setState(() => loaded = true);
          }
        },
        onAdFailedToLoad: (failed, error) {
          debugPrint(
            'ArrowNova banner load: ${error.code} ${error.domain} ${error.message}',
          );
          disposeAdSafely(failed);
          if (!mounted || !identical(ad, failed)) return;
          setState(() {
            ad = null;
            loaded = false;
          });
          scheduleRetry();
        },
      ),
    );
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      await ad?.load();
    } catch (_) {
      disposeAdSafely(ad);
      ad = null;
      scheduleRetry();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    retry?.cancel();
    disposeAdSafely(ad);
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
