import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../theme/app_tokens.dart';

/// Pesan sebaris di dalam layar: latar berwarna lembut dengan ikon.
class AppBanner extends StatelessWidget {
  const AppBanner({
    required this.message,
    this.title,
    this.tone = StatusTone.info,
    this.icon,
    this.action,
    super.key,
  });

  final String message;
  final String? title;
  final StatusTone tone;
  final IconData? icon;

  /// Tombol opsional di bawah pesan, misalnya "Coba lagi".
  final Widget? action;

  static IconData _defaultIcon(StatusTone tone) => switch (tone) {
    StatusTone.hadir => PhosphorIconsRegular.checkCircle,
    StatusTone.izin => PhosphorIconsRegular.warning,
    StatusTone.alfa => PhosphorIconsRegular.warningCircle,
    _ => PhosphorIconsRegular.info,
  };

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: tone.tint,
        borderRadius: AppRadius.control,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? _defaultIcon(tone), size: 20, color: tone.ink),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(
                    title!,
                    style: text.titleSmall?.copyWith(color: tone.ink),
                  ),
                Text(
                  message,
                  style: text.bodyMedium?.copyWith(color: tone.ink),
                ),
                if (action != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  action!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Keadaan kosong: menjelaskan apa yang akan muncul di sini.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    required this.title,
    this.message,
    this.icon = PhosphorIconsRegular.tray,
    this.action,
    super.key,
  });

  final String title;
  final String? message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.xxxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: AppColors.inkFaint),
          const SizedBox(height: AppSpacing.md),
          Text(title, textAlign: TextAlign.center, style: text.titleMedium),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: AppColors.inkMuted),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: AppSpacing.lg),
            action!,
          ],
        ],
      ),
    );
  }
}

/// Keadaan gagal memuat: menyebut masalahnya dan menawarkan coba lagi.
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    required this.message,
    this.title = 'Belum bisa dimuat',
    this.onRetry,
    super.key,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: PhosphorIconsRegular.cloudSlash,
      title: title,
      message: message,
      action: onRetry == null
          ? null
          : OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(PhosphorIconsRegular.arrowsClockwise, size: 20),
              label: const Text('Coba lagi'),
            ),
    );
  }
}

/// Balok abu-abu berdenyut sebagai pengganti isi yang sedang dimuat.
class AppSkeleton extends StatefulWidget {
  const AppSkeleton({
    this.width,
    this.height = 14,
    this.radius = AppRadius.sm,
    super.key,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Color.lerp(
            AppColors.surfaceInset,
            AppColors.line,
            _pulse.value,
          ),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

/// Beberapa baris kerangka dalam satu kartu, untuk daftar yang sedang dimuat.
class AppSkeletonList extends StatelessWidget {
  const AppSkeletonList({this.rows = 3, super.key});

  final int rows;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Memuat',
      child: Card(
        child: Column(
          children: [
            for (var i = 0; i < rows; i++) ...[
              if (i > 0) const Divider(),
              const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    AppSkeleton(width: 40, height: 40, radius: 20),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FractionallySizedBox(
                            widthFactor: 0.7,
                            child: AppSkeleton(),
                          ),
                          SizedBox(height: AppSpacing.sm),
                          FractionallySizedBox(
                            widthFactor: 0.4,
                            child: AppSkeleton(height: 12),
                          ),
                        ],
                      ),
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

class AppPageHeading extends StatelessWidget {
  const AppPageHeading({required this.title, this.description, super.key});

  final String title;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final description = this.description;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: text.headlineLarge),
          ),
          if (description != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              description,
              style: text.bodyMedium?.copyWith(color: AppColors.inkMuted),
            ),
          ],
        ],
      ),
    );
  }
}

/// Judul bagian dengan aksi opsional di kanan.
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({required this.title, this.action, super.key});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSizes.touch),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 17.5,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

/// Baris label dan nilai untuk rincian (bukti presensi, profil).
class AppKeyValueRow extends StatelessWidget {
  const AppKeyValueRow({
    required this.label,
    this.value,
    this.trailing,
    super.key,
  }) : assert(value != null || trailing != null);

  final String label;
  final String? value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: text.bodyMedium?.copyWith(color: AppColors.inkMuted),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child:
                  trailing ??
                  Text(
                    value!,
                    textAlign: TextAlign.right,
                    style: text.titleSmall,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
