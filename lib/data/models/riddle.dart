import 'package:cloud_firestore/cloud_firestore.dart';

/// Riddle difficulty levels
enum RiddleDifficulty {
  easy,
  medium,
  hard;

  static RiddleDifficulty fromString(String value) {
    return RiddleDifficulty.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => RiddleDifficulty.easy,
    );
  }
}

/// Riddle status for UGC moderation
enum RiddleStatus {
  pending,
  live,
  rejected;

  static RiddleStatus fromString(String value) {
    return RiddleStatus.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => RiddleStatus.pending,
    );
  }
}

/// Riddle category
enum RiddleCategory {
  objects,
  animals,
  food,
  nature,
  people,
  places,
  abstract;

  static RiddleCategory fromString(String value) {
    return RiddleCategory.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => RiddleCategory.objects,
    );
  }
}

/// Riddle statistics
class RiddleStats {
  final int plays;
  final int correctFirstTry;
  final int skips;
  final int reports;
  final int avgSolveMs;

  const RiddleStats({
    required this.plays,
    required this.correctFirstTry,
    required this.skips,
    required this.reports,
    required this.avgSolveMs,
  });

  factory RiddleStats.empty() {
    return const RiddleStats(
      plays: 0,
      correctFirstTry: 0,
      skips: 0,
      reports: 0,
      avgSolveMs: 0,
    );
  }

  factory RiddleStats.fromJson(Map<String, dynamic> json) {
    return RiddleStats(
      plays: json['plays'] as int? ?? 0,
      correctFirstTry: json['correctFirstTry'] as int? ?? 0,
      skips: json['skips'] as int? ?? 0,
      reports: json['reports'] as int? ?? 0,
      avgSolveMs: json['avgSolveMs'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'plays': plays,
      'correctFirstTry': correctFirstTry,
      'skips': skips,
      'reports': reports,
      'avgSolveMs': avgSolveMs,
    };
  }
}

/// Riddle hashes for duplicate detection
class RiddleHashes {
  final String sha256;
  final int simhash64;

  const RiddleHashes({
    required this.sha256,
    required this.simhash64,
  });

  factory RiddleHashes.fromJson(Map<String, dynamic> json) {
    return RiddleHashes(
      sha256: json['sha256'] as String? ?? '',
      simhash64: json['simhash64'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sha256': sha256,
      'simhash64': simhash64,
    };
  }
}

/// Riddle model
class Riddle {
  final String id;
  final String text; // Original text (must start with "I am...")
  final String canonText; // Canonicalised text
  final String answer; // Correct answer
  final String canonAnswer; // Canonicalised answer
  final List<String> aliases; // Alternative accepted answers
  final RiddleCategory category;
  final String? hint; // Optional hint
  final RiddleDifficulty difficulty;
  final RiddleStatus status;
  final String? createdBy; // User ID who submitted (for UGC)
  final DateTime createdAt;
  final RiddleStats stats;
  final RiddleHashes hashes;

  const Riddle({
    required this.id,
    required this.text,
    required this.canonText,
    required this.answer,
    required this.canonAnswer,
    this.aliases = const [],
    required this.category,
    this.hint,
    required this.difficulty,
    required this.status,
    this.createdBy,
    required this.createdAt,
    required this.stats,
    required this.hashes,
  });

  factory Riddle.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Riddle.fromJson(data, doc.id);
  }

  factory Riddle.fromJson(Map<String, dynamic> json, String id) {
    return Riddle(
      id: id,
      text: json['text'] as String? ?? '',
      canonText: json['canonText'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
      canonAnswer: json['canonAnswer'] as String? ?? '',
      aliases: (json['aliases'] as List<dynamic>?)?.cast<String>() ?? [],
      category: RiddleCategory.fromString(json['category'] as String? ?? 'objects'),
      hint: json['hint'] as String?,
      difficulty: RiddleDifficulty.fromString(json['difficulty'] as String? ?? 'easy'),
      status: RiddleStatus.fromString(json['status'] as String? ?? 'live'),
      createdBy: json['createdBy'] as String?,
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      stats: json['stats'] != null
          ? RiddleStats.fromJson(json['stats'] as Map<String, dynamic>)
          : RiddleStats.empty(),
      hashes: json['hashes'] != null
          ? RiddleHashes.fromJson(json['hashes'] as Map<String, dynamic>)
          : const RiddleHashes(sha256: '', simhash64: 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'canonText': canonText,
      'answer': answer,
      'canonAnswer': canonAnswer,
      'aliases': aliases,
      'category': category.name,
      'hint': hint,
      'difficulty': difficulty.name,
      'status': status.name,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'stats': stats.toJson(),
      'hashes': hashes.toJson(),
    };
  }

  Riddle copyWith({
    String? id,
    String? text,
    String? canonText,
    String? answer,
    String? canonAnswer,
    List<String>? aliases,
    RiddleCategory? category,
    String? hint,
    RiddleDifficulty? difficulty,
    RiddleStatus? status,
    String? createdBy,
    DateTime? createdAt,
    RiddleStats? stats,
    RiddleHashes? hashes,
  }) {
    return Riddle(
      id: id ?? this.id,
      text: text ?? this.text,
      canonText: canonText ?? this.canonText,
      answer: answer ?? this.answer,
      canonAnswer: canonAnswer ?? this.canonAnswer,
      aliases: aliases ?? this.aliases,
      category: category ?? this.category,
      hint: hint ?? this.hint,
      difficulty: difficulty ?? this.difficulty,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      stats: stats ?? this.stats,
      hashes: hashes ?? this.hashes,
    );
  }
}
