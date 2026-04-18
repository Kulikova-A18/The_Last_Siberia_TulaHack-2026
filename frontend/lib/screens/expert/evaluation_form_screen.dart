import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/score_input.dart';

class EvaluationFormScreen extends ConsumerStatefulWidget {
  final String teamId;

  const EvaluationFormScreen({super.key, required this.teamId});

  @override
  ConsumerState<EvaluationFormScreen> createState() =>
      _EvaluationFormScreenState();
}

class _EvaluationFormScreenState extends ConsumerState<EvaluationFormScreen> {
  final Map<String, double> _scores = {};
  final Map<String, String> _comments = {};
  String _overallComment = '';
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _criteria = [
    {'id': '1', 'title': 'Инновационность', 'max': 10.0, 'weight': 25.0},
    {'id': '2', 'title': 'Техническая реализация', 'max': 10.0, 'weight': 25.0},
    {'id': '3', 'title': 'Бизнес-ценность', 'max': 10.0, 'weight': 25.0},
    {'id': '4', 'title': 'Презентация', 'max': 10.0, 'weight': 25.0},
  ];

  @override
  void initState() {
    super.initState();
    // Загружаем демо-черновик
    for (var c in _criteria) {
      _scores[c['id']] = 7.0;
      _comments[c['id']] = '';
    }
  }

  int get _filledCount => _scores.values.where((s) => s > 0).length;

  Future<void> _saveDraft() async {
    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _isSubmitting = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Черновик сохранён')),
      );
    }
  }

  Future<void> _submit() async {
    // Проверка заполненности
    if (_scores.values.any((s) => s == 0)) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Не все критерии оценены'),
          content: const Text('Оцените все критерии перед отправкой'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isSubmitting = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Оценка отправлена')),
      );
      context.go('/expert/teams');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Оценка: ${widget.teamId}'),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '$_filledCount/${_criteria.length}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Team info
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.teamId,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Проект: Smart Judge',
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Платформа автоматизации оценки хакатонов',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Criteria
                  ..._criteria.map((criterion) => ScoreInput(
                        label: criterion['title'],
                        maxScore: criterion['max'],
                        value: _scores[criterion['id']],
                        onChanged: (value) {
                          setState(() {
                            _scores[criterion['id']] = value ?? 0;
                          });
                        },
                        comment: _comments[criterion['id']],
                        onCommentChanged: (value) {
                          _comments[criterion['id']] = value;
                        },
                      )),

                  // Overall comment
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Общий комментарий',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            decoration: const InputDecoration(
                              hintText: 'Общее впечатление о проекте...',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                            onChanged: (value) => _overallComment = value,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: _isSubmitting ? null : _saveDraft,
                  icon: const Icon(Icons.save),
                  label: const Text('Сохранить черновик'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: const Text('Отправить оценку'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
