import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../theme/app_theme.dart';

class GameOverScreen extends HookConsumerWidget {
  final int score;
  final int solved;
  final int streak;
  final int coinsEarned;

  const GameOverScreen({
    super.key,
    required this.score,
    required this.solved,
    required this.streak,
    required this.coinsEarned,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacing24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Game Over!', style: Theme.of(context).textTheme.displayLarge),
                const SizedBox(height: 48),
                _StatCard(label: 'Score', value: score.toString()),
                const SizedBox(height: 16),
                _StatCard(label: 'Solved', value: solved.toString()),
                const SizedBox(height: 16),
                _StatCard(label: 'Best Streak', value: streak.toString()),
                const SizedBox(height: 16),
                _StatCard(label: 'Coins Earned', value: coinsEarned.toString()),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => context.go('/play'),
                    child: const Text('PLAY AGAIN'),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('HOME'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacing24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.headlineSmall),
            Text(value, style: Theme.of(context).textTheme.displaySmall),
          ],
        ),
      ),
    );
  }
}
