import 'dart:async';

import 'package:flutter/widgets.dart';

/// Recovers missing SDK callbacks without timing out a visible native ad.
class AdSession extends WidgetsBindingObserver {
  AdSession(this.onFinish) {
    WidgetsBinding.instance.addObserver(this);
    _opening = Timer(const Duration(seconds: 5), finish);
  }
  final VoidCallback onFinish;
  Timer? _opening, _returning;
  bool finished = false;
  bool _leftApp = false;

  void markShown() {
    if (finished) return;
    _opening?.cancel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (finished) return;
    if (state != AppLifecycleState.resumed) {
      _leftApp = true;
      _opening?.cancel();
      _returning?.cancel();
    } else if (_leftApp) {
      // Give SDK reward and dismissal callbacks time to arrive on return.
      _returning = Timer(const Duration(seconds: 1), finish);
    }
  }

  void finish() {
    if (finished) return;
    finished = true;
    _opening?.cancel();
    _returning?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    onFinish();
  }
}
