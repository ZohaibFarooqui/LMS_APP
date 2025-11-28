import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/dashboard_summary.dart';
import '../../domain/usecases/get_dashboard_summary_usecase.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc(this._useCase) : super(const DashboardState()) {
    on<DashboardRequested>(_onRequested);
  }

  final GetDashboardSummaryUseCase _useCase;

  Future<void> _onRequested(DashboardRequested event, Emitter<DashboardState> emit) async {
    final cached = _useCase.cached();
    if (cached != null) {
      emit(state.copyWith(status: DashboardStatus.success, summary: cached));
    } else {
      emit(state.copyWith(status: DashboardStatus.loading));
    }
    try {
      final summary = await _useCase();
      emit(state.copyWith(status: DashboardStatus.success, summary: summary));
    } catch (error) {
      emit(state.copyWith(status: DashboardStatus.failure, errorMessage: error.toString()));
    }
  }
}

