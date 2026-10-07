import 'package:flutter/material.dart';

class StudentPagePlaceholder extends StatelessWidget {
  const StudentPagePlaceholder({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) => Center(child: Text(title));
}
