import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/hackathon_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/kpi_card.dart';
import '../../widgets/timer_widget.dart';
import '../../widgets/leaderboard_table.dart';
import '../../models/user.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final hackathonIdAsync = ref.watch(hackathonIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Дашборд администратора'),
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
      drawer:
          AppDrawer(role: user?.role ?? UserRole.admin, currentRoute: '/admin'),
      body: hackathonIdAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Ошибка: $err')),
        data: (hackathonId) => hackathonId.isEmpty
            ? const Center(
                child: Text(
                    'Нет активного хакатона. Создайте хакатон в админ-панели.'))
            : _DashboardContent(hackathonId: hackathonId),
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

class _DashboardContent extends ConsumerWidget {
  final String hackathonId;
  const _DashboardContent({required this.hackathonId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(adminDashboardProvider(hackathonId));

    return dashboardAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Ошибка загрузки дашборда: $err')),
      data: (dashboard) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              childAspectRatio: 1.8,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                KpiCard(
                    title: 'Всего команд',
                    value: '${dashboard.teamsTotal}',
                    icon: Icons.groups,
                    color: Colors.blue),
                KpiCard(
                    title: 'Экспертов',
                    value: '${dashboard.expertsTotal}',
                    icon: Icons.people,
                    color: Colors.green),
                KpiCard(
                    title: 'Критериев',
                    value: '${dashboard.criteriaTotal}',
                    icon: Icons.rule,
                    color: Colors.orange),
                KpiCard(
                  title: 'Оценок отправлено',
                  value:
                      '${dashboard.evaluationsSubmitted}/${dashboard.evaluationsTotalExpected}',
                  icon: Icons.check_circle,
                  color: Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Топ команд',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600)),
                              TextButton(
                                onPressed: () => context.go('/admin/results'),
                                child: const Text('Все результаты'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          dashboard.leaderboardTop.isEmpty
                              ? const Center(
                                  child: Padding(
                                      padding: EdgeInsets.all(32),
                                      child: Text('Нет данных')))
                              : LeaderboardTable(
                                  entries: dashboard.leaderboardTop,
                                  compact: true),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Прогресс экспертов',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 16),
                              if (dashboard.expertsProgress.isEmpty)
                                const Center(
                                    child: Padding(
                                        padding: EdgeInsets.all(16),
                                        child: Text('Нет экспертов')))
                              else
                                Column(
                                  children:
                                      dashboard.expertsProgress.map((expert) {
                                    final progress = expert.totalAssigned > 0
                                        ? expert.submitted /
                                            expert.totalAssigned
                                        : 0.0;
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(expert.expertName),
                                              Text(
                                                  '${expert.submitted}/${expert.totalAssigned}'),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          LinearProgressIndicator(
                                              value: progress,
                                              backgroundColor:
                                                  Colors.grey[200]),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Быстрые действия',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () => context.go('/admin/teams'),
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text('Команда'),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () => context.go('/admin/users'),
                                    icon:
                                        const Icon(Icons.person_add, size: 18),
                                    label: const Text('Эксперт'),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () =>
                                        context.go('/admin/criteria'),
                                    icon: const Icon(Icons.add_chart, size: 18),
                                    label: const Text('Критерий'),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () =>
                                        context.go('/admin/results'),
                                    icon: const Icon(Icons.publish, size: 18),
                                    label: const Text('Опубликовать'),
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}
