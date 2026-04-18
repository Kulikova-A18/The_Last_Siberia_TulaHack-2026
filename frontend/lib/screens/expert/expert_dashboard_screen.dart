import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hackrank_frontend/models/evaluation.dart';
import 'package:hackrank_frontend/models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/hackathon_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/kpi_card.dart';
import '../../widgets/timer_widget.dart';
import '../../widgets/status_badge.dart';
import '../../services/api/api_service.dart';

class ExpertDashboardScreen extends ConsumerWidget {
  const ExpertDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final hackathonIdAsync = ref.watch(hackathonIdProvider);
    final apiService = ref.watch(apiServiceProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Дашборд эксперта'),
        actions: [
          hackathonIdAsync.when(
            data: (hackathonId) => hackathonId.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: _DashboardTimer(hackathonId: hackathonId),
                  )
                : const SizedBox(),
            loading: () => const SizedBox(),
            error: (_, __) => const SizedBox(),
          ),
        ],
      ),
      drawer: AppDrawer(
        role: user?.role ?? UserRole.expert,
        currentRoute: '/expert',
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primary.withOpacity(0.05),
              colorScheme.background,
            ],
          ),
        ),
        child: hackathonIdAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Ошибка: $err')),
          data: (hackathonId) => hackathonId.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('Нет активного хакатона',
                          style: theme.textTheme.bodyLarge),
                    ],
                  ),
                )
              : _DashboardContent(
                  hackathonId: hackathonId, apiService: apiService),
        ),
      ),
    );
  }
}

class _DashboardTimer extends ConsumerWidget {
  final String hackathonId;
  const _DashboardTimer({required this.hackathonId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerAsync = ref.watch(timerProvider(hackathonId));
    return timerAsync.when(
      data: (timer) => TimerWidget(
        deadlineAt: timer.nextDeadline?.deadlineAt,
        label: timer.nextDeadline?.title ?? 'Дедлайн',
      ),
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }
}

class _DashboardContent extends StatefulWidget {
  final String hackathonId;
  final ApiService apiService;
  const _DashboardContent({
    required this.hackathonId,
    required this.apiService,
  });

  @override
  State<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<_DashboardContent> {
  late Future<AssignedTeamListResponse> _assignedTeamsFuture;
  int _evaluatedCount = 0;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _assignedTeamsFuture =
        widget.apiService.getMyAssignedTeams(widget.hackathonId);
    _assignedTeamsFuture.then((data) {
      setState(() {
        _totalCount = data.total;
        _evaluatedCount =
            data.items.where((t) => t.evaluationStatus == 'submitted').length;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI Cards
          Row(
            children: [
              Expanded(
                child: KpiCard(
                  title: 'Назначено команд',
                  value: '$_totalCount',
                  icon: Icons.assignment_outlined,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: KpiCard(
                  title: 'Оценено',
                  value: '$_evaluatedCount',
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: KpiCard(
                  title: 'Осталось',
                  value: '${_totalCount - _evaluatedCount}',
                  icon: Icons.pending_outlined,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Progress Bar
          if (_totalCount > 0) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Общий прогресс',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${(_evaluatedCount / _totalCount * 100).toStringAsFixed(0)}%',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value:
                          _totalCount > 0 ? _evaluatedCount / _totalCount : 0,
                      backgroundColor: Colors.grey[200],
                      color: colorScheme.primary,
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Teams List Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Назначенные команды',
                style: theme.textTheme.headlineMedium,
              ),
              TextButton.icon(
                onPressed: () => context.go('/expert/teams'),
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('Все команды'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Teams List
          Expanded(
            child: FutureBuilder<AssignedTeamListResponse>(
              future: _assignedTeamsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
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
                if (data.items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment_outlined,
                            size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('Нет назначенных команд',
                            style: theme.textTheme.bodyLarge),
                        const SizedBox(height: 8),
                        Text(
                          'Ожидайте назначения от администратора',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: data.items.length,
                  itemBuilder: (context, index) {
                    final team = data.items[index];
                    final isSubmitted = team.evaluationStatus == 'submitted';
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () =>
                            context.go('/expert/evaluate/${team.teamId}'),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isSubmitted
                                      ? Colors.green.withOpacity(0.1)
                                      : colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  isSubmitted
                                      ? Icons.check_circle_outline
                                      : Icons.assignment_outlined,
                                  color: isSubmitted
                                      ? Colors.green
                                      : colorScheme.primary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      team.teamName,
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      team.projectTitle,
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    StatusBadge(status: team.evaluationStatus),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: Colors.grey[400],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
