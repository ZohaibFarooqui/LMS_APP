part of 'notification_bloc.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

class NotificationsRequested extends NotificationEvent {
  const NotificationsRequested();
}

class NotificationRead extends NotificationEvent {
  const NotificationRead(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

