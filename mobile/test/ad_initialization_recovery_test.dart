import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:arrownova/core/ads.dart';

class OfflineConsent implements ConsentInformation {
  int requests = 0;
  @override
  void requestConsentInfoUpdate(
    ConsentRequestParameters params,
    OnConsentInfoUpdateSuccessListener success,
    OnConsentInfoUpdateFailureListener failure,
  ) {
    requests++;
    failure(FormError(errorCode: 2, message: 'offline'));
  }

  @override
  Future<bool> canRequestAds() async => false;
  @override
  Future<PrivacyOptionsRequirementStatus>
  getPrivacyOptionsRequirementStatus() async =>
      PrivacyOptionsRequirementStatus.unknown;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
    'offline startup retries without requests in background or bypassing consent',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final original = ConsentInformation.instance;
      final consent = OfflineConsent();
      ConsentInformation.instance = consent;
      final ads = GameAds.instance;
      addTearDown(() {
        ads.didChangeAppLifecycleState(AppLifecycleState.paused);
        WidgetsBinding.instance.removeObserver(ads);
        ConsentInformation.instance = original;
        debugDefaultTargetPlatformOverride = null;
      });
      await ads.initialize();
      await tester.pump();
      expect(consent.requests, 1);
      await tester.pump(const Duration(seconds: 30));
      expect(consent.requests, 2);
      expect(ads.ready.value, false);
      ads.didChangeAppLifecycleState(AppLifecycleState.paused);
      await tester.pump(const Duration(minutes: 2));
      expect(consent.requests, 2);
      ads.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pump();
      expect(consent.requests, 3);
      expect(ads.ready.value, false);
      ads.didChangeAppLifecycleState(AppLifecycleState.paused);
      debugDefaultTargetPlatformOverride = null;
    },
  );
}
