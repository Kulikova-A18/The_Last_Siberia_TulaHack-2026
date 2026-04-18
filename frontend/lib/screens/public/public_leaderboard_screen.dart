import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hackrank_frontend/models/hackathon.dart';
import '../../providers/auth_provider.dart';
import '../../providers/hackathon_provider.dart';
import '../../widgets/timer_widget.dart';
import '../../services/api/api_service.dart';

class PublicLeaderboardScreen extends ConsumerWidget {
  const PublicLeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hackathonIdAsync = ref.watch(hackathonIdProvider);
    final apiService = ref.watch(apiServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Публичный рейтинг'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () => Scaffold.of(context).openEndDrawer(),
            tooltip: 'Отладка API',
          ),
          IconButton(
            icon: const Icon(Icons.login),
            onPressed: () => context.go('/login'),
            tooltip: 'Войти',
          ),
        ],
      ),
      body: hackathonIdAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Ошибка: $err')),
        data: (hackathonId) => hackathonId.isEmpty
            ? const Center(child: Text('Нет активного хакатона'))
            : _LeaderboardContent(
                hackathonId: hackathonId, apiService: apiService),
      ),
    );
  }
}

class _LeaderboardContent extends StatefulWidget {
  final String hackathonId;
  final ApiService apiService;
  const _LeaderboardContent(
      {required this.hackathonId, required this.apiService});

  @override
  State<_LeaderboardContent> createState() => _LeaderboardContentState();
}

class _LeaderboardContentState extends State<_LeaderboardContent> {
  late Future<PublicLeaderboardResponse> _leaderboardFuture;
  late Future<PublicTimerResponse> _timerFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _leaderboardFuture =
        widget.apiService.getPublicLeaderboard(widget.hackathonId);
    _timerFuture = widget.apiService.getPublicTimer(widget.hackathonId);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.05),
            Colors.white
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.analytics_outlined,
                            size: 40,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('HackRank',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            Text('Публичный рейтинг',
                                style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      ],
                    ),
                    FutureBuilder<PublicTimerResponse>(
                      future: _timerFuture,
                      builder: (context, snapshot) {
                        if (snapshot.hasData &&
                            snapshot.data!.secondsRemaining != null) {
                          final seconds = snapshot.data!.secondsRemaining!;
                          final deadlineAt =
                              DateTime.now().add(Duration(seconds: seconds));
                          return TimerWidget(
                            deadlineAt: deadlineAt,
                            label:
                                snapshot.data!.nextDeadlineTitle ?? 'До конца',
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(4))),
                    const SizedBox(width: 8),
                    Text('Live • Обновляется автоматически',
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 13)),
                    const Spacer(),
                    FutureBuilder<PublicLeaderboardResponse>(
                      future: _leaderboardFuture,
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Text(
                            'Обновлено: ${_formatTime(snapshot.data!.updatedAt)}',
                            style: TextStyle(
                                color: Colors.grey[500], fontSize: 12),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: FutureBuilder<PublicLeaderboardResponse>(
                    future: _leaderboardFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Ошибка: ${snapshot.error}'));
                      }
                      final data = snapshot.data!;
                      if (!data.published) {
                        return const Center(
                            child: Text('Результаты ещё не опубликованы'));
                      }
                      if (data.items.isEmpty) {
                        return const Center(
                            child: Text('Нет данных для отображения'));
                      }
                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            color: Colors.white,
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                          width: 80,
                                          child: Text('МЕСТО',
                                              style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onPrimary,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12))),
                                      Expanded(
                                          child: Text('КОМАНДА',
                                              style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onPrimary,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12))),
                                      SizedBox(
                                          width: 100,
                                          child: Text('БАЛЛЫ',
                                              textAlign: TextAlign.right,
                                              style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onPrimary,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12))),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: ListView.separated(
                                    itemCount: data.items.length,
                                    separatorBuilder: (_, __) => Divider(
                                        height: 1, color: Colors.grey[200]),
                                    itemBuilder: (context, index) {
                                      final entry = data.items[index];
                                      final isTop3 = entry.place <= 3;
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 12),
                                        decoration: BoxDecoration(
                                            color: isTop3
                                                ? Colors.amber.withOpacity(0.05)
                                                : null),
                                        child: Row(
                                          children: [
                                            SizedBox(
                                                width: 80,
                                                child: _PlaceWidget(
                                                    place: entry.place)),
                                            Expanded(
                                                child: Text(entry.teamName,
                                                    style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: isTop3
                                                            ? FontWeight.w600
                                                            : FontWeight
                                                                .normal))),
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
                                                      FontFeature
                                                          .tabularFigures()
                                                    ]),
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
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
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
            border: Border.all(color: Colors.amber, width: 1.5)),
        child: Center(
            child: Text('1',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.amber[700]))),
      );
    }
    if (place == 2) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.withOpacity(0.2),
            border: Border.all(color: Colors.grey, width: 1.5)),
        child: Center(
            child: Text('2',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.grey[700]))),
      );
    }
    if (place == 3) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.brown.withOpacity(0.2),
            border: Border.all(color: Colors.brown, width: 1.5)),
        child: Center(
            child: Text('3',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.brown[700]))),
      );
    }
    return Text(place.toString(),
        style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey[600]));
  }
}
