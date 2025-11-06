import 'package:flutter_test/flutter_test.dart';
import 'package:i_am/core/utils/canon.dart';
import 'package:i_am/core/utils/text_match.dart';

void main() {
  group('Canon', () {
    test('canonicalise removes punctuation and normalizes whitespace', () {
      expect(Canon.canonicalise('Hello, World!'), 'hello world');
      expect(Canon.canonicalise('  Multiple   Spaces  '), 'multiple spaces');
      expect(Canon.canonicalise('I am...'), 'i am');
    });

    test('canonicalise handles British spelling', () {
      expect(Canon.canonicalise('color'), 'colour');
      expect(Canon.canonicalise('flavor'), 'flavour');
    });

    test('sha256Hash generates consistent hash', () {
      final hash1 = Canon.sha256Hash('test');
      final hash2 = Canon.sha256Hash('test');
      final hash3 = Canon.sha256Hash('TEST');
      final hash4 = Canon.sha256Hash('different');

      expect(hash1, hash2);
      expect(hash1, hash3); // Case-insensitive
      expect(hash1, isNot(hash4));
    });

    test('simHash64 generates similarity hash', () {
      final hash1 = Canon.simHash64('I am a circle');
      final hash2 = Canon.simHash64('I am a circle');
      final hash3 = Canon.simHash64('I am a square');

      expect(hash1, hash2);
      expect(hash1, isNot(hash3));
    });

    test('areSimilar detects similar hashes', () {
      final hash1 = Canon.simHash64('I am round');
      final hash2 = Canon.simHash64('I am round');
      final hash3 = Canon.simHash64('I am square');

      expect(Canon.areSimilar(hash1, hash2), isTrue);
      // Different texts should not be similar
      // (exact behavior depends on simhash implementation)
    });
  });

  group('TextMatch', () {
    test('matches exact answer', () {
      expect(TextMatch.matches('circle', 'circle'), isTrue);
      expect(TextMatch.matches('Circle', 'circle'), isTrue);
      expect(TextMatch.matches('CIRCLE', 'circle'), isTrue);
    });

    test('matches with whitespace differences', () {
      expect(TextMatch.matches('  circle  ', 'circle'), isTrue);
      expect(TextMatch.matches('circle', '  circle  '), isTrue);
    });

    test('matches with punctuation', () {
      expect(TextMatch.matches('circle!', 'circle'), isTrue);
      expect(TextMatch.matches('circle', 'circle.'), isTrue);
    });

    test('matches aliases', () {
      expect(
        TextMatch.matches('a circle', 'circle', aliases: ['a circle', 'the circle']),
        isTrue,
      );
      expect(
        TextMatch.matches('the circle', 'circle', aliases: ['a circle', 'the circle']),
        isTrue,
      );
    });

    test('allows Levenshtein distance of 1 for short answers', () {
      // Short answer (≤ 12 chars) with 1 character difference
      expect(TextMatch.matches('circl', 'circle'), isTrue); // Missing 'e'
      expect(TextMatch.matches('corcle', 'circle'), isTrue); // Wrong char
    });

    test('does not match with distance > 1', () {
      expect(TextMatch.matches('circ', 'circle'), isFalse); // 2 chars difference
      expect(TextMatch.matches('square', 'circle'), isFalse);
    });

    test('rejects empty answers', () {
      expect(TextMatch.matches('', 'circle'), isFalse);
      expect(TextMatch.matches('   ', 'circle'), isFalse);
    });

    test('levenshteinDistance calculates correctly', () {
      expect(TextMatch.levenshteinDistance('', ''), 0);
      expect(TextMatch.levenshteinDistance('a', ''), 1);
      expect(TextMatch.levenshteinDistance('', 'a'), 1);
      expect(TextMatch.levenshteinDistance('abc', 'abc'), 0);
      expect(TextMatch.levenshteinDistance('abc', 'abd'), 1);
      expect(TextMatch.levenshteinDistance('abc', 'ab'), 1);
      expect(TextMatch.levenshteinDistance('abc', 'abcd'), 1);
    });

    test('containsBannedWords detects profanity', () {
      expect(TextMatch.containsBannedWords('This is clean'), isFalse);
      expect(TextMatch.containsBannedWords('This has a bad word fuck'), isTrue);
      expect(TextMatch.containsBannedWords('FUCK'), isTrue);
    });

    test('isValidRiddleFormat checks I am prefix', () {
      expect(TextMatch.isValidRiddleFormat('I am a circle'), isTrue);
      expect(TextMatch.isValidRiddleFormat('I AM A CIRCLE'), isTrue);
      expect(TextMatch.isValidRiddleFormat('This is wrong'), isFalse);
    });

    test('isValidLength checks text length', () {
      expect(TextMatch.isValidLength('Short', minLength: 3, maxLength: 10), isTrue);
      expect(TextMatch.isValidLength('Hi', minLength: 3, maxLength: 10), isFalse);
      expect(TextMatch.isValidLength('This is way too long', minLength: 3, maxLength: 10), isFalse);
    });
  });
}
