import 'package:flutter/material.dart';

import 'package:bookslane_app/core/config/config.dart';
import 'package:bookslane_app/core/theme/theme.dart';

/// White header: logo, app name with the current section, notification bell.
class DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DashboardAppBar({
    super.key,
    required this.section,
    this.notificationCount = 0,
    this.onNotificationsPressed,
    this.onLogoutPressed,
  });

  /// Shown under the app name — "Home", "Orders", ...
  final String section;
  final int notificationCount;
  final VoidCallback? onNotificationsPressed;

  /// Shows a sign-out button when provided.
  final VoidCallback? onLogoutPressed;

  /// Also the offset the notifications dropdown hangs from.
  static const double height = 72;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceBackground,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                SizedBox(
                  width: AppSizes.tileMd,
                  height: AppSizes.tileMd,
                  child: ClipOval(child: Image.asset(AppAssets.logo)),
                ),

                const SizedBox(width: AppSpacing.sm),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Both single-line: a long section name ("My
                      // Publishings") would otherwise wrap and overflow the
                      // fixed-height bar.
                      Text(
                        AppConstants.appName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.titleLarge,
                      ),
                      Text(
                        section,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMedium,
                      ),
                    ],
                  ),
                ),

                _NotificationButton(
                  count: notificationCount,
                  onPressed: onNotificationsPressed,
                ),

                if (onLogoutPressed != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  IconButton(
                    onPressed: onLogoutPressed,
                    tooltip: 'Log out',
                    icon: const Icon(Icons.logout_rounded),
                    color: AppColors.iconPrimary,
                    iconSize: AppSizes.iconLg,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bell in a tinted circle with an unread-count badge.
class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.count, this.onPressed});

  final int count;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: AppColors.inputBackground,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox(
              width: AppSizes.tileMd,
              height: AppSizes.tileMd,
              child: Icon(
                Icons.notifications_none_rounded,
                size: AppSizes.iconLg,
                color: AppColors.iconPrimary,
              ),
            ),
          ),
        ),

        if (count > 0)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: AppSizes.badge,
              height: AppSizes.badge,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.ctaBackground,
                shape: BoxShape.circle,
              ),
              child: Text(
                count > 9 ? '9+' : '$count',
                style: AppTypography.caption.copyWith(
                  color: AppColors.inverseText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
