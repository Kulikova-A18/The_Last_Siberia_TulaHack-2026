import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';

class AppDrawer extends ConsumerWidget {
  final UserRole role;
  final String currentRoute;

  const AppDrawer({
    super.key,
    required this.role,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.analytics_outlined,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.fullName ?? 'Пользователь',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.login ?? '',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: _buildMenuItems(context, theme, colorScheme),
            ),
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.grey[600]),
            title: const Text('Выйти'),
            onTap: () async {
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  List<Widget> _buildMenuItems(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final isSelected = (String route) => currentRoute == route;

    switch (role) {
      case UserRole.admin:
        return [
          _MenuItem(
            title: 'Дашборд',
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard,
            route: '/admin',
            isSelected: isSelected('/admin'),
          ),
          _MenuItem(
            title: 'Пользователи',
            icon: Icons.people_outline,
            selectedIcon: Icons.people,
            route: '/admin/users',
            isSelected: isSelected('/admin/users'),
          ),
          _MenuItem(
            title: 'Команды',
            icon: Icons.groups_outlined,
            selectedIcon: Icons.groups,
            route: '/admin/teams',
            isSelected: isSelected('/admin/teams'),
          ),
          _MenuItem(
            title: 'Критерии',
            icon: Icons.rule_outlined,
            selectedIcon: Icons.rule,
            route: '/admin/criteria',
            isSelected: isSelected('/admin/criteria'),
          ),
          _MenuItem(
            title: 'Назначения',
            icon: Icons.assignment_outlined,
            selectedIcon: Icons.assignment,
            route: '/admin/assignments',
            isSelected: isSelected('/admin/assignments'),
          ),
          _MenuItem(
            title: 'Результаты',
            icon: Icons.leaderboard_outlined,
            selectedIcon: Icons.leaderboard,
            route: '/admin/results',
            isSelected: isSelected('/admin/results'),
          ),
          const Divider(),
          _MenuItem(
            title: 'Публичный рейтинг',
            icon: Icons.public_outlined,
            selectedIcon: Icons.public,
            route: '/public',
            isSelected: isSelected('/public'),
          ),
        ];
      case UserRole.expert:
        return [
          _MenuItem(
            title: 'Мой дашборд',
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard,
            route: '/expert',
            isSelected: isSelected('/expert'),
          ),
          _MenuItem(
            title: 'Назначенные команды',
            icon: Icons.assignment_outlined,
            selectedIcon: Icons.assignment,
            route: '/expert/teams',
            isSelected: isSelected('/expert/teams'),
          ),
          const Divider(),
          _MenuItem(
            title: 'Публичный рейтинг',
            icon: Icons.public_outlined,
            selectedIcon: Icons.public,
            route: '/public',
            isSelected: isSelected('/public'),
          ),
        ];
      case UserRole.team:
        return [
          _MenuItem(
            title: 'Профиль команды',
            icon: Icons.info_outline,
            selectedIcon: Icons.info,
            route: '/team',
            isSelected: isSelected('/team'),
          ),
          _MenuItem(
            title: 'Результаты',
            icon: Icons.emoji_events_outlined,
            selectedIcon: Icons.emoji_events,
            route: '/team/results',
            isSelected: isSelected('/team/results'),
          ),
          const Divider(),
          _MenuItem(
            title: 'Публичный рейтинг',
            icon: Icons.public_outlined,
            selectedIcon: Icons.public,
            route: '/public',
            isSelected: isSelected('/public'),
          ),
        ];
      case UserRole.public:
        return [];
    }
  }
}

class _MenuItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final IconData selectedIcon;
  final String route;
  final bool isSelected;

  const _MenuItem({
    required this.title,
    required this.icon,
    required this.selectedIcon,
    required this.route,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      leading: Icon(
        isSelected ? selectedIcon : icon,
        color: isSelected ? colorScheme.primary : Colors.grey[600],
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: isSelected ? colorScheme.primary : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: colorScheme.primary.withOpacity(0.05),
      onTap: () {
        if (!isSelected) context.go(route);
        Navigator.pop(context);
      },
    );
  }
}
