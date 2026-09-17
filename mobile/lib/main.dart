import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/auth/auth_bloc.dart';
import 'bloc/tasks/tasks_bloc.dart';
import 'core/api_client.dart';
import 'core/app_colors.dart';
import 'core/app_theme.dart';
import 'core/token_storage.dart';
import 'repositories/auth_repository.dart';
import 'repositories/task_repository.dart';
import 'screens/auth_screen.dart';
import 'screens/tasks_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = TokenStorage();
  final apiClient = ApiClient(storage);

  runApp(
    MomentumApp(
      authRepository: AuthRepository(apiClient, storage),
      taskRepository: TaskRepository(apiClient),
    ),
  );
}

class MomentumApp extends StatelessWidget {
  const MomentumApp({
    super.key,
    required this.authRepository,
    required this.taskRepository,
  });

  final AuthRepository authRepository;
  final TaskRepository taskRepository;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => AuthBloc(authRepository)..add(const AuthStarted()),
        ),
        BlocProvider(create: (_) => TasksBloc(taskRepository)),
      ],
      child: MaterialApp(
        title: 'Momentum',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const _AppGate(),
      ),
    );
  }
}

class _AppGate extends StatelessWidget {
  const _AppGate();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        return switch (state.status) {
          AuthStatus.unknown => const _SplashScreen(),
          AuthStatus.authenticated => TasksScreen(user: state.user!),
          _ => const AuthScreen(),
        };
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.ink,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                  bottomLeft: Radius.circular(5),
                ),
              ),
              child: SizedBox(
                width: 54,
                height: 54,
                child: Icon(
                  Icons.check_rounded,
                  color: AppColors.ink,
                  size: 34,
                ),
              ),
            ),
            SizedBox(height: 22),
            SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: AppColors.mint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
