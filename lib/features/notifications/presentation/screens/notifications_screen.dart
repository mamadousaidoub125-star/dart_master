import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

enum NotificationType { friendRequest, tournamentStart, dailyReward, achievement, system }

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime receivedAt;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.receivedAt,
    this.isRead = false,
  });
}

/// Écran centralisant les notifications reçues via Firebase Cloud
/// Messaging (invitations, tournois, récompenses, succès débloqués).
class NotificationsScreen extends StatelessWidget {
  final List<AppNotification> notifications;
  final void Function(AppNotification notification) onTapNotification;
  final VoidCallback onMarkAllRead;

  const NotificationsScreen({
    super.key,
    required this.notifications,
    required this.onTapNotification,
    required this.onMarkAllRead,
  });

  IconData _iconFor(NotificationType type) => switch (type) {
        NotificationType.friendRequest => Icons.person_add,
        NotificationType.tournamentStart => Icons.emoji_events,
        NotificationType.dailyReward => Icons.card_giftcard,
        NotificationType.achievement => Icons.military_tech,
        NotificationType.system => Icons.info,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.midnightBlue,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [TextButton(onPressed: onMarkAllRead, child: const Text('Tout marquer lu', style: TextStyle(color: AppColors.lightGray)))],
      ),
      body: notifications.isEmpty
          ? const Center(child: Text('Aucune notification', style: TextStyle(color: AppColors.lightGray)))
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final n = notifications[index];
                return Container(
                  color: n.isRead ? null : AppColors.electricBlue.withOpacity(0.08),
                  child: ListTile(
                    leading: Icon(_iconFor(n.type), color: AppColors.gold),
                    title: Text(n.title, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w600)),
                    subtitle: Text(n.body, style: const TextStyle(color: AppColors.lightGray, fontSize: 12)),
                    onTap: () => onTapNotification(n),
                  ),
                );
              },
            ),
    );
  }
}
