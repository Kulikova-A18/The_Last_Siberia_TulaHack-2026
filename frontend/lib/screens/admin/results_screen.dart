import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/leaderboard_table.dart';
import '../../models/hackathon.dart';

class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    final demoresults = [
      LeaderboardEntry(
          place: 1, teamId: '1', teamName: 'CodeMasters', finalScore: 92.5),
      LeaderboardEntry(
          place: 2, teamId: '2', teamName: 'ByteForce', finalScore: 87.3),
      LeaderboardEntry(
          place: 3, teamId: '3', teamName: 'InnovateX', finalScore: 84.1),
      LeaderboardEntry(
          place: 4, teamId: '4', teamName: 'DataWizards', finalScore: 79.8),
      LeaderboardEntry(
          place: 5, teamId: '5', teamName: 'AIBrains', finalScore: 76.2),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Результаты'),
        actions: [
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.refresh),
            label: const Text('Пересчитать'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Результаты опубликованы (демо)')),
              );
            },
            icon: const Icon(Icons.publish),
            label: const Text('Опубликовать'),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.download),
            tooltip: 'Экспорт в CSV',
          ),
        ],
      ),
      drawer: AppDrawer(
        role: user!.role,
        currentRoute: '/admin/results',
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Итоговый рейтинг',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(width: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_outline,
                          size: 16, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        'Не опубликован',
                        style:
                            TextStyle(color: Colors.orange[700], fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  'Обновлено: ${DateTime.now().toLocal().toString().substring(0, 16)}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: LeaderboardTable(entries: demoresults),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Winners section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Победители',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _WinnerCard(
                          place: 2,
                          team: demoresults[1].teamName,
                          score: demoresults[1].finalScore,
                          color: Colors.grey[400]!,
                        ),
                        _WinnerCard(
                          place: 1,
                          team: demoresults[0].teamName,
                          score: demoresults[0].finalScore,
                          color: Colors.amber,
                        ),
                        _WinnerCard(
                          place: 3,
                          team: demoresults[2].teamName,
                          score: demoresults[2].finalScore,
                          color: Colors.brown[300]!,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WinnerCard extends StatelessWidget {
  final int place;
  final String team;
  final double score;
  final Color color;

  const _WinnerCard({
    required this.place,
    required this.team,
    required this.score,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.2),
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              '$place',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          team,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${score.toStringAsFixed(1)} баллов',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
