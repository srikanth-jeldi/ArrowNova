import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:arrownova/core/ads.dart';

import 'ad_initialization_recovery_test.dart' show OfflineConsent;

class PendingFormConsent extends OfflineConsent {
  @override
  void requestConsentInfoUpdate(
    ConsentRequestParameters params,
    OnConsentInfoUpdateSuccessListener success,
    OnConsentInfoUpdateFailureListener failure,
  ) {
    requests++;
    success();
  }
}

void main() {
  testWidgets(
    'long consent form cannot stack another form on recovery or resume',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      const channel = MethodChannel('plugins.flutter.io/google_mobile_ads/ump');
      final form = Completer<void>();
      var forms = 0;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (call.method ==
            'UserMessagingPlatform#loadAndShowConsentFormIfRequired') {
          forms++;
          await form.future;
        }
        return null;
      });
      final original = ConsentInformation.instance;
      final consent = PendingFormConsent();
      ConsentInformation.instance = consent;
      final ads = GameAds.instance;
      addTearDown(() {
        ads.didChangeAppLifecycleState(AppLifecycleState.paused);
        WidgetsBinding.instance.removeObserver(ads);
        ConsentInformation.instance = original;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        );
        debugDefaultTargetPlatformOverride = null;
      });
      await ads.initialize();
      await tester.pump();
      await tester.pump(const Duration(minutes: 2));
      ads.didChangeAppLifecycleState(AppLifecycleState.paused);
      ads.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pump();
      expect(forms, 1);
      expect(consent.requests, 1);
      expect(ads.ready.value, false);
      form.complete();
      await tester.pump();
      ads.didChangeAppLifecycleState(AppLifecycleState.paused);
      debugDefaultTargetPlatformOverride = null;
    },
  );
}
