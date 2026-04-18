import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/hackathon_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../services/api/api_service.dart';
import '../../models/user.dart';
import '../../models/criterion.dart';

class CriteriaScreen extends ConsumerStatefulWidget {
  const CriteriaScreen({super.key});

  @override
  ConsumerState<CriteriaScreen> createState() => _CriteriaScreenState();
}

class _CriteriaScreenState extends ConsumerState<CriteriaScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final hackathonIdAsync = ref.watch(hackathonIdProvider);
    final apiService = ref.watch(apiServiceProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Критерии оценки'),
        actions: [
          IconButton(
            onPressed: () => _showCreateCriterionDialog(context, apiService),
            icon: Icon(Icons.add_outlined, color: colorScheme.secondary),
            tooltip: 'Добавить критерий',
          ),
        ],
      ),
      drawer: AppDrawer(
        role: user?.role ?? UserRole.admin,
        currentRoute: '/admin/criteria',
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
        child: hackathonIdAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Ошибка: $err')),
          data: (hackathonId) => hackathonId.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.rule_outlined,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('Нет активного хакатона',
                          style: theme.textTheme.bodyLarge),
                    ],
                  ),
                )
              : _CriteriaContent(hackathonId: hackathonId),
        ),
      ),
    );
  }

  void _showCreateCriterionDialog(BuildContext context, ApiService apiService) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final maxScoreController = TextEditingController(text: '10');
    final weightController = TextEditingController(text: '0');
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Новый критерий'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: SizedBox(
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Название',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: InputDecoration(
                  labelText: 'Описание',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: maxScoreController,
                      decoration: InputDecoration(
                        labelText: 'Макс. балл',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: weightController,
                      decoration: InputDecoration(
                        labelText: 'Вес (%)',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
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
                const SnackBar(
                    content: Text('Создание критерия будет реализовано')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Создать'),
          ),
        ],
      ),
    );
  }
}

class _CriteriaContent extends ConsumerWidget {
  final String hackathonId;
  const _CriteriaContent({required this.hackathonId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final criteriaAsync = ref.watch(criteriaProvider(hackathonId));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return criteriaAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Ошибка: $err')),
      data: (data) {
        final isValid = data.weightsValid;
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isValid
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: isValid ? Colors.green : Colors.red, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isValid
                          ? Icons.check_circle_outline
                          : Icons.error_outline,
                      color: isValid ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Сумма весов: ${data.totalWeight.toStringAsFixed(0)}% ${isValid ? '' : '(должно быть 100%)'}',
                      style: TextStyle(
                        color: isValid ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: data.items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.rule_outlined,
                                size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text('Нет критериев. Добавьте критерии.',
                                style: theme.textTheme.bodyLarge),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: data.items.length,
                        itemBuilder: (context, index) {
                          final c = data.items[index];
                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _showEditCriterionDialog(
                                  context, ref, hackathonId, c),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${c.sortOrder}',
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                c.title,
                                                style: theme
                                                    .textTheme.titleMedium
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color: c.isActive
                                                      ? null
                                                      : Colors.grey,
                                                ),
                                              ),
                                              if (!c.isActive) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[200],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                  ),
                                                  child: const Text(
                                                    'Неактивен',
                                                    style:
                                                        TextStyle(fontSize: 10),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          if (c.description != null) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              c.description!,
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
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
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  'Макс: ${c.maxScore}',
                                                  style: const TextStyle(
                                                      fontSize: 12),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: colorScheme.primary
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  'Вес: ${c.weightPercent}%',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: colorScheme.primary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.chevron_right,
                                        color: Colors.grey[400]),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditCriterionDialog(
    BuildContext context,
    WidgetRef ref,
    String hackathonId,
    Criterion criterion,
  ) {
    final titleController = TextEditingController(text: criterion.title);
    final descController = TextEditingController(text: criterion.description);
    final maxScoreController =
        TextEditingController(text: criterion.maxScore.toString());
    final weightController =
        TextEditingController(text: criterion.weightPercent.toString());
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редактировать критерий'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: SizedBox(
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Название',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: InputDecoration(
                  labelText: 'Описание',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: maxScoreController,
                      decoration: InputDecoration(
                        labelText: 'Макс. балл',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: weightController,
                      decoration: InputDecoration(
                        labelText: 'Вес (%)',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
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
                const SnackBar(
                    content: Text('Редактирование будет реализовано')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }
}
