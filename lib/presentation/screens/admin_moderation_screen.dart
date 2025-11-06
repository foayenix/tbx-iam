import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../theme/app_theme.dart';

class AdminModerationScreen extends HookConsumerWidget {
  const AdminModerationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Moderation')),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacing16),
        children: [
          Text('Pending Submissions', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          const Center(child: Text('No pending riddles')),
        ],
      ),
    );
  }
}
