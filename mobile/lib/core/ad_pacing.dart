/// Session-wide spacing for automatic full-screen ads. Rewarded ads remain opt-in.
class AdPacing {
  AdPacing({DateTime Function()? now}) : _now = now ?? DateTime.now {
    _lastBreak = _now();
  }

  final DateTime Function() _now;
  late DateTime _lastBreak;
  static const cooldown = Duration(seconds: 90);

  bool get canShowInterstitial => _now().difference(_lastBreak) >= cooldown;

  /// Count from dismissal so a long rewarded video cannot exhaust the cooldown.
  void fullscreenClosed() => _lastBreak = _now();
}
