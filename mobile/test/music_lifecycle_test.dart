import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arrownova/core/music_service.dart';

class FakeMusicPlayer implements AudioPlayer {
  @override
  PlayerState state = PlayerState.stopped;
  int plays = 0, resumes = 0, pauses = 0;
  bool pollingDisabled = false;
  @override
  set positionUpdater(PositionUpdater? value) =>
      pollingDisabled = value == null;
  @override
  Future<void> setAudioContext(AudioContext context) async {}
  @override
  Future<void> setReleaseMode(ReleaseMode mode) async {}
  @override
  Future<void> setVolume(double volume) async {}
  @override
  Future<void> play(
    Source source, {
    double? volume,
    double? balance,
    AudioContext? ctx,
    Duration? position,
    PlayerMode? mode,
  }) async {
    plays++;
    state = PlayerState.playing;
  }

  @override
  Future<void> resume() async {
    resumes++;
    state = PlayerState.playing;
  }

  @override
  Future<void> pause() async {
    pauses++;
    state = PlayerState.paused;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('many saves do not restart music or create polling loops', () async {
    final player = FakeMusicPlayer();
    final music = MusicService(createPlayer: () => player);
    addTearDown(() => WidgetsBinding.instance.removeObserver(music));
    music.setEnabled(true);
    await music.settled;
    for (var i = 0; i < 500; i++) {
      music.setEnabled(true);
    }
    await music.settled;
    expect(player.pollingDisabled, true);
    expect(player.plays, 1);
    expect(player.resumes, 0);
    for (var i = 0; i < 20; i++) {
      music.didChangeAppLifecycleState(AppLifecycleState.inactive);
      music.didChangeAppLifecycleState(AppLifecycleState.hidden);
      music.didChangeAppLifecycleState(AppLifecycleState.paused);
      await music.settled;
      expect(player.state, PlayerState.paused);
      music.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await music.settled;
    }
    expect(player.pauses, 20);
    expect(player.resumes, 20);
    music.setCelebrating(true);
    await music.settled;
    expect(player.resumes, 20);
    music.setEnabled(false);
    await music.settled;
  });
}
