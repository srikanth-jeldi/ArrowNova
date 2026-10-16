import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arrownova/core/feedback_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('haptic setting controls the native feedback calls', () async {
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            calls.add(call.arguments as String);
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );
    final feedback = FeedbackService();
    await feedback.play('clear', sound: false, haptics: true);
    await feedback.play('blocked', sound: false, haptics: true);
    await feedback.play('lost', sound: false, haptics: true);
    await feedback.play('blocked', sound: false, haptics: false);
    await feedback.play('lost', sound: false, haptics: false);
    await feedback.play('clear', sound: false, haptics: false);
    expect(calls, [
      'HapticFeedbackType.lightImpact',
      'HapticFeedbackType.mediumImpact',
      'HapticFeedbackType.heavyImpact',
    ]);
    feedback.dispose();
  });
  test('native haptic failure does not escape the gameplay action', () async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (_) async {
      throw PlatformException(code: 'unavailable');
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
    final feedback = FeedbackService();
    await feedback.play('clear', sound: false, haptics: true);
    await Future<void>.delayed(Duration.zero);
    feedback.dispose();
  });
}
