import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hackrank_frontend/screens/login_screen.dart';

import 'providers/auth_provider.dart';
import 'models/user.dart';

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

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class HackRankApp extends ConsumerStatefulWidget {
  const HackRankApp({super.key});

  @override
  ConsumerState<HackRankApp> createState() => _HackRankAppState();
}

class _HackRankAppState extends ConsumerState<HackRankApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = _buildRouter();
  }

  GoRouter _buildRouter() {
    return GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: '/login',
      redirect: (context, state) {
        final authState = ref.read(authStateProvider);
        final user = authState.valueOrNull;
        final isLoggingIn = state.matchedLocation == '/login';
        final isPublic = state.matchedLocation.startsWith('/public');

        if (isPublic) return null;

        if (user == null && !isLoggingIn) {
          return '/login';
        }

        if (user != null && isLoggingIn) {
          return _getHomePath(user.role);
        }

        if (user != null) {
          final location = state.matchedLocation;
          if (location.startsWith('/admin') && user.role != UserRole.admin) {
            return _getHomePath(user.role);
          }
          if (location.startsWith('/expert') && user.role != UserRole.expert) {
            return _getHomePath(user.role);
          }
          if (location.startsWith('/team') && user.role != UserRole.team) {
            return _getHomePath(user.role);
          }
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/public',
          name: 'public',
          builder: (context, state) => const PublicLeaderboardScreen(),
        ),
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
              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text(
                'Страница не найдена',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp.router(
      title: 'HackRank',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      routerConfig: _router,
      builder: (context, child) {
        return authState.when(
          data: (_) => child ?? const SizedBox(),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Ошибка: $err')),
        );
      },
    );
  }

  ThemeData _buildTheme() {
    const primaryColor = Color(0xFFE6A817);
    const secondaryColor = Color(0xFF2D2D2D);
    const backgroundColor = Color(0xFFF5F5F5);
    const surfaceColor = Color(0xFFFFFFFF);
    const errorColor = Color(0xFFD32F2F);

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        surface: surfaceColor,
        background: backgroundColor,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: secondaryColor,
        onBackground: secondaryColor,
        onError: Colors.white,
        primaryContainer: primaryColor.withOpacity(0.1),
        secondaryContainer: secondaryColor.withOpacity(0.1),
      ),
      scaffoldBackgroundColor: backgroundColor,
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge:
            const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        displayMedium:
            const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        displaySmall:
            const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        headlineLarge:
            const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        headlineMedium:
            const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        titleLarge: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: const TextStyle(fontSize: 14),
        bodyMedium: const TextStyle(fontSize: 13),
        labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        color: surfaceColor,
        shadowColor: Colors.black.withOpacity(0.05),
      ),
      inputDecorationTheme: InputDecorationTheme(
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
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorColor),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: secondaryColor,
          side: BorderSide(color: secondaryColor.withOpacity(0.3)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: secondaryColor,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: secondaryColor,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey[200],
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: primaryColor.withOpacity(0.1),
        selectedColor: primaryColor,
        labelStyle: const TextStyle(fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
