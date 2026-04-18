import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/hackathon_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/status_badge.dart';
import '../../services/api/api_service.dart';
import '../../models/user.dart';
import '../../models/team.dart';

class TeamsScreen extends ConsumerStatefulWidget {
  const TeamsScreen({super.key});

  @override
  ConsumerState<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends ConsumerState<TeamsScreen> {
  final _searchController = TextEditingController();
  int _page = 1;
  final int _pageSize = 20;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final hackathonIdAsync = ref.watch(hackathonIdProvider);
    final apiService = ref.watch(apiServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Команды'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () => Scaffold.of(context).openEndDrawer(),
            tooltip: 'Отладка API',
          ),
          IconButton(
            onPressed: () => _showCreateTeamDialog(context, apiService),
            icon: const Icon(Icons.add),
            tooltip: 'Создать команду',
          ),
        ],
      ),
      drawer: AppDrawer(
          role: user?.role ?? UserRole.admin, currentRoute: '/admin/teams'),
      body: hackathonIdAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Ошибка: $err')),
        data: (hackathonId) => hackathonId.isEmpty
            ? const Center(child: Text('Нет активного хакатона'))
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Поиск по названию или проекту...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: FutureBuilder<TeamListResponse>(
                        future: apiService.getTeams(
                          hackathonId,
                          page: _page,
                          pageSize: _pageSize,
                          search: _searchController.text.isEmpty
                              ? null
                              : _searchController.text,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Center(
                                child: Text('Ошибка: ${snapshot.error}'));
                          }
                          final data = snapshot.data!;
                          if (data.items.isEmpty) {
                            return const Center(child: Text('Нет команд'));
                          }
                          return Card(
                            child: SingleChildScrollView(
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('Название')),
                                  DataColumn(label: Text('Капитан')),
                                  DataColumn(label: Text('Участников')),
                                  DataColumn(label: Text('Проект')),
                                  DataColumn(label: Text('Статус')),
                                  DataColumn(label: Text('Балл')),
                                  DataColumn(label: Text('Место')),
                                ],
                                rows: data.items
                                    .map((team) => DataRow(
                                          onSelectChanged: (_) =>
                                              _showTeamDetails(
                                                  context,
                                                  apiService,
                                                  hackathonId,
                                                  team.id),
                                          cells: [
                                            DataCell(Text(team.name)),
                                            DataCell(Text(team.captainName)),
                                            DataCell(
                                                Text('${team.membersCount}')),
                                            DataCell(Text(team.projectTitle)),
                                            DataCell(StatusBadge(
                                                status: team.evaluationStatus ??
                                                    'not_started')),
                                            DataCell(Text(team.finalScore
                                                    ?.toStringAsFixed(1) ??
                                                '-')),
                                            DataCell(Text(
                                                team.place?.toString() ?? '-')),
                                          ],
                                        ))
                                    .toList(),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  void _showCreateTeamDialog(BuildContext context, ApiService apiService) {
    final nameController = TextEditingController();
    final captainController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final projectController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Создать команду'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                      labelText: 'Название команды',
                      border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(
                  controller: captainController,
                  decoration: const InputDecoration(
                      labelText: 'Капитан', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(
                  controller: projectController,
                  decoration: const InputDecoration(
                      labelText: 'Название проекта',
                      border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                      labelText: 'Email', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                      labelText: 'Телефон', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                      labelText: 'Описание', border: OutlineInputBorder()),
                  maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Создание команды будет реализовано')));
            },
            child: const Text('Создать'),
          ),
        ],
      ),
    );
  }

  void _showTeamDetails(BuildContext context, ApiService apiService,
      String hackathonId, String teamId) async {
    try {
      final team = await apiService.getTeam(hackathonId, teamId);
      if (!context.mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(team.name,
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(width: 12),
                  StatusBadge(status: team.evaluationStatus),
                ],
              ),
              const SizedBox(height: 8),
              Text(team.projectTitle,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500)),
              if (team.description != null) ...[
                const SizedBox(height: 8),
                Text(team.description!,
                    style: TextStyle(color: Colors.grey[600])),
              ],
              const SizedBox(height: 24),
              const Text('Участники:',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...team.members.map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(m.isCaptain ? Icons.star : Icons.person, size: 16),
                        const SizedBox(width: 8),
                        Text('${m.fullName}${m.isCaptain ? ' (капитан)' : ''}'),
                      ],
                    ),
                  )),
              const SizedBox(height: 16),
              const Text('Назначенные эксперты:',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              if (team.assignedExperts.isEmpty)
                const Text('Нет назначенных экспертов',
                    style: TextStyle(color: Colors.grey))
              else
                ...team.assignedExperts.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.person_outline, size: 16),
                          const SizedBox(width: 8),
                          Text(e['full_name']?.toString() ?? 'Неизвестно'),
                        ],
                      ),
                    )),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Закрыть'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (e.toString().contains('501')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Детальная информация о команде временно недоступна (API не реализовано)')),
        );
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
  }
}
