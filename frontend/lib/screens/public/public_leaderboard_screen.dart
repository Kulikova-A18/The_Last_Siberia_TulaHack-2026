import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hackrank_frontend/models/hackathon.dart';
import '../../services/api/api_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/timer_widget.dart';

class PublicLeaderboardScreen extends ConsumerStatefulWidget {
  const PublicLeaderboardScreen({super.key});

  @override
  ConsumerState<PublicLeaderboardScreen> createState() =>
      _PublicLeaderboardScreenState();
}

class _PublicLeaderboardScreenState
    extends ConsumerState<PublicLeaderboardScreen> {
  late Future<PublicLeaderboardResponse> _leaderboardFuture;
  late Future<PublicTimerResponse> _timerFuture;
  String _hackathonId = '';

  @override
  void initState() {
    super.initState();
    _loadHackathon();
  }

  Future<void> _loadHackathon() async {
    final apiService = ref.read(apiServiceProvider);
    try {
      final hackathon = await apiService.getPublicActiveHackathon();
      setState(() {
        _hackathonId = hackathon.id;
        _leaderboardFuture = apiService.getPublicLeaderboard(_hackathonId);
        _timerFuture = apiService.getPublicTimer(_hackathonId);
      });
    } catch (e) {
      try {
        final hackathons = await apiService.getHackathons();
        if (hackathons.isNotEmpty) {
          final active = hackathons.firstWhere(
            (h) => h.status == 'active',
            orElse: () => hackathons.first,
          );
          setState(() {
            _hackathonId = active.id;
            _leaderboardFuture = apiService.getPublicLeaderboard(_hackathonId);
            _timerFuture = apiService.getPublicTimer(_hackathonId);
          });
        }
      } catch (e2) {
        debugPrint('Failed to load hackathon: $e2');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Публичный рейтинг'),
        actions: [
          IconButton(
            icon: Icon(Icons.login_outlined, color: colorScheme.secondary),
            onPressed: () => context.go('/login'),
            tooltip: 'Войти',
          ),
        ],
      ),
      body: _hackathonId.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.primary.withOpacity(0.05),
                    Colors.white,
                  ],
                ),
              ),
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(
                                      Icons.analytics_outlined,
                                      size: 28,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'HackRank',
                                        style: theme.textTheme.headlineMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Публичный рейтинг',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              FutureBuilder<PublicTimerResponse>(
                                future: _timerFuture,
                                builder: (context, snapshot) {
                                  if (snapshot.hasData &&
                                      snapshot.data!.secondsRemaining != null) {
                                    final seconds =
                                        snapshot.data!.secondsRemaining!;
                                    final deadlineAt = DateTime.now()
                                        .add(Duration(seconds: seconds));
                                    return TimerWidget(
                                      deadlineAt: deadlineAt,
                                      label: snapshot.data!.nextDeadlineTitle ??
                                          'До конца',
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
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Обновляется автоматически',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[500],
                                ),
                              ),
                              const Spacer(),
                            ],
                          ),
                          const SizedBox(height: 16),
                          FutureBuilder<PublicLeaderboardResponse>(
                            future: _leaderboardFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }
                              if (snapshot.hasError) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.error_outline,
                                          size: 48, color: Colors.grey[400]),
                                      const SizedBox(height: 16),
                                      Text('Ошибка: ${snapshot.error}'),
                                    ],
                                  ),
                                );
                              }
                              final data = snapshot.data!;
                              if (!data.published) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.lock_outline,
                                          size: 48, color: Colors.grey[400]),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Результаты ещё не опубликованы',
                                        style: theme.textTheme.bodyLarge,
                                      ),
                                    ],
                                  ),
                                );
                              }
                              if (data.items.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.leaderboard_outlined,
                                          size: 48, color: Colors.grey[400]),
                                      const SizedBox(height: 16),
                                      Text('Нет данных для отображения',
                                          style: theme.textTheme.bodyLarge),
                                    ],
                                  ),
                                );
                              }
                              return Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    color: Colors.white,
                                    child: Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 20, vertical: 14),
                                          decoration: BoxDecoration(
                                            color: colorScheme.primary,
                                          ),
                                          child: Row(
                                            children: [
                                              const SizedBox(
                                                  width: 60,
                                                  child: Text('МЕСТО')),
                                              Expanded(child: Text('КОМАНДА')),
                                              const SizedBox(
                                                  width: 100,
                                                  child: Text('БАЛЛЫ',
                                                      textAlign:
                                                          TextAlign.right)),
                                            ]
                                                .map((child) =>
                                                    DefaultTextStyle(
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 12,
                                                      ),
                                                      child: child,
                                                    ))
                                                .toList(),
                                          ),
                                        ),
                                        ListView.separated(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          itemCount: data.items.length,
                                          separatorBuilder: (_, __) => Divider(
                                              height: 1,
                                              color: Colors.grey[200]),
                                          itemBuilder: (context, index) {
                                            final entry = data.items[index];
                                            final isTop3 = entry.place <= 3;
                                            return Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 20,
                                                      vertical: 14),
                                              decoration: BoxDecoration(
                                                color: isTop3
                                                    ? colorScheme.primary
                                                        .withOpacity(0.05)
                                                    : null,
                                              ),
                                              child: Row(
                                                children: [
                                                  SizedBox(
                                                    width: 60,
                                                    child: _PlaceWidget(
                                                        place: entry.place),
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      entry.teamName,
                                                      style: theme
                                                          .textTheme.bodyMedium
                                                          ?.copyWith(
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
                                                      textAlign:
                                                          TextAlign.right,
                                                      style: theme
                                                          .textTheme.titleMedium
                                                          ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: isTop3
                                                            ? colorScheme
                                                                .primary
                                                            : Colors.grey[800],
                                                        fontFeatures: const [
                                                          FontFeature
                                                              .tabularFigures()
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (place == 1) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colorScheme.primary.withOpacity(0.15),
          border: Border.all(color: colorScheme.primary, width: 1.5),
        ),
        child: Center(
          child: Text(
            '1',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ),
      );
    }
    if (place == 2) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.withOpacity(0.15),
          border: Border.all(color: Colors.grey, width: 1.5),
        ),
        child: Center(
          child: Text(
            '2',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ),
      );
    }
    if (place == 3) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.brown.withOpacity(0.15),
          border: Border.all(color: Colors.brown, width: 1.5),
        ),
        child: Center(
          child: Text(
            '3',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.brown[700],
            ),
          ),
        ),
      );
    }
    return Text(
      place.toString(),
      style: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w500,
        color: Colors.grey[600],
      ),
    );
  }
}
