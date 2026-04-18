import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/hackathon_provider.dart';
import '../../widgets/score_input.dart';
import '../../services/api/api_service.dart';
import '../../models/evaluation.dart';

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
  bool _isLoading = true;
  bool _isSubmitting = false;
  MyEvaluation? _evaluation;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEvaluation();
  }

  Future<void> _loadEvaluation() async {
    final hackathonId = ref.read(hackathonIdProvider).valueOrNull;
    final apiService = ref.read(apiServiceProvider);

    if (hackathonId == null || hackathonId.isEmpty) {
      setState(() {
        _error = 'Нет активного хакатона';
        _isLoading = false;
      });
      return;
    }

    try {
      final evaluation =
          await apiService.getMyEvaluation(hackathonId, widget.teamId);
      setState(() {
        _evaluation = evaluation;
        for (var c in evaluation.criteria) {
          _scores[c.criterionId] = c.rawScore ?? 0;
          _comments[c.criterionId] = c.comment ?? '';
        }
        _overallComment = evaluation.overallComment ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Ошибка загрузки: $e';
        _isLoading = false;
      });
    }
  }

  int get _filledCount => _scores.values.where((s) => s > 0).length;
  int get _totalCount => _evaluation?.criteria.length ?? 0;

  Future<void> _saveDraft() async {
    final hackathonId = ref.read(hackathonIdProvider).valueOrNull;
    final apiService = ref.read(apiServiceProvider);
    if (hackathonId == null) return;

    setState(() => _isSubmitting = true);
    try {
      final items = _scores.entries
          .map((e) => {
                'criterion_id': e.key,
                'raw_score': e.value,
                'comment': _comments[e.key] ?? '',
              })
          .toList();

      await apiService.saveEvaluationDraft(hackathonId, widget.teamId, {
        'items': items,
        'overall_comment': _overallComment,
      });

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Черновик сохранён')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submit() async {
    final hackathonId = ref.read(hackathonIdProvider).valueOrNull;
    final apiService = ref.read(apiServiceProvider);
    if (hackathonId == null) return;

    if (_scores.values.any((s) => s == 0)) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Не все критерии оценены'),
          content: const Text('Оцените все критерии перед отправкой'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'))
          ],
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final items = _scores.entries
          .map((e) => {
                'criterion_id': e.key,
                'raw_score': e.value,
                'comment': _comments[e.key] ?? '',
              })
          .toList();

      await apiService.submitEvaluation(hackathonId, widget.teamId, {
        'items': items,
        'overall_comment': _overallComment,
      });

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Оценка отправлена')));
        context.go('/expert/teams');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Оценка')),
        body: Center(child: Text(_error!)),
      );
    }

    final team = _evaluation!.team;
    final criteria = _evaluation!.criteria;
    final isSubmitted = _evaluation!.status == 'submitted';

    return Scaffold(
      appBar: AppBar(
        title: Text('Оценка: ${team['name'] ?? widget.teamId}'),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '$_filledCount/$_totalCount',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600),
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
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(team['name'] ?? 'Команда',
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 4),
                          Text('Проект: ${team['project_title'] ?? ''}',
                              style: TextStyle(
                                  fontSize: 16, color: Colors.grey[700])),
                          if (team['description'] != null) ...[
                            const SizedBox(height: 8),
                            Text(team['description']!,
                                style: TextStyle(color: Colors.grey[600])),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ...criteria.map((c) => ScoreInput(
                        label: c.title,
                        maxScore: c.maxScore,
                        value: _scores[c.criterionId],
                        onChanged: isSubmitted
                            ? (_) {}
                            : (value) => setState(
                                () => _scores[c.criterionId] = value ?? 0),
                        comment: _comments[c.criterionId],
                        onCommentChanged: isSubmitted
                            ? (_) {}
                            : (value) => _comments[c.criterionId] = value,
                      )),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Общий комментарий',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12),
                          TextField(
                            decoration: const InputDecoration(
                                hintText: 'Общее впечатление о проекте...',
                                border: OutlineInputBorder()),
                            maxLines: 3,
                            controller:
                                TextEditingController(text: _overallComment),
                            onChanged: isSubmitted
                                ? null
                                : (value) => _overallComment = value,
                            enabled: !isSubmitted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isSubmitted)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, -2))
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
                            child: CircularProgressIndicator(strokeWidth: 2))
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
