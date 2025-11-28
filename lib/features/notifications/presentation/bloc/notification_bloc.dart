import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/notification_message.dart';
import '../../domain/usecases/get_notifications_usecase.dart';
import '../../domain/usecases/mark_notification_read_usecase.dart';

part 'notification_event.dart';
part 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  NotificationBloc(this._getNotificationsUseCase, this._markReadUseCase)
      : super(const NotificationState()) {
    on<NotificationsRequested>(_onRequested);
    on<NotificationRead>(_onRead);
  }

  final GetNotificationsUseCase _getNotificationsUseCase;
  final MarkNotificationReadUseCase _markReadUseCase;

  Future<void> _onRequested(NotificationsRequested event, Emitter<NotificationState> emit) async {
    final cached = _getNotificationsUseCase.cached();
    if (cached != null) {
      emit(state.copyWith(status: NotificationStatus.success, notifications: cached));
    } else {
      emit(state.copyWith(status: NotificationStatus.loading));
    }
    try {
      final notifications = await _getNotificationsUseCase();
      emit(state.copyWith(status: NotificationStatus.success, notifications: notifications));
    } catch (error) {
      emit(state.copyWith(status: NotificationStatus.failure, errorMessage: error.toString()));
    }
  }

  Future<void> _onRead(NotificationRead event, Emitter<NotificationState> emit) async {
    await _markReadUseCase(event.id);
    final updated = state.notifications
        .map((e) => e.id == event.id ? e.copyWith(isRead: true) : e)
        .toList();
    emit(state.copyWith(notifications: updated));
  }
}

