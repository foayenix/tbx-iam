import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';
import '../env.dart';

/// Ad placement types
enum AdPlacement {
  saveStreak,
  getSkip,
  doubleCoins,
  dailyLoginBonus;

  String get displayName {
    switch (this) {
      case AdPlacement.saveStreak:
        return 'Save Streak';
      case AdPlacement.getSkip:
        return 'Get Skip';
      case AdPlacement.doubleCoins:
        return 'Double Coins';
      case AdPlacement.dailyLoginBonus:
        return 'Daily Login Bonus';
    }
  }
}

/// Ad reward result
class AdReward {
  final AdPlacement placement;
  final bool success;
  final String? errorMessage;

  const AdReward({
    required this.placement,
    required this.success,
    this.errorMessage,
  });
}

/// Provider for RewardedAdsService
final rewardedAdsServiceProvider = Provider<RewardedAdsService>((ref) {
  return RewardedAdsService();
});

/// Rewarded Ads service
class RewardedAdsService {
  static final RewardedAdsService _instance = RewardedAdsService._internal();
  factory RewardedAdsService() => _instance;
  RewardedAdsService._internal();

  final _logger = Logger();

  RewardedAd? _rewardedAd;
  bool _isAdLoading = false;
  bool _isAdReady = false;
  DateTime? _lastAdWatchedAt;

  // Tracking
  int _adsWatchedToday = 0;
  String? _lastAdDay;

  /// Initialize AdMob
  Future<void> initialize() async {
    if (!Env.enableAds) {
      _logger.i('Ads disabled in environment');
      return;
    }

    try {
      await MobileAds.instance.initialize();
      _logger.i('AdMob initialized');
      await loadAd();
    } catch (e, stack) {
      _logger.e('Failed to initialize AdMob', error: e, stackTrace: stack);
    }
  }

  /// Get ad unit ID based on platform
  String get _adUnitId {
    if (Platform.isAndroid) {
      return Env.androidRewardedAdUnitId;
    } else if (Platform.isIOS) {
      return Env.iosRewardedAdUnitId;
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  /// Load rewarded ad
  Future<void> loadAd() async {
    if (_isAdLoading || _isAdReady) {
      _logger.d('Ad already loading or ready');
      return;
    }

    _isAdLoading = true;

    try {
      await RewardedAd.load(
        adUnitId: _adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _logger.i('Rewarded ad loaded');
            _rewardedAd = ad;
            _isAdReady = true;
            _isAdLoading = false;

            _setupAdCallbacks();
          },
          onAdFailedToLoad: (error) {
            _logger.w('Failed to load rewarded ad: $error');
            _isAdLoading = false;
            _isAdReady = false;

            // Retry after delay
            Future.delayed(const Duration(seconds: 30), loadAd);
          },
        ),
      );
    } catch (e, stack) {
      _logger.e('Error loading rewarded ad', error: e, stackTrace: stack);
      _isAdLoading = false;
      _isAdReady = false;
    }
  }

  /// Setup ad callbacks
  void _setupAdCallbacks() {
    _rewardedAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        _logger.d('Ad dismissed');
        ad.dispose();
        _rewardedAd = null;
        _isAdReady = false;
        loadAd(); // Preload next ad
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _logger.e('Ad failed to show: $error');
        ad.dispose();
        _rewardedAd = null;
        _isAdReady = false;
        loadAd();
      },
    );
  }

  /// Check if ad is ready to show
  bool get isAdReady => _isAdReady && _rewardedAd != null;

  /// Check if cooldown is active
  bool get isCooldownActive {
    if (_lastAdWatchedAt == null) return false;
    final elapsed = DateTime.now().difference(_lastAdWatchedAt!);
    return elapsed.inSeconds < 120; // 2 minute cooldown from Remote Config
  }

  /// Get cooldown remaining in seconds
  int get cooldownRemaining {
    if (!isCooldownActive) return 0;
    final elapsed = DateTime.now().difference(_lastAdWatchedAt!);
    return 120 - elapsed.inSeconds;
  }

  /// Check if user can watch more ads today
  bool canWatchAd(int maxAdsPerDay) {
    // Reset counter if new day
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (_lastAdDay != today) {
      _adsWatchedToday = 0;
      _lastAdDay = today;
    }

    return _adsWatchedToday < maxAdsPerDay;
  }

  /// Show rewarded ad
  Future<AdReward> showAd({
    required AdPlacement placement,
    required int maxAdsPerDay,
  }) async {
    if (!Env.enableAds) {
      return AdReward(
        placement: placement,
        success: false,
        errorMessage: 'Ads are disabled',
      );
    }

    // Check daily limit
    if (!canWatchAd(maxAdsPerDay)) {
      _logger.w('Daily ad limit reached');
      return AdReward(
        placement: placement,
        success: false,
        errorMessage: 'Daily ad limit reached',
      );
    }

    // Check cooldown
    if (isCooldownActive) {
      _logger.w('Ad cooldown active');
      return AdReward(
        placement: placement,
        success: false,
        errorMessage: 'Please wait ${cooldownRemaining}s before watching another ad',
      );
    }

    // Check if ad is ready
    if (!isAdReady) {
      _logger.w('Ad not ready');
      return AdReward(
        placement: placement,
        success: false,
        errorMessage: 'Ad not ready, please try again later',
      );
    }

    try {
      bool rewardEarned = false;

      await _rewardedAd?.show(
        onUserEarnedReward: (ad, reward) {
          _logger.i('User earned reward: ${reward.amount} ${reward.type}');
          rewardEarned = true;

          // Update tracking
          _adsWatchedToday++;
          _lastAdWatchedAt = DateTime.now();
          final today = DateTime.now().toIso8601String().substring(0, 10);
          _lastAdDay = today;
        },
      );

      if (rewardEarned) {
        return AdReward(placement: placement, success: true);
      } else {
        return AdReward(
          placement: placement,
          success: false,
          errorMessage: 'Ad was not completed',
        );
      }
    } catch (e, stack) {
      _logger.e('Error showing rewarded ad', error: e, stackTrace: stack);
      return AdReward(
        placement: placement,
        success: false,
        errorMessage: 'Failed to show ad',
      );
    }
  }

  /// Get ads watched today
  int get adsWatchedToday {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (_lastAdDay != today) {
      return 0;
    }
    return _adsWatchedToday;
  }

  /// Dispose
  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }
}
