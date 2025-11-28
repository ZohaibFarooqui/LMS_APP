import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'di/service_locator.dart';
import 'features/authentication/presentation/bloc/auth_bloc.dart';
import 'features/authentication/presentation/pages/login_page.dart';
import 'presentation/home/home_shell.dart';
import 'presentation/splash/splash_page.dart';
import 'shared/bloc/app_bloc.dart';

class LmsApp extends StatelessWidget {
  const LmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, child) {
        return MultiBlocProvider(
          providers: [
            BlocProvider<AppBloc>(create: (_) => getIt<AppBloc>()),
            BlocProvider<AuthBloc>(create: (_) => getIt<AuthBloc>()..add(const AuthCheckRequested())),
          ],
          child: BlocBuilder<AppBloc, AppState>(
            builder: (context, appState) {
              return MaterialApp(
                title: AppStrings.appTitle,
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: appState.themeMode,
                home: const _AppRouter(),
              );
            },
          ),
        );
      },
    );
  }
}

class _AppRouter extends StatelessWidget {
  const _AppRouter();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        switch (state.status) {
          case AuthStatus.initial:
          case AuthStatus.loading:
            return const SplashPage();
          case AuthStatus.authenticated:
            return const HomeShell();
          case AuthStatus.unauthenticated:
          case AuthStatus.failure:
            return const LoginPage();
        }
      },
    );
  }
}

