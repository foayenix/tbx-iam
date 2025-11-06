import 'package:cloud_firestore/cloud_firestore.dart';

/// Leaderboard entry
class LeaderboardEntry {
  final String uid;
  final String displayName;
  final int score;
  final int solved;
  final DateTime updatedAt;
  final int? rank; // Calculated client-side

  const LeaderboardEntry({
    required this.uid,
    required this.displayName,
    required this.score,
    required this.solved,
    required this.updatedAt,
    this.rank,
  });

  factory LeaderboardEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LeaderboardEntry.fromJson(data, doc.id);
  }

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json, String uid) {
    return LeaderboardEntry(
      uid: uid,
      displayName: json['displayName'] as String? ?? 'Player',
      score: json['score'] as int? ?? 0,
      solved: json['solved'] as int? ?? 0,
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      rank: json['rank'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'displayName': displayName,
      'score': score,
      'solved': solved,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  LeaderboardEntry copyWith({
    String? uid,
    String? displayName,
    int? score,
    int? solved,
    DateTime? updatedAt,
    int? rank,
  }) {
    return LeaderboardEntry(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      score: score ?? this.score,
      solved: solved ?? this.solved,
      updatedAt: updatedAt ?? this.updatedAt,
      rank: rank ?? this.rank,
    );
  }
}

/// Leaderboard type
enum LeaderboardType {
  daily,
  global;

  String get displayName {
    switch (this) {
      case LeaderboardType.daily:
        return 'Daily';
      case LeaderboardType.global:
        return 'All Time';
    }
  }
}
