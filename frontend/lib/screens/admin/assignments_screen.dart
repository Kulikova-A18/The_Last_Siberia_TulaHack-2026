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
      'teams': ['ByteForce', 'CodeMasters', 'InnovateX'],
      'avatar': 'ИП',
    },
    {
      'id': 'e2',
      'name': 'Елена Смирнова',
      'teams': ['ByteForce', 'DataWizards'],
      'avatar': 'ЕС',
    },
    {
      'id': 'e3',
      'name': 'Алексей Иванов',
      'teams': ['CodeMasters', 'InnovateX'],
      'avatar': 'АИ',
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Назначения экспертов'),
        actions: [
          IconButton(
            onPressed: _showBulkAssignDialog,
            icon: Icon(Icons.assignment_outlined, color: colorScheme.secondary),
            tooltip: 'Массовое назначение',
          ),
        ],
      ),
      drawer: AppDrawer(
        role: user!.role,
        currentRoute: '/admin/assignments',
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Эксперты и назначенные команды',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Назначьте экспертов для оценки команд',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: _experts.length,
                  itemBuilder: (context, index) {
                    final expert = _experts[index];
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor:
                                      colorScheme.primary.withOpacity(0.1),
                                  child: Text(
                                    expert['avatar'],
                                    style: TextStyle(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        expert['name'],
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '${(expert['teams'] as List).length} команд',
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => _assignTeam(expert),
                                  icon: Icon(Icons.add_outlined, size: 18),
                                  label: const Text('Назначить'),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(
                                        color: colorScheme.primary, width: 1),
                                    foregroundColor: colorScheme.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  (expert['teams'] as List).map<Widget>((team) {
                                return Chip(
                                  label: Text(team),
                                  backgroundColor:
                                      colorScheme.primary.withOpacity(0.1),
                                  deleteIcon: Icon(Icons.close, size: 16),
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
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[500],
                                  fontStyle: FontStyle.italic,
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
      ),
    );
  }

  void _assignTeam(Map<String, dynamic> expert) {
    final availableTeams =
        _allTeams.where((t) => !(expert['teams'] as List).contains(t)).toList();
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Назначить команду — ${expert['name']}'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: SizedBox(
          width: 300,
          child: availableTeams.isEmpty
              ? const Text('Все команды уже назначены')
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: availableTeams
                      .map((team) => ListTile(
                            title: Text(team),
                            leading: CircleAvatar(
                              backgroundColor:
                                  colorScheme.primary.withOpacity(0.1),
                              child: Icon(Icons.groups_outlined,
                                  size: 18, color: colorScheme.primary),
                            ),
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
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Массовое назначение'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: const SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Функция массового назначения экспертов на команды.'),
              SizedBox(height: 16),
              Text('Выберите экспертов и команды для назначения.'),
            ],
          ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Применить'),
          ),
        ],
      ),
    );
  }
}
