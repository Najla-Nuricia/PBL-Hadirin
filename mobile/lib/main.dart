// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'routing/admin_router.dart';
import 'routing/lecturer_router.dart';
import 'routing/student_router.dart';
import 'theme/app_theme.dart';

const _appRole = String.fromEnvironment('APP_ROLE', defaultValue: 'student');

void main() {
  runApp(const ProviderScope(child: HadirinApp()));
}

class HadirinApp extends StatelessWidget {
  const HadirinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Hadirin',
      theme: AppTheme.light,
      routerConfig: switch (_appRole) {
        'student' => createStudentRouter(showOnboarding: true),
        'lecturer' => createLecturerRouter(showOnboarding: true),
        _ => createAdminRouter(showOnboarding: true),
      },
    );
  }
}
