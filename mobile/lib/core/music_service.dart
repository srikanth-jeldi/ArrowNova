import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';

/// A single quiet loop, muted during ads and whenever the app leaves foreground.
class MusicService with WidgetsBindingObserver {
  static final instance = MusicService();
  AudioPlayer? _player;
  bool _enabled = false, _foreground = true, _ad = false, _observing = false;
  Future<void> _queue = Future.value();
  void setEnabled(bool enabled) {
    if (!_observing) {
      WidgetsBinding.instance.addObserver(this);
      _observing = true;
    }
    _enabled = enabled;
    _sync();
  }

  void setAd(bool showing) {
    _ad = showing;
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _sync();
  }

  void _sync() {
    _queue = _queue.then((_) async {
      try {
        if (!_enabled || !_foreground || _ad) {
          await _player?.pause();
          return;
        }
        if (_player == null) {
          _player = AudioPlayer();
          await _player!.setAudioContext(
            AudioContext(
              iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
            ),
          );
          await _player!.setReleaseMode(ReleaseMode.loop);
          await _player!.play(AssetSource('audio/ambient.wav'), volume: .10);
        } else {
          await _player!.resume();
        }
      } catch (_) {
        /* Audio never blocks a puzzle. */
      }
    });
  }
}
