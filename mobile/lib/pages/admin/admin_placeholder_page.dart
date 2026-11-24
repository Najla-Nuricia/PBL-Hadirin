import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../widgets/widgets.dart';

class AdminPlaceholderPage extends StatelessWidget {
  const AdminPlaceholderPage({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: AppEmptyState(icon: PhosphorIconsRegular.wrench, title: title),
      ),
    );
  }
}
