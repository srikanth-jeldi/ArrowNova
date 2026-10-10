import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'music_service.dart';

/// Separate victory output keeps the final arrow from replacing the applause.
abstract class FeedbackOutput {
  Future<void> play(String asset, double volume);
  Future<void> stop();
  Future<void> dispose();
}

class _AssetOutput implements FeedbackOutput {
  AudioPlayer? _player;
  Future<void>? _ready;
  Future<void> _prepare() => _ready ??= _initialize();
  Future<void> _initialize() async {
    _player = AudioPlayer();
    await _player!.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(audioFocus: AndroidAudioFocus.none),
        iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
      ),
    );
  }

  @override
  Future<void> play(String asset, double volume) async {
    try {
      await _prepare();
      await _player!.play(AssetSource(asset), volume: volume);
    } catch (_) {
      final failed = _player;
      _player = null;
      _ready = null;
      try {
        await failed?.dispose();
      } catch (_) {}
      rethrow;
    }
  }

  @override
  Future<void> stop() async {
    await _player?.stop();
  }

  @override
  Future<void> dispose() async {
    await _player?.dispose();
  }
}

class FeedbackService {
  FeedbackService({
    FeedbackOutput? effects,
    FeedbackOutput? victory,
    FeedbackOutput? warnings,
    void Function(bool)? onCelebration,
    this.onError,
  }) : _effects = effects ?? _AssetOutput(),
       _victory = victory ?? _AssetOutput(),
       _warnings = warnings ?? _AssetOutput(),
       _onCelebration = onCelebration ?? MusicService.instance.setCelebrating;
  final void Function(String event, Object error)? onError;
  final FeedbackOutput _effects, _victory, _warnings;
  final void Function(bool) _onCelebration;
  Future<void> _queue = Future.value();
  Timer? _duckTimer;
  bool _disposed = false, _celebrating = false;
  int _generation = 0;

  Future<void> play(
    String event, {
    required bool sound,
    required bool haptics,
  }) {
    if (_disposed) return Future.value();
    if (haptics) {
      unawaited(
        event == 'lost'
            ? HapticFeedback.heavyImpact()
            : event == 'blocked'
            ? HapticFeedback.mediumImpact()
            : HapticFeedback.lightImpact(),
      );
    }
    if (!sound || (event != 'win' && _celebrating)) return Future.value();
    if (event == 'win') _celebrating = true;
    final generation = _generation;
    _queue = _queue.then((_) async {
      if (_disposed || generation != _generation) return;
      try {
        if (event == 'win') {
          await _effects.stop();
          await _warnings.stop();
          _onCelebration(true);
          _duckTimer?.cancel();
          _duckTimer = Timer(const Duration(milliseconds: 4700), () {
            _onCelebration(false);
          });
          await _victory.play('audio/win.mp3', .85);
        } else if (event == 'blocked' || event == 'lost') {
          await _effects.stop();
          await _warnings.play('audio/$event.mp3', .85);
        } else {
          await _effects.play('audio/$event.mp3', event == 'clear' ? .28 : .48);
        }
      } catch (error) {
        if (event == 'win') {
          _celebrating = false;
          _duckTimer?.cancel();
          _onCelebration(false);
        }
        onError?.call(event, error);
        debugPrint('ArrowNova audio ($event): $error');
      }
    });
    return _queue;
  }

  /// Stop celebrations on replay, next level, backgrounding or before an ad.
  Future<void> stop() {
    _generation++;
    _celebrating = false;
    _duckTimer?.cancel();
    _onCelebration(false);
    _queue = _queue
        .then((_) async {
          await _effects.stop();
          await _victory.stop();
          await _warnings.stop();
        })
        .catchError((Object error) {
          debugPrint('ArrowNova audio stop: $error');
        });
    return _queue;
  }

  void dispose() {
    _disposed = true;
    unawaited(
      stop().then((_) async {
        await _effects.dispose();
        await _victory.dispose();
        await _warnings.dispose();
      }),
    );
  }
}
