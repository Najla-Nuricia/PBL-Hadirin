import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingWelcomePage extends StatelessWidget {
  const OnboardingWelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.primary,
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: _OnboardingCircles()),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
              child: Column(
                children: [
                  const Spacer(),
                  const Text(
                    'HADIR.IN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Text(
                    'Absensi Mahasiswa Berbasis Face Recognition',
                    style: TextStyle(color: Colors.white, fontSize: 7),
                  ),
                  const Spacer(flex: 2),
                  _OnboardingButton(
                    label: 'Next',
                    onPressed: () => context.push('/onboarding/peran'),
                    backgroundColor: Colors.white,
                    foregroundColor: colorScheme.primary,
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
      height: 42,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _OnboardingCircles extends StatelessWidget {
  const _OnboardingCircles({
    this.color = const Color(0xFF0870F8),
    this.alignment = Alignment.topLeft,
  });

  final Color color;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: IgnorePointer(
        child: CustomPaint(
          size: const Size(220, 220),
          painter: _CirclePatternPainter(color),
        ),
      ),
    );
  }
}

class _CirclePatternPainter extends CustomPainter {
  const _CirclePatternPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.1, size.height * 0.1);
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22;

    canvas.drawCircle(center, 82, strokePaint);
    canvas.drawCircle(center, 124, strokePaint);
    canvas.drawCircle(center, 166, strokePaint);
  }

  @override
  bool shouldRepaint(_CirclePatternPainter oldDelegate) =>
      oldDelegate.color != color;
}
