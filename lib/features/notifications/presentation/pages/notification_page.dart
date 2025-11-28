import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../di/service_locator.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../bloc/notification_bloc.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<NotificationBloc>()..add(const NotificationsRequested()),
      child: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state.status == NotificationStatus.loading) {
            return const LoadingIndicator();
          }
          if (state.notifications.isEmpty) {
            return const Center(child: Text('No notifications'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final notification = state.notifications[index];
              return AppCard(
                child: ListTile(
                  title: Text(notification.title),
                  subtitle: Text(notification.body),
                  trailing: notification.isRead ? null : const Icon(Icons.brightness_1, size: 10, color: Colors.red),
                  onTap: () => context.read<NotificationBloc>().add(NotificationRead(notification.id)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

