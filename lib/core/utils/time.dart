import 'package:intl/intl.dart';

/// Time and date utilities
class TimeUtils {
  /// Get current date in YYYYMMDD format (local timezone)
  static String getTodayKey() {
    final now = DateTime.now();
    return DateFormat('yyyyMMdd').format(now);
  }

  /// Get midnight of today (local timezone)
  static DateTime getLocalMidnight() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Get midnight of tomorrow (local timezone)
  static DateTime getNextMidnight() {
    return getLocalMidnight().add(const Duration(days: 1));
  }

  /// Check if a timestamp is from today
  static bool isToday(DateTime timestamp) {
    final midnight = getLocalMidnight();
    final nextMidnight = getNextMidnight();
    return timestamp.isAfter(midnight) && timestamp.isBefore(nextMidnight);
  }

  /// Get time remaining until next midnight
  static Duration timeUntilMidnight() {
    final now = DateTime.now();
    final nextMidnight = getNextMidnight();
    return nextMidnight.difference(now);
  }

  /// Format duration as MM:SS
  static String formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Format duration as seconds with decimal
  static String formatSeconds(Duration duration) {
    final totalSeconds = duration.inMilliseconds / 1000;
    return totalSeconds.toStringAsFixed(1);
  }

  /// Format timestamp for display
  static String formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(timestamp);
    }
  }

  /// Convert milliseconds to Duration
  static Duration fromMillis(int millis) {
    return Duration(milliseconds: millis);
  }

  /// Get milliseconds from Duration
  static int toMillis(Duration duration) {
    return duration.inMilliseconds;
  }
}
