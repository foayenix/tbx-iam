import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';
import '../models/riddle.dart';
import '../services/firebase_service.dart';

/// Provider for RiddleRepository
final riddleRepositoryProvider = Provider<RiddleRepository>((ref) {
  return RiddleRepository(FirebaseService());
});

/// Repository for riddle data
class RiddleRepository {
  final FirebaseService _firebase;
  final _logger = Logger();

  RiddleRepository(this._firebase);

  CollectionReference get _riddlesCollection => _firebase.firestore.collection('riddles');

  /// Get riddle by ID
  Future<Riddle?> getRiddle(String id) async {
    try {
      final doc = await _riddlesCollection.doc(id).get();
      if (!doc.exists) return null;
      return Riddle.fromFirestore(doc);
    } catch (e, stack) {
      _logger.e('Failed to get riddle $id', error: e, stackTrace: stack);
      return null;
    }
  }

  /// Get multiple riddles by IDs
  Future<List<Riddle>> getRiddles(List<String> ids) async {
    try {
      if (ids.isEmpty) return [];

      final docs = await Future.wait(
        ids.map((id) => _riddlesCollection.doc(id).get()),
      );

      return docs
          .where((doc) => doc.exists)
          .map((doc) => Riddle.fromFirestore(doc))
          .toList();
    } catch (e, stack) {
      _logger.e('Failed to get riddles', error: e, stackTrace: stack);
      return [];
    }
  }

  /// Get riddles by difficulty
  Future<List<Riddle>> getRiddlesByDifficulty(
    RiddleDifficulty difficulty, {
    int limit = 20,
  }) async {
    try {
      final query = await _riddlesCollection
          .where('status', isEqualTo: 'live')
          .where('difficulty', isEqualTo: difficulty.name)
          .limit(limit)
          .get();

      return query.docs.map((doc) => Riddle.fromFirestore(doc)).toList();
    } catch (e, stack) {
      _logger.e('Failed to get riddles by difficulty', error: e, stackTrace: stack);
      return [];
    }
  }

  /// Get riddles by status (for moderation)
  Future<List<Riddle>> getRiddlesByStatus(
    RiddleStatus status, {
    int limit = 50,
  }) async {
    try {
      final query = await _riddlesCollection
          .where('status', isEqualTo: status.name)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return query.docs.map((doc) => Riddle.fromFirestore(doc)).toList();
    } catch (e, stack) {
      _logger.e('Failed to get riddles by status', error: e, stackTrace: stack);
      return [];
    }
  }

  /// Stream riddles by status (for admin moderation)
  Stream<List<Riddle>> streamRiddlesByStatus(RiddleStatus status) {
    return _riddlesCollection
        .where('status', isEqualTo: status.name)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Riddle.fromFirestore(doc)).toList();
    });
  }

  /// Create riddle (UGC submission)
  Future<String?> createRiddle(Riddle riddle) async {
    try {
      final docRef = await _riddlesCollection.add(riddle.toJson());
      _logger.i('Riddle created: ${docRef.id}');
      return docRef.id;
    } catch (e, stack) {
      _logger.e('Failed to create riddle', error: e, stackTrace: stack);
      return null;
    }
  }

  /// Update riddle status (for moderation)
  Future<bool> updateRiddleStatus(String id, RiddleStatus status) async {
    try {
      await _riddlesCollection.doc(id).update({
        'status': status.name,
      });
      _logger.i('Riddle $id status updated to ${status.name}');
      return true;
    } catch (e, stack) {
      _logger.e('Failed to update riddle status', error: e, stackTrace: stack);
      return false;
    }
  }

  /// Update riddle stats
  Future<bool> updateRiddleStats(
    String id, {
    bool? played,
    bool? correctFirstTry,
    bool? skipped,
    bool? reported,
    int? solveMs,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (played == true) {
        updates['stats.plays'] = FieldValue.increment(1);
      }
      if (correctFirstTry == true) {
        updates['stats.correctFirstTry'] = FieldValue.increment(1);
      }
      if (skipped == true) {
        updates['stats.skips'] = FieldValue.increment(1);
      }
      if (reported == true) {
        updates['stats.reports'] = FieldValue.increment(1);
      }

      if (updates.isEmpty) return true;

      await _riddlesCollection.doc(id).update(updates);
      return true;
    } catch (e, stack) {
      _logger.e('Failed to update riddle stats', error: e, stackTrace: stack);
      return false;
    }
  }

  /// Check if riddle with same hash exists
  Future<bool> riddleExistsByHash(String sha256Hash) async {
    try {
      final query = await _riddlesCollection
          .where('hashes.sha256', isEqualTo: sha256Hash)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e, stack) {
      _logger.e('Failed to check riddle by hash', error: e, stackTrace: stack);
      return false;
    }
  }

  /// Find similar riddles by simhash
  Future<List<Riddle>> findSimilarRiddles(int simhash64, {int limit = 10}) async {
    try {
      // In a real implementation, you'd query a range around the simhash
      // For now, get recent riddles and check similarity client-side
      final query = await _riddlesCollection
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();

      return query.docs
          .map((doc) => Riddle.fromFirestore(doc))
          .where((riddle) {
            // Check Hamming distance
            final distance = _hammingDistance(riddle.hashes.simhash64, simhash64);
            return distance <= 3; // Threshold for similarity
          })
          .take(limit)
          .toList();
    } catch (e, stack) {
      _logger.e('Failed to find similar riddles', error: e, stackTrace: stack);
      return [];
    }
  }

  /// Calculate Hamming distance
  int _hammingDistance(int hash1, int hash2) {
    int xor = hash1 ^ hash2;
    int distance = 0;
    while (xor != 0) {
      distance += xor & 1;
      xor >>= 1;
    }
    return distance;
  }

  /// Get random live riddles
  Future<List<Riddle>> getRandomRiddles({int limit = 10}) async {
    try {
      // Simple approach: get more than needed and shuffle client-side
      final query = await _riddlesCollection
          .where('status', isEqualTo: 'live')
          .limit(limit * 3)
          .get();

      final riddles = query.docs.map((doc) => Riddle.fromFirestore(doc)).toList();
      riddles.shuffle();
      return riddles.take(limit).toList();
    } catch (e, stack) {
      _logger.e('Failed to get random riddles', error: e, stackTrace: stack);
      return [];
    }
  }
}
