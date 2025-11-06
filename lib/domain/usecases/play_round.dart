import 'package:logger/logger.dart';
import '../../data/models/riddle.dart';
import '../../data/models/user.dart';
import '../../data/repositories/user_repo.dart';
import '../../data/repositories/riddle_repo.dart';
import '../../core/utils/text_match.dart';
import '../../core/config/remote_config.dart';
import '../../core/analytics/analytics.dart';

/// Result of answer submission
class AnswerResult {
  final bool correct;
  final int timeMs;
  final int coinsEarned;
  final int newStreak;
  final bool streakBonusEarned;

  const AnswerResult({
    required this.correct,
    required this.timeMs,
    required this.coinsEarned,
    required this.newStreak,
    required this.streakBonusEarned,
  });
}

/// Play round use case
class PlayRoundUseCase {
  final UserRepository _userRepo;
  final RiddleRepository _riddleRepo;
  final RemoteConfigService _config;
  final AnalyticsService _analytics;
  final _logger = Logger();

  PlayRoundUseCase({
    required UserRepository userRepo,
    required RiddleRepository riddleRepo,
    required RemoteConfigService config,
    required AnalyticsService analytics,
  })  : _userRepo = userRepo,
        _riddleRepo = riddleRepo,
        _config = config,
        _analytics = analytics;

  /// Submit answer for a riddle
  Future<AnswerResult?> submitAnswer({
    required String uid,
    required Riddle riddle,
    required String answer,
    required int timeMs,
    required int attemptNumber,
  }) async {
    try {
      // Check if answer is correct
      final isCorrect = TextMatch.matches(
        answer,
        riddle.answer,
        aliases: riddle.aliases,
      );

      final user = await _userRepo.getUser(uid);
      if (user == null) {
        _logger.e('User not found: $uid');
        return null;
      }

      int coinsEarned = 0;
      int newStreak = user.streak;
      bool streakBonusEarned = false;

      if (isCorrect) {
        // Update streak
        newStreak = user.streak + 1;
        await _userRepo.updateStreak(uid, newStreak);

        // Award base coins
        coinsEarned = _config.coinPerCorrect;

        // Check for streak bonus
        if (newStreak % _config.streakBonusThreshold == 0) {
          coinsEarned += _config.streakBonusCoins;
          streakBonusEarned = true;
          _logger.i('Streak bonus earned at streak $newStreak');
        }

        // Add coins
        if (coinsEarned > 0) {
          await _userRepo.addCoins(uid, coinsEarned);
          await _analytics.logCoinsEarned(
            amount: coinsEarned,
            source: 'correct_answer',
          );
        }

        // Update riddle stats
        await _riddleRepo.updateRiddleStats(
          riddle.id,
          played: true,
          correctFirstTry: attemptNumber == 1,
          solveMs: timeMs,
        );
      } else {
        // Wrong answer - reset streak
        if (user.streak > 0) {
          newStreak = 0;
          await _userRepo.updateStreak(uid, 0);
        }
      }

      // Log analytics
      await _analytics.logAnswerSubmitted(
        riddleId: riddle.id,
        correct: isCorrect,
        timeMs: timeMs,
        attempt: attemptNumber,
      );

      return AnswerResult(
        correct: isCorrect,
        timeMs: timeMs,
        coinsEarned: coinsEarned,
        newStreak: newStreak,
        streakBonusEarned: streakBonusEarned,
      );
    } catch (e, stack) {
      _logger.e('Failed to submit answer', error: e, stackTrace: stack);
      return null;
    }
  }

  /// Handle timeout (consumes skip or ends game)
  Future<bool> handleTimeout({
    required String uid,
    required Riddle riddle,
  }) async {
    try {
      final user = await _userRepo.getUser(uid);
      if (user == null) return false;

      // Reset streak on timeout
      if (user.streak > 0) {
        await _userRepo.updateStreak(uid, 0);
      }

      // Update riddle stats
      await _riddleRepo.updateRiddleStats(
        riddle.id,
        played: true,
        skipped: true,
      );

      // Deduct point (reflected in today's score)
      // This would be handled by the Cloud Function in production

      return true;
    } catch (e, stack) {
      _logger.e('Failed to handle timeout', error: e, stackTrace: stack);
      return false;
    }
  }

  /// Use a skip (daily, ad, or coin)
  Future<bool> useSkip({
    required String uid,
    required String skipType, // 'daily', 'ad', 'coin'
    required Riddle riddle,
  }) async {
    try {
      final user = await _userRepo.getUser(uid);
      if (user == null) return false;

      switch (skipType) {
        case 'daily':
          if (!user.hasSkipsRemaining) return false;
          await _userRepo.incrementDailySkipsUsed(uid);
          break;

        case 'ad':
          // Ad skip tracking handled by AdService
          await _userRepo.incrementAdSkipsUsed(uid);
          break;

        case 'coin':
          final cost = _config.skipCostCoins;
          if (!user.canAfford(cost)) return false;
          await _userRepo.deductCoins(uid, cost);
          await _analytics.logCoinsSpent(amount: cost, purpose: 'skip');
          break;

        default:
          return false;
      }

      // Update riddle stats
      await _riddleRepo.updateRiddleStats(
        riddle.id,
        skipped: true,
      );

      await _analytics.logSkipUsed(type: skipType);
      return true;
    } catch (e, stack) {
      _logger.e('Failed to use skip', error: e, stackTrace: stack);
      return false;
    }
  }

  /// Save streak (via ad or coins)
  Future<bool> saveStreak({
    required String uid,
    required bool useAd,
  }) async {
    try {
      if (!useAd) {
        // Pay with coins
        final cost = _config.streakSaveAltCostCoins;
        final user = await _userRepo.getUser(uid);
        if (user == null || !user.canAfford(cost)) return false;

        await _userRepo.deductCoins(uid, cost);
        await _analytics.logCoinsSpent(amount: cost, purpose: 'save_streak');
      }

      // Streak is preserved (don't reset to 0)
      return true;
    } catch (e, stack) {
      _logger.e('Failed to save streak', error: e, stackTrace: stack);
      return false;
    }
  }
}
