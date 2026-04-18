import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_drawer.dart';

class TeamResultScreen extends ConsumerWidget {
  const TeamResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Результаты'),
      ),
      drawer: AppDrawer(
        role: user!.role,
        currentRoute: '/team/results',
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Result header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.amber, width: 2),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'МЕСТО',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '2',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ByteForce',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Итоговый балл: 87.3',
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.check_circle,
                                        size: 16, color: Colors.green),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Результаты опубликованы',
                                      style: TextStyle(
                                          color: Colors.green[700],
                                          fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Criteria breakdown
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Оценки по критериям',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    DataTable(
                      columns: const [
                        DataColumn(label: Text('Критерий')),
                        DataColumn(label: Text('Вес')),
                        DataColumn(label: Text('Средний балл')),
                        DataColumn(label: Text('Взвешенный балл')),
                      ],
                      rows: [
                        _buildCriterionRow('Инновационность', 25, 8.7, 21.75),
                        _buildCriterionRow(
                            'Техническая реализация', 25, 8.2, 20.50),
                        _buildCriterionRow('Бизнес-ценность', 25, 9.1, 22.75),
                        _buildCriterionRow('Презентация', 25, 8.9, 22.25),
                      ],
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text(
                            'ИТОГО:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '87.25',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Experts comments
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Комментарии экспертов',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const CircleAvatar(child: Text('ИП')),
                      title: const Text('Иван Петров'),
                      subtitle: const Text(
                          'Отличный проект, хорошая проработка идеи. Рекомендую усилить презентацию.'),
                      trailing: Text(
                        '85.0',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const CircleAvatar(child: Text('ЕС')),
                      title: const Text('Елена Смирнова'),
                      subtitle: const Text(
                          'Сильная техническая часть. Инновационный подход к решению проблемы.'),
                      trailing: Text(
                        '89.5',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
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

  DataRow _buildCriterionRow(
      String title, int weight, double avgScore, double weighted) {
    return DataRow(
      cells: [
        DataCell(Text(title)),
        DataCell(Text('$weight%')),
        DataCell(Text('${avgScore.toStringAsFixed(1)} / 10')),
        DataCell(Text(weighted.toStringAsFixed(2))),
      ],
    );
  }
}
