import 'package:flutter/material.dart';

class AdminPlaceholderPage extends StatelessWidget {
  const AdminPlaceholderPage({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      body: Center(child: Text(title)),
    );
  }
}
