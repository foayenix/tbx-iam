import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../screens/splash_screen.dart';
import '../screens/home_screen.dart';
import '../screens/play_screen.dart';
import '../screens/game_over_screen.dart';
import '../screens/leaderboard_screen.dart';
import '../screens/daily_challenge_screen.dart';
import '../screens/submit_riddle_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/admin_moderation_screen.dart';

/// Router provider
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      // Splash
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Home
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),

      // Play
      GoRoute(
        path: '/play',
        name: 'play',
        builder: (context, state) {
          final isDailyChallenge = state.uri.queryParameters['daily'] == 'true';
          return PlayScreen(isDailyChallenge: isDailyChallenge);
        },
      ),

      // Game Over
      GoRoute(
        path: '/game-over',
        name: 'game-over',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return GameOverScreen(
            score: extra?['score'] as int? ?? 0,
            solved: extra?['solved'] as int? ?? 0,
            streak: extra?['streak'] as int? ?? 0,
            coinsEarned: extra?['coinsEarned'] as int? ?? 0,
          );
        },
      ),

      // Leaderboard
      GoRoute(
        path: '/leaderboard',
        name: 'leaderboard',
        builder: (context, state) => const LeaderboardScreen(),
      ),

      // Daily Challenge
      GoRoute(
        path: '/daily-challenge',
        name: 'daily-challenge',
        builder: (context, state) => const DailyChallengeScreen(),
      ),

      // Submit Riddle (UGC)
      GoRoute(
        path: '/submit-riddle',
        name: 'submit-riddle',
        builder: (context, state) => const SubmitRiddleScreen(),
      ),

      // Profile
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),

      // Admin Moderation
      GoRoute(
        path: '/admin/moderation',
        name: 'admin-moderation',
        builder: (context, state) => const AdminModerationScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              state.uri.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});
