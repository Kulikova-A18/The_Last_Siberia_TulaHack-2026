import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';

class AppDrawer extends ConsumerWidget {
  final UserRole role;
  final String currentRoute;

  const AppDrawer({super.key, required this.role, required this.currentRoute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(user?.fullName ?? 'Пользователь'),
            accountEmail: Text(user?.login ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text((user?.fullName ?? 'U')[0].toUpperCase(),
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontSize: 24)),
            ),
          ),
          Expanded(child: ListView(children: _buildMenuItems(context))),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Выйти'),
            onTap: () async {
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  List<Widget> _buildMenuItems(BuildContext context) {
    switch (role) {
      case UserRole.admin:
        return [
          _MenuItem(
              title: 'Дашборд',
              icon: Icons.dashboard,
              route: '/admin',
              currentRoute: currentRoute),
          _MenuItem(
              title: 'Пользователи',
              icon: Icons.people,
              route: '/admin/users',
              currentRoute: currentRoute),
          _MenuItem(
              title: 'Команды',
              icon: Icons.groups,
              route: '/admin/teams',
              currentRoute: currentRoute),
          _MenuItem(
              title: 'Критерии',
              icon: Icons.rule,
              route: '/admin/criteria',
              currentRoute: currentRoute),
          _MenuItem(
              title: 'Назначения',
              icon: Icons.assignment_ind,
              route: '/admin/assignments',
              currentRoute: currentRoute),
          _MenuItem(
              title: 'Результаты',
              icon: Icons.leaderboard,
              route: '/admin/results',
              currentRoute: currentRoute),
          const Divider(),
          _MenuItem(
              title: 'Публичный рейтинг',
              icon: Icons.public,
              route: '/public',
              currentRoute: currentRoute),
        ];
      case UserRole.expert:
        return [
          _MenuItem(
              title: 'Мой дашборд',
              icon: Icons.dashboard,
              route: '/expert',
              currentRoute: currentRoute),
          _MenuItem(
              title: 'Назначенные команды',
              icon: Icons.assignment,
              route: '/expert/teams',
              currentRoute: currentRoute),
          const Divider(),
          _MenuItem(
              title: 'Публичный рейтинг',
              icon: Icons.public,
              route: '/public',
              currentRoute: currentRoute),
        ];
      case UserRole.team:
        return [
          _MenuItem(
              title: 'Профиль команды',
              icon: Icons.info,
              route: '/team',
              currentRoute: currentRoute),
          _MenuItem(
              title: 'Результаты',
              icon: Icons.emoji_events,
              route: '/team/results',
              currentRoute: currentRoute),
          const Divider(),
          _MenuItem(
              title: 'Публичный рейтинг',
              icon: Icons.public,
              route: '/public',
              currentRoute: currentRoute),
        ];
      case UserRole.public:
        return [];
    }
  }
}

class _MenuItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final String route;
  final String currentRoute;

  const _MenuItem(
      {required this.title,
      required this.icon,
      required this.route,
      required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final isSelected = currentRoute == route;
    return ListTile(
      leading: Icon(icon,
          color: isSelected ? Theme.of(context).colorScheme.primary : null),
      title: Text(title,
          style: TextStyle(
              color: isSelected ? Theme.of(context).colorScheme.primary : null,
              fontWeight: isSelected ? FontWeight.w600 : null)),
      selected: isSelected,
      onTap: () {
        if (!isSelected) context.go(route);
        Navigator.pop(context);
      },
    );
  }
}
