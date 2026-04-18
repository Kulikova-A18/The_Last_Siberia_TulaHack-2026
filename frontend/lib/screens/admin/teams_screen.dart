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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Команды'),
        actions: [
          IconButton(
            onPressed: () => _showCreateTeamDialog(context, apiService),
            icon: Icon(Icons.add_outlined, color: colorScheme.secondary),
            tooltip: 'Создать команду',
          ),
        ],
      ),
      drawer: AppDrawer(
        role: user?.role ?? UserRole.admin,
        currentRoute: '/admin/teams',
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
                      Icon(Icons.groups_outlined,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('Нет активного хакатона',
                          style: theme.textTheme.bodyLarge),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Поиск по названию или проекту...',
                          prefixIcon:
                              Icon(Icons.search, color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[200]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Color(0xFFE6A817), width: 2),
                          ),
                        ),
                        onSubmitted: (_) => setState(() => _page = 1),
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
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.error_outline,
                                        size: 48, color: Colors.grey[400]),
                                    const SizedBox(height: 16),
                                    Text('Ошибка: ${snapshot.error}'),
                                  ],
                                ),
                              );
                            }
                            final data = snapshot.data!;
                            if (data.items.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.groups_outlined,
                                        size: 48, color: Colors.grey[400]),
                                    const SizedBox(height: 16),
                                    Text('Нет команд',
                                        style: theme.textTheme.bodyLarge),
                                  ],
                                ),
                              );
                            }
                            return Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width - 48,
                                    child: DataTable(
                                      columnSpacing: 16,
                                      headingRowColor:
                                          MaterialStateProperty.all(
                                        Colors.grey[50],
                                      ),
                                      headingRowHeight: 56,
                                      dataRowMinHeight: 60,
                                      dataRowMaxHeight: 60,
                                      columns: const [
                                        DataColumn(label: Text('Название')),
                                        DataColumn(label: Text('Капитан')),
                                        DataColumn(label: Text('Уч.')),
                                        DataColumn(label: Text('Проект')),
                                        DataColumn(label: Text('Статус')),
                                        DataColumn(label: Text('Балл')),
                                        DataColumn(label: Text('Место')),
                                      ],
                                      rows: data.items.map((team) {
                                        return DataRow(
                                          onSelectChanged: (_) =>
                                              _showTeamDetails(
                                            context,
                                            apiService,
                                            hackathonId,
                                            team.id,
                                          ),
                                          cells: [
                                            DataCell(
                                              SizedBox(
                                                width: 120,
                                                child: Text(
                                                  team.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              SizedBox(
                                                width: 120,
                                                child: Text(
                                                  team.captainName,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                                Text('${team.membersCount}')),
                                            DataCell(
                                              SizedBox(
                                                width: 150,
                                                child: Text(
                                                  team.projectTitle,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              StatusBadge(
                                                status: team.evaluationStatus ??
                                                    'not_started',
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                team.finalScore
                                                        ?.toStringAsFixed(1) ??
                                                    '-',
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                team.place?.toString() ?? '-',
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: _page > 1
                                ? () => setState(() => _page--)
                                : null,
                          ),
                          Text('Страница $_page'),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: () => setState(() => _page++),
                          ),
                        ],
                      ),
                    ],
                  ),
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
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Создать команду'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Название команды',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: captainController,
                  decoration: InputDecoration(
                    labelText: 'Капитан',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: projectController,
                  decoration: InputDecoration(
                    labelText: 'Название проекта',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: 'Телефон',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: InputDecoration(
                    labelText: 'Описание',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Создание команды будет реализовано')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Создать'),
          ),
        ],
      ),
    );
  }

  void _showTeamDetails(
    BuildContext context,
    ApiService apiService,
    String hackathonId,
    String teamId,
  ) async {
    try {
      final team = await apiService.getTeam(hackathonId, teamId);
      if (!context.mounted) return;
      _showTeamDetailsSheet(context, team);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Детальная информация о команде временно недоступна'),
          ),
        );
      }
    }
  }

  void _showTeamDetailsSheet(BuildContext context, TeamDetail team) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.primary.withOpacity(0.05),
                Colors.white,
              ],
            ),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        team.name,
                        style: theme.textTheme.headlineMedium,
                      ),
                    ),
                    StatusBadge(status: team.evaluationStatus),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  team.projectTitle,
                  style: theme.textTheme.titleMedium,
                ),
                if (team.description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    team.description!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Участники',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (team.members.isEmpty)
                  Text(
                    'Нет участников',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                    ),
                  )
                else
                  ...team.members.map((m) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(
                              m.isCaptain ? Icons.star : Icons.person_outline,
                              size: 18,
                              color: m.isCaptain
                                  ? colorScheme.primary
                                  : Colors.grey[500],
                            ),
                            const SizedBox(width: 12),
                            Text(
                                '${m.fullName}${m.isCaptain ? ' (капитан)' : ''}'),
                          ],
                        ),
                      )),
                const SizedBox(height: 16),
                Text(
                  'Назначенные эксперты',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (team.assignedExperts.isEmpty)
                  Text(
                    'Нет назначенных экспертов',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[500],
                    ),
                  )
                else
                  ...team.assignedExperts.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(Icons.person_outline,
                                size: 18, color: Colors.grey[500]),
                            const SizedBox(width: 12),
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
        ),
      ),
    );
  }
}
