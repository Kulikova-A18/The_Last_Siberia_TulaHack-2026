import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hackrank_frontend/models/hackathon.dart';
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
      error: (err, _) {
        // Если дашборд не реализован, показываем заглушку с базовой информацией
        if (err.toString().contains('404')) {
          return _buildFallbackDashboard(context, ref);
        }
        return Center(child: Text('Ошибка загрузки дашборда: $err'));
      },
      data: (dashboard) => _buildDashboard(context, dashboard),
    );
  }

  Widget _buildFallbackDashboard(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.orange),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Дашборд администратора находится в разработке. Используйте меню для навигации.',
                    style: TextStyle(color: Colors.orange[700]),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Быстрые действия',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _buildActionCard(
                        context,
                        icon: Icons.groups,
                        title: 'Команды',
                        subtitle: 'Управление командами',
                        onTap: () => context.go('/admin/teams'),
                        color: Colors.blue,
                      ),
                      _buildActionCard(
                        context,
                        icon: Icons.people,
                        title: 'Пользователи',
                        subtitle: 'Управление пользователями',
                        onTap: () => context.go('/admin/users'),
                        color: Colors.green,
                      ),
                      _buildActionCard(
                        context,
                        icon: Icons.rule,
                        title: 'Критерии',
                        subtitle: 'Настройка критериев оценки',
                        onTap: () => context.go('/admin/criteria'),
                        color: Colors.orange,
                      ),
                      _buildActionCard(
                        context,
                        icon: Icons.assignment_ind,
                        title: 'Назначения',
                        subtitle: 'Назначение экспертов',
                        onTap: () => context.go('/admin/assignments'),
                        color: Colors.purple,
                      ),
                      _buildActionCard(
                        context,
                        icon: Icons.leaderboard,
                        title: 'Результаты',
                        subtitle: 'Просмотр и публикация результатов',
                        onTap: () => context.go('/admin/results'),
                        color: Colors.red,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return SizedBox(
      width: 200,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(height: 12),
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, AdminDashboard dashboard) {
    return SingleChildScrollView(
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
                                    fontSize: 18, fontWeight: FontWeight.w600)),
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
                                    fontSize: 16, fontWeight: FontWeight.w600)),
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
                                      ? expert.submitted / expert.totalAssigned
                                      : 0.0;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
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
                                            backgroundColor: Colors.grey[200]),
                                      ],
                                    ),
                                  );
                                }).toList(),
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
