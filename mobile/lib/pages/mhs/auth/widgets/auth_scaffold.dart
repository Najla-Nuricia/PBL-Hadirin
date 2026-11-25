import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../theme/style/auth_style.dart';
import '../../../../widgets/widgets.dart';

/// Kerangka layar auth: langit [AuthHeader] sampai ke balik status bar,
/// isi dibatasi lebarnya di layar lebar.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Layar ini tidak memakai AppBar, jadi warna ikon status bar diatur di
    // sini: gelap di atas langit.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: skyStatusBar,
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        body: AuroraBackground(
          child: SafeArea(
            // Langit di AuthHeader sudah memberi jarak status bar sendiri.
            top: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AuthStyle.maxContentWidth,
                ),
                child: SizedBox.expand(child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
