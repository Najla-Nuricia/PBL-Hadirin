import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/student_router.dart';

class AbsensiPage extends StatefulWidget {
  const AbsensiPage({super.key});

  @override
  State<AbsensiPage> createState() => _AbsensiPageState();
}

class _AbsensiPageState extends State<AbsensiPage>
    with TickerProviderStateMixin {
  // Step 1 = Scan QR, Step 2 = Scan Wajah
  int _currentStep = 0;

  // Simulasi scanning state
  bool _isScanning = false;
  bool _qrDetected = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Simulasi QR terdeteksi setelah 3 detik
    _startScanning();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _startScanning() {
    setState(() => _isScanning = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _qrDetected = true;
      });
    });
  }

  void _lanjutkanKeScanWajah() {
    setState(() {
      _currentStep = 1;
      _qrDetected = false;
      _isScanning = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _qrDetected = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(colorScheme),
            _buildStepper(colorScheme),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                child: Column(
                  children: [
                    _buildQrScanArea(colorScheme),
                    const SizedBox(height: 16),
                    _buildStatusText(colorScheme),
                    const SizedBox(height: 20),
                    _buildLocationCard(colorScheme),
                    const SizedBox(height: 20),
                    _buildActionButton(colorScheme),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(ColorScheme colorScheme) {
    return Container(
      height: 52,
      color: colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            color: colorScheme.onSurfaceVariant,
            onPressed: () => context.go(StudentRoutePaths.beranda),
            tooltip: 'Kembali',
          ),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Absensi',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(
                  text: ' - ${_currentStep == 0 ? 'Scan QR' : 'Scan Wajah'}',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepper(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          _StepIndicatorItem(
            stepNumber: 1,
            label: 'Scan QR',
            isActive: _currentStep == 0,
            isDone: _currentStep > 0,
            colorScheme: colorScheme,
          ),
          Expanded(
            child: Container(
              height: 1.5,
              color: _currentStep > 0
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
              margin: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
          _StepIndicatorItem(
            stepNumber: 2,
            label: 'Scan Wajah',
            isActive: _currentStep == 1,
            isDone: false,
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }

  Widget _buildQrScanArea(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      height: 260,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _qrDetected
              ? colorScheme.secondary
              : colorScheme.outlineVariant,
          width: _qrDetected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Simulated camera background
          Container(
            color: colorScheme.surfaceContainerHighest,
          ),
          // QR scan frame
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isScanning ? _pulseAnimation.value : 1.0,
                child: child,
              );
            },
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _qrDetected
                      ? colorScheme.secondary
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  // Corner decorations
                  ..._buildCorners(
                    _qrDetected ? colorScheme.secondary : colorScheme.primary,
                  ),
                  // Center icon / status
                  Center(
                    child: _qrDetected
                        ? Icon(Icons.check_circle_outline,
                            color: colorScheme.secondary, size: 48)
                        : Icon(Icons.qr_code_scanner,
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.3,
                            ),
                            size: 48),
                  ),
                ],
              ),
            ),
          ),
          // Scan line animation when scanning
          if (_isScanning)
            _ScanLine(colorScheme: colorScheme),
          // Status overlay text inside frame
          if (!_qrDetected && !_isScanning)
            Positioned(
              bottom: 60,
              child: Text(
                'Scanning QR Code...',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildCorners(Color color) {
    const size = 16.0;
    const width = 2.5;
    return [
      Positioned(
        top: 0,
        left: 0,
        child: _Corner(color: color, size: size, width: width,
            top: true, left: true),
      ),
      Positioned(
        top: 0,
        right: 0,
        child: _Corner(color: color, size: size, width: width,
            top: true, left: false),
      ),
      Positioned(
        bottom: 0,
        left: 0,
        child: _Corner(color: color, size: size, width: width,
            top: false, left: true),
      ),
      Positioned(
        bottom: 0,
        right: 0,
        child: _Corner(color: color, size: size, width: width,
            top: false, left: false),
      ),
    ];
  }

  Widget _buildStatusText(ColorScheme colorScheme) {
    final text = _qrDetected
        ? (_currentStep == 0
            ? 'QR Code terdeteksi! Silakan lanjutkan.'
            : 'Wajah terdeteksi! Absensi berhasil.')
        : 'Arahkan kamera ke QR yang tersedia di depan kelas';

    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: _qrDetected
            ? colorScheme.secondary
            : colorScheme.onSurfaceVariant,
        fontSize: 13,
        fontWeight: _qrDetected ? FontWeight.w600 : FontWeight.w400,
      ),
    );
  }

  Widget _buildLocationCard(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on_outlined,
              color: colorScheme.primary, size: 22),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Status Lokasi',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
              ),
              Text(
                'JTI Polinema',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check, color: colorScheme.onPrimary, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(ColorScheme colorScheme) {
    if (_currentStep == 1 && _qrDetected) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Absensi berhasil dicatat!')),
            );
            context.go(StudentRoutePaths.beranda);
          },
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.secondary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text(
            'Selesai',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: _qrDetected ? _lanjutkanKeScanWajah : null,
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          disabledBackgroundColor: colorScheme.primary.withValues(alpha: 0.38),
          foregroundColor: colorScheme.onPrimary,
          disabledForegroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_qrDetected && _isScanning) ...[
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: colorScheme.onPrimary,
                  strokeWidth: 2,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              _currentStep == 0
                  ? 'Lanjutkan ke Scan Wajah'
                  : 'Lanjutkan ke Scan Wajah',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Step indicator item
// ─────────────────────────────────────────────────────────
class _StepIndicatorItem extends StatelessWidget {
  const _StepIndicatorItem({
    required this.stepNumber,
    required this.label,
    required this.isActive,
    required this.isDone,
    required this.colorScheme,
  });

  final int stepNumber;
  final String label;
  final bool isActive;
  final bool isDone;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final activeColor = isActive || isDone
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isActive || isDone
                ? colorScheme.primary
                : colorScheme.outlineVariant,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isDone
                ? Icon(Icons.check, color: colorScheme.onPrimary, size: 14)
                : Text(
                    '$stepNumber',
                    style: TextStyle(
                      color: isActive
                          ? colorScheme.onPrimary
                          : colorScheme.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: activeColor,
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// Corner decorator for QR frame
// ─────────────────────────────────────────────────────────
class _Corner extends StatelessWidget {
  const _Corner({
    required this.color,
    required this.size,
    required this.width,
    required this.top,
    required this.left,
  });

  final Color color;
  final double size;
  final double width;
  final bool top;
  final bool left;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CornerPainter(
          color: color,
          width: width,
          top: top,
          left: left,
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  const _CornerPainter({
    required this.color,
    required this.width,
    required this.top,
    required this.left,
  });

  final Color color;
  final double width;
  final bool top;
  final bool left;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    if (top && left) {
      path.moveTo(0, size.height);
      path.lineTo(0, 0);
      path.lineTo(size.width, 0);
    } else if (top && !left) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
    } else if (!top && left) {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, 0);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CornerPainter old) =>
      old.color != color || old.width != width;
}

// ─────────────────────────────────────────────────────────
// Animated scan line
// ─────────────────────────────────────────────────────────
class _ScanLine extends StatefulWidget {
  const _ScanLine({required this.colorScheme});
  final ColorScheme colorScheme;

  @override
  State<_ScanLine> createState() => _ScanLineState();
}

class _ScanLineState extends State<_ScanLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 40,
      right: 40,
      top: 40,
      bottom: 40,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) {
          return Align(
            alignment: Alignment(0, _anim.value * 2 - 1),
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    widget.colorScheme.primary.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
