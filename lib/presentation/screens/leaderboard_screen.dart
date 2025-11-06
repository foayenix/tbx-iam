import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../theme/app_theme.dart';

class LeaderboardScreen extends HookConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard')),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              tabs: [Tab(text: 'Daily'), Tab(text: 'All Time')],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _LeaderboardList(entries: []),
                  _LeaderboardList(entries: []),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardList extends StatelessWidget {
  final List entries;

  const _LeaderboardList({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Center(child: Text('No entries yet'));
    }
    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, index) => ListTile(
        leading: Text('#${index + 1}'),
        title: Text('Player ${index + 1}'),
        trailing: Text('${100 - index * 5}'),
      ),
    );
  }
}
