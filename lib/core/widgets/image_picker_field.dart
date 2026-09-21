import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:bookslane_app/core/theme/theme.dart';
import 'package:bookslane_app/core/widgets/app_toast.dart';

/// A file input for a single image — the form's equivalent of `<input
/// type="file" accept="image/*">`.
///
/// Empty it is a tappable drop zone; once a file is picked it becomes a
/// thumbnail with the file name, a size read-out and a remove button. Tapping
/// it offers Gallery or Camera in a bottom sheet.
///
/// It is a [FormField] so the surrounding `Form` validates and saves it along
/// with every text field — no separate "did they pick an image?" check at
/// submit time.
///
/// Preview uses [Image.memory] rather than `Image.file` on purpose: `dart:io`
/// is not available on web, and the bytes read works on every platform.
class ImagePickerField extends FormField<XFile> {
  ImagePickerField({
    super.key,
    XFile? value,
    required this.onChanged,
    super.validator,
    super.onSaved,
    this.hintText = 'Choose an image',
    this.helperText,
    this.maxWidth = 1600,
    this.imageQuality = 85,
  }) : super(
         initialValue: value,
         builder: (FormFieldState<XFile> state) =>
             _ImagePickerFieldView(state: state as _ImagePickerFieldState),
       );

  /// Called with the new file, or null when the user removes it.
  final ValueChanged<XFile?> onChanged;

  final String hintText;
  final String? helperText;

  /// Downscale on pick, so a 12MP camera shot is not what gets uploaded.
  final double maxWidth;
  final int imageQuality;

  @override
  FormFieldState<XFile> createState() => _ImagePickerFieldState();
}

class _ImagePickerFieldState extends FormFieldState<XFile> {
  final _picker = ImagePicker();

  @override
  ImagePickerField get widget => super.widget as ImagePickerField;

  Future<void> pick(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: widget.maxWidth,
        imageQuality: widget.imageQuality,
      );
      // Null means the user backed out of the picker — leave the current
      // selection alone rather than clearing it.
      if (file == null) return;

      didChange(file);
      widget.onChanged(file);
    } on Exception catch (_) {
      if (!mounted) return;
      AppToast.error(context, 'Could not open the image picker.');
    }
  }

  void clear() {
    didChange(null);
    widget.onChanged(null);
  }

  Future<void> promptForSource() async {
    // Keyboard down first, or the sheet fights it for the bottom of the screen.
    FocusScope.of(context).unfocus();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.sheetBackground,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetTop),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.sm),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text('Choose from gallery', style: AppTypography.bodyLarge),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text('Take a photo', style: AppTypography.bodyLarge),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
        ),
      ),
    );

    if (source != null) await pick(source);
  }
}

class _ImagePickerFieldView extends StatelessWidget {
  const _ImagePickerFieldView({required this.state});

  final _ImagePickerFieldState state;

  @override
  Widget build(BuildContext context) {
    final file = state.value;
    final hasError = state.hasError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: AppColors.inputBackground,
          borderRadius: AppRadius.mdAll,
          child: InkWell(
            borderRadius: AppRadius.mdAll,
            onTap: state.promptForSource,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              constraints: const BoxConstraints(
                minHeight: AppSizes.inputHeight,
              ),
              decoration: BoxDecoration(
                borderRadius: AppRadius.mdAll,
                border: Border.all(
                  color: hasError
                      ? AppColors.inputBorderError
                      : AppColors.inputBorder,
                  width: AppSizes.borderWidth,
                ),
              ),
              child: file == null
                  ? _EmptyState(hintText: state.widget.hintText)
                  : _SelectedState(file: file, onRemove: state.clear),
            ),
          ),
        ),

        if (hasError)
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.xs,
              left: AppSpacing.sm,
            ),
            child: Text(
              state.errorText!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.errorText,
              ),
            ),
          )
        else if (state.widget.helperText != null)
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.xs,
              left: AppSpacing.sm,
            ),
            child: Text(
              state.widget.helperText!,
              style: AppTypography.caption,
            ),
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hintText});

  final String hintText;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: AppSpacing.xs),
        Icon(
          Icons.add_photo_alternate_outlined,
          size: AppSizes.iconMd,
          color: AppColors.inputPrefixIcon,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(hintText, style: AppTypography.hint)),
        Text('Browse', style: AppTypography.link),
        const SizedBox(width: AppSpacing.xs),
      ],
    );
  }
}

class _SelectedState extends StatelessWidget {
  const _SelectedState({required this.file, required this.onRemove});

  final XFile file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: AppRadius.xsAll,
          child: FutureBuilder<Uint8List>(
            // `file.path` cannot be read with Image.file on web; bytes can.
            future: file.readAsBytes(),
            builder: (context, snapshot) {
              final bytes = snapshot.data;
              if (bytes == null) {
                return Container(
                  width: AppSizes.tileLg,
                  height: AppSizes.tileLg,
                  color: AppColors.dividerColor,
                );
              }
              return Image.memory(
                bytes,
                width: AppSizes.tileLg,
                height: AppSizes.tileLg,
                fit: BoxFit.cover,
              );
            },
          ),
        ),

        const SizedBox(width: AppSpacing.sm),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                // XFile derives `name` from its path, which a file built from
                // raw bytes does not have. Better a generic label than a blank
                // row where the file name should be.
                file.name.isNotEmpty ? file.name : 'Selected image',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.bodyText,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text('Tap to replace', style: AppTypography.caption),
            ],
          ),
        ),

        IconButton(
          onPressed: onRemove,
          icon: const Icon(Icons.close_rounded, size: AppSizes.iconMd),
          color: AppColors.iconMuted,
          tooltip: 'Remove image',
        ),
      ],
    );
  }
}
