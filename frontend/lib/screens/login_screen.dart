import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';
import '../../app.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await ref.read(authStateProvider.notifier).login(
            _loginController.text.trim(),
            _passwordController.text,
          );

      if (!mounted) return;

      if (result.success) {
        ref.invalidate(authStateProvider);
        await Future.delayed(const Duration(milliseconds: 100));

        final user = ref.read(currentUserProvider);

        if (!mounted) return;

        final context = rootNavigatorKey.currentContext;
        if (context != null) {
          switch (user?.role) {
            case UserRole.admin:
              context.go('/admin');
              break;
            case UserRole.expert:
              context.go('/expert');
              break;
            case UserRole.team:
              context.go('/team');
              break;
            default:
              context.go('/public');
          }
        }
      } else {
        setState(() {
          _isLoading = false;
          _error = result.errorMessage ?? 'Ошибка авторизации';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Ошибка: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primary.withOpacity(0.08),
              colorScheme.background,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'HackRank',
                      style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onBackground,
                          letterSpacing: -0.5,
                          fontSize: 45),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Оценка хакатона в один клик',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Форма внутри карточки с улучшенным стилем
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _loginController,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: 'Логин',
                              hintText: 'Введите ваш логин',
                              prefixIcon: const Icon(Icons.person_2_outlined),
                              filled: true,
                              fillColor: colorScheme.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            validator: (v) =>
                                v?.isEmpty ?? true ? 'Введите логин' : null,
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            onFieldSubmitted: (_) => _handleLogin(),
                            decoration: InputDecoration(
                              labelText: 'Пароль',
                              hintText: 'Введите ваш пароль',
                              prefixIcon:
                                  const Icon(Icons.lock_outline_rounded),
                              filled: true,
                              fillColor: colorScheme.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                            ),
                            validator: (v) =>
                                v?.isEmpty ?? true ? 'Введите пароль' : null,
                          ),
                          const SizedBox(height: 12),

                          // Анимированный вывод ошибки
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: _error != null
                                ? Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Material(
                                      color: colorScheme.errorContainer,
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 12),
                                        child: Row(
                                          children: [
                                            Icon(Icons.warning_amber_rounded,
                                                color: colorScheme.error,
                                                size: 20),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                _error!,
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                        color: colorScheme
                                                            .onErrorContainer,
                                                        fontWeight:
                                                            FontWeight.w500),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),

                          const SizedBox(height: 12),

                          // Кнопка входа
                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ).copyWith(
                                elevation: MaterialStateProperty.resolveWith(
                                    (states) =>
                                        states.contains(MaterialState.pressed)
                                            ? 0
                                            : 2),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation(
                                            Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      'Войти в систему',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Ссылка на публичный рейтинг
                    TextButton.icon(
                      onPressed: () => context.go('/public'),
                      icon: const Icon(Icons.leaderboard_outlined, size: 20),
                      label: const Text('Смотреть публичный рейтинг'),
                      style: TextButton.styleFrom(
                        foregroundColor: colorScheme.secondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
