import 'package:flutter/material.dart';

import '../../../../widgets/widgets.dart';

class AuthInfoBanner extends StatelessWidget {
  const AuthInfoBanner({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) => AppBanner(message: message);
}
