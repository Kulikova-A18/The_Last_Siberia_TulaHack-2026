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
  int _activeTab = 0;

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
  double get _overallProgress =>
      _totalCount > 0 ? _filledCount / _totalCount : 0;

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Черновик сохранён'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
        );
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK')),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Оценка отправлена'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/expert/teams');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Прогресс оценки',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _overallProgress,
                              backgroundColor: Colors.grey[200],
                              color: _overallProgress == 1.0
                                  ? Colors.green
                                  : colorScheme.primary,
                              minHeight: 6,
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
                        color: _overallProgress == 1.0
                            ? Colors.green.withOpacity(0.1)
                            : colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$_filledCount/$_totalCount',
                        style: TextStyle(
                          color: _overallProgress == 1.0
                              ? Colors.green
                              : colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Team Info Card
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.groups_outlined,
                                    color: colorScheme.primary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        team['name'] ?? 'Команда',
                                        style: theme.textTheme.titleLarge,
                                      ),
                                      Text(
                                        'Проект: ${team['project_title'] ?? ''}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSubmitted)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check_circle,
                                            size: 14, color: Colors.green),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Отправлено',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.green[700],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            if (team['description'] != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  team['description']!,
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Criteria Tabs
                    if (criteria.length > 3)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            _buildTab(0, 'Критерии', criteria.length),
                            const SizedBox(width: 8),
                            _buildTab(1, 'Общий комментарий', null),
                          ],
                        ),
                      ),

                    // Criteria Content
                    if (_activeTab == 0)
                      ...criteria.map((c) => ScoreInput(
                            label: c.title,
                            description: null,
                            maxScore: c.maxScore,
                            value: _scores[c.criterionId],
                            onChanged: isSubmitted
                                ? (_) {}
                                : (value) => setState(
                                    () => _scores[c.criterionId] = value ?? 0),
                            comment: _comments[c.criterionId],
                            onCommentChanged: isSubmitted
                                ? null
                                : (value) => _comments[c.criterionId] = value,
                          ))
                    else
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
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
                                decoration: InputDecoration(
                                  hintText: 'Общее впечатление о проекте...',
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                maxLines: 5,
                                controller: TextEditingController(
                                    text: _overallComment),
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

            // Bottom Action Bar
            if (!isSubmitted)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _isSubmitting ? null : _saveDraft,
                      icon: const Icon(Icons.save_outlined, size: 18),
                      label: const Text('Сохранить черновик'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _submit,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_outlined, size: 18),
                      label: const Text('Отправить оценку'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(int index, String label, int? count) {
    final isSelected = _activeTab == index;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (count != null && !isSelected) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
