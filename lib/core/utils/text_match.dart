import 'canon.dart';

/// Text matching utilities with tolerance for typos
class TextMatch {
  /// Check if user answer matches the correct answer with tolerance
  ///
  /// Returns true if:
  /// - Exact match after canonicalisation
  /// - Answer in aliases list (if provided)
  /// - Levenshtein distance ≤ 1 for short answers (≤ 12 chars)
  static bool matches(
    String userAnswer,
    String correctAnswer, {
    List<String>? aliases,
  }) {
    if (userAnswer.isEmpty) return false;

    final canonUser = Canon.canonicalise(userAnswer);
    final canonCorrect = Canon.canonicalise(correctAnswer);

    // Exact match
    if (canonUser == canonCorrect) return true;

    // Check aliases
    if (aliases != null) {
      for (final alias in aliases) {
        if (canonUser == Canon.canonicalise(alias)) {
          return true;
        }
      }
    }

    // For short answers, allow Levenshtein distance ≤ 1
    if (canonCorrect.length <= 12) {
      final distance = levenshteinDistance(canonUser, canonCorrect);
      if (distance <= 1) return true;
    }

    return false;
  }

  /// Calculate Levenshtein distance between two strings
  static int levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    final len1 = s1.length;
    final len2 = s2.length;

    // Create a matrix
    List<List<int>> matrix = List.generate(
      len1 + 1,
      (i) => List.filled(len2 + 1, 0),
    );

    // Initialize first row and column
    for (int i = 0; i <= len1; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= len2; j++) {
      matrix[0][j] = j;
    }

    // Fill the matrix
    for (int i = 1; i <= len1; i++) {
      for (int j = 1; j <= len2; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1, // deletion
          matrix[i][j - 1] + 1, // insertion
          matrix[i - 1][j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[len1][len2];
  }

  /// Check if text contains banned words
  static bool containsBannedWords(String text) {
    final canonical = Canon.canonicalise(text);

    // Basic banned words list (expand as needed)
    final bannedWords = [
      'fuck',
      'shit',
      'damn',
      'hell',
      'bitch',
      'bastard',
      'cunt',
      'dick',
      'cock',
      'pussy',
      'nigger',
      'nigga',
      'faggot',
      'retard',
      'rape',
      'nazi',
      'hitler',
    ];

    for (final word in bannedWords) {
      if (canonical.contains(word)) {
        return true;
      }
    }

    return false;
  }

  /// Validate riddle text format (must start with "I am")
  static bool isValidRiddleFormat(String text) {
    final canonical = Canon.canonicalise(text);
    return canonical.startsWith('i am');
  }

  /// Validate text length constraints
  static bool isValidLength(String text, {int minLength = 10, int maxLength = 200}) {
    final trimmed = text.trim();
    return trimmed.length >= minLength && trimmed.length <= maxLength;
  }
}
