import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';
import '../models/user.dart';
import '../services/firebase_service.dart';
import '../../core/utils/time.dart';

/// Provider for UserRepository
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(FirebaseService());
});

/// Repository for user data
class UserRepository {
  final FirebaseService _firebase;
  final _logger = Logger();

  UserRepository(this._firebase);

  CollectionReference get _usersCollection => _firebase.firestore.collection('users');

  /// Get user by ID
  Future<User?> getUser(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      if (!doc.exists) return null;
      return User.fromFirestore(doc);
    } catch (e, stack) {
      _logger.e('Failed to get user $uid', error: e, stackTrace: stack);
      return null;
    }
  }

  /// Create a new user
  Future<User?> createUser({
    required String uid,
    required String handle,
    String? inviterUid,
  }) async {
    try {
      final user = User.create(uid: uid, handle: handle);
      final userData = user.toJson();

      // Add inviter if provided
      if (inviterUid != null) {
        userData['referral'] = {
          'inviterUid': inviterUid,
          'referredCount': 0,
        };
      }

      await _usersCollection.doc(uid).set(userData);
      _logger.i('User created: $uid');
      return user;
    } catch (e, stack) {
      _logger.e('Failed to create user', error: e, stackTrace: stack);
      return null;
    }
  }

  /// Update user data
  Future<bool> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _usersCollection.doc(uid).update(data);
      return true;
    } catch (e, stack) {
      _logger.e('Failed to update user $uid', error: e, stackTrace: stack);
      return false;
    }
  }

  /// Stream user data
  Stream<User?> streamUser(String uid) {
    return _usersCollection.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return User.fromFirestore(doc);
    });
  }

  /// Add coins to user
  Future<bool> addCoins(String uid, int amount) async {
    try {
      await _usersCollection.doc(uid).update({
        'coins': FieldValue.increment(amount),
      });
      _logger.i('Added $amount coins to user $uid');
      return true;
    } catch (e, stack) {
      _logger.e('Failed to add coins', error: e, stackTrace: stack);
      return false;
    }
  }

  /// Deduct coins from user
  Future<bool> deductCoins(String uid, int amount) async {
    try {
      final user = await getUser(uid);
      if (user == null || !user.canAfford(amount)) {
        _logger.w('User $uid cannot afford $amount coins');
        return false;
      }

      await _usersCollection.doc(uid).update({
        'coins': FieldValue.increment(-amount),
      });
      _logger.i('Deducted $amount coins from user $uid');
      return true;
    } catch (e, stack) {
      _logger.e('Failed to deduct coins', error: e, stackTrace: stack);
      return false;
    }
  }

  /// Increment daily skips used
  Future<bool> incrementDailySkipsUsed(String uid) async {
    try {
      await _usersCollection.doc(uid).update({
        'dailySkipsUsed': FieldValue.increment(1),
      });
      return true;
    } catch (e, stack) {
      _logger.e('Failed to increment daily skips', error: e, stackTrace: stack);
      return false;
    }
  }

  /// Increment ad skips used today
  Future<bool> incrementAdSkipsUsed(String uid) async {
    try {
      await _usersCollection.doc(uid).update({
        'adSkipsUsedToday': FieldValue.increment(1),
      });
      return true;
    } catch (e, stack) {
      _logger.e('Failed to increment ad skips', error: e, stackTrace: stack);
      return false;
    }
  }

  /// Reset daily counters (called at midnight or on first play of new day)
  Future<bool> resetDailyCounters(String uid) async {
    try {
      final todayKey = TimeUtils.getTodayKey();
      await _usersCollection.doc(uid).update({
        'dailySkipsUsed': 0,
        'adSkipsUsedToday': 0,
        'todayScore': 0,
        'todaySolvedCount': 0,
        'lastDailyKey': todayKey,
      });
      _logger.i('Reset daily counters for user $uid');
      return true;
    } catch (e, stack) {
      _logger.e('Failed to reset daily counters', error: e, stackTrace: stack);
      return false;
    }
  }

  /// Update streak
  Future<bool> updateStreak(String uid, int streak) async {
    try {
      await _usersCollection.doc(uid).update({
        'streak': streak,
      });
      return true;
    } catch (e, stack) {
      _logger.e('Failed to update streak', error: e, stackTrace: stack);
      return false;
    }
  }

  /// Increment referred count for inviter
  Future<bool> incrementReferredCount(String uid) async {
    try {
      await _usersCollection.doc(uid).update({
        'referral.referredCount': FieldValue.increment(1),
      });
      return true;
    } catch (e, stack) {
      _logger.e('Failed to increment referred count', error: e, stackTrace: stack);
      return false;
    }
  }

  /// Update handle
  Future<bool> updateHandle(String uid, String handle) async {
    return updateUser(uid, {'handle': handle});
  }
}
