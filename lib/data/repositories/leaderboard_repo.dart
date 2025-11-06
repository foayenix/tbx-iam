import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';
import '../models/leaderboard.dart';
import '../services/firebase_service.dart';
import '../../core/utils/time.dart';

/// Provider for LeaderboardRepository
final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  return LeaderboardRepository(FirebaseService());
});

/// Repository for leaderboard data
class LeaderboardRepository {
  final FirebaseService _firebase;
  final _logger = Logger();

  LeaderboardRepository(this._firebase);

  /// Get daily leaderboard collection
  CollectionReference _getDailyLeaderboard(String dateKey) {
    return _firebase.firestore
        .collection('leaderboards')
        .doc('daily_$dateKey')
        .collection('scores');
  }

  /// Get global leaderboard collection
  CollectionReference get _globalLeaderboard {
    return _firebase.firestore
        .collection('leaderboards')
        .doc('global')
        .collection('scores');
  }

  /// Get daily leaderboard entries
  Future<List<LeaderboardEntry>> getDailyLeaderboard({
    int limit = 20,
    String? dateKey,
  }) async {
    try {
      final key = dateKey ?? TimeUtils.getTodayKey();
      final query = await _getDailyLeaderboard(key)
          .orderBy('score', descending: true)
          .limit(limit)
          .get();

      return _addRanks(
        query.docs.map((doc) => LeaderboardEntry.fromFirestore(doc)).toList(),
      );
    } catch (e, stack) {
      _logger.e('Failed to get daily leaderboard', error: e, stackTrace: stack);
      return [];
    }
  }

  /// Get global leaderboard entries
  Future<List<LeaderboardEntry>> getGlobalLeaderboard({int limit = 20}) async {
    try {
      final query = await _globalLeaderboard
          .orderBy('score', descending: true)
          .limit(limit)
          .get();

      return _addRanks(
        query.docs.map((doc) => LeaderboardEntry.fromFirestore(doc)).toList(),
      );
    } catch (e, stack) {
      _logger.e('Failed to get global leaderboard', error: e, stackTrace: stack);
      return [];
    }
  }

  /// Stream daily leaderboard
  Stream<List<LeaderboardEntry>> streamDailyLeaderboard({
    int limit = 20,
    String? dateKey,
  }) {
    final key = dateKey ?? TimeUtils.getTodayKey();
    return _getDailyLeaderboard(key)
        .orderBy('score', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return _addRanks(
        snapshot.docs.map((doc) => LeaderboardEntry.fromFirestore(doc)).toList(),
      );
    });
  }

  /// Stream global leaderboard
  Stream<List<LeaderboardEntry>> streamGlobalLeaderboard({int limit = 20}) {
    return _globalLeaderboard
        .orderBy('score', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return _addRanks(
        snapshot.docs.map((doc) => LeaderboardEntry.fromFirestore(doc)).toList(),
      );
    });
  }

  /// Get user's daily rank
  Future<int?> getUserDailyRank(String uid, {String? dateKey}) async {
    try {
      final key = dateKey ?? TimeUtils.getTodayKey();
      final userDoc = await _getDailyLeaderboard(key).doc(uid).get();

      if (!userDoc.exists) return null;

      final userEntry = LeaderboardEntry.fromFirestore(userDoc);

      // Count how many users have a higher score
      final higherScores = await _getDailyLeaderboard(key)
          .where('score', isGreaterThan: userEntry.score)
          .count()
          .get();

      return (higherScores.count ?? 0) + 1;
    } catch (e, stack) {
      _logger.e('Failed to get user daily rank', error: e, stackTrace: stack);
      return null;
    }
  }

  /// Get user's global rank
  Future<int?> getUserGlobalRank(String uid) async {
    try {
      final userDoc = await _globalLeaderboard.doc(uid).get();

      if (!userDoc.exists) return null;

      final userEntry = LeaderboardEntry.fromFirestore(userDoc);

      // Count how many users have a higher score
      final higherScores = await _globalLeaderboard
          .where('score', isGreaterThan: userEntry.score)
          .count()
          .get();

      return (higherScores.count ?? 0) + 1;
    } catch (e, stack) {
      _logger.e('Failed to get user global rank', error: e, stackTrace: stack);
      return null;
    }
  }

  /// Update user's daily leaderboard entry
  Future<bool> updateDailyLeaderboard({
    required String uid,
    required String displayName,
    required int score,
    required int solved,
    String? dateKey,
  }) async {
    try {
      final key = dateKey ?? TimeUtils.getTodayKey();
      final entry = LeaderboardEntry(
        uid: uid,
        displayName: displayName,
        score: score,
        solved: solved,
        updatedAt: DateTime.now(),
      );

      await _getDailyLeaderboard(key).doc(uid).set(entry.toJson());
      _logger.i('Updated daily leaderboard for $uid');
      return true;
    } catch (e, stack) {
      _logger.e('Failed to update daily leaderboard', error: e, stackTrace: stack);
      return false;
    }
  }

  /// Update user's global leaderboard entry
  Future<bool> updateGlobalLeaderboard({
    required String uid,
    required String displayName,
    required int score,
    required int solved,
  }) async {
    try {
      final entry = LeaderboardEntry(
        uid: uid,
        displayName: displayName,
        score: score,
        solved: solved,
        updatedAt: DateTime.now(),
      );

      await _globalLeaderboard.doc(uid).set(entry.toJson());
      _logger.i('Updated global leaderboard for $uid');
      return true;
    } catch (e, stack) {
      _logger.e('Failed to update global leaderboard', error: e, stackTrace: stack);
      return false;
    }
  }

  /// Add ranks to leaderboard entries
  List<LeaderboardEntry> _addRanks(List<LeaderboardEntry> entries) {
    return entries.asMap().entries.map((entry) {
      return entry.value.copyWith(rank: entry.key + 1);
    }).toList();
  }

  /// Get user's position changes (for "You overtook X!" notifications)
  Future<Map<String, dynamic>?> getUserPositionChange({
    required String uid,
    required LeaderboardType type,
    String? dateKey,
  }) async {
    try {
      final collection = type == LeaderboardType.daily
          ? _getDailyLeaderboard(dateKey ?? TimeUtils.getTodayKey())
          : _globalLeaderboard;

      final userDoc = await collection.doc(uid).get();
      if (!userDoc.exists) return null;

      final userEntry = LeaderboardEntry.fromFirestore(userDoc);

      // Get the user just below (next lower score)
      final belowQuery = await collection
          .where('score', isLessThan: userEntry.score)
          .orderBy('score', descending: true)
          .limit(1)
          .get();

      if (belowQuery.docs.isEmpty) return null;

      final overtakenUser = LeaderboardEntry.fromFirestore(belowQuery.docs.first);
      final rank = await (type == LeaderboardType.daily
          ? getUserDailyRank(uid, dateKey: dateKey)
          : getUserGlobalRank(uid));

      return {
        'overtaken': overtakenUser,
        'rank': rank,
      };
    } catch (e, stack) {
      _logger.e('Failed to get position change', error: e, stackTrace: stack);
      return null;
    }
  }
}
