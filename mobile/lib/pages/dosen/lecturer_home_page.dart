import 'package:flutter/material.dart';

import 'widgets/lecturer_app_bar.dart';

class LecturerHomePage extends StatelessWidget {
  const LecturerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      appBar: const LecturerAppBar(title: 'Beranda'),
      body: const Center(child: Text('Beranda Dosen')),
    );
  }
}