import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/photo_picker.dart';
import '../state/studio_state.dart';
import '../theme.dart';
import '../widgets/instruction_card.dart';
import '../widgets/photo_thumbnail.dart';
import '../widgets/primary_button.dart';

class AddPhotosScreen extends StatefulWidget {
  const AddPhotosScreen({super.key});

  @override
  State<AddPhotosScreen> createState() => _AddPhotosScreenState();
}

class _AddPhotosScreenState extends State<AddPhotosScreen> {
  final _picker = PhotoPickerService();
  var _busy = false;

  Future<void> _add(BuildContext context, {required bool fromCamera}) async {
    final state = context.read<StudioState>();
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _busy = true);
    try {
      final photos = fromCamera
          ? await _picker.takePhoto(state.nextPhotoId)
          : await _picker.pickFromGallery(state.nextPhotoId);
      state.addPhotos(photos);
    } on PhotoPickerException catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.message, style: const TextStyle(fontSize: 18)),
          backgroundColor: AppColors.guide,
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Camera or gallery, asked as two large buttons rather than a menu.
  Future<void> _chooseSource(BuildContext context) async {
    final fromCamera = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.card),
        ),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.pageMargin),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add a photo',
                style: Theme.of(sheetContext).textTheme.headlineLg,
              ),
              const SizedBox(height: AppSpacing.stackMd),
              PrimaryButton(
                label: 'Take Photo',
                icon: Icons.photo_camera_outlined,
                trailingIcon: false,
                expand: true,
                onPressed: () => Navigator.pop(sheetContext, true),
              ),
              const SizedBox(height: AppSpacing.gutter),
              SizedBox(
                height: AppSpacing.primaryButtonHeight,
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(sheetContext, false),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(
                    'Choose from Gallery',
                    style: Theme.of(sheetContext).textTheme.buttonText,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.button),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (fromCamera == null || !context.mounted) return;
    await _add(context, fromCamera: fromCamera);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final state = context.watch<StudioState>();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageMargin,
        0,
        AppSpacing.pageMargin,
        AppSpacing.stackMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const InstructionCard(
            title: 'Step 1: Add Photos',
            body: 'Tap to add photos from your camera or gallery. '
                'Ensure good lighting and a plain background.',
          ),
          const SizedBox(height: AppSpacing.stackLg),

          Center(
            child: _AddPhotoButton(
              busy: _busy,
              onTap: () => _chooseSource(context),
            ),
          ),
          const SizedBox(height: AppSpacing.stackLg),

          if (state.hasPhotos) ...[
            Text('Selected Photos', style: text.labelBold),
            const SizedBox(height: AppSpacing.gutter),
            SizedBox(
              height: PhotoThumbnail.height + 8,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(top: 8, right: 8),
                itemCount: state.photos.length + 1,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.gutter),
                itemBuilder: (context, i) {
                  if (i == state.photos.length) {
                    return AddMoreTile(onTap: () => _chooseSource(context));
                  }
                  final photo = state.photos[i];
                  return PhotoThumbnail(
                    photo: photo,
                    isActive: photo.id == state.activePhoto?.id,
                    position: i + 1,
                    total: state.photos.length,
                    onSelect: () => state.setActivePhoto(photo.id),
                    onRemove: () => state.removePhoto(photo.id),
                  );
                },
              ),
            ),
          ] else
            _EmptyState(text: text),

          const SizedBox(height: AppSpacing.stackMd),

          Align(
            alignment: Alignment.centerRight,
            child: PrimaryButton(
              label: 'Next Step',
              icon: Icons.arrow_forward,
              // Nothing to adjust until there is a photo, so the way forward
              // stays visibly closed rather than leading to an empty screen.
              onPressed: state.hasPhotos ? state.nextStep : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddPhotoButton extends StatelessWidget {
  const _AddPhotoButton({required this.busy, required this.onTap});

  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Add photo, from camera or gallery',
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppRadii.card),
          ),
          child: busy
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.onPrimary,
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.add_a_photo_outlined,
                      size: 64,
                      color: AppColors.onPrimary,
                    ),
                    const SizedBox(height: AppSpacing.gutter),
                    Text(
                      'Add Photo',
                      style: Theme.of(context).textTheme.labelBold.copyWith(
                        fontSize: 20,
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.text});

  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No photos yet.\nTap the button above to start.',
        textAlign: TextAlign.center,
        style: text.bodyLg.copyWith(color: AppColors.onSurfaceVariant),
      ),
    );
  }
}
