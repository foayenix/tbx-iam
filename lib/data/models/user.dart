import 'package:cloud_firestore/cloud_firestore.dart';

/// User referral data
class UserReferral {
  final String? inviterUid;
  final int referredCount;

  const UserReferral({
    this.inviterUid,
    required this.referredCount,
  });

  factory UserReferral.empty() {
    return const UserReferral(
      inviterUid: null,
      referredCount: 0,
    );
  }

  factory UserReferral.fromJson(Map<String, dynamic> json) {
    return UserReferral(
      inviterUid: json['inviterUid'] as String?,
      referredCount: json['referredCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'inviterUid': inviterUid,
      'referredCount': referredCount,
    };
  }
}

/// User roles
class UserRoles {
  final bool isAdmin;

  const UserRoles({
    required this.isAdmin,
  });

  factory UserRoles.user() {
    return const UserRoles(isAdmin: false);
  }

  factory UserRoles.fromJson(Map<String, dynamic> json) {
    return UserRoles(
      isAdmin: json['isAdmin'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isAdmin': isAdmin,
    };
  }
}

/// User model
class User {
  final String uid;
  final String handle;
  final DateTime createdAt;
  final int coins;
  final int dailySkipsUsed;
  final int adSkipsUsedToday;
  final int bestScoreAllTime;
  final int todayScore;
  final int todaySolvedCount;
  final int streak;
  final UserReferral referral;
  final UserRoles roles;
  final DateTime? lastPlayedAt;
  final String? lastDailyKey; // YYYYMMDD of last play

  const User({
    required this.uid,
    required this.handle,
    required this.createdAt,
    required this.coins,
    required this.dailySkipsUsed,
    required this.adSkipsUsedToday,
    required this.bestScoreAllTime,
    required this.todayScore,
    required this.todaySolvedCount,
    required this.streak,
    required this.referral,
    required this.roles,
    this.lastPlayedAt,
    this.lastDailyKey,
  });

  factory User.create({
    required String uid,
    required String handle,
  }) {
    return User(
      uid: uid,
      handle: handle,
      createdAt: DateTime.now(),
      coins: 0,
      dailySkipsUsed: 0,
      adSkipsUsedToday: 0,
      bestScoreAllTime: 0,
      todayScore: 0,
      todaySolvedCount: 0,
      streak: 0,
      referral: UserReferral.empty(),
      roles: UserRoles.user(),
      lastPlayedAt: null,
      lastDailyKey: null,
    );
  }

  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return User.fromJson(data, doc.id);
  }

  factory User.fromJson(Map<String, dynamic> json, String uid) {
    return User(
      uid: uid,
      handle: json['handle'] as String? ?? 'Player',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      coins: json['coins'] as int? ?? 0,
      dailySkipsUsed: json['dailySkipsUsed'] as int? ?? 0,
      adSkipsUsedToday: json['adSkipsUsedToday'] as int? ?? 0,
      bestScoreAllTime: json['bestScoreAllTime'] as int? ?? 0,
      todayScore: json['todayScore'] as int? ?? 0,
      todaySolvedCount: json['todaySolvedCount'] as int? ?? 0,
      streak: json['streak'] as int? ?? 0,
      referral: json['referral'] != null
          ? UserReferral.fromJson(json['referral'] as Map<String, dynamic>)
          : UserReferral.empty(),
      roles: json['roles'] != null
          ? UserRoles.fromJson(json['roles'] as Map<String, dynamic>)
          : UserRoles.user(),
      lastPlayedAt: (json['lastPlayedAt'] as Timestamp?)?.toDate(),
      lastDailyKey: json['lastDailyKey'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'handle': handle,
      'createdAt': Timestamp.fromDate(createdAt),
      'coins': coins,
      'dailySkipsUsed': dailySkipsUsed,
      'adSkipsUsedToday': adSkipsUsedToday,
      'bestScoreAllTime': bestScoreAllTime,
      'todayScore': todayScore,
      'todaySolvedCount': todaySolvedCount,
      'streak': streak,
      'referral': referral.toJson(),
      'roles': roles.toJson(),
      'lastPlayedAt': lastPlayedAt != null ? Timestamp.fromDate(lastPlayedAt!) : null,
      'lastDailyKey': lastDailyKey,
    };
  }

  User copyWith({
    String? uid,
    String? handle,
    DateTime? createdAt,
    int? coins,
    int? dailySkipsUsed,
    int? adSkipsUsedToday,
    int? bestScoreAllTime,
    int? todayScore,
    int? todaySolvedCount,
    int? streak,
    UserReferral? referral,
    UserRoles? roles,
    DateTime? lastPlayedAt,
    String? lastDailyKey,
  }) {
    return User(
      uid: uid ?? this.uid,
      handle: handle ?? this.handle,
      createdAt: createdAt ?? this.createdAt,
      coins: coins ?? this.coins,
      dailySkipsUsed: dailySkipsUsed ?? this.dailySkipsUsed,
      adSkipsUsedToday: adSkipsUsedToday ?? this.adSkipsUsedToday,
      bestScoreAllTime: bestScoreAllTime ?? this.bestScoreAllTime,
      todayScore: todayScore ?? this.todayScore,
      todaySolvedCount: todaySolvedCount ?? this.todaySolvedCount,
      streak: streak ?? this.streak,
      referral: referral ?? this.referral,
      roles: roles ?? this.roles,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      lastDailyKey: lastDailyKey ?? this.lastDailyKey,
    );
  }

  /// Check if user has daily skips remaining
  bool get hasSkipsRemaining => dailySkipsUsed < 3;

  /// Check if user can use ad skip
  bool canUseAdSkip(int maxAdSkipsPerDay) => adSkipsUsedToday < maxAdSkipsPerDay;

  /// Check if user can afford coin cost
  bool canAfford(int cost) => coins >= cost;
}
