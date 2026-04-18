import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'providers/auth_provider.dart';
import 'models/user.dart';
import 'screens/login_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/users_screen.dart';
import 'screens/admin/teams_screen.dart';
import 'screens/admin/criteria_screen.dart';
import 'screens/admin/assignments_screen.dart';
import 'screens/admin/results_screen.dart';
import 'screens/expert/expert_dashboard_screen.dart';
import 'screens/expert/assigned_teams_screen.dart';
import 'screens/expert/evaluation_form_screen.dart';
import 'screens/team/team_profile_screen.dart';
import 'screens/team/team_result_screen.dart';
import 'screens/public/public_leaderboard_screen.dart';

class HackRankApp extends ConsumerWidget {
  const HackRankApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final config = ref.watch(appConfigProvider);

    final router = GoRouter(
      initialLocation: '/public',
      redirect: (context, state) {
        final user = authState.valueOrNull;
        final isLoggingIn = state.matchedLocation == '/login';
        final isPublic = state.matchedLocation.startsWith('/public');

        // Публичные страницы доступны всегда
        if (isPublic) return null;

        // Не авторизован и не на странице логина -> перенаправляем на логин
        if (user == null && !isLoggingIn) {
          return '/login';
        }

        // Авторизован, но пытается зайти на логин -> перенаправляем на домашнюю
        if (user != null && isLoggingIn) {
          return _getHomePath(user.role);
        }

        return null;
      },
      routes: [
        // Авторизация
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),

        // Публичные страницы
        GoRoute(
          path: '/public',
          name: 'public',
          builder: (context, state) => const PublicLeaderboardScreen(),
        ),

        // Администратор
        GoRoute(
          path: '/admin',
          name: 'admin_dashboard',
          builder: (context, state) => const AdminDashboardScreen(),
        ),
        GoRoute(
          path: '/admin/users',
          name: 'admin_users',
          builder: (context, state) => const UsersScreen(),
        ),
        GoRoute(
          path: '/admin/teams',
          name: 'admin_teams',
          builder: (context, state) => const TeamsScreen(),
        ),
        GoRoute(
          path: '/admin/criteria',
          name: 'admin_criteria',
          builder: (context, state) => const CriteriaScreen(),
        ),
        GoRoute(
          path: '/admin/assignments',
          name: 'admin_assignments',
          builder: (context, state) => const AssignmentsScreen(),
        ),
        GoRoute(
          path: '/admin/results',
          name: 'admin_results',
          builder: (context, state) => const ResultsScreen(),
        ),

        // Эксперт
        GoRoute(
          path: '/expert',
          name: 'expert_dashboard',
          builder: (context, state) => const ExpertDashboardScreen(),
        ),
        GoRoute(
          path: '/expert/teams',
          name: 'expert_teams',
          builder: (context, state) => const AssignedTeamsScreen(),
        ),
        GoRoute(
          path: '/expert/evaluate/:teamId',
          name: 'expert_evaluate',
          builder: (context, state) => EvaluationFormScreen(
            teamId: state.pathParameters['teamId']!,
          ),
        ),

        // Команда
        GoRoute(
          path: '/team',
          name: 'team_profile',
          builder: (context, state) => const TeamProfileScreen(),
        ),
        GoRoute(
          path: '/team/results',
          name: 'team_results',
          builder: (context, state) => const TeamResultScreen(),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Страница не найдена',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Путь "${state.uri}" не существует',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/public'),
                child: const Text('На главную'),
              ),
            ],
          ),
        ),
      ),
    );

    return MaterialApp.router(
      title: 'HackRank',
      debugShowCheckedModeBanner: config.isDevelopment,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      routerConfig: router,
    );
  }

  String _getHomePath(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return '/admin';
      case UserRole.expert:
        return '/expert';
      case UserRole.team:
        return '/team';
      case UserRole.public:
        return '/public';
    }
  }
}
