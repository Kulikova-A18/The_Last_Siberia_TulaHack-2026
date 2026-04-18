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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Пользователи'),
        actions: [
          IconButton(
            onPressed: () => _showCreateUserDialog(context, apiService),
            icon: Icon(Icons.person_add_outlined, color: colorScheme.secondary),
            tooltip: 'Создать пользователя',
          ),
        ],
      ),
      drawer: AppDrawer(
        role: user?.role ?? UserRole.admin,
        currentRoute: '/admin/users',
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
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Поиск по имени или логину...',
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
                      onSubmitted: (_) => setState(() => _page = 1),
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
                      child: DropdownButton<String?>(
                        hint: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('Роль',
                              style: TextStyle(color: Colors.grey[600])),
                        ),
                        value: _selectedRole,
                        items: const [
                          DropdownMenuItem(value: null, child: Text('Все')),
                          DropdownMenuItem(
                              value: 'admin', child: Text('Администратор')),
                          DropdownMenuItem(
                              value: 'expert', child: Text('Эксперт')),
                          DropdownMenuItem(
                              value: 'team', child: Text('Команда')),
                        ],
                        onChanged: (value) => setState(() {
                          _selectedRole = value;
                          _page = 1;
                        }),
                      ),
                    ),
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
                            Icon(Icons.people_outline,
                                size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text('Нет пользователей',
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
                            width: MediaQuery.of(context).size.width - 48,
                            child: DataTable(
                              columnSpacing: 16,
                              headingRowColor: MaterialStateProperty.all(
                                Colors.grey[50],
                              ),
                              headingRowHeight: 56,
                              dataRowMinHeight: 60,
                              dataRowMaxHeight: 60,
                              columns: const [
                                DataColumn(label: Text('ФИО')),
                                DataColumn(label: Text('Логин')),
                                DataColumn(label: Text('Роль')),
                                DataColumn(label: Text('Email')),
                                DataColumn(label: Text('Статус')),
                                DataColumn(label: Text('')),
                              ],
                              rows: data.items.map((u) {
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      SizedBox(
                                        width: 150,
                                        child: Text(
                                          u.fullName,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w500),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 100,
                                        child: Text(
                                          u.login,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getRoleColor(u.roleString)
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          _getRoleLabel(u.roleString),
                                          style: TextStyle(
                                            color: _getRoleColor(u.roleString),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 150,
                                        child: Text(
                                          u.email ?? '-',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      StatusBadge(
                                        status:
                                            u.isActive ? 'active' : 'inactive',
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(Icons.edit_outlined,
                                                size: 20,
                                                color: Colors.grey[600]),
                                            onPressed: () =>
                                                _showEditUserDialog(
                                                    context, apiService, u),
                                            tooltip: 'Редактировать',
                                            constraints: const BoxConstraints(
                                              minWidth: 32,
                                              minHeight: 32,
                                            ),
                                            padding: EdgeInsets.zero,
                                          ),
                                          IconButton(
                                            icon: Icon(
                                                Icons.lock_reset_outlined,
                                                size: 20,
                                                color: Colors.grey[600]),
                                            onPressed: () =>
                                                _showResetPasswordDialog(
                                                    context, apiService, u),
                                            tooltip: 'Сбросить пароль',
                                            constraints: const BoxConstraints(
                                              minWidth: 32,
                                              minHeight: 32,
                                            ),
                                            padding: EdgeInsets.zero,
                                          ),
                                        ],
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
                    onPressed: _page > 1 ? () => setState(() => _page--) : null,
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
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'expert':
        return Colors.blue;
      case 'team':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Админ';
      case 'expert':
        return 'Эксперт';
      case 'team':
        return 'Команда';
      default:
        return role;
    }
  }

  void _showCreateUserDialog(BuildContext context, ApiService apiService) {
    final loginController = TextEditingController();
    final passwordController = TextEditingController();
    final fullNameController = TextEditingController();
    final emailController = TextEditingController();
    String? selectedRole;
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Создать пользователя'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: fullNameController,
                  decoration: InputDecoration(
                    labelText: 'ФИО',
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
                  controller: loginController,
                  decoration: InputDecoration(
                    labelText: 'Логин',
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
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Пароль',
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
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Роль',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
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
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
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
                  const SnackBar(content: Text('Пользователь создан')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Ошибка: $e')),
                );
              }
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

  void _showEditUserDialog(
      BuildContext context, ApiService apiService, User user) {
    final fullNameController = TextEditingController(text: user.fullName);
    final emailController = TextEditingController(text: user.email ?? '');
    bool isActive = user.isActive;
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редактировать пользователя'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: fullNameController,
                decoration: InputDecoration(
                  labelText: 'ФИО',
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
              CheckboxListTile(
                title: const Text('Активен'),
                value: isActive,
                onChanged: (value) => isActive = value ?? true,
                contentPadding: EdgeInsets.zero,
                activeColor: colorScheme.primary,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
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
                  const SnackBar(content: Text('Пользователь обновлён')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Ошибка: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _showResetPasswordDialog(
      BuildContext context, ApiService apiService, User user) {
    final passwordController = TextEditingController();
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Сброс пароля: ${user.fullName}'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Новый пароль',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (passwordController.text.isEmpty) return;
              try {
                await apiService.resetUserPassword(
                    user.id, passwordController.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Пароль сброшен')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Ошибка: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Сбросить'),
          ),
        ],
      ),
    );
  }
}
