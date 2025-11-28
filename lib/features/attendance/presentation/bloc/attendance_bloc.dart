import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/attendance_summary.dart';
import '../../domain/usecases/get_attendance_report_usecase.dart';
import '../../domain/usecases/get_attendance_summary_usecase.dart';

part 'attendance_event.dart';
part 'attendance_state.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  AttendanceBloc(
    this._reportUseCase,
    this._summaryUseCase,
  ) : super(AttendanceState.initial()) {
    on<AttendanceRequested>(_onRequested);
    on<AttendanceRangeChanged>(_onRangeChanged);
  }

  final GetAttendanceReportUseCase _reportUseCase;
  final GetAttendanceSummaryUseCase _summaryUseCase;

  Future<void> _onRequested(AttendanceRequested event, Emitter<AttendanceState> emit) async {
    emit(state.copyWith(status: AttendanceStatus.loading));
    final cachedRecords = _reportUseCase.cached();
    final cachedSummary = _summaryUseCase.cached();
    if (cachedRecords != null && cachedSummary != null) {
      emit(
        state.copyWith(
          status: AttendanceStatus.success,
          records: cachedRecords,
          summary: cachedSummary,
        ),
      );
    }
    await _fetchData(state.fromDate, state.toDate, emit);
  }

  Future<void> _onRangeChanged(AttendanceRangeChanged event, Emitter<AttendanceState> emit) async {
    emit(state.copyWith(fromDate: event.from, toDate: event.to, status: AttendanceStatus.loading));
    await _fetchData(event.from, event.to, emit);
  }

  Future<void> _fetchData(DateTime from, DateTime to, Emitter<AttendanceState> emit) async {
    try {
      final results = await Future.wait([
        _reportUseCase(from, to),
        _summaryUseCase(from, to),
      ]);
      emit(
        state.copyWith(
          status: AttendanceStatus.success,
          records: results.first as List<AttendanceRecord>,
          summary: results.last as AttendanceSummary,
        ),
      );
    } catch (error) {
      emit(state.copyWith(status: AttendanceStatus.failure, errorMessage: error.toString()));
    }
  }
}

