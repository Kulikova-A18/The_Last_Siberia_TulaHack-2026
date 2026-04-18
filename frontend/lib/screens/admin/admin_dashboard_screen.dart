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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Дашборд администратора'),
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
        role: user?.role ?? UserRole.admin,
        currentRoute: '/admin',
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
                      Icon(
                        Icons.event_busy,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Нет активного хакатона',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Создайте хакатон в админ-панели',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : _DashboardContent(hackathonId: hackathonId),
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

class _DashboardContent extends ConsumerWidget {
  final String hackathonId;
  const _DashboardContent({required this.hackathonId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(adminDashboardProvider(hackathonId));

    return dashboardAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) {
        if (err.toString().contains('404')) {
          return _buildFallbackDashboard(context, ref);
        }
        return Center(child: Text('Ошибка загрузки дашборда: $err'));
      },
      data: (dashboard) => _buildDashboard(context, dashboard),
    );
  }

  Widget _buildFallbackDashboard(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Дашборд администратора находится в разработке. Используйте меню для навигации.',
                    style: TextStyle(color: colorScheme.secondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildQuickActionsGrid(context),
        ],
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, AdminDashboard dashboard) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Actions Section
          _buildQuickActionsGrid(context),

          const SizedBox(height: 32),

          // Leaderboard and Progress Section
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Топ команд',
                              style: theme.textTheme.headlineMedium,
                            ),
                            TextButton(
                              onPressed: () => context.go('/admin/results'),
                              child: const Text('Все результаты'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        dashboard.leaderboardTop.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: Text(
                                    'Нет данных',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ),
                              )
                            : LeaderboardTable(
                                entries: dashboard.leaderboardTop,
                                compact: true,
                              ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Прогресс экспертов',
                          style: theme.textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 16),
                        if (dashboard.expertsProgress.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Text(
                                'Нет экспертов',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[500],
                                ),
                              ),
                            ),
                          )
                        else
                          Column(
                            children: dashboard.expertsProgress.map((expert) {
                              final progress = expert.totalAssigned > 0
                                  ? expert.submitted / expert.totalAssigned
                                  : 0.0;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          expert.expertName,
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                        Text(
                                          '${expert.submitted}/${expert.totalAssigned}',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: LinearProgressIndicator(
                                        value: progress,
                                        backgroundColor: Colors.grey[200],
                                        color: colorScheme.primary,
                                        minHeight: 6,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Быстрые действия',
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 5,
          childAspectRatio: 1.2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildQuickActionCard(
              context,
              icon: Icons.groups_outlined,
              title: 'Команды',
              subtitle: 'Управление командами',
              color: colorScheme.primary,
              onTap: () => context.go('/admin/teams'),
            ),
            _buildQuickActionCard(
              context,
              icon: Icons.people_outline,
              title: 'Пользователи',
              subtitle: 'Управление пользователями',
              color: colorScheme.secondary,
              onTap: () => context.go('/admin/users'),
            ),
            _buildQuickActionCard(
              context,
              icon: Icons.rule_outlined,
              title: 'Критерии',
              subtitle: 'Настройка критериев оценки',
              color: Colors.blue,
              onTap: () => context.go('/admin/criteria'),
            ),
            _buildQuickActionCard(
              context,
              icon: Icons.assignment_outlined,
              title: 'Назначения',
              subtitle: 'Назначение экспертов',
              color: Colors.purple,
              onTap: () => context.go('/admin/assignments'),
            ),
            _buildQuickActionCard(
              context,
              icon: Icons.leaderboard_outlined,
              title: 'Результаты',
              subtitle: 'Просмотр и публикация',
              color: Colors.orange,
              onTap: () => context.go('/admin/results'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 2,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClickableKpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ClickableKpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
