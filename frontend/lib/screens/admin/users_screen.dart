import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/status_badge.dart';

class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    // Демо-данные пользователей
    final demoUsers = [
      {
        'name': 'Администратор',
        'login': 'admin',
        'role': 'admin',
        'status': 'active'
      },
      {
        'name': 'Иван Петров',
        'login': 'expert1',
        'role': 'expert',
        'status': 'active'
      },
      {
        'name': 'Елена Смирнова',
        'login': 'expert2',
        'role': 'expert',
        'status': 'active'
      },
      {
        'name': 'ByteForce',
        'login': 'team1',
        'role': 'team',
        'status': 'active'
      },
      {
        'name': 'CodeMasters',
        'login': 'team2',
        'role': 'team',
        'status': 'inactive'
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Пользователи'),
        actions: [
          IconButton(
            onPressed: () => _showCreateUserDialog(context),
            icon: const Icon(Icons.person_add),
            tooltip: 'Создать пользователя',
          ),
        ],
      ),
      drawer: AppDrawer(
        role: user!.role,
        currentRoute: '/admin/users',
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Search and filter
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Поиск по имени или логину...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  hint: const Text('Роль'),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Все')),
                    DropdownMenuItem(
                        value: 'admin', child: Text('Администратор')),
                    DropdownMenuItem(value: 'expert', child: Text('Эксперт')),
                    DropdownMenuItem(value: 'team', child: Text('Команда')),
                  ],
                  onChanged: (_) {},
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Users table
            Expanded(
              child: Card(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('ФИО')),
                      DataColumn(label: Text('Логин')),
                      DataColumn(label: Text('Роль')),
                      DataColumn(label: Text('Статус')),
                      DataColumn(label: Text('Действия')),
                    ],
                    rows: demoUsers
                        .map((u) => DataRow(
                              cells: [
                                DataCell(Text(u['name']!)),
                                DataCell(Text(u['login']!)),
                                DataCell(Text(u['role']!)),
                                DataCell(StatusBadge(status: u['status']!)),
                                DataCell(Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 18),
                                      onPressed: () {},
                                      tooltip: 'Редактировать',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.lock_reset,
                                          size: 18),
                                      onPressed: () {},
                                      tooltip: 'Сбросить пароль',
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        u['status'] == 'active'
                                            ? Icons.block
                                            : Icons.check_circle,
                                        size: 18,
                                        color: u['status'] == 'active'
                                            ? Colors.red
                                            : Colors.green,
                                      ),
                                      onPressed: () {},
                                      tooltip: u['status'] == 'active'
                                          ? 'Деактивировать'
                                          : 'Активировать',
                                    ),
                                  ],
                                )),
                              ],
                            ))
                        .toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateUserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Создать пользователя'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'ФИО',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Логин',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Роль',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'admin', child: Text('Администратор')),
                  DropdownMenuItem(value: 'expert', child: Text('Эксперт')),
                  DropdownMenuItem(value: 'team', child: Text('Команда')),
                ],
                onChanged: (_) {},
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
              // Создание пользователя
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Пользователь создан (демо)')),
              );
            },
            child: const Text('Создать'),
          ),
        ],
      ),
    );
  }
}
