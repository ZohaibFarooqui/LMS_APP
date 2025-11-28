import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/entities/leave_request.dart';
import '../../../domain/usecases/submit_leave_request_usecase.dart';

part 'leave_application_event.dart';
part 'leave_application_state.dart';

class LeaveApplicationBloc extends Bloc<LeaveApplicationEvent, LeaveApplicationState> {
  LeaveApplicationBloc(this._submitUseCase) : super(LeaveApplicationState.initial()) {
    on<LeaveTypeChanged>(_onTypeChanged);
    on<LeaveDatesChanged>(_onDatesChanged);
    on<LeaveReasonChanged>(_onReasonChanged);
    on<LeaveHalfDayToggled>(_onHalfDayToggled);
    on<LeaveSubmitted>(_onSubmitted);
  }

  final SubmitLeaveRequestUseCase _submitUseCase;
  final _uuid = const Uuid();

  void _onTypeChanged(LeaveTypeChanged event, Emitter<LeaveApplicationState> emit) {
    final autoReason = _reasonForType(event.leaveType) ?? state.reason;
    emit(state.copyWith(leaveType: event.leaveType, reason: autoReason));
  }

  void _onDatesChanged(LeaveDatesChanged event, Emitter<LeaveApplicationState> emit) {
    emit(state.copyWith(fromDate: event.from, toDate: event.to));
  }

  void _onReasonChanged(LeaveReasonChanged event, Emitter<LeaveApplicationState> emit) {
    emit(state.copyWith(reason: event.reason));
  }

  void _onHalfDayToggled(LeaveHalfDayToggled event, Emitter<LeaveApplicationState> emit) {
    emit(state.copyWith(halfDay: event.halfDay));
  }

  Future<void> _onSubmitted(LeaveSubmitted event, Emitter<LeaveApplicationState> emit) async {
    emit(state.copyWith(status: LeaveApplicationStatus.submitting));
    try {
      final request = LeaveRequest(
        id: _uuid.v4(),
        type: state.leaveType,
        fromDate: state.fromDate,
        toDate: state.toDate,
        status: LeaveStatus.pending,
        reason: state.reason,
        halfDay: state.halfDay,
      );
      _validate(request);
      await _submitUseCase(request);
      emit(state.copyWith(status: LeaveApplicationStatus.success));
    } catch (error) {
      emit(state.copyWith(status: LeaveApplicationStatus.failure, errorMessage: error.toString()));
    }
  }

  void _validate(LeaveRequest request) {
    if (request.type.isEmpty) {
      throw Exception('Select leave type');
    }
    if (request.fromDate.isAfter(request.toDate)) {
      throw Exception('From date cannot be after To date');
    }
    final now = DateTime.now();
    if (request.type != 'OD' && request.fromDate.isBefore(DateTime(now.year, now.month, now.day))) {
      throw Exception('Cannot apply leave for past dates (except OD)');
    }
    if (request.halfDay && request.fromDate != request.toDate) {
      throw Exception('Half-day allowed only for single-day leave');
    }
  }

  String? _reasonForType(String type) {
    switch (type) {
      case 'ML':
        return 'Medical Leave due to health reasons';
      case 'SL':
        return 'Sick Leave';
      case 'OD':
        return 'Out Door Duty for official purpose';
      default:
        return null;
    }
  }
}

