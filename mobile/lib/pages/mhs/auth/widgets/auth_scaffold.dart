import 'package:flutter/material.dart';

import '../../../../theme/style/auth_style.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AuthStyle.maxContentWidth,
          ),
          child: SizedBox.expand(
            child: ColoredBox(
              color: colorScheme.surface,
              child: Column(
                children: [
                  Expanded(child: SafeArea(bottom: false, child: child)),
                  Container(
                    height: AuthStyle.bottomAccentHeight,
                    color: colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
