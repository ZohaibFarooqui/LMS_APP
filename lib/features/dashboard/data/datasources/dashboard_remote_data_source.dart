import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../models/dashboard_summary_model.dart';

abstract class DashboardRemoteDataSource {
  Future<DashboardSummaryModel> fetchDashboard(String empPk);
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  DashboardRemoteDataSourceImpl({Dio? dio}) : _dio = dio ?? DioClient.instance;

  final Dio _dio;

  @override
  Future<DashboardSummaryModel> fetchDashboard(String empPk) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/data',
      queryParameters: {'emp_pk': empPk},
    );
    final body = response.data?['body'] as Map<String, dynamic>? ?? {};
    return DashboardSummaryModel.fromJson(body);
  }
}
