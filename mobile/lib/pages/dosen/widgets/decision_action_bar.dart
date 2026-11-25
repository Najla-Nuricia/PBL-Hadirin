import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../data/dosen/lecturer_providers.dart';
import '../../../widgets/widgets.dart';
import 'lecturer_bottom_bar.dart';

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
    final decision = this.decision;

    return LecturerBottomBar(
      child: decision == null
          ? Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: scheme.error,
                      side: BorderSide(color: scheme.error),
                    ),
                    onPressed: onReject,
                    child: const Text('Tolak'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    onPressed: onAccept,
                    child: const Text('Terima'),
                  ),
                ),
              ],
            )
          : _Result(accepted: decision == LeaveDecision.accepted),
    );
  }
}

class _Result extends StatelessWidget {
  const _Result({required this.accepted});

  final bool accepted;

  @override
  Widget build(BuildContext context) {
    return AppBanner(
      tone: accepted ? StatusTone.success : StatusTone.danger,
      icon: accepted ? PhosphorIconsFill.checkCircle : PhosphorIconsFill.xCircle,
      message: accepted
          ? 'Pengajuan telah diterima'
          : 'Pengajuan telah ditolak',
    );
  }
}
