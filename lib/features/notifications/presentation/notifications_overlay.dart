import 'package:flutter/material.dart';

import 'package:bookslane_app/core/theme/theme.dart';
import 'package:bookslane_app/features/notifications/presentation/widgets/app_notification.dart';
import 'package:bookslane_app/features/notifications/presentation/widgets/notification_panel.dart';

/// Opens the notifications dropdown under the app bar.
///
/// A route rather than an [OverlayEntry], so the system back gesture and a tap
/// outside both dismiss it, and focus is trapped while it is open.
///
/// [topOffset] is the distance from the top of the screen to the panel — pass
/// the height of the bar it should hang from.
Future<void> showNotificationsPanel({
  required BuildContext context,
  required List<AppNotification> notifications,
  required double topOffset,
  VoidCallback? onMarkAllRead,
  VoidCallback? onViewAll,
  ValueChanged<AppNotification>? onNotificationTap,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    // A dropdown shouldn't dim the page behind it the way a modal does.
    barrierColor: Colors.transparent,
    transitionDuration: AppDurations.fast,
    pageBuilder: (context, _, _) {
      final media = MediaQuery.of(context);

      return Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: EdgeInsets.only(
            top: media.padding.top + topOffset,
            right: AppSpacing.md,
            // Hangs off the right like a dropdown rather than filling the row.
            left: AppSpacing.xxl,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: AppRadius.lgAll,
                boxShadow: AppShadows.raised,
              ),
              child: NotificationPanel(
                notifications: notifications,
                onMarkAllRead: onMarkAllRead,
                onViewAll: onViewAll,
                onNotificationTap: onNotificationTap,
                // Leave room for the bottom nav and a breath of page below.
                maxHeight: media.size.height * 0.5,
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: AppCurves.standard,
      );
      return FadeTransition(
        opacity: curved,
        // Grows out of the bell in the top-right corner.
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
          alignment: Alignment.topRight,
          child: child,
        ),
      );
    },
  );
}
