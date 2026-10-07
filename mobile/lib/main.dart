import 'package:flutter/material.dart';

import 'routing/student_router.dart';

void main() {
  runApp(const HadirinApp());
}

class HadirinApp extends StatelessWidget {
  const HadirinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Hadirin',
      routerConfig: studentRouter,
    );
  }
}
