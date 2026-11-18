import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:arrownova/game/puzzle.dart';

void main() {
  test('released lane checkpoints resume with identical board and cleared arrows', () {
    final fixtures = jsonDecode(File('test/fixtures/pre_circuit_runs.json').readAsStringSync()) as Map;
    for (final entry in fixtures.entries) {
      final run = Map<String, dynamic>.from(entry.value as Map);
      final level = int.parse(entry.key as String);
      final restored = GameSession(LevelCatalog.resume(level, run));
      expect(restored.layoutKey, run['layout']);
      expect(restored.restore(run), 1234);
      expect(restored.removed, (run['removed'] as List).toSet());
      for (final id in restored.puzzle.solution(restored.removed)) {
        restored.tap(id);
      }
      expect(restored.won, true);
    }
  });
}
