import 'package:flutter/material.dart';

import 'package:bookslane_app/core/theme/theme.dart';

/// A book cover at 2:3. The real image when there is one; otherwise — or if
/// it fails to load — a generated typographic cover, so a shelf of imageless
/// books still reads as books rather than a grid of grey boxes.
///
/// Shared by the Shop and My Store lists.
class BookCover extends StatelessWidget {
  const BookCover({
    super.key,
    required this.title,
    this.author = '',
    this.imageUrl,
    this.seed,
    this.compact = false,
  });

  final String title;
  final String author;
  final String? imageUrl;

  /// Picks the generated cover's colour, so a book keeps it across
  /// rebuilds. Defaults to [title]; pass the book's id when you have it.
  final String? seed;

  /// Smaller type, for the list-view thumbnail.
  final bool compact;

  static const double aspectRatio = 2 / 3;

  @override
  Widget build(BuildContext context) {
    final fallback = _GeneratedCover(
      title: title,
      author: author,
      seed: seed ?? title,
      compact: compact,
    );
    final url = imageUrl;

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppRadius.smAll,
          boxShadow: AppShadows.card,
        ),
        child: ClipRRect(
          borderRadius: AppRadius.smAll,
          child: url == null
              ? fallback
              : Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => fallback,
                ),
        ),
      ),
    );
  }
}

class _GeneratedCover extends StatelessWidget {
  const _GeneratedCover({
    required this.title,
    required this.author,
    required this.seed,
    required this.compact,
  });

  final String title;
  final String author;
  final String seed;
  final bool compact;

  /// Summed code units rather than hashCode, which isn't stable across runs
  /// — a book should keep its colour.
  Color get _tint {
    final sum = seed.codeUnits.fold<int>(0, (a, b) => a + b);
    return AppColors.coverTints[sum % AppColors.coverTints.length];
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _tint,
      child: Padding(
        padding: EdgeInsets.all(compact ? AppSpacing.xxs : AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            Text(
              title,
              maxLines: compact ? 3 : 4,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style:
                  (compact
                          ? AppTypography.caption
                          : AppTypography.headlineMedium)
                      .copyWith(
                        color: AppColors.coverText,
                        height: 1.15,
                        fontWeight: FontWeight.w700,
                      ),
            ),
            const Spacer(flex: 2),
            if (!compact && author.isNotEmpty) ...[
              Center(
                child: Container(
                  width: AppSpacing.lg,
                  height: 2,
                  color: AppColors.coverTextMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                author.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTypography.caption.copyWith(
                  color: AppColors.coverTextMuted,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
