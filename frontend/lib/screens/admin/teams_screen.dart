import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/status_badge.dart';

class TeamsScreen extends ConsumerWidget {
  const TeamsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    // Явно указываем тип Map<String, Object>
    final List<Map<String, Object>> demoteams = [
      {
        'name': 'ByteForce',
        'captain': 'Алексей Ковалев',
        'members': 4,
        'project': 'Smart Judge',
        'status': 'in_progress',
        'score': 83.5,
        'place': 2,
      },
      {
        'name': 'CodeMasters',
        'captain': 'Дмитрий Волков',
        'members': 3,
        'project': 'HackRank AI',
        'status': 'completed',
        'score': 92.5,
        'place': 1,
      },
      {
        'name': 'InnovateX',
        'captain': 'Мария Смирнова',
        'members': 5,
        'project': 'GreenTech',
        'status': 'not_started',
        'score': 0.0,
        'place': Null,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Команды'),
        actions: [
          IconButton(
            onPressed: () => _showCreateTeamDialog(context),
            icon: const Icon(Icons.add),
            tooltip: 'Создать команду',
          ),
        ],
      ),
      drawer: AppDrawer(
        role: user!.role,
        currentRoute: '/admin/teams',
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Поиск по названию или проекту...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Card(
                child: SingleChildScrollView(
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Название')),
                      DataColumn(label: Text('Капитан')),
                      DataColumn(label: Text('Участников')),
                      DataColumn(label: Text('Проект')),
                      DataColumn(label: Text('Статус')),
                      DataColumn(label: Text('Балл')),
                      DataColumn(label: Text('Место')),
                      DataColumn(label: Text('')),
                    ],
                    rows: demoteams.map((t) {
                      // Приведение типов для безопасного доступа
                      final name = t['name'] as String;
                      final captain = t['captain'] as String;
                      final members = t['members'] as int;
                      final project = t['project'] as String;
                      final status = t['status'] as String;
                      final score = t['score'] as double;
                      final place = t['place'] as int?;

                      return DataRow(
                        onSelectChanged: (_) {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) => _TeamDetailsSheet(team: t),
                          );
                        },
                        cells: [
                          DataCell(Text(name)),
                          DataCell(Text(captain)),
                          DataCell(Text('$members')),
                          DataCell(Text(project)),
                          DataCell(StatusBadge(status: status)),
                          DataCell(Text(score.toStringAsFixed(1))),
                          DataCell(Text(place?.toString() ?? '-')),
                          DataCell(IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            onPressed: () {},
                          )),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateTeamDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Создать команду'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Название команды',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Капитан',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Название проекта',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Команда создана (демо)')),
              );
            },
            child: const Text('Создать'),
          ),
        ],
      ),
    );
  }
}

class _TeamDetailsSheet extends StatelessWidget {
  final Map<String, Object> team;

  const _TeamDetailsSheet({required this.team});

  @override
  Widget build(BuildContext context) {
    final name = team['name'] as String;
    final project = team['project'] as String;
    final status = team['status'] as String;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(width: 12),
              StatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            project,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 24),
          const Text('Участники:',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...[
            'Алексей Ковалев (капитан)',
            'Мария Смирнова',
            'Иван Петров',
            'Елена Сидорова'
          ].map(
            (m) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.person, size: 16),
                  const SizedBox(width: 8),
                  Text(m),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Назначенные эксперты:',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...['Иван Петров', 'Елена Смирнова'].map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.person_outline, size: 16),
                  const SizedBox(width: 8),
                  Text(e),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Закрыть'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
