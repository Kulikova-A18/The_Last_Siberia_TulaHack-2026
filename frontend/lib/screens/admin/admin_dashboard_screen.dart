import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/hackathon_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/kpi_card.dart';
import '../../widgets/timer_widget.dart';
import '../../widgets/leaderboard_table.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final hackathonId = ref.watch(hackathonIdProvider);
    final dashboardAsync = ref.watch(adminDashboardProvider(hackathonId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Дашборд администратора'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TimerWidget(
              deadlineAt: dashboardAsync.valueOrNull?.nextDeadline?.deadlineAt,
              label: 'Дедлайн',
            ),
          ),
        ],
      ),
      drawer: AppDrawer(
        role: user!.role,
        currentRoute: '/admin',
      ),
      body: dashboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Ошибка: $err')),
        data: (dashboard) => dashboard == null
            ? const Center(child: Text('Нет данных'))
            : _buildDashboard(context, dashboard),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, dynamic dashboard) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI Cards
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
                color: Colors.blue,
              ),
              KpiCard(
                title: 'Экспертов',
                value: '${dashboard.expertsTotal}',
                icon: Icons.people,
                color: Colors.green,
              ),
              KpiCard(
                title: 'Критериев',
                value: '${dashboard.criteriaTotal}',
                icon: Icons.rule,
                color: Colors.orange,
              ),
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

          // Two columns
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Leaderboard
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
                            const Text(
                              'Топ команд',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextButton(
                              onPressed: () => context.go('/admin/results'),
                              child: const Text('Все результаты'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        LeaderboardTable(
                          entries: dashboard.leaderboardTop,
                          compact: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),

              // Right: Progress and Deadlines
              Expanded(
                child: Column(
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Прогресс экспертов',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...dashboard.expertsProgress.map<Widget>((expert) {
                              final progress =
                                  expert.submitted / expert.totalAssigned;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                      backgroundColor: Colors.grey[200],
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Quick actions
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Быстрые действия',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
                                  icon: const Icon(Icons.person_add, size: 18),
                                  label: const Text('Эксперт'),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      context.go('/admin/criteria'),
                                  icon: const Icon(Icons.add_chart, size: 18),
                                  label: const Text('Критерий'),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () => context.go('/admin/results'),
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
    );
  }
}
