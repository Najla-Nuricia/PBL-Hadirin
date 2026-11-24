import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../../theme/style/auth_style.dart';
import '../../../../widgets/widgets.dart';

/// Kepala layar auth di atas langit: logo atau tombol kembali, indikator
/// langkah, judul, dan keterangan. Tepi awan di bawahnya menyambung ke
/// formulir.
class AuthHeader extends StatelessWidget {
  const AuthHeader({
    required this.title,
    required this.activeSteps,
    this.totalSteps = 1,
    this.subtitle,
    this.onBack,
    super.key,
  });

  final String title;

  /// Langkah yang sedang dijalani, dihitung dari 1.
  final int activeSteps;

  /// Jumlah langkah alur ini. Indikator hanya tampil bila lebih dari satu.
  final int totalSteps;
  final String? subtitle;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    // Pemanggil yang hanya mengirim `activeSteps: 2` tetap mendapat dua segmen.
    final steps = math.max(totalSteps, activeSteps);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: SkyHeader(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tingginya tetap dipesan walau tanpa tombol, supaya judul tidak
            // bergeser saat berpindah dari login ke registrasi.
            SizedBox(
              height: AppSizes.touch,
              child: onBack == null
                  ? const Align(
                      alignment: Alignment.centerLeft,
                      child: WordmarkPill(),
                    )
                  : Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: onBack,
                        tooltip: 'Kembali',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.gownNavy,
                        ),
                        icon: const Icon(PhosphorIconsRegular.arrowLeft),
                      ),
                    ),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (steps > 1) ...[
              _StepIndicator(activeSteps: activeSteps, totalSteps: steps),
              const SizedBox(height: AppSpacing.lg),
            ],
            Semantics(
              header: true,
              child: Text(
                title,
                style: text.headlineLarge?.copyWith(
                  color: AppColors.gownNavy,
                ),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle!,
                style: text.bodyLarge?.copyWith(
                  color: AppColors.gownNavy,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.activeSteps, required this.totalSteps});

  final int activeSteps;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Posisi langkah ditulis juga, tidak hanya dibedakan lewat warna.
        Text(
          'Langkah $activeSteps dari $totalSteps',
          style: Theme.of(context).textTheme.labelMedium?.tabular.copyWith(
            color: AppColors.gownNavy,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ExcludeSemantics(
          child: Row(
            spacing: AppSpacing.xs,
            children: [
              for (var step = 0; step < totalSteps; step++)
                Expanded(
                  child: Container(
                    height: AuthStyle.stepIndicatorHeight,
                    decoration: BoxDecoration(
                      color: step < activeSteps
                          ? AppColors.gownNavy
                          : Colors.white.withValues(alpha: 0.55),
                      borderRadius: AppRadius.pill,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
