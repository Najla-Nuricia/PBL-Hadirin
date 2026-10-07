import 'package:flutter/material.dart';

import '../../../../theme/style/auth_style.dart';

class AuthInfoBanner extends StatelessWidget {
  const AuthInfoBanner({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(AuthStyle.fieldRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              Icons.info_outline,
              size: 16,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: colorScheme.primary,
                fontSize: AuthStyle.captionSize,
                height: 16 / AuthStyle.captionSize,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
