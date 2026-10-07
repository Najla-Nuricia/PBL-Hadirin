import 'package:flutter/material.dart';

import '../../../../theme/style/auth_style.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({
    required this.title,
    required this.activeSteps,
    this.totalSteps = 2,
    this.subtitle,
    this.onBack,
    super.key,
  });

  final String title;
  final int activeSteps;
  final int totalSteps;
  final String? subtitle;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasBackButton = onBack != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AuthStyle.headerHorizontalPadding,
        hasBackButton ? 40 : 48,
        AuthStyle.headerHorizontalPadding,
        hasBackButton ? 16 : 32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StepIndicator(activeSteps: activeSteps, totalSteps: totalSteps),
          SizedBox(height: hasBackButton ? 16 : 32),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal:
                  AuthStyle.contentHorizontalPadding -
                  AuthStyle.headerHorizontalPadding,
            ),
            child: _buildTitleBlock(colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleBlock(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (onBack != null)
          TextButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.chevron_left, size: 20),
            label: const Text('Kembali'),
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.onSurfaceVariant,
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(
                fontSize: AuthStyle.bodySize,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        Text(
          title,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: AuthStyle.titleSize,
            fontWeight: FontWeight.w700,
            height: 32 / AuthStyle.titleSize,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: AuthStyle.bodySize,
            ),
          ),
        ],
      ],
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.activeSteps, required this.totalSteps});

  final int activeSteps;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      label: 'Langkah $activeSteps dari $totalSteps',
      child: Row(
        children: [
          for (var step = 0; step < totalSteps; step++) ...[
            if (step > 0) const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: AuthStyle.stepIndicatorHeight,
                decoration: BoxDecoration(
                  color: step < activeSteps
                      ? colorScheme.primary
                      : colorScheme.outline,
                  borderRadius: BorderRadius.circular(
                    AuthStyle.stepIndicatorHeight,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
