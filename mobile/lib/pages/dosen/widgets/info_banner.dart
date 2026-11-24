import 'package:flutter/material.dart';

import '../../../widgets/widgets.dart';

class InfoBanner extends StatelessWidget {
  const InfoBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return AppBanner(message: message);
  }
}
