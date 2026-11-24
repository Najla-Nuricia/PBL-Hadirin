import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../widgets/widgets.dart';

// Kedua layar ini tidak memakai AppBar, jadi warna ikon status bar diatur
// sendiri lewat [skyStatusBar].

/// Langit cadangan selama ilustrasi belum termuat, sewarna dengan gambarnya.
const _skyGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [AppColors.sky, AppColors.skySoft, AppColors.cloud],
  stops: [0, 0.42, 0.62],
);

class OnboardingWelcomePage extends StatelessWidget {
  const OnboardingWelcomePage({super.key});

  /// Ilustrasi wisudawan di atas awan; separuh bawahnya sengaja kosong
  /// sebagai tempat judul dan ajakan.
  static const heroAsset = 'assets/images/landing_hero.jpg';

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: skyStatusBar,
      child: Scaffold(
        backgroundColor: AppColors.cloud,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(gradient: _skyGradient),
            ),
            const _LandingIllustration(),
            // Kabut putih tipis di bagian awan supaya teks tetap terbaca di
            // layar yang lebih pendek dari ilustrasinya.
            const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x00F3F8FF),
                      Color(0x00F3F8FF),
                      Color(0x99F3F8FF),
                      Color(0xD9F6F9FF),
                    ],
                    stops: [0, 0.5, 0.7, 1],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: _CenteredContent(
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.page,
                            AppSpacing.lg,
                            AppSpacing.page,
                            AppSpacing.lg,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const _Reveal(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: WordmarkPill(),
                                ),
                              ),
                              const Spacer(),
                              _Reveal(
                                start: 0.15,
                                child: Semantics(
                                  header: true,
                                  child: Text(
                                    'Presensi kuliah,\ncukup scan wajah.',
                                    style: text.displaySmall?.copyWith(
                                      color: AppColors.gownNavy,
                                      fontSize: 34,
                                      height: 1.08,
                                      letterSpacing: -1.3,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _Reveal(
                                start: 0.25,
                                child: Text(
                                  'Cepat, akurat, tanpa antre. Lokasimu '
                                  'divalidasi otomatis saat hadir di kelas.',
                                  style: text.bodyLarge?.copyWith(
                                    color: AppColors.inkMuted,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              const _Reveal(
                                start: 0.35,
                                child: _FeatureStrip(),
                              ),
                              const SizedBox(height: AppSpacing.xxl),
                              _Reveal(
                                start: 0.45,
                                child: AppGradientButton(
                                  // Appium membuka layar peran lewat `~Mulai`.
                                  label: 'Mulai',
                                  trailingIcon: PhosphorIconsRegular.arrowRight,
                                  gradient: AppColors.landingCtaGradient,
                                  onPressed: () =>
                                      context.push('/onboarding/peran'),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'JTI Polinema',
                                textAlign: TextAlign.center,
                                style: text.labelMedium?.copyWith(
                                  color: AppColors.inkFaint,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ilustrasi selebar layar, dirapatkan ke atas supaya wisudawan selalu
/// terlihat. Muncul dengan zoom-out pelan sekali saat layar dibuka.
class _LandingIllustration extends StatelessWidget {
  const _LandingIllustration();

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      OnboardingWelcomePage.heroAsset,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      excludeFromSemantics: true,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: AppMotion.slow,
          curve: Curves.easeOut,
          child: child,
        );
      },
    );

    if (MediaQuery.disableAnimationsOf(context)) return image;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.06, end: 1),
      duration: const Duration(milliseconds: 1400),
      curve: Curves.easeOutCubic,
      child: image,
      builder: (context, scale, child) => Transform.scale(
        scale: scale,
        alignment: Alignment.topCenter,
        child: child,
      ),
    );
  }
}

/// Isi masuk bertahap: memudar sambil naik sedikit, sekali saja.
class _Reveal extends StatelessWidget {
  const _Reveal({required this.child, this.start = 0});

  final Widget child;

  /// Titik mulai dalam rentang 0–1 dari durasi total.
  final double start;

  static const _total = Duration(milliseconds: 1100);

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;

    final end = (start + 0.55).clamp(0.0, 1.0);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: _total,
      curve: Interval(start, end, curve: AppMotion.curve),
      child: child,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 20),
          child: child,
        ),
      ),
    );
  }
}

/// Tiga keunggulan dalam satu panel putih, dibagi rata.
class _FeatureStrip extends StatelessWidget {
  const _FeatureStrip();

  static const _items = [
    (
      icon: PhosphorIconsRegular.userFocus,
      label: 'Scan wajah',
      color: AppColors.brand600,
    ),
    (
      icon: PhosphorIconsRegular.mapPin,
      label: 'Validasi lokasi',
      color: AppColors.ribbonOrange,
    ),
    (
      icon: PhosphorIconsRegular.lightning,
      label: 'Real-time',
      color: AppColors.ribbonCoral,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final label = Theme.of(context).textTheme.labelMedium?.copyWith(
      color: AppColors.gownNavy,
      fontWeight: FontWeight.w700,
    );

    // Permukaan buram penuh: bayangan di bawah isian transparan akan
    // tembus dan tampak seperti kotak kedua.
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.card,
        boxShadow: AppColors.shadowSoft,
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (final (index, item) in _items.indexed) ...[
              if (index > 0)
                const VerticalDivider(
                  width: 1,
                  indent: 6,
                  endIndent: 6,
                  color: AppColors.line,
                ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: 0.13),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(item.icon, size: 18, color: item.color),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: label,
                    ),
                  ],
                ),
              ),
            ],
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

  /// Seberapa jauh kartu peran naik menutupi tepi awan.
  static const double _tileOverlap = 44;

  void _showUnavailable(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Login untuk peran ini belum tersedia.')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: skyStatusBar,
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SkyHeader(
                      overlap: _tileOverlap,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const WordmarkPill(),
                          const SizedBox(height: AppSpacing.xxl),
                          Semantics(
                            header: true,
                            child: Text(
                              'Pilih peran Anda',
                              style: text.displaySmall?.copyWith(
                                color: AppColors.gownNavy,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Masuk sesuai peran Anda di JTI Polinema.',
                            style: text.bodyLarge?.copyWith(
                              color: AppColors.gownNavy,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(0, -_tileOverlap),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: AppSizes.contentMaxWidth,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.page,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _RoleTile(
                                  icon: PhosphorIconsRegular.graduationCap,
                                  title: 'Mahasiswa',
                                  subtitle:
                                      'Presensi, jadwal, dan riwayat kuliah',
                                  gradient: AppColors.brandGradient,
                                  onTap:
                                      onStudentPressed ??
                                      () => _showUnavailable(context),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                _RoleTile(
                                  icon: PhosphorIconsRegular.chalkboardTeacher,
                                  title: 'Dosen',
                                  subtitle: 'Pantau kehadiran dan tinjau izin',
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.ribbonCoral,
                                      AppColors.ribbonOrange,
                                    ],
                                  ),
                                  onTap:
                                      onLecturerPressed ??
                                      () => _showUnavailable(context),
                                ),
                                const SizedBox(height: AppSpacing.xl),
                                _PrivacyNote(text: text),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  0,
                  AppSpacing.page,
                  AppSpacing.md,
                ),
                child: TextButton.icon(
                  onPressed: onAdminPressed ?? () => _showUnavailable(context),
                  icon: const Icon(
                    PhosphorIconsRegular.userGear,
                    size: 20,
                  ),
                  label: const Text(
                    'Login Sebagai Sekretaris Jurusan',
                    textAlign: TextAlign.center,
                    textWidthBasis: TextWidthBasis.longestLine,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote({required this.text});

  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: AppRadius.card,
        border: Border.all(color: Colors.white),
      ),
      child: Row(
        children: [
          const Icon(
            PhosphorIconsRegular.shieldCheck,
            size: 22,
            color: AppColors.hadirInk,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Wajah dan lokasi hanya dipakai untuk verifikasi presensi.',
              style: text.bodySmall?.copyWith(color: AppColors.inkMuted),
            ),
          ),
        ],
      ),
    );
  }
}

/// Membatasi lebar isi di layar lebar dan menaruhnya di tengah.
class _CenteredContent extends StatelessWidget {
  const _CenteredContent({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
        child: SizedBox.expand(child: child),
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  const _RoleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    // Label aksesibilitas sengaja hanya nama peran: Appium mencarinya lewat
    // `~Mahasiswa` dan `~Dosen`.
    return Semantics(
      button: true,
      label: title,
      onTap: onTap,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          borderRadius: AppRadius.hero,
          boxShadow: AppColors.shadowSoft,
        ),
        child: Material(
          color: Colors.white,
          clipBehavior: Clip.antiAlias,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.hero),
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 104),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: gradient,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: AppColors.shadowSoft,
                      ),
                      child: Icon(icon, size: 28, color: Colors.white),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: text.titleLarge?.copyWith(fontSize: 19),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: text.bodyMedium?.copyWith(
                              color: AppColors.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: AppColors.brand50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        PhosphorIconsRegular.arrowRight,
                        size: 18,
                        color: AppColors.brand700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
