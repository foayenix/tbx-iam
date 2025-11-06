import 'package:flutter_test/flutter_test.dart';
import 'package:i_am/core/config/remote_config.dart';
import 'package:i_am/data/models/riddle.dart';
import 'package:i_am/domain/logic/rotation_engine.dart';

void main() {
  group('RotationEngine', () {
    late RotationEngine engine;
    late List<Riddle> mockRiddles;

    setUp(() {
      // Note: In real tests, you'd mock RemoteConfigService
      engine = RotationEngine(RemoteConfigService());

      // Create mock riddles
      mockRiddles = [
        _createMockRiddle('1', RiddleDifficulty.easy),
        _createMockRiddle('2', RiddleDifficulty.easy),
        _createMockRiddle('3', RiddleDifficulty.medium),
        _createMockRiddle('4', RiddleDifficulty.medium),
        _createMockRiddle('5', RiddleDifficulty.hard),
      ];
    });

    test('selectNext returns a riddle from available pool', () {
      final riddle = engine.selectNext(mockRiddles);
      expect(riddle, isNotNull);
      expect(mockRiddles.contains(riddle), isTrue);
    });

    test('selectNext returns null for empty pool', () {
      final riddle = engine.selectNext([]);
      expect(riddle, isNull);
    });

    test('selectNext avoids recent repeats', () {
      final selectedIds = <String>{};

      // Select 3 riddles
      for (int i = 0; i < 3; i++) {
        final riddle = engine.selectNext(mockRiddles);
        expect(riddle, isNotNull);
        selectedIds.add(riddle!.id);
      }

      // Should have selected 3 different riddles
      expect(selectedIds.length, 3);
    });

    test('selectNext clears history when all riddles are recent', () {
      // Select all riddles
      for (int i = 0; i < mockRiddles.length; i++) {
        final riddle = engine.selectNext(mockRiddles);
        expect(riddle, isNotNull);
      }

      // Should still be able to select (history cleared)
      final riddle = engine.selectNext(mockRiddles);
      expect(riddle, isNotNull);
    });

    test('buildRotationPool respects difficulty mix', () {
      final easyRiddles = List.generate(
        20,
        (i) => _createMockRiddle('e$i', RiddleDifficulty.easy),
      );
      final mediumRiddles = List.generate(
        20,
        (i) => _createMockRiddle('m$i', RiddleDifficulty.medium),
      );
      final hardRiddles = List.generate(
        20,
        (i) => _createMockRiddle('h$i', RiddleDifficulty.hard),
      );

      final pool = engine.buildRotationPool(
        easyRiddles: easyRiddles,
        mediumRiddles: mediumRiddles,
        hardRiddles: hardRiddles,
        poolSize: 50,
      );

      // Count by difficulty
      final easyCount = pool.where((r) => r.difficulty == RiddleDifficulty.easy).length;
      final mediumCount = pool.where((r) => r.difficulty == RiddleDifficulty.medium).length;
      final hardCount = pool.where((r) => r.difficulty == RiddleDifficulty.hard).length;

      // With default mix (60/30/10), expect approximately:
      // 50 * 0.6 = 30 easy, 50 * 0.3 = 15 medium, 50 * 0.1 = 5 hard
      expect(easyCount, greaterThan(mediumCount));
      expect(mediumCount, greaterThan(hardCount));
      expect(pool.length, lessThanOrEqualTo(50));
    });

    test('clearHistory resets recent riddles', () {
      // Select some riddles
      for (int i = 0; i < 3; i++) {
        engine.selectNext(mockRiddles);
      }

      // Clear history
      engine.clearHistory();

      // All riddles should be available again
      final stats = engine.getStats();
      expect(stats['recent_count'], 0);
    });

    test('getStats returns rotation info', () {
      final stats = engine.getStats();

      expect(stats, isA<Map<String, dynamic>>());
      expect(stats.containsKey('recent_count'), isTrue);
      expect(stats.containsKey('difficulty_mix'), isTrue);
    });
  });
}

Riddle _createMockRiddle(String id, RiddleDifficulty difficulty) {
  return Riddle(
    id: id,
    text: 'I am riddle $id',
    canonText: 'i am riddle $id',
    answer: 'answer$id',
    canonAnswer: 'answer$id',
    category: RiddleCategory.objects,
    difficulty: difficulty,
    status: RiddleStatus.live,
    createdAt: DateTime.now(),
    stats: RiddleStats.empty(),
    hashes: const RiddleHashes(sha256: '', simhash64: 0),
  );
}
