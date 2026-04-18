import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_drawer.dart';

class AssignmentsScreen extends ConsumerStatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  ConsumerState<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends ConsumerState<AssignmentsScreen> {
  final List<Map<String, dynamic>> _experts = [
    {
      'id': 'e1',
      'name': 'Иван Петров',
      'teams': ['ByteForce', 'CodeMasters', 'InnovateX']
    },
    {
      'id': 'e2',
      'name': 'Елена Смирнова',
      'teams': ['ByteForce', 'DataWizards']
    },
    {
      'id': 'e3',
      'name': 'Алексей Иванов',
      'teams': ['CodeMasters', 'InnovateX']
    },
  ];

  final List<String> _allTeams = [
    'ByteForce',
    'CodeMasters',
    'InnovateX',
    'DataWizards',
    'AIBrains',
  ];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Назначения экспертов'),
        actions: [
          IconButton(
            onPressed: _showBulkAssignDialog,
            icon: const Icon(Icons.assignment_add),
            tooltip: 'Массовое назначение',
          ),
        ],
      ),
      drawer: AppDrawer(
        role: user!.role,
        currentRoute: '/admin/assignments',
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Эксперты и назначенные команды',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: _experts.length,
                itemBuilder: (context, index) {
                  final expert = _experts[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                expert['name'],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                '${(expert['teams'] as List).length} команд',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: () => _assignTeam(expert),
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Назначить'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                (expert['teams'] as List).map<Widget>((team) {
                              return Chip(
                                label: Text(team),
                                onDeleted: () {
                                  setState(() {
                                    expert['teams'].remove(team);
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          if ((expert['teams'] as List).isEmpty)
                            Text(
                              'Нет назначенных команд',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey[500],
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

  void _assignTeam(Map<String, dynamic> expert) {
    final availableTeams =
        _allTeams.where((t) => !(expert['teams'] as List).contains(t)).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Назначить команду — ${expert['name']}'),
        content: SizedBox(
          width: 300,
          child: availableTeams.isEmpty
              ? const Text('Все команды уже назначены')
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: availableTeams
                      .map((team) => ListTile(
                            title: Text(team),
                            onTap: () {
                              setState(() {
                                expert['teams'].add(team);
                              });
                              Navigator.pop(context);
                            },
                          ))
                      .toList(),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );
  }

  void _showBulkAssignDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Массовое назначение'),
        content: const SizedBox(
          width: 400,
          child: Text('Функция массового назначения (демо)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Назначения сохранены (демо)')),
              );
            },
            child: const Text('Применить'),
          ),
        ],
      ),
    );
  }
}
