import 'package:flutter/material.dart';

import 'package:bookslane_app/core/theme/theme.dart';

/// What a notification is about. Drives the colour of its leading dot.
enum NotificationKind {
  order,
  visit,
  stock,
  delivery,
  report;

  Color get dotColor => switch (this) {
    NotificationKind.order => AppColors.successText,
    NotificationKind.visit => AppColors.brandPrimary,
    NotificationKind.stock => AppColors.warningText,
    NotificationKind.delivery => AppColors.ctaBackground,
    NotificationKind.report => AppColors.brandPrimary,
  };
}

/// One row in the notifications panel.
@immutable
class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.timeAgo,
    this.isRead = false,
  });

  final String id;
  final NotificationKind kind;
  final String title;
  final String body;

  /// Preformatted for display: "5 min ago", "3 hours ago".
  final String timeAgo;

  final bool isRead;

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id,
    kind: kind,
    title: title,
    body: body,
    timeAgo: timeAgo,
    isRead: isRead ?? this.isRead,
  );
}
