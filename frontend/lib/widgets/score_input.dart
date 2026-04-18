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
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          description!,
                          style: TextStyle(
                            fontSize: 13,
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
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'из $maxScore',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 100,
                  child: TextFormField(
                    initialValue: value?.toString() ?? '',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
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
                    onChanged: onChanged,
                  ),
                ),
              ],
            ),
            if (onCommentChanged != null) ...[
              const SizedBox(height: 12),
              TextField(
                controller: TextEditingController(text: comment),
                decoration: const InputDecoration(
                  hintText: 'Комментарий (опционально)',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
