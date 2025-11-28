import '../../../../data/datasources/lms_local_data_source.dart';
import '../../../../data/datasources/lms_remote_data_source.dart';
import '../../domain/entities/notification_message.dart';
import '../../domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl(this._remote, this._local);

  final LmsRemoteDataSource _remote;
  final LmsLocalDataSource _local;

  @override
  List<NotificationMessage>? cachedNotifications() => _local.notifications();

  @override
  Future<List<NotificationMessage>> fetchNotifications() async {
    final items = await _remote.notifications();
    await _local.cacheNotifications(items);
    return items;
  }

  @override
  Future<void> markAsRead(String id) async {
    final cached = _local.notifications() ?? [];
    final updated = cached.map((e) => e.id == id ? e.copyWith(isRead: true) : e).toList();
    await _local.cacheNotifications(updated);
  }
}

