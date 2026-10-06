import 'package:flutter/material.dart';

import 'package:bookslane_app/core/config/config.dart';
import 'package:bookslane_app/core/theme/theme.dart';

/// White header: logo, app name with the current section, notification bell —
/// and, at the right, either a sign-out button or (on the Shop) a cart.
class DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DashboardAppBar({
    super.key,
    required this.section,
    this.notificationCount = 0,
    this.onNotificationsPressed,
    this.onLogoutPressed,
    this.cartCount = 0,
    this.onCartPressed,
  });

  /// Shown under the app name — "Home", "Orders", ...
  final String section;
  final int notificationCount;
  final VoidCallback? onNotificationsPressed;

  /// Shows a sign-out button when provided — unless [onCartPressed] is, which
  /// takes that spot.
  final VoidCallback? onLogoutPressed;

  /// Shows a cart button, with a red count badge like the bell's, in place of
  /// the sign-out button. The Shop passes it; other tabs don't.
  final VoidCallback? onCartPressed;

  /// Units in the cart — the badge on the cart button.
  final int cartCount;

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

                _BadgedCircleButton(
                  icon: Icons.notifications_none_rounded,
                  tooltip: 'Notifications',
                  count: notificationCount,
                  onPressed: onNotificationsPressed,
                ),

                if (onCartPressed != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  _BadgedCircleButton(
                    icon: Icons.shopping_cart_outlined,
                    tooltip: 'Cart',
                    count: cartCount,
                    onPressed: onCartPressed,
                  ),
                ] else if (onLogoutPressed != null) ...[
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

/// An icon in a tinted circle with a red count badge — the bell and the cart
/// are the same widget, so they always look alike.
class _BadgedCircleButton extends StatelessWidget {
  const _BadgedCircleButton({
    required this.icon,
    required this.tooltip,
    required this.count,
    this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final int count;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Stack(
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
                  icon,
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
      ),
    );
  }
}
