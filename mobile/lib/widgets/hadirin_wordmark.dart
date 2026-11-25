import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

class HadirinWordmark extends StatelessWidget {
  const HadirinWordmark({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Hadir.in',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.all(Radius.circular(11)),
              boxShadow: AppColors.shadowBrand,
            ),
            child: Padding(
              padding: EdgeInsets.all(5),
              child: HadirinMark(size: 24),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text.rich(
              const TextSpan(
                text: 'hadir',
                children: [
                  TextSpan(
                    text: '.in',
                    style: TextStyle(color: AppColors.brand700),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(letterSpacing: -1.1),
            ),
          ),
        ],
      ),
    );
  }
}

class HadirinMark extends StatelessWidget {
  const HadirinMark({required this.size, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: const _MarkPainter());
  }
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final corner = Path()
      ..moveTo(3, 8)
      ..lineTo(3, 6)
      ..quadraticBezierTo(3, 3, 6, 3)
      ..lineTo(8, 3);
    for (var turn = 0; turn < 4; turn++) {
      canvas.drawPath(corner, paint);
      canvas.translate(24, 0);
      canvas.rotate(math.pi / 2);
    }

    final check = Path()
      ..moveTo(7.5, 12.25)
      ..lineTo(10.5, 15.25)
      ..lineTo(16.5, 9);
    canvas.drawPath(check, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MarkPainter oldDelegate) => false;
}
