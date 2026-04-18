import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_drawer.dart';

class TeamResultScreen extends ConsumerStatefulWidget {
  const TeamResultScreen({super.key});

  @override
  ConsumerState<TeamResultScreen> createState() => _TeamResultScreenState();
}

class _TeamResultScreenState extends ConsumerState<TeamResultScreen> {
  final List<Map<String, dynamic>> _criteriaResults = [
    {
      'title': 'Инновационность',
      'weight': 25,
      'avgScore': 8.7,
      'weighted': 21.75
    },
    {
      'title': 'Техническая реализация',
      'weight': 25,
      'avgScore': 8.2,
      'weighted': 20.50
    },
    {
      'title': 'Бизнес-ценность',
      'weight': 25,
      'avgScore': 9.1,
      'weighted': 22.75
    },
    {'title': 'Презентация', 'weight': 25, 'avgScore': 8.9, 'weighted': 22.25},
  ];

  final List<Map<String, dynamic>> _expertComments = [
    {
      'name': 'Иван Петров',
      'score': 85.0,
      'comment':
          'Отличный проект, хорошая проработка идеи. Рекомендую усилить презентацию.',
      'avatar': 'ИП'
    },
    {
      'name': 'Елена Смирнова',
      'score': 89.5,
      'comment':
          'Сильная техническая часть. Инновационный подход к решению проблемы.',
      'avatar': 'ЕС'
    },
    {
      'name': 'Алексей Иванов',
      'score': 87.5,
      'comment':
          'Хорошая командная работа. Проект имеет потенциал для масштабирования.',
      'avatar': 'АИ'
    },
  ];

  double get _totalScore => _criteriaResults.fold(
      0, (sum, item) => sum + (item['weighted'] as double));

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Результаты'),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Экспорт результатов будет реализован')),
              );
            },
            icon: Icon(Icons.download_outlined, color: colorScheme.secondary),
          ),
        ],
      ),
      drawer: AppDrawer(
        role: user!.role,
        currentRoute: '/team/results',
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
              // Result Header Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.amber.shade400,
                              Colors.amber.shade700,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'МЕСТО',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '2',
                              style: const TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
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
                              style: theme.textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        'Итоговый балл',
                                        style: TextStyle(
                                          color: colorScheme.onPrimary,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        _totalScore.toStringAsFixed(1),
                                        style: TextStyle(
                                          color: colorScheme.onPrimary,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
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
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
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
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Criteria Breakdown Card
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
                        'Оценки по критериям',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: MaterialStateProperty.all(
                            Colors.grey[50],
                          ),
                          headingRowHeight: 48,
                          dataRowMinHeight: 56,
                          columnSpacing: 24,
                          columns: const [
                            DataColumn(
                                label: Text('Критерий',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600))),
                            DataColumn(
                                label: Text('Вес',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600))),
                            DataColumn(
                                label: Text('Средний балл',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600))),
                            DataColumn(
                                label: Text('Взвешенный балл',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600))),
                          ],
                          rows: _criteriaResults.map((c) {
                            return DataRow(
                              cells: [
                                DataCell(Text(c['title'])),
                                DataCell(Text('${c['weight']}%')),
                                DataCell(Row(
                                  children: [
                                    Text('${c['avgScore']}'),
                                    const SizedBox(width: 4),
                                    Text(
                                      '/10',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                )),
                                DataCell(
                                  Text(
                                    c['weighted'].toStringAsFixed(2),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                      const Divider(height: 32),
                      Row(
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _totalScore.toStringAsFixed(2),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Experts Comments Card
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
                        'Комментарии экспертов',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      ..._expertComments.map((expert) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
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
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                expert['name'],
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const Spacer(),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  '${expert['score']}',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.blue[700],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            expert['comment'],
                                            style: TextStyle(
                                                color: Colors.grey[600]),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (expert != _expertComments.last)
                                  const Divider(height: 24),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
