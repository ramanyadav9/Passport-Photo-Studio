import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/photo_spec.dart';
import '../state/studio_state.dart';
import '../theme.dart';
import '../widgets/crop_canvas.dart';
import '../widgets/primary_button.dart';
import '../widgets/selector_chip.dart';

class CropScreen extends StatelessWidget {
  const CropScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<StudioState>();
    final photo = state.activePhoto;

    if (photo == null) return const _NoPhotoYet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Stack(
            children: [
              CropCanvas(
                // Keyed by photo so the gesture base resets cleanly when the
                // user switches between people.
                key: ValueKey(photo.id),
                photo: photo,
                spec: state.photoSpec,
                onChanged: state.updateActiveTransform,
              ),
              const Positioned(
                top: AppSpacing.stackMd,
                left: 0,
                right: 0,
                child: IgnorePointer(child: Center(child: _HintPill())),
              ),
            ],
          ),
        ),
        if (state.photos.length > 1) _PhotoSwitcher(state: state),
        _Controls(state: state),
      ],
    );
  }
}

class _HintPill extends StatelessWidget {
  const _HintPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadii.chip),
      ),
      child: Text(
        'Pinch to zoom, drag to pan',
        style: Theme.of(context).textTheme.labelBold,
      ),
    );
  }
}

/// Lets the user move between people without leaving the crop editor. Each
/// photo keeps its own zoom and pan.
class _PhotoSwitcher extends StatelessWidget {
  const _PhotoSwitcher({required this.state});

  final StudioState state;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.pageMargin,
          0,
          AppSpacing.pageMargin,
          AppSpacing.stackSm,
        ),
        itemCount: state.photos.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.stackSm),
        itemBuilder: (context, i) {
          final photo = state.photos[i];
          final isActive = photo.id == state.activePhoto?.id;

          return Semantics(
            button: true,
            selected: isActive,
            label: 'Adjust photo ${i + 1} of ${state.photos.length}',
            child: GestureDetector(
              onTap: () => state.setActivePhoto(photo.id),
              child: Container(
                width: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadii.chip),
                  border: Border.all(
                    color: isActive
                        ? AppColors.primary
                        : AppColors.outlineVariant,
                    width: isActive ? 3 : 1.5,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.memory(
                  photo.bytes,
                  fit: BoxFit.cover,
                  cacheWidth: 168,
                  gaplessPlayback: true,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.state});

  final StudioState state;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.pageMargin,
        AppSpacing.stackSm,
        AppSpacing.pageMargin,
        AppSpacing.gutter,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rotate shares the heading's row rather than taking one of its own.
          // Every row down here is a row the photo does not get, and on this
          // screen the photo is the thing being worked on.
          Row(
            children: [
              Semantics(
                header: true,
                child: Text('Photo Format', style: text.labelBold),
              ),
              const Spacer(),
              _RotateButton(onTap: state.rotateActivePhoto),
            ],
          ),
          const SizedBox(height: AppSpacing.stackSm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final spec in PhotoSpec.presets) ...[
                  SelectorChip(
                    label: spec.name,
                    isSelected: state.photoSpec == spec,
                    onTap: () => state.setPhotoSpec(spec),
                  ),
                  const SizedBox(width: AppSpacing.stackSm),
                ],
                SelectorChip(
                  label: state.photoSpec.isCustom
                      ? '${_trim(state.photoSpec.widthMm)}'
                            'x${_trim(state.photoSpec.heightMm)}mm'
                      : 'Custom',
                  isSelected: state.photoSpec.isCustom,
                  onTap: () => _askCustomSize(context, state),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.gutter),
          PrimaryButton(
            label: 'Confirm Alignment',
            expand: true,
            onPressed: state.nextStep,
          ),
          // Keeps the button clear of the gesture bar without the extra block
          // of padding a fixed margin would add.
          SizedBox(height: MediaQuery.paddingOf(context).bottom > 0 ? 0 : 4),
        ],
      ),
    );
  }

  static String _trim(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  Future<void> _askCustomSize(BuildContext context, StudioState state) async {
    final result = await showDialog<PhotoSpec>(
      context: context,
      builder: (_) => _CustomSizeDialog(current: state.photoSpec),
    );
    if (result != null) state.setPhotoSpec(result);
  }
}

/// Straightens a photo that arrived sideways. One button turning one way is
/// less to think about than two buttons turning opposite ways — four taps
/// return to the start.
class _RotateButton extends StatelessWidget {
  const _RotateButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Rotate photo a quarter turn to the right',
      child: SizedBox(
        height: AppSpacing.touchTargetMin,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.rotate_90_degrees_cw_outlined, size: 22),
          label: Text('Rotate', style: Theme.of(context).textTheme.labelBold),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary, width: 2),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.chip),
            ),
          ),
        ),
      ),
    );
  }
}

/// Width and height in millimetres, for a size the presets do not cover.
class _CustomSizeDialog extends StatefulWidget {
  const _CustomSizeDialog({required this.current});

  final PhotoSpec current;

  @override
  State<_CustomSizeDialog> createState() => _CustomSizeDialogState();
}

class _CustomSizeDialogState extends State<_CustomSizeDialog> {
  late final _width = TextEditingController(
    text: widget.current.widthMm.toStringAsFixed(0),
  );
  late final _height = TextEditingController(
    text: widget.current.heightMm.toStringAsFixed(0),
  );
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _width.dispose();
    _height.dispose();
    super.dispose();
  }

  String? _validate(String? raw) {
    final value = double.tryParse(raw?.trim() ?? '');
    if (value == null) return 'Enter a number';
    if (value < 10) return 'At least 10 mm';
    if (value > 300) return 'At most 300 mm';
    return null;
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;
    Navigator.pop(
      context,
      PhotoSpec.custom(
        double.parse(_width.text.trim()),
        double.parse(_height.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return AlertDialog(
      backgroundColor: AppColors.background,
      title: Text('Custom size', style: text.headlineLg),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field('Width (mm)', _width),
            const SizedBox(height: AppSpacing.gutter),
            _field('Height (mm)', _height),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: text.labelBold),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          child: Text('Use size', style: text.labelBold),
        ),
      ],
    );
  }

  Widget _field(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      validator: _validate,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      style: const TextStyle(fontSize: 20),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 18),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
          borderRadius: BorderRadius.circular(AppRadii.chip),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.chip),
        ),
      ),
    );
  }
}

class _NoPhotoYet extends StatelessWidget {
  const _NoPhotoYet();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final state = context.read<StudioState>();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.pageMargin),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.photo_outlined,
              size: 64,
              color: AppColors.outline,
            ),
            const SizedBox(height: AppSpacing.gutter),
            Text(
              'Add a photo first.',
              style: text.headlineLg,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.stackSm),
            Text(
              'There is nothing to adjust yet.',
              style: text.bodyLg.copyWith(color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.stackMd),
            PrimaryButton(
              label: 'Go to Step 1',
              onPressed: () => state.goToStep(WorkflowStep.add),
            ),
          ],
        ),
      ),
    );
  }
}
