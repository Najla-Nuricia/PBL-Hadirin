import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Latar dengan kabut warna lembut di atas kanvas. Dipakai di layar pembuka,
/// auth, dan kepala layar agar permukaannya terasa hidup tanpa mengganggu isi.
class AuroraBackground extends StatelessWidget {
  const AuroraBackground({
    required this.child,
    this.baseColor = AppColors.canvas,
    this.dense = false,
    super.key,
  });

  final Widget child;
  final Color baseColor;

  /// Versi lebih pekat untuk kepala layar berukuran besar.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: baseColor),
          Positioned(
            top: dense ? -170 : -120,
            right: -110,
            child: _Blob(
              color: AppColors.auroraBlobs[0],
              size: dense ? 380 : 300,
            ),
          ),
          Positioned(
            top: dense ? 60 : 40,
            left: -130,
            child: _Blob(
              color: AppColors.auroraBlobs[1],
              size: dense ? 320 : 260,
            ),
          ),
          Positioned(
            bottom: -140,
            right: -40,
            child: _Blob(
              color: AppColors.auroraBlobs[2],
              size: dense ? 300 : 240,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

/// Tombol utama bergradien dengan bayangan biru. Satu aksi utama per layar.
class AppGradientButton extends StatelessWidget {
  const AppGradientButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.isBusy = false,
    this.gradient = AppColors.brandGradient,
    this.foregroundColor = Colors.white,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// Ikon setelah label, misalnya panah pada ajakan "Mulai".
  final IconData? trailingIcon;
  final bool isBusy;
  final Gradient gradient;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isBusy;
    final text = Theme.of(context).textTheme;

    // Label aksesibilitas sama persis dengan teksnya: Appium mencari tombol
    // lewat accessibility id seperti `~Masuk` dan `~Mulai`.
    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      label: label,
      onTap: enabled ? onPressed : null,
      excludeSemantics: true,
      child: AnimatedOpacity(
        duration: AppMotion.fast,
        opacity: enabled ? 1 : 0.55,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AppRadius.control,
            boxShadow: enabled ? AppColors.shadowBrand : null,
          ),
          child: Material(
            color: Colors.transparent,
            clipBehavior: Clip.antiAlias,
            shape: const RoundedRectangleBorder(
              borderRadius: AppRadius.control,
            ),
            child: Ink(
              decoration: BoxDecoration(
                gradient: enabled ? gradient : null,
                color: enabled ? null : AppColors.surfaceInset,
                borderRadius: AppRadius.control,
              ),
              child: InkWell(
                onTap: enabled ? onPressed : null,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: AppSizes.control,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.md,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isBusy)
                          SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: foregroundColor,
                              semanticsLabel: 'Memproses',
                            ),
                          )
                        else if (icon != null)
                          Icon(icon, size: 20, color: foregroundColor),
                        if (isBusy || icon != null)
                          const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: text.labelLarge?.copyWith(
                              color: foregroundColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (trailingIcon != null && !isBusy) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Icon(trailingIcon, size: 20, color: foregroundColor),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Kartu bergradien untuk momen utama, misalnya sesi presensi yang dibuka.
class AppGradientCard extends StatelessWidget {
  const AppGradientCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    this.gradient = AppColors.heroGradient,
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Gradient gradient;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.hero,
        gradient: gradient,
        boxShadow: AppColors.shadowLifted,
      ),
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.hero),
        child: onTap == null
            ? content
            : InkWell(onTap: onTap, child: content),
      ),
    );
  }
}

/// Panel kaca untuk batang navigasi melayang.
class GlassDock extends StatelessWidget {
  const GlassDock({
    required this.child,
    this.margin = const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      0,
      AppSpacing.lg,
      AppSpacing.md,
    ),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          borderRadius: AppRadius.dock,
          boxShadow: AppColors.shadowLifted,
        ),
        child: ClipRRect(
          borderRadius: AppRadius.dock,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.82),
                borderRadius: AppRadius.dock,
                border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Label kecil berlatar lembut, dipakai di atas permukaan gelap.
class OnDarkPill extends StatelessWidget {
  const OnDarkPill({
    required this.label,
    this.color = AppColors.sessionOpen,
    this.icon,
    super.key,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 5, 11, 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: AppRadius.pill,
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
          ] else ...[
            DecoratedBox(
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: const SizedBox.square(dimension: 7),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
