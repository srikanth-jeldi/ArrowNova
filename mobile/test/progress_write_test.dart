import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:arrownova/core/progress_store.dart';

void main() {
  test('read failure never overwrites an existing save', () async {
    var unavailable = true;
    var writes = 0;
    final original = jsonEncode(PlayerProgress(completed: {1, 2, 3}).toJson());
    final store = ProgressStore(
      read: () async {
        if (unavailable) throw StateError('keystore unavailable');
        return original;
      },
      write: (_) async {
        writes++;
      },
    );
    await expectLater(store.read(), throwsStateError);
    await expectLater(store.save(PlayerProgress()), throwsStateError);
    expect(writes, 0);
    unavailable = false;
    final recovered = await store.read();
    expect(recovered.completed, {1, 2, 3});
    await store.save(recovered);
    expect(writes, 1);
  });

  test(
    'invalid JSON stays on disk rather than becoming a blank save',
    () async {
      var writes = 0;
      final store = ProgressStore(
        read: () async => '{broken',
        write: (_) async {
          writes++;
        },
      );
      await expectLater(store.read(), throwsFormatException);
      await expectLater(store.save(PlayerProgress()), throwsStateError);
      expect(writes, 0);
    },
  );

  test('malformed optional collections preserve valid level progress', () {
    for (final bad in [7, 'bad', true]) {
      final progress = PlayerProgress.fromJson({
        'completed': [1, 2],
        'skipped': bad,
        'owned': bad,
        'placements': bad,
        'homePlacements': bad,
        'stars': bad,
      });
      expect(progress.completed, {1, 2});
      expect(progress.skipped, isEmpty);
      expect(progress.bestStars, isEmpty);
    }
    expect(PlayerProgress.fromJson({'completed': 'bad'}).completed, isEmpty);
  });

  test('failed older write retries the newest completed checkpoint', () async {
    final firstWrite = Completer<void>();
    final writes = <String>[];
    final store = ProgressStore(
      write: (value) async {
        writes.add(value);
        if (writes.length == 1) await firstWrite.future;
      },
    );
    final progress = PlayerProgress();
    progress.runs['classic/1'] = {
      'removed': [1],
    };
    final saved = store.save(progress);
    progress.runs.clear();
    progress.completed.add(1);
    final completionSaved = store.save(progress);
    firstWrite.completeError(StateError('temporary storage failure'));
    await saved;
    await completionSaved;
    final loaded = PlayerProgress.fromJson(jsonDecode(writes.last));
    expect(writes.length, 2);
    expect(loaded.completed, {1});
    expect(loaded.runs, isEmpty);
  });

  test(
    'persistent write errors surface and a later save can recover',
    () async {
      var unavailable = true;
      var attempts = 0;
      String? disk;
      final store = ProgressStore(
        write: (value) async {
          attempts++;
          if (unavailable) throw StateError('storage unavailable');
          disk = value;
        },
      );
      final progress = PlayerProgress(completed: {1});
      await expectLater(store.save(progress), throwsStateError);
      expect(attempts, 2);
      unavailable = false;
      progress.completed.add(2);
      await store.save(progress);
      expect(PlayerProgress.fromJson(jsonDecode(disk!)).completed, {1, 2});
    },
  );

  test(
    'slow storage skips old checkpoints and writes the completed puzzle next',
    () async {
      final firstWrite = Completer<void>();
      final writes = <String>[];
      final store = ProgressStore(
        write: (value) async {
          writes.add(value);
          if (writes.length == 1) await firstWrite.future;
        },
      );
      final progress = PlayerProgress();
      final saved = store.save(progress);
      for (var i = 0; i < 200; i++) {
        progress.runs['classic/1'] = {
          'removed': [i],
        };
        unawaited(store.save(progress));
      }
      progress.runs.remove('classic/1');
      progress.completed.add(1);
      unawaited(store.save(progress));
      firstWrite.complete();
      await saved;
      expect(writes.length, 2);
      final loaded = PlayerProgress.fromJson(jsonDecode(writes.last));
      expect(loaded.completed, {1});
      expect(loaded.runs, isEmpty);
      progress.completed.add(2);
      await store.save(progress);
      expect(writes.length, 3);
    },
  );
}
