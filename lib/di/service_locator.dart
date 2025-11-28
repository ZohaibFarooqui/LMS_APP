import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/app_config.dart';
import '../core/network/mock_api_service.dart';
import '../core/network/network_client.dart';
import '../core/services/biometric_service.dart';
import '../core/services/geofence_service.dart';
import '../core/services/local_storage_service.dart';
import '../core/services/location_service.dart';
import '../core/services/notification_service.dart';
import '../core/services/secure_storage_service.dart';
import '../data/datasources/lms_local_data_source.dart';
import '../data/datasources/lms_remote_data_source.dart';
import '../features/attendance/data/repositories/attendance_repository_impl.dart';
import '../features/attendance/domain/repositories/attendance_repository.dart';
import '../features/attendance/domain/usecases/get_attendance_report_usecase.dart';
import '../features/attendance/domain/usecases/get_attendance_summary_usecase.dart';
import '../features/attendance/presentation/bloc/attendance_bloc.dart';
import '../features/authentication/data/datasources/auth_local_data_source.dart';
import '../features/authentication/data/datasources/auth_remote_data_source.dart';
import '../features/authentication/data/repositories/auth_repository_impl.dart';
import '../features/authentication/domain/repositories/auth_repository.dart';
import '../features/authentication/domain/usecases/authenticate_user_usecase.dart';
import '../features/authentication/domain/usecases/get_cached_user_usecase.dart';
import '../features/authentication/domain/usecases/logout_usecase.dart';
import '../features/authentication/domain/usecases/toggle_biometric_usecase.dart';
import '../features/authentication/presentation/bloc/auth_bloc.dart';
import '../features/dashboard/data/repositories/dashboard_repository_impl.dart';
import '../features/dashboard/domain/repositories/dashboard_repository.dart';
import '../features/dashboard/domain/usecases/get_dashboard_summary_usecase.dart';
import '../features/dashboard/presentation/bloc/dashboard_bloc.dart';
import '../features/geofence/data/repositories/geofence_repository_impl.dart';
import '../features/geofence/domain/repositories/geofence_repository.dart';
import '../features/geofence/domain/usecases/manual_attendance_override_usecase.dart';
import '../features/geofence/domain/usecases/mark_automatic_check_in_usecase.dart';
import '../features/geofence/presentation/bloc/geofence_bloc.dart';
import '../features/leaves/data/repositories/leave_repository_impl.dart';
import '../features/leaves/domain/repositories/leave_repository.dart';
import '../features/leaves/domain/usecases/get_leave_balances_usecase.dart';
import '../features/leaves/domain/usecases/get_leave_requests_usecase.dart';
import '../features/leaves/domain/usecases/submit_leave_request_usecase.dart';
import '../features/leaves/presentation/bloc/leave_application/leave_application_bloc.dart';
import '../features/leaves/presentation/bloc/leave_balance/leave_balance_bloc.dart';
import '../features/leaves/presentation/bloc/leave_status/leave_status_bloc.dart';
import '../features/notifications/data/repositories/notification_repository_impl.dart';
import '../features/notifications/domain/repositories/notification_repository.dart';
import '../features/notifications/domain/usecases/get_notifications_usecase.dart';
import '../features/notifications/domain/usecases/mark_notification_read_usecase.dart';
import '../features/notifications/presentation/bloc/notification_bloc.dart';
import '../features/profile/data/repositories/profile_repository_impl.dart';
import '../features/profile/domain/repositories/profile_repository.dart';
import '../features/profile/domain/usecases/get_profile_usecase.dart';
import '../features/profile/domain/usecases/update_profile_contacts_usecase.dart';
import '../features/profile/presentation/bloc/profile_bloc.dart';
import '../features/settings/data/repositories/settings_repository_impl.dart';
import '../features/settings/domain/repositories/settings_repository.dart';
import '../features/settings/presentation/cubit/settings_cubit.dart';
import '../shared/bloc/app_bloc.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  final preferences = await SharedPreferences.getInstance();

  // Core
  getIt
    ..registerLazySingleton<AppConfig>(() => const AppConfig())
    ..registerLazySingleton<LocalStorageService>(() => LocalStorageService(preferences))
    ..registerLazySingleton<SecureStorageService>(() => SecureStorageService())
    ..registerLazySingleton<MockApiService>(() => MockApiService())
    ..registerLazySingleton<NetworkClient>(() => NetworkClient(getIt<AppConfig>()))
    ..registerLazySingleton<LocationService>(() => LocationService())
    ..registerLazySingleton<GeoFenceService>(
      () => GeoFenceService(getIt<AppConfig>(), getIt<LocationService>()),
    )
    ..registerLazySingleton<NotificationService>(() => NotificationService())
    ..registerLazySingleton<BiometricService>(() => BiometricService())
    ..registerLazySingleton<LmsLocalDataSource>(() => LmsLocalDataSource(getIt<LocalStorageService>()))
    ..registerLazySingleton<LmsRemoteDataSourceImpl>(
      () => LmsRemoteDataSourceImpl(
        getIt<NetworkClient>(),
        getIt<AppConfig>(),
        getIt<MockApiService>(),
      ),
    )
    ..registerLazySingleton<LmsRemoteDataSource>(() => getIt<LmsRemoteDataSourceImpl>());

  // Auth
  getIt
    ..registerLazySingleton<AuthLocalDataSource>(
      () => AuthLocalDataSourceImpl(getIt<LocalStorageService>(), getIt<SecureStorageService>()),
    )
    ..registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(
        getIt<NetworkClient>(),
        getIt<AppConfig>(),
        getIt<MockApiService>(),
      ),
    )
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(getIt<AuthRemoteDataSource>(), getIt<AuthLocalDataSource>()),
    )
    ..registerLazySingleton(() => AuthenticateUserUseCase(getIt()))
    ..registerLazySingleton(() => GetCachedUserUseCase(getIt()))
    ..registerLazySingleton(() => LogoutUseCase(getIt()))
    ..registerLazySingleton(() => ToggleBiometricUseCase(getIt()))
    ..registerFactory(
      () => AuthBloc(
        authenticateUserUseCase: getIt(),
        getCachedUserUseCase: getIt(),
        logoutUseCase: getIt(),
        toggleBiometricUseCase: getIt(),
        authRepository: getIt(),
      ),
    );

  // Dashboard
  getIt
    ..registerLazySingleton<DashboardRepository>(
        () => DashboardRepositoryImpl(getIt<LmsRemoteDataSource>(), getIt<LmsLocalDataSource>()))
    ..registerLazySingleton(() => GetDashboardSummaryUseCase(getIt()))
    ..registerFactory(() => DashboardBloc(getIt()));

  // Attendance
  getIt
    ..registerLazySingleton<AttendanceRepository>(
        () => AttendanceRepositoryImpl(getIt<LmsRemoteDataSource>(), getIt<LmsLocalDataSource>()))
    ..registerLazySingleton(() => GetAttendanceReportUseCase(getIt()))
    ..registerLazySingleton(() => GetAttendanceSummaryUseCase(getIt()))
    ..registerFactory(() => AttendanceBloc(getIt(), getIt()));

  // Leaves
  getIt
    ..registerLazySingleton<LeaveRepository>(
      () => LeaveRepositoryImpl(getIt<LmsRemoteDataSource>(), getIt<LmsLocalDataSource>()),
    )
    ..registerLazySingleton(() => GetLeaveBalancesUseCase(getIt()))
    ..registerLazySingleton(() => GetLeaveRequestsUseCase(getIt()))
    ..registerLazySingleton(() => SubmitLeaveRequestUseCase(getIt()))
    ..registerFactory(() => LeaveBalanceBloc(getIt()))
    ..registerFactory(() => LeaveStatusBloc(getIt()))
    ..registerFactory(() => LeaveApplicationBloc(getIt()));

  // Profile
  getIt
    ..registerLazySingleton<ProfileRepository>(
      () => ProfileRepositoryImpl(getIt<LmsRemoteDataSource>(), getIt<LmsLocalDataSource>()),
    )
    ..registerLazySingleton(() => GetProfileUseCase(getIt()))
    ..registerLazySingleton(() => UpdateProfileContactsUseCase(getIt()))
    ..registerFactory(() => ProfileBloc(getIt(), getIt()));

  // Notifications
  getIt
    ..registerLazySingleton<NotificationRepository>(
        () => NotificationRepositoryImpl(
              getIt<LmsRemoteDataSource>(),
              getIt<LmsLocalDataSource>(),
            ))
    ..registerLazySingleton(() => GetNotificationsUseCase(getIt()))
    ..registerLazySingleton(() => MarkNotificationReadUseCase(getIt()))
    ..registerFactory(() => NotificationBloc(getIt(), getIt()));

  // GeoFence
  getIt
    ..registerLazySingleton<GeoFenceRepository>(
      () => GeoFenceRepositoryImpl(getIt<LmsRemoteDataSource>()),
    )
    ..registerLazySingleton(() => MarkAutomaticCheckInUseCase(getIt()))
    ..registerLazySingleton(() => ManualAttendanceOverrideUseCase(getIt()))
    ..registerFactory(() => GeoFenceBloc(getIt(), getIt(), getIt()));

  // Settings
  getIt
    ..registerLazySingleton<SettingsRepository>(() => SettingsRepositoryImpl(getIt<LocalStorageService>()))
    ..registerFactory(() => SettingsCubit(getIt()));

  // Global Blocs
  getIt.registerFactory(() => AppBloc());
}

