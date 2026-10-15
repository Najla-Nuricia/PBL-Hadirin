import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingWelcomePage extends StatelessWidget {
  const OnboardingWelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0870F8),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final colorScheme = Theme.of(context).colorScheme;
            return Stack(
              fit: StackFit.expand,
              children: [
                const CustomPaint(painter: _WelcomePatternPainter()),
                const Align(
                  alignment: Alignment(0, 0.015),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'HADIR.IN',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          height: 1,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Absensi Mahasiswa Berbasis Face Recognition',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 6,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: constraints.maxWidth * 0.085,
                  right: constraints.maxWidth * 0.085,
                  bottom: constraints.maxHeight * 0.055,
                  child: _OnboardingButton(
                    label: 'Next',
                    onPressed: () => context.push('/onboarding/peran'),
                    backgroundColor: Colors.white,
                    foregroundColor: colorScheme.primary,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class OnboardingRolePage extends StatelessWidget {
  const OnboardingRolePage({
    super.key,
    this.onStudentPressed,
    this.onLecturerPressed,
    this.onAdminPressed,
  });

  final VoidCallback? onStudentPressed;
  final VoidCallback? onLecturerPressed;
  final VoidCallback? onAdminPressed;

  void _showUnavailable(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Login untuk peran ini belum tersedia.')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(
              child: _OnboardingCircles(
                color: Color(0xFFEAF2FF),
                alignment: Alignment.topRight,
              ),
            ),
            const Positioned.fill(
              child: _OnboardingCircles(
                color: Color(0xFFEAF2FF),
                alignment: Alignment.bottomLeft,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 16),
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  const Text(
                    'Apa peran anda di JTI?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF111111),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 44),
                  Row(
                    children: [
                      Expanded(
                        child: _OnboardingButton(
                          label: 'Mahasiswa',
                          onPressed:
                              onStudentPressed ??
                              () => _showUnavailable(context),
                          backgroundColor: colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _OnboardingButton(
                          label: 'Dosen',
                          onPressed:
                              onLecturerPressed ??
                              () => _showUnavailable(context),
                          backgroundColor: colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(flex: 4),
                  TextButton(
                    onPressed:
                        onAdminPressed ?? () => _showUnavailable(context),
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 20),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(fontSize: 7),
                    ),
                    child: const Text('Login Sebagai Sekretaris Jurusan'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomePatternPainter extends CustomPainter {
  const _WelcomePatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 210;
    final paint = Paint()
      ..color = const Color(0xFF0064E8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 29 * scale;

    final topCenter = Offset(29 * scale, 72 * scale);
    canvas.drawCircle(topCenter, 103 * scale, paint);
    canvas.drawCircle(topCenter, 140 * scale, paint);
    canvas.drawCircle(topCenter, 177 * scale, paint);

    final bottomCenter = Offset(194 * scale, size.height - 21 * scale);
    paint.strokeWidth = 20 * scale;
    canvas.drawCircle(bottomCenter, 55 * scale, paint);
    canvas.drawCircle(bottomCenter, 80 * scale, paint);
    canvas.drawCircle(bottomCenter, 105 * scale, paint);
  }

  @override
  bool shouldRepaint(_WelcomePatternPainter oldDelegate) => false;
}

class _OnboardingButton extends StatelessWidget {
  const _OnboardingButton({
    required this.label,
    required this.onPressed,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 27,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _OnboardingCircles extends StatelessWidget {
  const _OnboardingCircles({
    this.size = 220,
    this.color = const Color(0xFF0870F8),
    this.alignment = Alignment.topLeft,
    this.strokeWidth = 22,
    this.filled = false,
  });

  final double size;
  final Color color;
  final Alignment alignment;
  final double strokeWidth;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: IgnorePointer(
        child: CustomPaint(
          size: Size.square(size),
          painter: _CirclePatternPainter(
            color,
            strokeWidth: strokeWidth,
            filled: filled,
          ),
        ),
      ),
    );
  }
}

class _CirclePatternPainter extends CustomPainter {
  const _CirclePatternPainter(
    this.color, {
    required this.strokeWidth,
    required this.filled,
  });

  final Color color;
  final double strokeWidth;
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final center = filled
        ? Offset(size.width * 0.37, size.height * 0.37)
        : Offset(size.width * 0.1, size.height * 0.1);
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    if (filled) {
      canvas.drawCircle(
        center,
        size.width * 0.48,
        Paint()
          ..color = color.withValues(alpha: 0.72)
          ..style = PaintingStyle.fill,
      );
    }

    canvas.drawCircle(center, size.width * 0.48, strokePaint);
    canvas.drawCircle(center, size.width * 0.66, strokePaint);
    canvas.drawCircle(center, size.width * 0.84, strokePaint);
  }

  @override
  bool shouldRepaint(_CirclePatternPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.filled != filled;
}
