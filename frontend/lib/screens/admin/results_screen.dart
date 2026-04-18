import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hackrank_frontend/models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/hackathon_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/leaderboard_table.dart';
import '../../services/api/api_service.dart';

class ResultsScreen extends ConsumerWidget {
  const ResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final hackathonIdAsync = ref.watch(hackathonIdProvider);
    final apiService = ref.watch(apiServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Результаты'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () => Scaffold.of(context).openEndDrawer(),
            tooltip: 'Отладка API',
          ),
          TextButton.icon(
            onPressed: () async {
              final hackathonId = hackathonIdAsync.valueOrNull;
              if (hackathonId != null && hackathonId.isNotEmpty) {
                try {
                  await apiService.recalculateResults(hackathonId);
                  ref.invalidate(leaderboardProvider(hackathonId));
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Результаты пересчитаны')));
                } catch (e) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
                }
              }
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Пересчитать'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () async {
              final hackathonId = hackathonIdAsync.valueOrNull;
              if (hackathonId != null && hackathonId.isNotEmpty) {
                try {
                  await apiService.publishResults(hackathonId);
                  ref.invalidate(leaderboardProvider(hackathonId));
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Результаты опубликованы')));
                } catch (e) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
                }
              }
            },
            icon: const Icon(Icons.publish),
            label: const Text('Опубликовать'),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Экспорт будет реализован')));
            },
            icon: const Icon(Icons.download),
            tooltip: 'Экспорт в CSV',
          ),
        ],
      ),
      drawer: AppDrawer(
          role: user?.role ?? UserRole.admin, currentRoute: '/admin/results'),
      body: hackathonIdAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Ошибка: $err')),
        data: (hackathonId) => hackathonId.isEmpty
            ? const Center(child: Text('Нет активного хакатона'))
            : _ResultsContent(hackathonId: hackathonId),
      ),
    );
  }
}

class _ResultsContent extends ConsumerWidget {
  final String hackathonId;
  const _ResultsContent({required this.hackathonId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboardAsync = ref.watch(leaderboardProvider(hackathonId));

    return leaderboardAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Ошибка: $err')),
      data: (data) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Итоговый рейтинг',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(width: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: data.published
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(data.published ? Icons.public : Icons.lock_outline,
                          size: 16,
                          color: data.published ? Colors.green : Colors.orange),
                      const SizedBox(width: 4),
                      Text(data.published ? 'Опубликован' : 'Не опубликован',
                          style: TextStyle(
                              color: data.published
                                  ? Colors.green[700]
                                  : Colors.orange[700],
                              fontSize: 13)),
                    ],
                  ),
                ),
                const Spacer(),
                if (data.updatedAt != null)
                  Text('Обновлено: ${_formatDateTime(data.updatedAt!)}',
                      style: TextStyle(color: Colors.grey[600])),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: data.items.isEmpty
                      ? const Center(child: Text('Нет данных для отображения'))
                      : LeaderboardTable(entries: data.items),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
