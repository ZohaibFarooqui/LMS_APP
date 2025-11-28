import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:lms/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:lms/features/dashboard/domain/usecases/get_dashboard_summary_usecase.dart';
import 'package:lms/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:lms/features/leaves/domain/entities/leave_balance.dart';

class _MockGetDashboardSummaryUseCase extends Mock implements GetDashboardSummaryUseCase {}

void main() {
  late GetDashboardSummaryUseCase useCase;
  late DashboardBloc bloc;
  final cachedSummary = DashboardSummary(
    userName: 'Cached',
    employeeCode: 'EMP001',
    cadre: 'Cadre',
    designation: 'Role',
    department: 'Dept',
    location: 'HQ',
    cardNumber: 'CARD',
    balances: const [LeaveBalance(code: 'CL', name: 'Casual Leave', balance: 5)],
  );
  final refreshedSummary = DashboardSummary(
    userName: 'Refreshed',
    employeeCode: 'EMP001',
    cadre: 'Cadre',
    designation: 'Role',
    department: 'Dept',
    location: 'HQ',
    cardNumber: 'CARD',
    balances: const [LeaveBalance(code: 'CL', name: 'Casual Leave', balance: 8)],
  );

  setUp(() {
    useCase = _MockGetDashboardSummaryUseCase();
    bloc = DashboardBloc(useCase);
  });

  test('SPRITE: Dashboard emits cached then refreshed summary', () async {
    when(() => useCase.cached()).thenReturn(cachedSummary);
    when(() => useCase()).thenAnswer((_) async => refreshedSummary);

    final states = <DashboardState>[];
    final subscription = bloc.stream.listen(states.add);

    bloc.add(const DashboardRequested());
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(states.first.summary?.userName, equals('Cached'));
    expect(states.last.summary?.userName, equals('Refreshed'));

    await subscription.cancel();
  });
}

