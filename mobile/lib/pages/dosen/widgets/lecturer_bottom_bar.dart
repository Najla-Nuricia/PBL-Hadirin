import 'package:flutter/material.dart';

import '../../../theme/style/lecturer_style.dart';
import 'content_constraint.dart';

/// Batang aksi di dasar layar, dipisah dari isi oleh garis tipis.
class LecturerBottomBar extends StatelessWidget {
  const LecturerBottomBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Padding(
        // Di dalam shell jarak ini nol. Tanpa shell, tombol ikut naik agar
        // tidak tertutup papan ketik.
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: LecturerStyle.bottomBarInsets,
            // Column memberi tinggi tak terbatas ke isinya, sehingga isi
            // seperti AppBanner tidak melar setinggi layar.
            child: ContentConstraint(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [child],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
