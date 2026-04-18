import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/kpi_card.dart';
import '../../widgets/timer_widget.dart';
import '../../widgets/status_badge.dart';

class ExpertDashboardScreen extends ConsumerWidget {
  const ExpertDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Дашборд эксперта'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TimerWidget(
              deadlineAt: DateTime.now().add(const Duration(hours: 5)),
              label: 'Дедлайн',
            ),
          ),
        ],
      ),
      drawer: AppDrawer(
        role: user!.role,
        currentRoute: '/expert',
      ),
      body: Padding(
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
                    value: '8',
                    icon: Icons.assignment,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: KpiCard(
                    title: 'Оценено',
                    value: '5',
                    icon: Icons.check_circle,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: KpiCard(
                    title: 'Осталось',
                    value: '3',
                    icon: Icons.pending,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Assigned teams
            Text(
              'Назначенные команды',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: 5,
                itemBuilder: (context, index) {
                  final teams = [
                    {
                      'name': 'ByteForce',
                      'project': 'Smart Judge',
                      'status': 'draft'
                    },
                    {
                      'name': 'CodeMasters',
                      'project': 'HackRank AI',
                      'status': 'submitted'
                    },
                    {
                      'name': 'InnovateX',
                      'project': 'GreenTech',
                      'status': 'not_started'
                    },
                    {
                      'name': 'DataWizards',
                      'project': 'Analytics Pro',
                      'status': 'in_progress'
                    },
                    {
                      'name': 'AIBrains',
                      'project': 'Neural Mind',
                      'status': 'draft'
                    },
                  ];
                  final team = teams[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        child: Text('${index + 1}'),
                      ),
                      title: Text(
                        team['name']!,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(team['project']!),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          StatusBadge(status: team['status']!),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () {
                              context.go('/expert/evaluate/${team['name']}');
                            },
                            child: Text(team['status'] == 'submitted'
                                ? 'Просмотр'
                                : 'Оценить'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
