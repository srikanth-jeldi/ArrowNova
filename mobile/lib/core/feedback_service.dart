import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class FeedbackService {
  AudioPlayer? _player;
  Future<void> play(
    String event, {
    required bool sound,
    required bool haptics,
  }) async {
    if (haptics) {
      unawaited(
        event == 'blocked'
            ? HapticFeedback.mediumImpact()
            : HapticFeedback.lightImpact(),
      );
    }
    if (sound) {
      try {
        if (_player == null) {
          _player = AudioPlayer();
          await _player!.setAudioContext(
            AudioContext(
              android: const AudioContextAndroid(
                audioFocus: AndroidAudioFocus.none,
              ),
              iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
            ),
          );
        }
        await _player!.play(AssetSource('audio/$event.wav'), volume: .3);
      } catch (_) {
        /* Feedback must never interrupt a move. */
      }
    }
  }

  void dispose() {
    if (_player != null) unawaited(_player!.dispose());
  }
}
