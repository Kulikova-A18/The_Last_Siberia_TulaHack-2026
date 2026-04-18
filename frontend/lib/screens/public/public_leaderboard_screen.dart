import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/timer_widget.dart';
import '../../widgets/leaderboard_table.dart';
import '../../models/hackathon.dart';

class PublicLeaderboardScreen extends ConsumerWidget {
  const PublicLeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 900),
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.analytics_outlined,
                            size: 40,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'HackRank 2026',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              Text(
                                'Публичный рейтинг',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ],
                      ),
                      TimerWidget(
                        deadlineAt: DateTime.now()
                            .add(const Duration(hours: 3, minutes: 45)),
                        label: 'До конца',
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Live indicator
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Live • Обновляется автоматически',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      const Spacer(),
                      Text(
                        'Обновлено: ${DateTime.now().toLocal().toString().substring(11, 16)}',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Leaderboard
                  Expanded(
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          color: Colors.white,
                          child: Column(
                            children: [
                              // Table header
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 80,
                                      child: Text(
                                        'МЕСТО',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        'КОМАНДА',
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 100,
                                      child: Text(
                                        'БАЛЛЫ',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Table body
                              Expanded(
                                child: ListView.separated(
                                  itemCount: demoresults.length,
                                  separatorBuilder: (_, __) => Divider(
                                    height: 1,
                                    color: Colors.grey[200],
                                  ),
                                  itemBuilder: (context, index) {
                                    final entry = demoresults[index];
                                    final isTop3 = entry.place <= 3;
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: isTop3
                                            ? Colors.amber.withOpacity(0.05)
                                            : null,
                                      ),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 80,
                                            child: _PlaceWidget(
                                                place: entry.place),
                                          ),
                                          Expanded(
                                            child: Text(
                                              entry.teamName,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: isTop3
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 100,
                                            child: Text(
                                              entry.finalScore
                                                  .toStringAsFixed(1),
                                              textAlign: TextAlign.right,
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                                color: isTop3
                                                    ? Colors.amber[700]
                                                    : Colors.grey[800],
                                                fontFeatures: const [
                                                  FontFeature.tabularFigures()
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Top 3 podium
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _PodiumCard(
                          place: 2,
                          team: demoresults[1].teamName,
                          score: demoresults[1].finalScore,
                          color: Colors.grey[400]!,
                        ),
                        _PodiumCard(
                          place: 1,
                          team: demoresults[0].teamName,
                          score: demoresults[0].finalScore,
                          color: Colors.amber,
                          isFirst: true,
                        ),
                        _PodiumCard(
                          place: 3,
                          team: demoresults[2].teamName,
                          score: demoresults[2].finalScore,
                          color: Colors.brown[300]!,
                        ),
                      ],
                    ),
                  ),

                  // Footer
                  const SizedBox(height: 16),
                  Text(
                    '© 2026 HackRank — Платформа автоматизации оценки хакатонов',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaceWidget extends StatelessWidget {
  final int place;

  const _PlaceWidget({required this.place});

  @override
  Widget build(BuildContext context) {
    if (place == 1) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.amber.withOpacity(0.2),
          border: Border.all(color: Colors.amber, width: 1.5),
        ),
        child: Center(
          child: Text(
            '1',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.amber[700],
            ),
          ),
        ),
      );
    } else if (place == 2) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.withOpacity(0.2),
          border: Border.all(color: Colors.grey, width: 1.5),
        ),
        child: Center(
          child: Text(
            '2',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ),
      );
    } else if (place == 3) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.brown.withOpacity(0.2),
          border: Border.all(color: Colors.brown, width: 1.5),
        ),
        child: Center(
          child: Text(
            '3',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.brown[700],
            ),
          ),
        ),
      );
    }
    return Text(
      place.toString(),
      style: TextStyle(
        fontWeight: FontWeight.w500,
        color: Colors.grey[600],
      ),
    );
  }
}

class _PodiumCard extends StatelessWidget {
  final int place;
  final String team;
  final double score;
  final Color color;
  final bool isFirst;

  const _PodiumCard({
    required this.place,
    required this.team,
    required this.score,
    required this.color,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: isFirst ? 90 : 70,
          height: isFirst ? 90 : 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.15),
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              place.toString(),
              style: TextStyle(
                fontSize: isFirst ? 40 : 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          team,
          style: TextStyle(
            fontSize: isFirst ? 16 : 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          '${score.toStringAsFixed(1)} баллов',
          style: TextStyle(
            fontSize: isFirst ? 14 : 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
