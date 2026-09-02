import 'package:flutter/material.dart';

import 'package:bookslane_app/core/theme/theme.dart';
import 'package:bookslane_app/features/notifications/presentation/widgets/app_notification.dart';

/// The dropdown card listing recent notifications.
///
/// Unread rows carry a tinted background and a red dot; read rows sit on the
/// plain surface.
class NotificationPanel extends StatelessWidget {
  const NotificationPanel({
    super.key,
    required this.notifications,
    this.onMarkAllRead,
    this.onViewAll,
    this.onNotificationTap,
    this.maxHeight = 420,
  });

  final List<AppNotification> notifications;
  final VoidCallback? onMarkAllRead;
  final VoidCallback? onViewAll;
  final ValueChanged<AppNotification>? onNotificationTap;

  /// The list scrolls past this; the panel never grows beyond it.
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceBackground,
      borderRadius: AppRadius.lgAll,
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Header(onMarkAllRead: onMarkAllRead),

          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: notifications.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return _NotificationTile(
                    notification: notification,
                    onTap: onNotificationTap == null
                        ? null
                        : () => onNotificationTap!(notification),
                  );
                },
              ),
            ),
          ),

          const Divider(height: 1),

          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: onViewAll,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.linkTextBrand,
                textStyle: AppTypography.linkBrand,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: const RoundedRectangleBorder(),
              ),
              child: const Text('View all notifications'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({this.onMarkAllRead});

  final VoidCallback? onMarkAllRead;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Notifications',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.titleLarge,
            ),
          ),
          TextButton.icon(
            onPressed: onMarkAllRead,
            icon: const Icon(Icons.done_all_rounded, size: AppSizes.iconMd),
            label: const Text('Mark all read'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.linkTextBrand,
              textStyle: AppTypography.linkBrand,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, this.onTap});

  final AppNotification notification;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool isUnread = !notification.isRead;

    return Material(
      // Unread rows are tinted so they read as a group at a glance.
      color: isUnread
          ? AppColors.inputBackground
          : AppColors.surfaceBackground,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xxs + 2),
                child: _Dot(color: notification.kind.dotColor, size: 10),
              ),

              const SizedBox(width: AppSpacing.sm),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.titleMedium,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          notification.timeAgo,
                          style: AppTypography.caption,
                        ),
                        if (isUnread) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.xxs),
                            child: _Dot(
                              color: AppColors.ctaBackground,
                              size: 8,
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xxs),

                    Text(notification.body, style: AppTypography.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
