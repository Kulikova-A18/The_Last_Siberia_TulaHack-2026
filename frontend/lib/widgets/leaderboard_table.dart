import 'package:flutter/material.dart';
import '../models/hackathon.dart';

class LeaderboardTable extends StatelessWidget {
  final List<LeaderboardEntry> entries;
  final bool showMedals;
  final bool compact;

  const LeaderboardTable({
    super.key,
    required this.entries,
    this.showMedals = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Нет данных для отображения',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
        ),
      );
    }

    return Table(
      columnWidths: const {
        0: IntrinsicColumnWidth(),
        1: FlexColumnWidth(),
        2: IntrinsicColumnWidth(),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
          ),
          children: [
            _HeaderCell('Место'),
            _HeaderCell('Команда'),
            _HeaderCell('Баллы', alignment: Alignment.centerRight),
          ],
        ),
        ...entries.map((entry) => TableRow(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
              ),
              children: [
                _PlaceCell(place: entry.place, showMedal: showMedals),
                TableCell(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 12 : 16,
                      vertical: compact ? 10 : 14,
                    ),
                    child: Text(
                      entry.teamName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: entry.place <= 3
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
                TableCell(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 12 : 16,
                      vertical: compact ? 10 : 14,
                    ),
                    child: Text(
                      entry.finalScore.toStringAsFixed(1),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: entry.place <= 3 ? colorScheme.primary : null,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
              ],
            )),
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final Alignment alignment;
  const _HeaderCell(this.text, {this.alignment = Alignment.centerLeft});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TableCell(
      child: Container(
        alignment: alignment,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          text,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }
}

class _PlaceCell extends StatelessWidget {
  final int place;
  final bool showMedal;
  const _PlaceCell({required this.place, required this.showMedal});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget child;

    if (showMedal && place <= 3) {
      final colors = [
        const Color(0xFFE6A817),
        const Color(0xFF9E9E9E),
        const Color(0xFF8D6E63),
      ];
      child = Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors[place - 1].withOpacity(0.15),
          border: Border.all(color: colors[place - 1], width: 1.5),
        ),
        child: Center(
          child: Text(
            '$place',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors[place - 1],
            ),
          ),
        ),
      );
    } else {
      child = Text(
        '$place',
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: Colors.grey[600],
        ),
      );
    }
    return TableCell(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: child,
      ),
    );
  }
}
