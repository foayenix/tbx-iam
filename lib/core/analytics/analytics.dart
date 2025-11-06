import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';
import '../env.dart';

/// Provider for AnalyticsService
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

/// Analytics service for tracking events
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final _logger = Logger();
  late final FirebaseAnalytics _analytics;
  bool _initialized = false;

  /// Initialize analytics
  Future<void> initialize() async {
    if (_initialized) return;

    if (!Env.enableAnalytics) {
      _logger.i('Analytics disabled');
      return;
    }

    try {
      _analytics = FirebaseAnalytics.instance;
      await _analytics.setAnalyticsCollectionEnabled(true);
      _initialized = true;
      _logger.i('Analytics initialized');
    } catch (e, stack) {
      _logger.e('Failed to initialize analytics', error: e, stackTrace: stack);
    }
  }

  /// Log session start
  Future<void> logSessionStart() async {
    await _logEvent('session_start');
  }

  /// Log riddle shown
  Future<void> logRiddleShown({
    required String riddleId,
    required String difficulty,
  }) async {
    await _logEvent('riddle_shown', parameters: {
      'riddle_id': riddleId,
      'difficulty': difficulty,
    });
  }

  /// Log answer submitted
  Future<void> logAnswerSubmitted({
    required String riddleId,
    required bool correct,
    required int timeMs,
    required int attempt,
  }) async {
    await _logEvent('answer_submitted', parameters: {
      'riddle_id': riddleId,
      'correct': correct,
      'time_ms': timeMs,
      'attempt': attempt,
    });
  }

  /// Log ad offered
  Future<void> logAdOffered({required String placement}) async {
    await _logEvent('ad_offered', parameters: {
      'placement': placement,
    });
  }

  /// Log ad watched
  Future<void> logAdWatched({required String placement}) async {
    await _logEvent('ad_watched', parameters: {
      'placement': placement,
    });
  }

  /// Log ad capped (daily limit reached)
  Future<void> logAdCapped() async {
    await _logEvent('ad_capped');
  }

  /// Log share card created
  Future<void> logShareCardCreated({
    required int score,
    required int streak,
  }) async {
    await _logEvent('share_card_created', parameters: {
      'score': score,
      'streak': streak,
    });
  }

  /// Log referral link opened
  Future<void> logReferralLinkOpened({String? inviterUid}) async {
    await _logEvent('referral_link_opened', parameters: {
      'inviter_uid': inviterUid ?? 'unknown',
    });
  }

  /// Log UGC submitted
  Future<void> logUgcSubmitted({required String category}) async {
    await _logEvent('ugc_submitted', parameters: {
      'category': category,
    });
  }

  /// Log UGC accepted
  Future<void> logUgcAccepted({required String riddleId}) async {
    await _logEvent('ugc_accepted', parameters: {
      'riddle_id': riddleId,
    });
  }

  /// Log UGC rejected
  Future<void> logUgcRejected({
    required String riddleId,
    required String reason,
  }) async {
    await _logEvent('ugc_rejected', parameters: {
      'riddle_id': riddleId,
      'reason': reason,
    });
  }

  /// Log leaderboard viewed
  Future<void> logLeaderboardViewed({required String type}) async {
    await _logEvent('leaderboard_viewed', parameters: {
      'type': type,
    });
  }

  /// Log daily challenge played
  Future<void> logDailyChallengePlayd({
    required bool completed,
    required int timeMs,
  }) async {
    await _logEvent('daily_challenge_played', parameters: {
      'completed': completed,
      'time_ms': timeMs,
    });
  }

  /// Log skip used
  Future<void> logSkipUsed({required String type}) async {
    await _logEvent('skip_used', parameters: {
      'type': type, // 'daily', 'ad', 'coin'
    });
  }

  /// Log coins earned
  Future<void> logCoinsEarned({
    required int amount,
    required String source,
  }) async {
    await _logEvent('coins_earned', parameters: {
      'amount': amount,
      'source': source,
    });
  }

  /// Log coins spent
  Future<void> logCoinsSpent({
    required int amount,
    required String purpose,
  }) async {
    await _logEvent('coins_spent', parameters: {
      'amount': amount,
      'purpose': purpose,
    });
  }

  /// Set user properties
  Future<void> setUserProperties({
    String? userId,
    int? totalPlays,
    int? bestScore,
    int? coins,
  }) async {
    if (!Env.enableAnalytics || !_initialized) return;

    try {
      if (userId != null) {
        await _analytics.setUserId(id: userId);
      }
      if (totalPlays != null) {
        await _analytics.setUserProperty(
          name: 'total_plays',
          value: totalPlays.toString(),
        );
      }
      if (bestScore != null) {
        await _analytics.setUserProperty(
          name: 'best_score',
          value: bestScore.toString(),
        );
      }
      if (coins != null) {
        await _analytics.setUserProperty(
          name: 'coins',
          value: coins.toString(),
        );
      }
    } catch (e, stack) {
      _logger.e('Failed to set user properties', error: e, stackTrace: stack);
    }
  }

  /// Log custom event
  Future<void> _logEvent(String name, {Map<String, Object>? parameters}) async {
    if (!Env.enableAnalytics || !_initialized) return;

    try {
      await _analytics.logEvent(
        name: name,
        parameters: parameters,
      );
      _logger.d('Analytics event: $name ${parameters ?? ""}');
    } catch (e, stack) {
      _logger.e('Failed to log event $name', error: e, stackTrace: stack);
    }
  }
}
