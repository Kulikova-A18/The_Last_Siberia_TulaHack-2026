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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Критерии оценки'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () => Scaffold.of(context).openEndDrawer(),
            tooltip: 'Отладка API',
          ),
          IconButton(
            onPressed: () => _showCreateCriterionDialog(context, apiService),
            icon: const Icon(Icons.add),
            tooltip: 'Добавить критерий',
          ),
        ],
      ),
      drawer: AppDrawer(
          role: user?.role ?? UserRole.admin, currentRoute: '/admin/criteria'),
      body: hackathonIdAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Ошибка: $err')),
        data: (hackathonId) => hackathonId.isEmpty
            ? const Center(child: Text('Нет активного хакатона'))
            : _CriteriaContent(hackathonId: hackathonId),
      ),
    );
  }

  void _showCreateCriterionDialog(BuildContext context, ApiService apiService) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final maxScoreController = TextEditingController(text: '10');
    final weightController = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Новый критерий'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                      labelText: 'Название', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                      labelText: 'Описание', border: OutlineInputBorder()),
                  maxLines: 2),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: TextField(
                          controller: maxScoreController,
                          decoration: const InputDecoration(
                              labelText: 'Макс. балл',
                              border: OutlineInputBorder()),
                          keyboardType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: TextField(
                          controller: weightController,
                          decoration: const InputDecoration(
                              labelText: 'Вес (%)',
                              border: OutlineInputBorder()),
                          keyboardType: TextInputType.number)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Создание критерия будет реализовано')));
            },
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
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: isValid ? Colors.green : Colors.red),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isValid ? Icons.check_circle : Icons.error,
                        color: isValid ? Colors.green : Colors.red),
                    const SizedBox(width: 8),
                    Text(
                      'Сумма весов: ${data.totalWeight.toStringAsFixed(0)}% ${isValid ? '' : '(должно быть 100%)'}',
                      style: TextStyle(
                          color: isValid ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: data.items.isEmpty
                    ? const Center(
                        child: Text('Нет критериев. Добавьте критерии.'))
                    : ListView.builder(
                        itemCount: data.items.length,
                        itemBuilder: (context, index) {
                          final c = data.items[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    '${c.sortOrder}',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer),
                                  ),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Text(c.title,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color:
                                              c.isActive ? null : Colors.grey)),
                                  if (!c.isActive)
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                          color: Colors.grey[300],
                                          borderRadius:
                                              BorderRadius.circular(4)),
                                      child: const Text('Неактивен',
                                          style: TextStyle(fontSize: 10)),
                                    ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (c.description != null)
                                    Text(c.description!,
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[600])),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        child: Text('Макс: ${c.maxScore}',
                                            style:
                                                const TextStyle(fontSize: 12)),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                            color:
                                                Colors.green.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        child: Text('Вес: ${c.weightPercent}%',
                                            style:
                                                const TextStyle(fontSize: 12)),
                                      ),
                                    ],
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
        );
      },
    );
  }
}
