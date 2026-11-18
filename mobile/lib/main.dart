import 'dart:async';

import 'core/ads.dart';

import 'package:flutter/material.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ArrowNovaApp(onHomeReady: () => unawaited(GameAds.instance.initialize())),
  );
}
