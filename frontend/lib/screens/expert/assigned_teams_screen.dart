import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/status_badge.dart';

class AssignedTeamsScreen extends ConsumerWidget {
  const AssignedTeamsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    final List<Map<String, Object>> teams = [
      {
        'name': 'ByteForce',
        'project': 'Smart Judge',
        'status': 'draft',
        'progress': 0.4
      },
      {
        'name': 'CodeMasters',
        'project': 'HackRank AI',
        'status': 'submitted',
        'progress': 1.0
      },
      {
        'name': 'InnovateX',
        'project': 'GreenTech',
        'status': 'not_started',
        'progress': 0.0
      },
      {
        'name': 'DataWizards',
        'project': 'Analytics Pro',
        'status': 'draft',
        'progress': 0.7
      },
      {
        'name': 'AIBrains',
        'project': 'Neural Mind',
        'status': 'draft',
        'progress': 0.2
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Назначенные команды'),
      ),
      drawer: AppDrawer(
        role: user!.role,
        currentRoute: '/expert/teams',
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Поиск по названию...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  hint: const Text('Статус'),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Все')),
                    DropdownMenuItem(value: 'draft', child: Text('Черновик')),
                    DropdownMenuItem(
                        value: 'submitted', child: Text('Отправлено')),
                    DropdownMenuItem(
                        value: 'not_started', child: Text('Не начато')),
                  ],
                  onChanged: (_) {},
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 350,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: teams.length,
                itemBuilder: (context, index) {
                  final team = teams[index];
                  final name = team['name'] as String;
                  final project = team['project'] as String;
                  final status = team['status'] as String;
                  final progress = team['progress'] as double;

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              StatusBadge(status: status),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            project,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const Spacer(),
                          LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.grey[200],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                context.go('/expert/evaluate/$name');
                              },
                              child: Text(status == 'submitted'
                                  ? 'Просмотреть'
                                  : 'Оценить'),
                            ),
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
