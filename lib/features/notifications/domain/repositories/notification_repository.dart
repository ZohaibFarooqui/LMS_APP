import '../entities/notification_message.dart';

abstract class NotificationRepository {
  Future<List<NotificationMessage>> fetchNotifications();
  Future<void> markAsRead(String id);
  List<NotificationMessage>? cachedNotifications();
}

