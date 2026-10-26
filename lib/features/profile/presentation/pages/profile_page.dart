import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bookslane_app/core/theme/theme.dart';
import 'package:bookslane_app/core/widgets/widgets.dart';
import 'package:bookslane_app/features/orders/presentation/order_format.dart';
import 'package:bookslane_app/features/profile/domain/entities/profile.dart';
import 'package:bookslane_app/features/profile/domain/repositories/profile_repository.dart';
import 'package:bookslane_app/features/profile/presentation/providers/profile_provider.dart';

/// The Profile tab: the signed-in owner's `users` row, read-only. The branded
/// app bar (with sign-out) and bottom bar come from DashboardPage.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ProfileProvider>(
      create: (_) => ProfileProvider(context.read<ProfileRepository>())..load(),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();
    final profile = provider.profile;

    if (profile == null) {
      if (provider.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: AppSizes.logoTile,
                color: AppColors.disabledText,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                provider.error ?? 'Something went wrong.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton(
                onPressed: provider.load,
                child: const Text('TRY AGAIN'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: provider.load,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _Header(profile: profile),
          const SizedBox(height: AppSpacing.md),
          _Section(
            title: 'Personal',
            rows: [
              ('First name', profile.firstName),
              ('Last name', profile.lastName),
              ('Email', profile.email),
              ('Mobile', profile.mobile),
              ('Address', profile.address),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _Section(
            title: 'Account',
            rows: [
              ('User Id', profile.id),
              ('Thinkerslane Id', profile.legacyUserId),
              ('Role', profile.roleIds),
              ('Status', profile.isActive ? 'Active' : 'Inactive'),
              ('Created', formatDayTime(profile.createdAt)),
              ('Updated', formatDayTime(profile.updatedAt)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: AppColors.brandPrimary,
          child: Text(
            profile.initials,
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.inverseText,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          profile.fullName.isEmpty ? profile.email : profile.fullName,
          textAlign: TextAlign.center,
          style: AppTypography.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.xxs),
        StatusPill(
          label: profile.isActive ? 'Active' : 'Inactive',
          color: profile.isActive
              ? AppColors.successText
              : AppColors.secondaryText,
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.rows});

  final String title;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceBackground,
        borderRadius: AppRadius.lgAll,
        boxShadow: AppShadows.card,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.titleMedium),
          const Divider(height: AppSpacing.lg),
          for (final (label, value) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 112,
                    child: Text(
                      label,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      value.isEmpty ? '—' : value,
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
