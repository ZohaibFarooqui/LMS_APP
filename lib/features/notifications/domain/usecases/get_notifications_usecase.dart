import '../entities/notification_message.dart';
import '../repositories/notification_repository.dart';

class GetNotificationsUseCase {
  GetNotificationsUseCase(this._repository);

  final NotificationRepository _repository;

  Future<List<NotificationMessage>> call() => _repository.fetchNotifications();
  List<NotificationMessage>? cached() => _repository.cachedNotifications();
}

