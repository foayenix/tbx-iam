import 'dart:math';
import 'package:logger/logger.dart';
import '../../data/models/riddle.dart';
import '../../core/config/remote_config.dart';

/// Rotation engine for selecting riddles with difficulty mix
class RotationEngine {
  final RemoteConfigService _config;
  final _logger = Logger();
  final _random = Random();

  // Track recently shown riddles to avoid repeats
  final Set<String> _recentRiddleIds = {};
  static const int _recentHistorySize = 20;

  RotationEngine(this._config);

  /// Select next riddle from available pool
  /// Ensures difficulty mix and no recent repeats
  Riddle? selectNext(List<Riddle> availableRiddles) {
    if (availableRiddles.isEmpty) {
      _logger.w('No available riddles');
      return null;
    }

    // Filter out recently shown
    final filtered = availableRiddles
        .where((riddle) => !_recentRiddleIds.contains(riddle.id))
        .toList();

    if (filtered.isEmpty) {
      _logger.w('All available riddles recently shown, clearing history');
      _recentRiddleIds.clear();
      return selectNext(availableRiddles);
    }

    // Get target difficulty based on mix
    final targetDifficulty = _selectDifficultyByMix();

    // Try to find riddle of target difficulty
    final targetRiddles = filtered
        .where((riddle) => riddle.difficulty == targetDifficulty)
        .toList();

    Riddle? selected;

    if (targetRiddles.isNotEmpty) {
      // Select random from target difficulty
      selected = targetRiddles[_random.nextInt(targetRiddles.length)];
    } else {
      // Fallback to any available riddle
      selected = filtered[_random.nextInt(filtered.length)];
      _logger.d('No riddles of target difficulty $targetDifficulty, using ${selected.difficulty}');
    }

    // Track selection
    _recentRiddleIds.add(selected.id);
    if (_recentRiddleIds.length > _recentHistorySize) {
      _recentRiddleIds.remove(_recentRiddleIds.first);
    }

    _logger.d('Selected riddle: ${selected.id} (${selected.difficulty})');
    return selected;
  }

  /// Select difficulty based on configured mix
  RiddleDifficulty _selectDifficultyByMix() {
    final mix = _config.difficultyMix;
    final easyProb = mix['easy'] ?? 0.6;
    final mediumProb = mix['medium'] ?? 0.3;

    final roll = _random.nextDouble();

    if (roll < easyProb) {
      return RiddleDifficulty.easy;
    } else if (roll < easyProb + mediumProb) {
      return RiddleDifficulty.medium;
    } else {
      return RiddleDifficulty.hard;
    }
  }

  /// Build rotation pool from riddles of each difficulty
  List<Riddle> buildRotationPool({
    required List<Riddle> easyRiddles,
    required List<Riddle> mediumRiddles,
    required List<Riddle> hardRiddles,
    int poolSize = 50,
  }) {
    final mix = _config.difficultyMix;
    final easyCount = (poolSize * (mix['easy'] ?? 0.6)).round();
    final mediumCount = (poolSize * (mix['medium'] ?? 0.3)).round();
    final hardCount = (poolSize * (mix['hard'] ?? 0.1)).round();

    final pool = <Riddle>[];

    // Add easy riddles
    final shuffledEasy = List<Riddle>.from(easyRiddles)..shuffle(_random);
    pool.addAll(shuffledEasy.take(easyCount));

    // Add medium riddles
    final shuffledMedium = List<Riddle>.from(mediumRiddles)..shuffle(_random);
    pool.addAll(shuffledMedium.take(mediumCount));

    // Add hard riddles
    final shuffledHard = List<Riddle>.from(hardRiddles)..shuffle(_random);
    pool.addAll(shuffledHard.take(hardCount));

    _logger.i('Built rotation pool: ${pool.length} riddles '
        '(Easy: ${pool.where((r) => r.difficulty == RiddleDifficulty.easy).length}, '
        'Medium: ${pool.where((r) => r.difficulty == RiddleDifficulty.medium).length}, '
        'Hard: ${pool.where((r) => r.difficulty == RiddleDifficulty.hard).length})');

    return pool;
  }

  /// Clear recent history (useful for testing or reset)
  void clearHistory() {
    _recentRiddleIds.clear();
    _logger.d('Rotation history cleared');
  }

  /// Get statistics about current rotation
  Map<String, dynamic> getStats() {
    return {
      'recent_count': _recentRiddleIds.length,
      'difficulty_mix': _config.difficultyMix,
    };
  }
}
