import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';

/// Provider for RemoteConfigService
final remoteConfigProvider = Provider<RemoteConfigService>((ref) {
  return RemoteConfigService();
});

/// Remote Config service for feature flags and tunables
class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._internal();

  final _logger = Logger();
  late final FirebaseRemoteConfig _remoteConfig;
  bool _initialized = false;

  /// Default values
  static const Map<String, dynamic> _defaults = {
    'timer_seconds': 12,
    'max_rewarded_ads_per_day': 5,
    'max_rewarded_skips_per_day': 3,
    'daily_skips': 3,
    'coin_per_correct': 1,
    'skip_cost_coins': 1,
    'streak_save_alt_cost_coins': 3,
    'difficulty_mix_easy': 0.6,
    'difficulty_mix_medium': 0.3,
    'difficulty_mix_hard': 0.1,
    'streak_bonus_threshold': 5, // Bonus coins every N correct answers
    'streak_bonus_coins': 1,
    'daily_login_coins': 3,
    'ugc_reward_coins': 25,
    'referral_coins_inviter': 2,
    'referral_coins_invitee': 2,
    'ad_cooldown_seconds': 120,
  };

  /// Initialize Remote Config
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _remoteConfig = FirebaseRemoteConfig.instance;

      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );

      await _remoteConfig.setDefaults(_defaults);
      await _remoteConfig.fetchAndActivate();

      _initialized = true;
      _logger.i('Remote Config initialized');
    } catch (e, stack) {
      _logger.e('Failed to initialize Remote Config', error: e, stackTrace: stack);
      // Continue with defaults
    }
  }

  /// Get timer duration in seconds
  int get timerSeconds => _remoteConfig.getInt('timer_seconds');

  /// Get max rewarded ads per day
  int get maxRewardedAdsPerDay => _remoteConfig.getInt('max_rewarded_ads_per_day');

  /// Get max rewarded skips per day
  int get maxRewardedSkipsPerDay => _remoteConfig.getInt('max_rewarded_skips_per_day');

  /// Get daily skips
  int get dailySkips => _remoteConfig.getInt('daily_skips');

  /// Get coins per correct answer
  int get coinPerCorrect => _remoteConfig.getInt('coin_per_correct');

  /// Get skip cost in coins
  int get skipCostCoins => _remoteConfig.getInt('skip_cost_coins');

  /// Get streak save alternative cost in coins
  int get streakSaveAltCostCoins => _remoteConfig.getInt('streak_save_alt_cost_coins');

  /// Get difficulty mix
  Map<String, double> get difficultyMix => {
        'easy': _remoteConfig.getDouble('difficulty_mix_easy'),
        'medium': _remoteConfig.getDouble('difficulty_mix_medium'),
        'hard': _remoteConfig.getDouble('difficulty_mix_hard'),
      };

  /// Get streak bonus threshold
  int get streakBonusThreshold => _remoteConfig.getInt('streak_bonus_threshold');

  /// Get streak bonus coins
  int get streakBonusCoins => _remoteConfig.getInt('streak_bonus_coins');

  /// Get daily login coins
  int get dailyLoginCoins => _remoteConfig.getInt('daily_login_coins');

  /// Get UGC reward coins (when riddle is accepted)
  int get ugcRewardCoins => _remoteConfig.getInt('ugc_reward_coins');

  /// Get referral coins for inviter
  int get referralCoinsInviter => _remoteConfig.getInt('referral_coins_inviter');

  /// Get referral coins for invitee
  int get referralCoinsInvitee => _remoteConfig.getInt('referral_coins_invitee');

  /// Get ad cooldown in seconds
  int get adCooldownSeconds => _remoteConfig.getInt('ad_cooldown_seconds');

  /// Refresh config (fetch latest values)
  Future<bool> refresh() async {
    try {
      await _remoteConfig.fetchAndActivate();
      _logger.i('Remote Config refreshed');
      return true;
    } catch (e, stack) {
      _logger.e('Failed to refresh Remote Config', error: e, stackTrace: stack);
      return false;
    }
  }

  /// Get all config values (for debugging)
  Map<String, dynamic> getAllValues() {
    return {
      'timer_seconds': timerSeconds,
      'max_rewarded_ads_per_day': maxRewardedAdsPerDay,
      'max_rewarded_skips_per_day': maxRewardedSkipsPerDay,
      'daily_skips': dailySkips,
      'coin_per_correct': coinPerCorrect,
      'skip_cost_coins': skipCostCoins,
      'streak_save_alt_cost_coins': streakSaveAltCostCoins,
      'difficulty_mix': difficultyMix,
      'streak_bonus_threshold': streakBonusThreshold,
      'streak_bonus_coins': streakBonusCoins,
      'daily_login_coins': dailyLoginCoins,
      'ugc_reward_coins': ugcRewardCoins,
      'referral_coins_inviter': referralCoinsInviter,
      'referral_coins_invitee': referralCoinsInvitee,
      'ad_cooldown_seconds': adCooldownSeconds,
    };
  }
}
