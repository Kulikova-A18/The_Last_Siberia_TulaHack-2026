import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_drawer.dart';

class CriteriaScreen extends ConsumerStatefulWidget {
  const CriteriaScreen({super.key});

  @override
  ConsumerState<CriteriaScreen> createState() => _CriteriaScreenState();
}

class _CriteriaScreenState extends ConsumerState<CriteriaScreen> {
  final List<Map<String, dynamic>> _criteria = [
    {
      'id': '1',
      'title': 'Инновационность',
      'description': 'Новизна и оригинальность идеи',
      'maxScore': 10.0,
      'weight': 25.0,
      'order': 1,
      'active': true,
    },
    {
      'id': '2',
      'title': 'Техническая реализация',
      'description': 'Качество кода, архитектура',
      'maxScore': 10.0,
      'weight': 25.0,
      'order': 2,
      'active': true,
    },
    {
      'id': '3',
      'title': 'Бизнес-ценность',
      'description': 'Потенциал продукта на рынке',
      'maxScore': 10.0,
      'weight': 25.0,
      'order': 3,
      'active': true,
    },
    {
      'id': '4',
      'title': 'Презентация',
      'description': 'Качество выступления и демо',
      'maxScore': 10.0,
      'weight': 25.0,
      'order': 4,
      'active': true,
    },
  ];

  double get _totalWeight =>
      _criteria.fold(0, (sum, c) => sum + (c['weight'] as num));

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isValid = _totalWeight == 100.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Критерии оценки'),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isValid
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isValid ? Colors.green : Colors.red,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isValid ? Icons.check_circle : Icons.error,
                  color: isValid ? Colors.green : Colors.red,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Сумма весов: ${_totalWeight.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: isValid ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: _addCriterion,
            icon: const Icon(Icons.add),
            tooltip: 'Добавить критерий',
          ),
        ],
      ),
      drawer: AppDrawer(
        role: user!.role,
        currentRoute: '/admin/criteria',
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            if (!isValid)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.red),
                    const SizedBox(width: 12),
                    Text(
                      'Сумма весов должна быть ровно 100%',
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ReorderableListView(
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex--;
                    final item = _criteria.removeAt(oldIndex);
                    _criteria.insert(newIndex, item);
                    _updateOrder();
                  });
                },
                children: _criteria
                    .map((criterion) => _CriterionCard(
                          key: ValueKey(criterion['id']),
                          criterion: criterion,
                          onEdit: () => _editCriterion(criterion),
                          onDelete: () => _deleteCriterion(criterion['id']),
                          onToggleActive: () => _toggleActive(criterion['id']),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateOrder() {
    for (var i = 0; i < _criteria.length; i++) {
      _criteria[i]['order'] = i + 1;
    }
  }

  void _addCriterion() {
    showDialog(
      context: context,
      builder: (context) => _CriterionDialog(
        onSave: (data) {
          setState(() {
            _criteria.add({
              'id': DateTime.now().millisecondsSinceEpoch.toString(),
              ...data,
              'order': _criteria.length + 1,
              'active': true,
            });
          });
        },
      ),
    );
  }

  void _editCriterion(Map<String, dynamic> criterion) {
    showDialog(
      context: context,
      builder: (context) => _CriterionDialog(
        criterion: criterion,
        onSave: (data) {
          setState(() {
            criterion['title'] = data['title'];
            criterion['description'] = data['description'];
            criterion['maxScore'] = data['maxScore'];
            criterion['weight'] = data['weight'];
          });
        },
      ),
    );
  }

  void _deleteCriterion(String id) {
    setState(() {
      _criteria.removeWhere((c) => c['id'] == id);
      _updateOrder();
    });
  }

  void _toggleActive(String id) {
    setState(() {
      final criterion = _criteria.firstWhere((c) => c['id'] == id);
      criterion['active'] = !criterion['active'];
    });
  }
}

class _CriterionCard extends StatelessWidget {
  final Map<String, dynamic> criterion;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleActive;

  const _CriterionCard({
    super.key,
    required this.criterion,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '${criterion['order']}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              criterion['title'],
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: criterion['active'] ? null : Colors.grey,
              ),
            ),
            if (!criterion['active'])
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Неактивен',
                  style: TextStyle(fontSize: 10),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (criterion['description'] != null)
              Text(
                criterion['description'],
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Макс: ${criterion['maxScore']}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Вес: ${criterion['weight']}%',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: onEdit,
              tooltip: 'Редактировать',
            ),
            IconButton(
              icon: Icon(
                criterion['active'] ? Icons.visibility_off : Icons.visibility,
                size: 20,
              ),
              onPressed: onToggleActive,
              tooltip: criterion['active'] ? 'Деактивировать' : 'Активировать',
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
              onPressed: onDelete,
              tooltip: 'Удалить',
            ),
          ],
        ),
      ),
    );
  }
}

class _CriterionDialog extends StatefulWidget {
  final Map<String, dynamic>? criterion;
  final Function(Map<String, dynamic>) onSave;

  const _CriterionDialog({this.criterion, required this.onSave});

  @override
  State<_CriterionDialog> createState() => _CriterionDialogState();
}

class _CriterionDialogState extends State<_CriterionDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _maxScoreController;
  late TextEditingController _weightController;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.criterion?['title'] ?? '');
    _descController =
        TextEditingController(text: widget.criterion?['description'] ?? '');
    _maxScoreController = TextEditingController(
        text: widget.criterion?['maxScore']?.toString() ?? '10');
    _weightController = TextEditingController(
        text: widget.criterion?['weight']?.toString() ?? '0');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _maxScoreController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.criterion == null
          ? 'Новый критерий'
          : 'Редактировать критерий'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Название',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Описание',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _maxScoreController,
                    decoration: const InputDecoration(
                      labelText: 'Макс. балл',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    decoration: const InputDecoration(
                      labelText: 'Вес (%)',
                      border: OutlineInputBorder(),
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
            final data = {
              'title': _titleController.text,
              'description': _descController.text,
              'maxScore': double.tryParse(_maxScoreController.text) ?? 10.0,
              'weight': double.tryParse(_weightController.text) ?? 0.0,
            };
            widget.onSave(data);
            Navigator.pop(context);
          },
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}
