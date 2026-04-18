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
    if (entries.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('Нет данных для отображения'),
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
            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
          ),
          children: [
            _HeaderCell('Место'),
            _HeaderCell('Команда'),
            _HeaderCell('Баллы', alignment: Alignment.centerRight),
          ],
        ),
        ...entries.map((entry) => TableRow(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
              ),
              children: [
                _PlaceCell(place: entry.place, showMedal: showMedals),
                TableCell(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 8 : 16,
                      vertical: compact ? 8 : 12,
                    ),
                    child: Text(
                      entry.teamName,
                      style: TextStyle(
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
                      horizontal: compact ? 8 : 16,
                      vertical: compact ? 8 : 12,
                    ),
                    child: Text(
                      entry.finalScore.toStringAsFixed(1),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontFeatures: [FontFeature.tabularFigures()],
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
    return TableCell(
      child: Container(
        alignment: alignment,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
            fontSize: 12,
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
    Widget child;
    if (showMedal && place <= 3) {
      final colors = [
        const Color(0xFFFFD700), // Gold
        const Color(0xFFC0C0C0), // Silver
        const Color(0xFFCD7F32), // Bronze
      ];
      child = Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors[place - 1].withOpacity(0.2),
          border: Border.all(color: colors[place - 1]),
        ),
        child: Center(
          child: Text(
            '$place',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colors[place - 1],
            ),
          ),
        ),
      );
    } else {
      child = Text(
        '$place',
        style: const TextStyle(fontWeight: FontWeight.w500),
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
