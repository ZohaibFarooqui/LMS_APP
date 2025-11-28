import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:lms/features/settings/domain/entities/app_settings.dart';
import 'package:lms/features/settings/domain/repositories/settings_repository.dart';
import 'package:lms/features/settings/presentation/cubit/settings_cubit.dart';

class _MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  late SettingsRepository repository;

  setUpAll(() {
    registerFallbackValue(
      const AppSettings(
        biometricEnabled: false,
        notificationsEnabled: true,
        darkMode: false,
      ),
    );
  });

  setUp(() {
    repository = _MockSettingsRepository();
  });

  test('SPRITE: Settings toggles persist biometric preference', () async {
    when(() => repository.load()).thenAnswer(
      (_) async => const AppSettings(biometricEnabled: false, notificationsEnabled: true, darkMode: false),
    );
    when(() => repository.save(any())).thenAnswer((_) async {});

    final cubit = SettingsCubit(repository);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    await cubit.toggleBiometric(true);
    expect(cubit.state.settings.biometricEnabled, isTrue);
    verify(() => repository.save(any())).called(1);
  });
}

