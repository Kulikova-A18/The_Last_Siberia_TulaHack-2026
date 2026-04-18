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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Результаты'),
        actions: [
          TextButton.icon(
            onPressed: () async {
              final hackathonId = hackathonIdAsync.valueOrNull;
              if (hackathonId != null && hackathonId.isNotEmpty) {
                try {
                  await apiService.recalculateResults(hackathonId);
                  ref.invalidate(leaderboardProvider(hackathonId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Результаты пересчитаны')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка: $e')),
                  );
                }
              }
            },
            icon: Icon(Icons.refresh_outlined, color: colorScheme.secondary),
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
                    const SnackBar(content: Text('Результаты опубликованы')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.publish_outlined),
            label: const Text('Опубликовать'),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Экспорт будет реализован')),
              );
            },
            icon: Icon(Icons.download_outlined, color: colorScheme.secondary),
            tooltip: 'Экспорт в CSV',
          ),
        ],
      ),
      drawer: AppDrawer(
        role: user?.role ?? UserRole.admin,
        currentRoute: '/admin/results',
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
        child: hackathonIdAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Ошибка: $err')),
          data: (hackathonId) => hackathonId.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.leaderboard_outlined,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('Нет активного хакатона',
                          style: theme.textTheme.bodyLarge),
                    ],
                  ),
                )
              : _ResultsContent(hackathonId: hackathonId),
        ),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                Text('Итоговый рейтинг', style: theme.textTheme.headlineMedium),
                const SizedBox(width: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: data.published
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        data.published
                            ? Icons.public_outlined
                            : Icons.lock_outline,
                        size: 16,
                        color: data.published ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        data.published ? 'Опубликован' : 'Не опубликован',
                        style: TextStyle(
                          color: data.published
                              ? Colors.green[700]
                              : Colors.orange[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (data.updatedAt != null)
                  Text(
                    'Обновлено: ${_formatDateTime(data.updatedAt!)}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.grey[500]),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: data.items.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.leaderboard_outlined,
                                  size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text('Нет данных для отображения',
                                  style: theme.textTheme.bodyLarge),
                            ],
                          ),
                        )
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
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
