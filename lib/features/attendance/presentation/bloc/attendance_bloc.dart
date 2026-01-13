import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/attendance_record.dart';
import '../../domain/usecases/get_attendance_report_usecase.dart';

part 'attendance_event.dart';
part 'attendance_state.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  AttendanceBloc(this._getAttendanceReportUseCase)
    : super(const AttendanceState()) {
    on<AttendanceRequested>(_onRequested);
  }

  final GetAttendanceReportUseCase _getAttendanceReportUseCase;

  Future<void> _onRequested(
    AttendanceRequested event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(state.copyWith(status: AttendanceStatus.loading, errorMessage: null));
    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month + 1, 0);
      final records = await _getAttendanceReportUseCase(start, end);
      emit(state.copyWith(status: AttendanceStatus.success, records: records));
    } catch (e) {
      emit(
        state.copyWith(
          status: AttendanceStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}






