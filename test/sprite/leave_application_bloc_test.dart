import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:lms/features/leaves/domain/entities/leave_request.dart';
import 'package:lms/features/leaves/domain/usecases/submit_leave_request_usecase.dart';
import 'package:lms/features/leaves/presentation/bloc/leave_application/leave_application_bloc.dart';

class _MockSubmitLeaveRequestUseCase extends Mock implements SubmitLeaveRequestUseCase {}

void main() {
  late SubmitLeaveRequestUseCase submitLeaveRequestUseCase;
  late LeaveApplicationBloc bloc;

  setUp(() {
    submitLeaveRequestUseCase = _MockSubmitLeaveRequestUseCase();
    bloc = LeaveApplicationBloc(submitLeaveRequestUseCase);
    registerFallbackValue(
      LeaveRequest(
        id: 'sample',
        type: 'CL',
        fromDate: DateTime.now(),
        toDate: DateTime.now(),
        status: LeaveStatus.pending,
        reason: '',
      ),
    );
  });

  test('SPRITE: Half-day validation prevents multi-day leave', () async {
    final now = DateTime.now().add(const Duration(days: 5));
    bloc
      ..add(LeaveDatesChanged(now, now.add(const Duration(days: 1))))
      ..add(const LeaveHalfDayToggled(true))
      ..add(const LeaveSubmitted());

    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(bloc.state.status, LeaveApplicationStatus.failure);
    expect(bloc.state.errorMessage, contains('Half-day allowed only for single-day leave'));
    verifyNever(() => submitLeaveRequestUseCase(any()));
  });

  test('SPRITE: Successful leave submission emits success state', () async {
    when(() => submitLeaveRequestUseCase(any())).thenAnswer((_) async {});
    final now = DateTime.now().add(const Duration(days: 5));
    bloc
      ..add(LeaveDatesChanged(now, now))
      ..add(const LeaveReasonChanged('Family visit'))
      ..add(const LeaveHalfDayToggled(false))
      ..add(const LeaveSubmitted());

    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(bloc.state.status, LeaveApplicationStatus.success);
    verify(() => submitLeaveRequestUseCase(any())).called(1);
  });
}

