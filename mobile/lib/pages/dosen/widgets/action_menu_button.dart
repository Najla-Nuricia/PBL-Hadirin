import 'package:flutter/material.dart';

class ActionMenuButton extends StatelessWidget {
  const ActionMenuButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = isDestructive ? scheme.error : scheme.onSurface;
    final iconBg =
        isDestructive ? scheme.errorContainer : scheme.surfaceContainerHighest;
    final iconFg = isDestructive ? scheme.error : scheme.onSurfaceVariant;

    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconFg),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: fg),
                ),
              ),
              Icon(Icons.chevron_right, size: 20, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}