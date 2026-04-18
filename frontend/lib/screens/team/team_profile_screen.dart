import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/timer_widget.dart';
import '../../widgets/status_badge.dart';

class TeamProfileScreen extends ConsumerStatefulWidget {
  const TeamProfileScreen({super.key});

  @override
  ConsumerState<TeamProfileScreen> createState() => _TeamProfileScreenState();
}

class _TeamProfileScreenState extends ConsumerState<TeamProfileScreen> {
  final List<Map<String, String>> _members = [
    {'name': 'Алексей Ковалев', 'role': 'Капитан', 'email': 'alex@mail.com'},
    {
      'name': 'Мария Смирнова',
      'role': 'Разработчик',
      'email': 'maria@mail.com'
    },
    {'name': 'Иван Петров', 'role': 'Дизайнер', 'email': 'ivan@mail.com'},
    {'name': 'Елена Сидорова', 'role': 'Аналитик', 'email': 'elena@mail.com'},
  ];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль команды'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TimerWidget(
              deadlineAt: DateTime.now().add(const Duration(hours: 5)),
              label: 'До конца хакатона',
            ),
          ),
        ],
      ),
      drawer: AppDrawer(
        role: user!.role,
        currentRoute: '/team',
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Team Header Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.groups_outlined,
                              size: 32,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'ByteForce',
                                      style: theme.textTheme.headlineMedium,
                                    ),
                                    const SizedBox(width: 12),
                                    StatusBadge(status: 'in_progress'),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Проект: Smart Judge',
                                  style: theme.textTheme.titleLarge,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Платформа автоматизации оценки хакатонов',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.email_outlined,
                              size: 18, color: Colors.grey[500]),
                          const SizedBox(width: 8),
                          Text('byteforce@mail.com',
                              style: TextStyle(color: Colors.grey[600])),
                          const SizedBox(width: 24),
                          Icon(Icons.phone_outlined,
                              size: 18, color: Colors.grey[500]),
                          const SizedBox(width: 8),
                          Text('+7 (999) 000-11-22',
                              style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Members Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Состав команды',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_members.length} участников',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _members.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final member = _members[index];
                          final isCaptain = member['role'] == 'Капитан';
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isCaptain
                                  ? colorScheme.primary.withOpacity(0.1)
                                  : Colors.grey[200],
                              child: Text(
                                member['name']![0],
                                style: TextStyle(
                                  color: isCaptain
                                      ? colorScheme.primary
                                      : Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            title: Text(
                              member['name']!,
                              style: TextStyle(
                                fontWeight: isCaptain
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(member['email']!),
                            trailing: isCaptain
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          colorScheme.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      member['role']!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  )
                                : Text(
                                    member['role']!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Evaluation Status Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Статус оценивания',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.rate_review,
                                size: 32, color: Colors.orange),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Оценка в процессе',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Эксперты оценивают ваш проект. Оценено: 2/3',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: 2 / 3,
                                    backgroundColor: Colors.grey[200],
                                    color: Colors.orange,
                                    minHeight: 6,
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
              ),
              const SizedBox(height: 24),

              // Quick Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Редактировать'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.people_outline, size: 18),
                      label: const Text('Пригласить'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
