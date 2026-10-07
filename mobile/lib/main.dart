import 'package:flutter/material.dart';

import 'routing/student_router.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const HadirinApp());
}

class HadirinApp extends StatelessWidget {
  const HadirinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Hadirin',
      theme: AppTheme.light,
      routerConfig: studentRouter,
    );
  }
}
