import 'package:flutter/material.dart';

import 'widgets/lecturer_app_bar.dart';

class LecturerHomePage extends StatelessWidget {
  const LecturerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: LecturerAppBar(title: 'Beranda'),
      body: Center(child: Text('Beranda Dosen')),
    );
  }
}
