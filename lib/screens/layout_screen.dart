import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/paper_spec.dart';
import '../state/studio_state.dart';
import '../theme.dart';
import '../widgets/primary_button.dart';
import '../widgets/selector_chip.dart';
import '../widgets/sheet_preview.dart';

const _paperIcons = <String, IconData>{
  'A4': Icons.description_outlined,
  'Letter': Icons.description_outlined,
  '4x6': Icons.receipt_outlined,
};

class LayoutScreen extends StatelessWidget {
  const LayoutScreen({super.key});

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
          Center(
            child: Column(
              children: [
                Text('3 Layout', style: text.headlineLg),
                const SizedBox(height: AppSpacing.stackSm),
                Text(
                  'Preview and configure your print layout.',
                  textAlign: TextAlign.center,
                  style: text.bodyLg.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.stackMd),

          // The preview always matches the real paper's aspect ratio, so what
          // the user sees is the shape of the sheet that comes out.
          if (!state.hasPhotos)
            SheetPlaceholder(
              aspectRatio: state.paper.aspectRatio,
              message: 'Add a photo in Step 1 to see your sheet.',
            )
          else if (state.layout.photoTooLarge)
            SheetPlaceholder(
              aspectRatio: state.paper.aspectRatio,
              message:
                  'A ${_mm(state.photoSpec.widthMm)}x'
                  '${_mm(state.photoSpec.heightMm)}mm photo does not fit on '
                  '${state.paper.name} paper. Choose a smaller photo size or '
                  'larger paper.',
            )
          else
            SheetPreview(layout: state.layout, photoFor: state.photoById),
          const SizedBox(height: AppSpacing.stackSm),
          Center(
            child: Semantics(
              liveRegion: true,
              child: Text(
                _summary(state),
                style: text.labelMd.copyWith(color: AppColors.onSurfaceVariant),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.stackMd),

          Semantics(
            header: true,
            child: Text('Number of Copies', style: text.labelBold),
          ),
          const SizedBox(height: AppSpacing.gutter),
          Row(
            children: [
              for (final option in CopyCount.values) ...[
                Expanded(
                  child: SelectorChip(
                    label: option.label,
                    isSelected: state.copies == option,
                    onTap: () => state.setCopies(option),
                  ),
                ),
                if (option != CopyCount.values.last)
                  const SizedBox(width: AppSpacing.stackSm),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.stackMd),

          Semantics(
            header: true,
            child: Text('Paper Size', style: text.labelBold),
          ),
          const SizedBox(height: AppSpacing.gutter),
          Row(
            children: [
              for (final paper in PaperSpec.presets) ...[
                Expanded(
                  child: SelectorChip(
                    label: paper.name,
                    icon: _paperIcons[paper.name],
                    isSelected: state.paper == paper,
                    onTap: () => state.setPaper(paper),
                  ),
                ),
                if (paper != PaperSpec.presets.last)
                  const SizedBox(width: AppSpacing.stackSm),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.stackMd),

          const _OriginToggle(),
          const SizedBox(height: AppSpacing.stackMd),

          PrimaryButton(
            label: 'Next to Final Print',
            icon: Icons.arrow_forward,
            expand: true,
            onPressed: state.layout.isEmpty ? null : state.nextStep,
          ),
        ],
      ),
    );
  }

  static String _mm(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  /// Says plainly what was produced, since "Fill" and a too-small page can
  /// both give a different number than the user asked for.
  static String _summary(StudioState state) {
    final placed = state.layout.tiles.length;
    if (placed == 0) return 'Nothing fits on this sheet yet.';

    final people = state.photos.length;
    final each = placed ~/ people;

    final size = '${_mm(state.photoSpec.widthMm)}x'
        '${_mm(state.photoSpec.heightMm)}mm';

    if (people > 1 && each > 0) {
      return '$placed photos on ${state.paper.name} - '
          '$size - about $each each for $people people';
    }
    return '$placed photos on ${state.paper.name} - $size';
  }
}

/// Whether packing starts at the printer's safe area or the true paper corner.
class _OriginToggle extends StatelessWidget {
  const _OriginToggle();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final state = context.watch<StudioState>();
    final isEdge = state.origin == PageOrigin.paperEdge;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.gutter),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Print to paper edge', style: text.labelBold),
                const SizedBox(height: 2),
                Text(
                  isEdge
                      ? 'Tighter packing. Needs a borderless printer.'
                      : 'Keeps a safe margin so nothing is cut off.',
                  style: text.labelMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isEdge,
            activeThumbColor: AppColors.onPrimary,
            activeTrackColor: AppColors.primary,
            onChanged: (v) => state.setOrigin(
              v ? PageOrigin.paperEdge : PageOrigin.printableArea,
            ),
          ),
        ],
      ),
    );
  }
}
