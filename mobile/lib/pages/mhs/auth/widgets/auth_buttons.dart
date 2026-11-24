import 'package:flutter/material.dart';

import '../../../../widgets/widgets.dart';

/// Aksi utama formulir: selebar isi, bergradien, dengan indikator saat
/// sedang diproses.
class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppRadius.control,
          gradient: isLoading ? null : AppColors.brandGradient,
          color: isLoading ? AppColors.surfaceInset : null,
          boxShadow: isLoading ? null : AppColors.shadowBrand,
        ),
        child: ClipRRect(
          borderRadius: AppRadius.control,
          child: FilledButton(
            onPressed: isLoading ? null : onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.transparent,
              disabledBackgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.white,
            ),
            child: isLoading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                      semanticsLabel: 'Sedang diproses',
                    ),
                  )
                : Text(label),
          ),
        ),
      ),
    );
  }
}

/// Aksi kedua di bawah aksi utama.
class AuthSecondaryButton extends StatelessWidget {
  const AuthSecondaryButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.7),
          side: const BorderSide(color: AppColors.lineStrong),
        ),
        child: Text(label),
      ),
    );
  }
}
