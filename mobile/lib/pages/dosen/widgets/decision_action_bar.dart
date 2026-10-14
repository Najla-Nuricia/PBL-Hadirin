import 'package:flutter/material.dart';

import '../../../data/dosen/lecturer_providers.dart';
import '../../../theme/style/lecturer_style.dart';

class DecisionActionBar extends StatelessWidget {
  const DecisionActionBar({
    super.key,
    required this.decision,
    required this.onAccept,
    required this.onReject,
  });

  final LeaveDecision? decision;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(LecturerStyle.controlRadius),
    );
    const size = Size.fromHeight(LecturerStyle.buttonHeight);
    const textStyle = TextStyle(fontSize: 15, fontWeight: FontWeight.w700);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outline)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(LecturerStyle.pagePadding),
          child: decision == null
              ? Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: scheme.secondary,
                          foregroundColor: scheme.onSecondary,
                          minimumSize: size,
                          shape: shape,
                          textStyle: textStyle,
                        ),
                        onPressed: onAccept,
                        child: const Text('Terima'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: scheme.error,
                          side: BorderSide(color: scheme.error),
                          minimumSize: size,
                          shape: shape,
                          textStyle: textStyle,
                        ),
                        onPressed: onReject,
                        child: const Text('Tolak'),
                      ),
                    ),
                  ],
                )
              : _Result(accepted: decision == LeaveDecision.accepted),
        ),
      ),
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({required this.accepted});

  final bool accepted;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final iconColor = accepted ? s.secondary : s.error;
    final textColor = accepted ? s.onSecondaryContainer : s.onErrorContainer;
    return SizedBox(
      height: LecturerStyle.buttonHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(accepted ? Icons.check_circle : Icons.cancel, color: iconColor),
          const SizedBox(width: 8),
          Text(
            accepted ? 'Pengajuan telah diterima' : 'Pengajuan telah ditolak',
            style: TextStyle(fontWeight: FontWeight.w700, color: textColor),
          ),
        ],
      ),
    );
  }
}