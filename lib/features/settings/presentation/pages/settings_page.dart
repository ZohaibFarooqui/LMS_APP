import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../di/service_locator.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../../../../shared/bloc/app_bloc.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SettingsCubit>(),
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final settings = state.settings;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              AppCard(
                child: Column(
                  children: [
                    SwitchListTile(
                      value: settings.biometricEnabled,
                      title: const Text('Enable Biometric Login'),
                      onChanged: (value) => context.read<SettingsCubit>().toggleBiometric(value),
                    ),
                    SwitchListTile(
                      value: settings.notificationsEnabled,
                      title: const Text('Notifications'),
                      onChanged: (value) => context.read<SettingsCubit>().toggleNotifications(value),
                    ),
                    SwitchListTile(
                      value: settings.darkMode,
                      title: const Text('Dark Mode'),
                      onChanged: (value) {
                        context.read<SettingsCubit>().toggleDarkMode(value);
                        context.read<AppBloc>().add(AppThemeToggled(value ? ThemeMode.dark : ThemeMode.light));
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => context.read<AuthBloc>().add(const LogoutRequested()),
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
              ),
            ],
          );
        },
      ),
    );
  }
}

