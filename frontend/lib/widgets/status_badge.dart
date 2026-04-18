import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  Color _getColor() {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'submitted':
      case 'active':
        return Colors.green;
      case 'in_progress':
      case 'draft':
        return Colors.orange;
      case 'not_started':
        return Colors.grey;
      case 'finished':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getLabel() {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Завершено';
      case 'submitted':
        return 'Отправлено';
      case 'active':
        return 'Активно';
      case 'in_progress':
        return 'В процессе';
      case 'draft':
        return 'Черновик';
      case 'not_started':
        return 'Не начато';
      case 'finished':
        return 'Завершён';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        _getLabel(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
