import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';

/// A single quiet loop, muted during ads and whenever the app leaves foreground.
class MusicService with WidgetsBindingObserver {
  MusicService({AudioPlayer Function()? createPlayer})
    : _createPlayer = createPlayer ?? AudioPlayer.new;
  final AudioPlayer Function() _createPlayer;
  Future<void> get settled => _queue;
  static final instance = MusicService();
  AudioPlayer? _player;
  bool _celebrating = false;
  bool _enabled = false, _foreground = true, _ad = false, _observing = false;
  Future<void> _queue = Future.value();
  void setEnabled(bool enabled) {
    if (!_observing) {
      WidgetsBinding.instance.addObserver(this);
      _observing = true;
    }
    if (_enabled == enabled) return;
    _enabled = enabled;
    _sync();
  }

  void setCelebrating(bool celebrating) {
    if (_celebrating == celebrating) return;
    _celebrating = celebrating;
    _sync();
  }

  void setAd(bool showing) {
    if (_ad == showing) return;
    _ad = showing;
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground = state == AppLifecycleState.resumed;
    if (_foreground == foreground) return;
    _foreground = foreground;
    _sync();
  }

  void _sync() {
    _queue = _queue.then((_) async {
      try {
        if (!_enabled || !_foreground || _ad) {
          if (_player?.state == PlayerState.playing) await _player?.pause();
          return;
        }
        if (_player == null) {
          _player = _createPlayer();
          // No playback scrubber: avoid per-frame native position queries.
          // Repeated resume used to start overlapping frame polling loops.
          _player!.positionUpdater = null;
          await _player!.setAudioContext(
            AudioContext(
              iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
            ),
          );
          await _player!.setReleaseMode(ReleaseMode.loop);
          await _player!.play(
            AssetSource('audio/ambient.mp3'),
            volume: _celebrating ? .025 : .24,
          );
        } else {
          await _player!.setVolume(_celebrating ? .025 : .24);
          if (_player!.state != PlayerState.playing) await _player!.resume();
        }
      } catch (_) {
        /* Audio never blocks a puzzle. */
      }
    });
  }
}
