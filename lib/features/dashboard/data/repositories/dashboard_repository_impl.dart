import '../../domain/entities/dashboard_summary.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_data_source.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl(this._remoteDataSource, this._empPkProvider);

  final DashboardRemoteDataSource _remoteDataSource;
  final Future<String?> Function() _empPkProvider;

  DashboardSummary? _cache;

  @override
  DashboardSummary? cachedDashboard() => _cache;

  @override
  Future<DashboardSummary> fetchDashboard() async {
    final empPk = await _empPkProvider() ?? '';
    final summary = await _remoteDataSource.fetchDashboard(empPk);
    _cache = summary;
    return summary;
  }
}
