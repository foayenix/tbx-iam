import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:diacritic/diacritic.dart';

/// Canonicalisation utilities for text normalisation
class Canon {
  /// Canonicalise text: lowercase, strip punctuation, remove diacritics, normalise whitespace
  static String canonicalise(String text) {
    if (text.isEmpty) return '';

    // Remove diacritics (café → cafe)
    String result = removeDiacritics(text);

    // Lowercase
    result = result.toLowerCase();

    // British to American spelling normalization (keep British as base)
    result = _normaliseBritishSpelling(result);

    // Remove punctuation and keep only alphanumeric + spaces
    result = result.replaceAll(RegExp(r'[^\w\s]'), '');

    // Normalise whitespace (multiple spaces → single space, trim)
    result = result.replaceAll(RegExp(r'\s+'), ' ').trim();

    return result;
  }

  /// Normalise British spelling variants
  static String _normaliseBritishSpelling(String text) {
    // Accept both British and American spellings by normalizing to British
    // This map handles common variations
    final spellingMap = {
      'color': 'colour',
      'colors': 'colours',
      'flavor': 'flavour',
      'flavors': 'flavours',
      'honor': 'honour',
      'honors': 'honours',
      'labor': 'labour',
      'labors': 'labours',
      'neighbor': 'neighbour',
      'neighbors': 'neighbours',
      'harbor': 'harbour',
      'harbors': 'harbours',
    };

    String result = text;
    spellingMap.forEach((american, british) {
      result = result.replaceAll(american, british);
    });

    return result;
  }

  /// Generate SHA-256 hash of canonical text
  static String sha256Hash(String text) {
    final canonical = canonicalise(text);
    final bytes = utf8.encode(canonical);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generate SimHash (64-bit) for fuzzy duplicate detection
  /// Uses simple character trigram hashing
  static int simHash64(String text) {
    final canonical = canonicalise(text);
    if (canonical.isEmpty) return 0;

    // Generate character trigrams
    final trigrams = <String>{};
    for (int i = 0; i < canonical.length - 2; i++) {
      trigrams.add(canonical.substring(i, i + 3));
    }
    // Also add bigrams for short text
    for (int i = 0; i < canonical.length - 1; i++) {
      trigrams.add(canonical.substring(i, i + 2));
    }

    // Simple SimHash: XOR hash of all trigrams
    int hash = 0;
    for (final trigram in trigrams) {
      hash ^= trigram.hashCode;
    }

    // Ensure 64-bit
    return hash & 0xFFFFFFFFFFFFFFFF;
  }

  /// Calculate Hamming distance between two 64-bit hashes
  static int hammingDistance(int hash1, int hash2) {
    int xor = hash1 ^ hash2;
    int distance = 0;

    // Count set bits
    while (xor != 0) {
      distance += xor & 1;
      xor >>= 1;
    }

    return distance;
  }

  /// Check if two hashes are similar (Hamming distance ≤ threshold)
  static bool areSimilar(int hash1, int hash2, {int threshold = 3}) {
    return hammingDistance(hash1, hash2) <= threshold;
  }
}
