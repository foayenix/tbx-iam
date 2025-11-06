import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../theme/app_theme.dart';
import '../../core/config/remote_config.dart';
import '../../data/models/riddle.dart';

/// Play screen - main gameplay
class PlayScreen extends HookConsumerWidget {
  final bool isDailyChallenge;

  const PlayScreen({super.key, this.isDailyChallenge = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(remoteConfigProvider);
    final timerSeconds = config.timerSeconds;

    // Game state
    final currentRiddle = useState<Riddle?>(null);
    final answerController = useTextEditingController();
    final timeRemaining = useState(timerSeconds);
    final score = useState(0);
    final streak = useState(0);
    final attempts = useState(0);
    final coinsEarned = useState(0);

    // Timer
    useEffect(() {
      final timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (timeRemaining.value > 0) {
          timeRemaining.value--;
        } else {
          // Timeout
          timer.cancel();
          _handleTimeout(context, score.value, attempts.value, streak.value, coinsEarned.value);
        }
      });
      return timer.cancel;
    }, [currentRiddle.value]);

    // Load first riddle
    useEffect(() {
      _loadNextRiddle(currentRiddle, timeRemaining, timerSeconds);
      return null;
    }, []);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacing24),
            child: Column(
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Score: ${score.value}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      'Streak: ${streak.value} 🔥',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Timer ring
                _TimerRing(
                  timeRemaining: timeRemaining.value,
                  totalTime: timerSeconds,
                ),
                const SizedBox(height: 32),

                // Riddle text
                if (currentRiddle.value != null)
                  Expanded(
                    child: Center(
                      child: Text(
                        currentRiddle.value!.text,
                        style: Theme.of(context).textTheme.displaySmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),

                // Answer input
                TextField(
                  controller: answerController,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                  decoration: const InputDecoration(
                    hintText: 'I am...',
                  ),
                  onSubmitted: (answer) {
                    _submitAnswer(
                      context,
                      answer,
                      currentRiddle.value!.answer,
                      score,
                      streak,
                      attempts,
                      coinsEarned,
                      answerController,
                      timeRemaining,
                      timerSeconds,
                      currentRiddle,
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      _submitAnswer(
                        context,
                        answerController.text,
                        currentRiddle.value!.answer,
                        score,
                        streak,
                        attempts,
                        coinsEarned,
                        answerController,
                        timeRemaining,
                        timerSeconds,
                        currentRiddle,
                      );
                    },
                    child: const Text('SUBMIT'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _loadNextRiddle(
    ValueNotifier<Riddle?> currentRiddle,
    ValueNotifier<int> timeRemaining,
    int timerSeconds,
  ) {
    // Mock riddle for demo
    currentRiddle.value = Riddle(
      id: '1',
      text: 'I am round, I have no beginning or end, and I represent infinity. What am I?',
      canonText: 'i am round i have no beginning or end and i represent infinity what am i',
      answer: 'circle',
      canonAnswer: 'circle',
      aliases: ['a circle', 'the circle'],
      category: RiddleCategory.abstract,
      difficulty: RiddleDifficulty.easy,
      status: RiddleStatus.live,
      createdAt: DateTime.now(),
      stats: RiddleStats.empty(),
      hashes: const RiddleHashes(sha256: '', simhash64: 0),
    );
    timeRemaining.value = timerSeconds;
  }

  void _submitAnswer(
    BuildContext context,
    String answer,
    String correctAnswer,
    ValueNotifier<int> score,
    ValueNotifier<int> streak,
    ValueNotifier<int> attempts,
    ValueNotifier<int> coinsEarned,
    TextEditingController controller,
    ValueNotifier<int> timeRemaining,
    int timerSeconds,
    ValueNotifier<Riddle?> currentRiddle,
  ) {
    attempts.value++;

    // Simple check (in real app, use TextMatch.matches)
    if (answer.trim().toLowerCase() == correctAnswer.toLowerCase()) {
      // Correct!
      score.value++;
      streak.value++;
      coinsEarned.value++;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Correct! 🎉'), backgroundColor: AppTheme.successColor),
      );

      // Load next riddle
      controller.clear();
      _loadNextRiddle(currentRiddle, timeRemaining, timerSeconds);
    } else {
      // Wrong
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Try again!'), backgroundColor: AppTheme.errorColor),
      );
    }
  }

  void _handleTimeout(BuildContext context, int finalScore, int attempts, int finalStreak, int coins) {
    context.go('/game-over', extra: {
      'score': finalScore,
      'solved': finalScore,
      'streak': finalStreak,
      'coinsEarned': coins,
    });
  }
}

class _TimerRing extends StatelessWidget {
  final int timeRemaining;
  final int totalTime;

  const _TimerRing({
    required this.timeRemaining,
    required this.totalTime,
  });

  @override
  Widget build(BuildContext context) {
    final progress = timeRemaining / totalTime;
    final color = progress > 0.5
        ? AppTheme.successColor
        : progress > 0.25
            ? AppTheme.warningColor
            : AppTheme.errorColor;

    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 8,
              backgroundColor: AppTheme.surfaceColor,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          Text(
            '$timeRemaining',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}
