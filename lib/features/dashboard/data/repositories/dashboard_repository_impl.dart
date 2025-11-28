import '../../../../data/datasources/lms_local_data_source.dart';
import '../../../../data/datasources/lms_remote_data_source.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/repositories/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl(this._remoteDataSource, this._localDataSource);

  final LmsRemoteDataSource _remoteDataSource;
  final LmsLocalDataSource _localDataSource;

  @override
  DashboardSummary? cachedDashboard() {
    return _localDataSource.dashboard();
  }

  @override
  Future<DashboardSummary> fetchDashboard() async {
    final summary = await _remoteDataSource.dashboard();
    await _localDataSource.cacheDashboard(summary);
    return summary;
  }
}

