import 'dart:async';

import 'core/ads.dart';

import 'package:flutter/material.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ArrowNovaApp());
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(GameAds.instance.initialize());
  });
}
