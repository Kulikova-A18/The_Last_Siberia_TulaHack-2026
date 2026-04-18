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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Дашборд эксперта'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () => Scaffold.of(context).openEndDrawer(),
            tooltip: 'Отладка API',
          ),
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
          role: user?.role ?? UserRole.expert, currentRoute: '/expert'),
      body: hackathonIdAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Ошибка: $err')),
        data: (hackathonId) => hackathonId.isEmpty
            ? const Center(child: Text('Нет активного хакатона'))
            : _DashboardContent(
                hackathonId: hackathonId, apiService: apiService),
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
  const _DashboardContent(
      {required this.hackathonId, required this.apiService});

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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: KpiCard(
                      title: 'Назначено команд',
                      value: '$_totalCount',
                      icon: Icons.assignment,
                      color: Colors.blue)),
              const SizedBox(width: 16),
              Expanded(
                  child: KpiCard(
                      title: 'Оценено',
                      value: '$_evaluatedCount',
                      icon: Icons.check_circle,
                      color: Colors.green)),
              const SizedBox(width: 16),
              Expanded(
                  child: KpiCard(
                      title: 'Осталось',
                      value: '${_totalCount - _evaluatedCount}',
                      icon: Icons.pending,
                      color: Colors.orange)),
            ],
          ),
          const SizedBox(height: 32),
          Text('Назначенные команды',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<AssignedTeamListResponse>(
              future: _assignedTeamsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Ошибка: ${snapshot.error}'));
                }
                final data = snapshot.data!;
                if (data.items.isEmpty) {
                  return const Center(child: Text('Нет назначенных команд'));
                }
                return ListView.builder(
                  itemCount: data.items.length,
                  itemBuilder: (context, index) {
                    final team = data.items[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          child: Text('${index + 1}'),
                        ),
                        title: Text(team.teamName,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(team.projectTitle),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            StatusBadge(status: team.evaluationStatus),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () =>
                                  context.go('/expert/evaluate/${team.teamId}'),
                              child: Text(team.evaluationStatus == 'submitted'
                                  ? 'Просмотр'
                                  : 'Оценить'),
                            ),
                          ],
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
