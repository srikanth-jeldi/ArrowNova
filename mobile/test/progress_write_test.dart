import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:arrownova/core/progress_store.dart';

void main() {
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
