import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/timer_widget.dart';
import '../../widgets/status_badge.dart';

class TeamProfileScreen extends ConsumerWidget {
  const TeamProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

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
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Team header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'ByteForce',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(width: 16),
                        StatusBadge(status: 'in_progress'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Проект: Smart Judge',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Платформа автоматизации оценки хакатонов',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.email, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text('byteforce@mail.com',
                            style: TextStyle(color: Colors.grey[600])),
                        const SizedBox(width: 24),
                        const Icon(Icons.phone, size: 16, color: Colors.grey),
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

            // Members
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Состав команды',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 4,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final members = [
                          {
                            'name': 'Алексей Ковалев',
                            'role': 'Капитан',
                            'email': 'alex@mail.com'
                          },
                          {
                            'name': 'Мария Смирнова',
                            'role': 'Разработчик',
                            'email': 'maria@mail.com'
                          },
                          {
                            'name': 'Иван Петров',
                            'role': 'Дизайнер',
                            'email': 'ivan@mail.com'
                          },
                          {
                            'name': 'Елена Сидорова',
                            'role': 'Аналитик',
                            'email': 'elena@mail.com'
                          },
                        ];
                        final member = members[index];
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(member['name']![0]),
                          ),
                          title: Text(member['name']!),
                          subtitle: Text(member['email']!),
                          trailing: member['role'] == 'Капитан'
                              ? Chip(label: Text(member['role']!))
                              : Text(member['role']!),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Статус оценивания',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.rate_review,
                              size: 32, color: Colors.orange),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Оценка в процессе',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Эксперты оценивают ваш проект. Оценено: 2/3',
                                style: TextStyle(color: Colors.grey[600]),
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
          ],
        ),
      ),
    );
  }
}
