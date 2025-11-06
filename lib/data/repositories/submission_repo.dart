import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';
import '../models/riddle.dart';
import '../services/firebase_service.dart';
import '../../core/utils/canon.dart';
import '../../core/utils/text_match.dart';

/// Provider for SubmissionRepository
final submissionRepositoryProvider = Provider<SubmissionRepository>((ref) {
  return SubmissionRepository(FirebaseService());
});

/// Result of submission validation
class SubmissionValidationResult {
  final bool isValid;
  final String? errorMessage;

  const SubmissionValidationResult({
    required this.isValid,
    this.errorMessage,
  });

  factory SubmissionValidationResult.valid() {
    return const SubmissionValidationResult(isValid: true);
  }

  factory SubmissionValidationResult.invalid(String message) {
    return SubmissionValidationResult(isValid: false, errorMessage: message);
  }
}

/// Repository for UGC riddle submissions
class SubmissionRepository {
  final FirebaseService _firebase;
  final _logger = Logger();

  SubmissionRepository(this._firebase);

  CollectionReference get _riddlesCollection => _firebase.firestore.collection('riddles');

  /// Validate riddle submission (client-side checks)
  SubmissionValidationResult validateSubmission({
    required String text,
    required String answer,
    required RiddleCategory category,
    String? hint,
  }) {
    // Check format (must start with "I am")
    if (!TextMatch.isValidRiddleFormat(text)) {
      return SubmissionValidationResult.invalid('Riddle must start with "I am"');
    }

    // Check length
    if (!TextMatch.isValidLength(text, minLength: 10, maxLength: 200)) {
      return SubmissionValidationResult.invalid('Riddle must be between 10 and 200 characters');
    }

    if (!TextMatch.isValidLength(answer, minLength: 2, maxLength: 50)) {
      return SubmissionValidationResult.invalid('Answer must be between 2 and 50 characters');
    }

    // Check banned words
    if (TextMatch.containsBannedWords(text) || TextMatch.containsBannedWords(answer)) {
      return SubmissionValidationResult.invalid('Content contains inappropriate language');
    }

    // Check hint if provided
    if (hint != null && hint.isNotEmpty) {
      if (!TextMatch.isValidLength(hint, minLength: 5, maxLength: 100)) {
        return SubmissionValidationResult.invalid('Hint must be between 5 and 100 characters');
      }
      if (TextMatch.containsBannedWords(hint)) {
        return SubmissionValidationResult.invalid('Hint contains inappropriate language');
      }
    }

    return SubmissionValidationResult.valid();
  }

  /// Submit a riddle for moderation
  /// Returns the submission ID if successful
  Future<String?> submitRiddle({
    required String text,
    required String answer,
    required RiddleCategory category,
    String? hint,
    required String createdBy,
  }) async {
    try {
      // Validate
      final validation = validateSubmission(
        text: text,
        answer: answer,
        category: category,
        hint: hint,
      );

      if (!validation.isValid) {
        _logger.w('Submission validation failed: ${validation.errorMessage}');
        return null;
      }

      // Canonicalise
      final canonText = Canon.canonicalise(text);
      final canonAnswer = Canon.canonicalise(answer);

      // Generate hashes
      final sha256Hash = Canon.sha256Hash(text);
      final simhash64 = Canon.simHash64(text);

      // Check exact duplicate
      final duplicateExists = await _checkDuplicate(sha256Hash);
      if (duplicateExists) {
        _logger.w('Duplicate riddle detected: $sha256Hash');
        return null;
      }

      // Check similar riddles
      final similarRiddles = await _findSimilarRiddles(simhash64);
      if (similarRiddles.isNotEmpty) {
        _logger.w('Similar riddle found, rejecting submission');
        return null;
      }

      // Create riddle with pending status
      final riddle = Riddle(
        id: '', // Will be set by Firestore
        text: text,
        canonText: canonText,
        answer: answer,
        canonAnswer: canonAnswer,
        aliases: [], // Can be added during moderation
        category: category,
        hint: hint,
        difficulty: RiddleDifficulty.medium, // Default, can be changed during moderation
        status: RiddleStatus.pending,
        createdBy: createdBy,
        createdAt: DateTime.now(),
        stats: RiddleStats.empty(),
        hashes: RiddleHashes(
          sha256: sha256Hash,
          simhash64: simhash64,
        ),
      );

      // Submit to Firestore
      final docRef = await _riddlesCollection.add(riddle.toJson());
      _logger.i('Riddle submitted for moderation: ${docRef.id}');

      return docRef.id;
    } catch (e, stack) {
      _logger.e('Failed to submit riddle', error: e, stackTrace: stack);
      return null;
    }
  }

  /// Check if exact duplicate exists
  Future<bool> _checkDuplicate(String sha256Hash) async {
    try {
      final query = await _riddlesCollection
          .where('hashes.sha256', isEqualTo: sha256Hash)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e, stack) {
      _logger.e('Failed to check duplicate', error: e, stackTrace: stack);
      return false;
    }
  }

  /// Find similar riddles using simhash
  Future<List<Riddle>> _findSimilarRiddles(int simhash64) async {
    try {
      // Get recent riddles and check similarity
      final query = await _riddlesCollection
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();

      final riddles = query.docs.map((doc) => Riddle.fromFirestore(doc)).toList();

      return riddles.where((riddle) {
        return Canon.areSimilar(riddle.hashes.simhash64, simhash64, threshold: 3);
      }).toList();
    } catch (e, stack) {
      _logger.e('Failed to find similar riddles', error: e, stackTrace: stack);
      return [];
    }
  }

  /// Get user's submissions
  Future<List<Riddle>> getUserSubmissions(String uid) async {
    try {
      final query = await _riddlesCollection
          .where('createdBy', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();

      return query.docs.map((doc) => Riddle.fromFirestore(doc)).toList();
    } catch (e, stack) {
      _logger.e('Failed to get user submissions', error: e, stackTrace: stack);
      return [];
    }
  }

  /// Stream user's submissions
  Stream<List<Riddle>> streamUserSubmissions(String uid) {
    return _riddlesCollection
        .where('createdBy', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Riddle.fromFirestore(doc)).toList();
    });
  }
}
