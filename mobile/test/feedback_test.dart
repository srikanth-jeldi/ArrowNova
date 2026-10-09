import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arrownova/core/feedback_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('haptic setting controls the native feedback calls', () async {
    final calls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') calls.add(call.arguments as String);
      return null;
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    final feedback = FeedbackService();
    await feedback.play('clear', sound: false, haptics: true);
    await feedback.play('blocked', sound: false, haptics: true);
    await feedback.play('clear', sound: false, haptics: false);
    expect(calls, ['HapticFeedbackType.lightImpact', 'HapticFeedbackType.mediumImpact']);
    feedback.dispose();
  });
}
