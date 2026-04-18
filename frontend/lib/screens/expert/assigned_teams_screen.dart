import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/status_badge.dart';

class AssignedTeamsScreen extends ConsumerStatefulWidget {
  const AssignedTeamsScreen({super.key});

  @override
  ConsumerState<AssignedTeamsScreen> createState() =>
      _AssignedTeamsScreenState();
}

class _AssignedTeamsScreenState extends ConsumerState<AssignedTeamsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _statusFilter = 'all';
  String _sortBy = 'name';

  final List<Map<String, dynamic>> _teams = [
    {
      'name': 'ByteForce',
      'project': 'Smart Judge',
      'status': 'draft',
      'progress': 0.4,
      'deadline': '2024-04-20'
    },
    {
      'name': 'CodeMasters',
      'project': 'HackRank AI',
      'status': 'submitted',
      'progress': 1.0,
      'deadline': '2024-04-18'
    },
    {
      'name': 'InnovateX',
      'project': 'GreenTech',
      'status': 'not_started',
      'progress': 0.0,
      'deadline': '2024-04-22'
    },
    {
      'name': 'DataWizards',
      'project': 'Analytics Pro',
      'status': 'draft',
      'progress': 0.7,
      'deadline': '2024-04-19'
    },
    {
      'name': 'AIBrains',
      'project': 'Neural Mind',
      'status': 'draft',
      'progress': 0.2,
      'deadline': '2024-04-21'
    },
  ];

  List<Map<String, dynamic>> get _filteredTeams {
    var filtered = List<Map<String, dynamic>>.from(_teams);

    // Filter by search
    if (_searchController.text.isNotEmpty) {
      filtered = filtered
          .where((t) =>
              t['name']
                  .toLowerCase()
                  .contains(_searchController.text.toLowerCase()) ||
              t['project']
                  .toLowerCase()
                  .contains(_searchController.text.toLowerCase()))
          .toList();
    }

    // Filter by status
    if (_statusFilter != 'all') {
      filtered = filtered.where((t) => t['status'] == _statusFilter).toList();
    }

    // Sort
    filtered.sort((a, b) {
      if (_sortBy == 'name') return a['name'].compareTo(b['name']);
      if (_sortBy == 'status') return a['status'].compareTo(b['status']);
      if (_sortBy == 'deadline') return a['deadline'].compareTo(b['deadline']);
      return 0;
    });

    return filtered;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final filteredTeams = _filteredTeams;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Назначенные команды'),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.sort_outlined, color: colorScheme.secondary),
            onSelected: (value) => setState(() => _sortBy = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'name', child: Text('По названию')),
              const PopupMenuItem(value: 'status', child: Text('По статусу')),
              const PopupMenuItem(
                  value: 'deadline', child: Text('По дедлайну')),
            ],
          ),
        ],
      ),
      drawer: AppDrawer(
        role: user!.role,
        currentRoute: '/expert/teams',
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Search and Filter Row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Поиск по названию или проекту...',
                        prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
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
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey[200]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        hint: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('Статус',
                              style: TextStyle(color: Colors.grey[600])),
                        ),
                        value: _statusFilter,
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('Все')),
                          DropdownMenuItem(
                              value: 'draft', child: Text('Черновик')),
                          DropdownMenuItem(
                              value: 'submitted', child: Text('Отправлено')),
                          DropdownMenuItem(
                              value: 'not_started', child: Text('Не начато')),
                        ],
                        onChanged: (value) =>
                            setState(() => _statusFilter = value!),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Stats Row
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _StatChip(
                      label: 'Всего',
                      count: _teams.length,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    _StatChip(
                      label: 'Черновики',
                      count: _teams.where((t) => t['status'] == 'draft').length,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    _StatChip(
                      label: 'Отправлено',
                      count: _teams
                          .where((t) => t['status'] == 'submitted')
                          .length,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 12),
                    _StatChip(
                      label: 'Не начато',
                      count: _teams
                          .where((t) => t['status'] == 'not_started')
                          .length,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Teams Grid
              Expanded(
                child: filteredTeams.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.assignment_outlined,
                                size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text('Нет команд для отображения',
                                style: theme.textTheme.bodyLarge),
                          ],
                        ),
                      )
                    : GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 380,
                          childAspectRatio: 1.1,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: filteredTeams.length,
                        itemBuilder: (context, index) {
                          final team = filteredTeams[index];
                          final name = team['name'] as String;
                          final project = team['project'] as String;
                          final status = team['status'] as String;
                          final progress = team['progress'] as double;
                          final isSubmitted = status == 'submitted';

                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                context.go(
                                    '/expert/evaluate/${name.toLowerCase()}');
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: colorScheme.primary
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Icon(
                                            Icons.groups_outlined,
                                            color: colorScheme.primary,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                name,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                project,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        StatusBadge(status: status),
                                        const Spacer(),
                                        Text(
                                          '${(progress * 100).toStringAsFixed(0)}%',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: progress == 1.0
                                                ? Colors.green
                                                : Colors.orange,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: progress,
                                        backgroundColor: Colors.grey[200],
                                        color: progress == 1.0
                                            ? Colors.green
                                            : colorScheme.primary,
                                        minHeight: 4,
                                      ),
                                    ),
                                    const Spacer(),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          context.go(
                                              '/expert/evaluate/${name.toLowerCase()}');
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isSubmitted
                                              ? Colors.grey[200]
                                              : colorScheme.primary,
                                          foregroundColor: isSubmitted
                                              ? Colors.grey[600]
                                              : Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                        child: Text(isSubmitted
                                            ? 'Просмотреть'
                                            : 'Оценить'),
                                      ),
                                    ),
                                  ],
                                ),
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
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatChip({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: $count',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
