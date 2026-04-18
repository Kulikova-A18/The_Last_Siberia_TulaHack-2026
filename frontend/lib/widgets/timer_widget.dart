import 'package:flutter/material.dart';
import 'dart:async';

class TimerWidget extends StatefulWidget {
  final DateTime? deadlineAt;
  final String label;

  const TimerWidget({
    super.key,
    this.deadlineAt,
    this.label = 'До дедлайна',
  });

  @override
  State<TimerWidget> createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget> {
  late Timer _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer =
        Timer.periodic(const Duration(seconds: 1), (_) => _updateRemaining());
  }

  @override
  void didUpdateWidget(TimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deadlineAt != widget.deadlineAt) {
      _updateRemaining();
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateRemaining() {
    if (widget.deadlineAt == null) {
      setState(() => _remaining = Duration.zero);
      return;
    }
    final now = DateTime.now();
    final diff = widget.deadlineAt!.difference(now);
    setState(() => _remaining = diff.isNegative ? Duration.zero : diff);
  }

  Color _getColor() {
    final theme = Theme.of(context);
    if (_remaining.inHours < 1) return Colors.red;
    if (_remaining.inHours < 6) return Colors.orange;
    return theme.colorScheme.primary;
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            widget.label,
            style: theme.textTheme.bodySmall?.copyWith(color: color),
          ),
          const SizedBox(width: 8),
          Text(
            _formatDuration(_remaining),
            style: theme.textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
