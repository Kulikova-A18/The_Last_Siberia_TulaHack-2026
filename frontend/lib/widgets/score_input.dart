import 'package:flutter/material.dart';

class ScoreInput extends StatelessWidget {
  final String label;
  final String? description;
  final double maxScore;
  final double? value;
  final ValueChanged<double?> onChanged;
  final String? comment;
  final ValueChanged<String>? onCommentChanged;

  const ScoreInput({
    super.key,
    required this.label,
    this.description,
    required this.maxScore,
    required this.value,
    required this.onChanged,
    this.comment,
    this.onCommentChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          description!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'из $maxScore',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    initialValue: value?.toString() ?? '',
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    textAlign: TextAlign.center,
                    onChanged: (val) {
                      final parsed = double.tryParse(val);
                      if (parsed != null && parsed >= 0 && parsed <= maxScore) {
                        onChanged(parsed);
                      } else if (val.isEmpty) {
                        onChanged(null);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Slider(
                    value: value ?? 0,
                    min: 0,
                    max: maxScore,
                    divisions: maxScore.toInt(),
                    label: value?.toStringAsFixed(1) ?? '0',
                    activeColor: colorScheme.primary,
                    onChanged: onChanged,
                  ),
                ),
              ],
            ),
            if (onCommentChanged != null) ...[
              const SizedBox(height: 16),
              TextField(
                controller: TextEditingController(text: comment),
                decoration: InputDecoration(
                  hintText: 'Комментарий (опционально)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLines: 2,
                onChanged: onCommentChanged,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
