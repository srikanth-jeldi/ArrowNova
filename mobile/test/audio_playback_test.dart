import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:arrownova/core/feedback_service.dart';

class FakeOutput implements FeedbackOutput {
  final events = <String>[];
  Completer<void>? pending;
  bool failNext = false;
  @override
  Future<void> play(String asset, double volume) async {
    events.add('$asset@$volume');
    if (failNext) {
      failNext = false;
      throw StateError('decoder failed');
    }
    await pending?.future;
  }

  @override
  Future<void> stop() async {
    events.add('stop');
  }

  @override
  Future<void> dispose() async {
    events.add('dispose');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('victory waits for last arrow and uses its own output', () async {
    final effects = FakeOutput()..pending = Completer<void>(),
        victory = FakeOutput();
    final duck = <bool>[];
    final service = FeedbackService(
      effects: effects,
      victory: victory,
      onCelebration: duck.add,
    );
    final clear = service.play('clear', sound: true, haptics: false);
    await Future<void>.delayed(Duration.zero);
    final win = service.play('win', sound: true, haptics: false);
    effects.pending!.complete();
    await clear;
    await win;
    expect(effects.events, ['audio/clear.mp3@0.28', 'stop']);
    expect(victory.events, ['audio/win.mp3@0.85']);
    expect(duck, [true]);
    await service.play('clear', sound: true, haptics: false);
    expect(effects.events.length, 2);
    await service.stop();
    expect(victory.events.last, 'stop');
    expect(duck.last, false);
    await service.play('clear', sound: true, haptics: false);
    expect(effects.events.last, 'audio/clear.mp3@0.28');
    service.dispose();
  });
  test('mute remains silent and stop cancels queued victory', () async {
    final effects = FakeOutput()..pending = Completer<void>(),
        victory = FakeOutput();
    final service = FeedbackService(
      effects: effects,
      victory: victory,
      onCelebration: (_) {},
    );
    await service.play('win', sound: false, haptics: false);
    expect(victory.events, isEmpty);
    final clear = service.play('clear', sound: true, haptics: false);
    await Future<void>.delayed(Duration.zero);
    final win = service.play('win', sound: true, haptics: false);
    final stopped = service.stop();
    effects.pending!.complete();
    await Future.wait([clear, win, stopped]);
    expect(victory.events, ['stop']);
    service.dispose();
  });
  test(
    'blocked and final-life errors use dedicated cues, mute suppresses both',
    () async {
      final effects = FakeOutput(), victory = FakeOutput();
      final service = FeedbackService(
        effects: effects,
        victory: victory,
        onCelebration: (_) {},
      );
      await service.play('blocked', sound: true, haptics: false);
      await service.play('lost', sound: true, haptics: false);
      await service.play('blocked', sound: false, haptics: false);
      await service.play('lost', sound: false, haptics: false);
      expect(effects.events, ['audio/blocked.mp3@0.48', 'audio/lost.mp3@0.48']);
      expect(victory.events, isEmpty);
      service.dispose();
    },
  );
  test(
    'failed victory reports an error and does not suppress later effects',
    () async {
      final effects = FakeOutput(), victory = FakeOutput()..failNext = true;
      final errors = <String>[];
      final duck = <bool>[];
      final service = FeedbackService(
        effects: effects,
        victory: victory,
        onCelebration: duck.add,
        onError: (event, error) => errors.add(event),
      );
      await service.play('win', sound: true, haptics: false);
      expect(errors, ['win']);
      expect(duck, [true, false]);
      await service.play('clear', sound: true, haptics: false);
      expect(effects.events.last, 'audio/clear.mp3@0.28');
      await service.play('win', sound: true, haptics: false);
      expect(victory.events.length, 2);
      service.dispose();
    },
  );
  test('new assets packaged and old machine sounds absent', () {
    for (final name in [
      'clear',
      'blocked',
      'lost',
      'life_lost',
      'win',
      'ambient',
    ]) {
      expect(File('assets/audio/$name.mp3').lengthSync(), greaterThan(1000));
      expect(File('assets/audio/$name.wav').existsSync(), false);
    }
  });
}
