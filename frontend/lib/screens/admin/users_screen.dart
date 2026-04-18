import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/status_badge.dart';
import '../../services/api/api_service.dart';
import '../../models/user.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  final _searchController = TextEditingController();
  String? _selectedRole;
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
    final apiService = ref.watch(apiServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Пользователи'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () => Scaffold.of(context).openEndDrawer(),
            tooltip: 'Отладка API',
          ),
          IconButton(
            onPressed: () => _showCreateUserDialog(context, apiService),
            icon: const Icon(Icons.person_add),
            tooltip: 'Создать пользователя',
          ),
        ],
      ),
      drawer: AppDrawer(
          role: user?.role ?? UserRole.admin, currentRoute: '/admin/users'),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Поиск по имени или логину...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<String?>(
                  hint: const Text('Роль'),
                  value: _selectedRole,
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Все')),
                    DropdownMenuItem(
                        value: 'admin', child: Text('Администратор')),
                    DropdownMenuItem(value: 'expert', child: Text('Эксперт')),
                    DropdownMenuItem(value: 'team', child: Text('Команда')),
                  ],
                  onChanged: (value) => setState(() => _selectedRole = value),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: FutureBuilder<UserListResponse>(
                future: apiService.getUsers(
                  page: _page,
                  pageSize: _pageSize,
                  role: _selectedRole,
                  search: _searchController.text.isEmpty
                      ? null
                      : _searchController.text,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Ошибка: ${snapshot.error}'));
                  }
                  final data = snapshot.data!;
                  if (data.items.isEmpty) {
                    return const Center(child: Text('Нет пользователей'));
                  }
                  return Card(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('ФИО')),
                          DataColumn(label: Text('Логин')),
                          DataColumn(label: Text('Роль')),
                          DataColumn(label: Text('Email')),
                          DataColumn(label: Text('Статус')),
                          DataColumn(label: Text('Действия')),
                        ],
                        rows: data.items
                            .map((u) => DataRow(
                                  cells: [
                                    DataCell(Text(u.fullName)),
                                    DataCell(Text(u.login)),
                                    DataCell(Text(u.roleString)),
                                    DataCell(Text(u.email ?? '-')),
                                    DataCell(StatusBadge(
                                        status: u.isActive
                                            ? 'active'
                                            : 'inactive')),
                                    DataCell(Row(
                                      children: [
                                        IconButton(
                                          icon:
                                              const Icon(Icons.edit, size: 18),
                                          onPressed: () => _showEditUserDialog(
                                              context, apiService, u),
                                          tooltip: 'Редактировать',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.lock_reset,
                                              size: 18),
                                          onPressed: () =>
                                              _showResetPasswordDialog(
                                                  context, apiService, u),
                                          tooltip: 'Сбросить пароль',
                                        ),
                                      ],
                                    )),
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
    );
  }

  void _showCreateUserDialog(BuildContext context, ApiService apiService) {
    final loginController = TextEditingController();
    final passwordController = TextEditingController();
    final fullNameController = TextEditingController();
    final emailController = TextEditingController();
    String? selectedRole;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Создать пользователя'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: fullNameController,
                  decoration: const InputDecoration(
                      labelText: 'ФИО', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(
                  controller: loginController,
                  decoration: const InputDecoration(
                      labelText: 'Логин', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: 'Пароль', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                      labelText: 'Email', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                    labelText: 'Роль', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(
                      value: 'admin', child: Text('Администратор')),
                  DropdownMenuItem(value: 'expert', child: Text('Эксперт')),
                  DropdownMenuItem(value: 'team', child: Text('Команда')),
                ],
                onChanged: (value) => selectedRole = value,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () async {
              if (selectedRole == null ||
                  loginController.text.isEmpty ||
                  passwordController.text.isEmpty ||
                  fullNameController.text.isEmpty) {
                return;
              }
              try {
                await apiService.createUser({
                  'login': loginController.text,
                  'password': passwordController.text,
                  'full_name': fullNameController.text,
                  'email': emailController.text.isEmpty
                      ? null
                      : emailController.text,
                  'role_code': selectedRole,
                  'is_active': true,
                });
                Navigator.pop(context);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Пользователь создан')));
              } catch (e) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
              }
            },
            child: const Text('Создать'),
          ),
        ],
      ),
    );
  }

  void _showEditUserDialog(
      BuildContext context, ApiService apiService, User user) {
    final fullNameController = TextEditingController(text: user.fullName);
    final emailController = TextEditingController(text: user.email ?? '');
    bool isActive = user.isActive;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редактировать пользователя'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: fullNameController,
                  decoration: const InputDecoration(
                      labelText: 'ФИО', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                      labelText: 'Email', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              CheckboxListTile(
                title: const Text('Активен'),
                value: isActive,
                onChanged: (value) => isActive = value ?? true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () async {
              try {
                await apiService.updateUser(user.id, {
                  'full_name': fullNameController.text,
                  'email': emailController.text.isEmpty
                      ? null
                      : emailController.text,
                  'is_active': isActive,
                });
                Navigator.pop(context);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Пользователь обновлён')));
              } catch (e) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _showResetPasswordDialog(
      BuildContext context, ApiService apiService, User user) {
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Сброс пароля: ${user.fullName}'),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(
              labelText: 'Новый пароль', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () async {
              if (passwordController.text.isEmpty) return;
              try {
                await apiService.resetUserPassword(
                    user.id, passwordController.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Пароль сброшен')));
              } catch (e) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
              }
            },
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );
  }
}
