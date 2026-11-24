import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../routing/admin_route_paths.dart';
import '../../../widgets/widgets.dart';

/// Tombol kembali baku layar admin.
class AdminBackButton extends StatelessWidget {
  const AdminBackButton({required this.onPressed, super.key});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: 'Kembali',
      icon: const Icon(PhosphorIconsRegular.arrowLeft, size: 20),
    );
  }
}

/// Isi layar yang bisa digulir: 20 dp dari tepi, dan di layar lebar
/// dipusatkan selebar [AppSizes.contentMaxWidth].
class AdminBody extends StatelessWidget {
  const AdminBody({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      top: false,
      bottom: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final side = math.max(
            AppSpacing.page,
            (constraints.maxWidth - AppSizes.contentMaxWidth) / 2,
          );
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              side,
              AppSpacing.lg,
              side,
              AppSpacing.xxl + bottomInset,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          );
        },
      ),
    );
  }
}

/// Batang aksi di bawah layar: pesan opsional, lalu satu tombol utama.
class AdminBottomBar extends StatelessWidget {
  const AdminBottomBar({required this.child, this.notice, super.key});

  final Widget child;

  /// Pesan terkait aksi, misalnya alasan data ditolak.
  final Widget? notice;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.canvas,
        boxShadow: [
          BoxShadow(
            color: Color(0x140C1B33),
            blurRadius: 24,
            offset: Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.md,
            AppSpacing.page,
            AppSpacing.lg,
          ),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSizes.contentMaxWidth,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (notice != null) ...[
                    // Pembaca layar membacakan pesan begitu muncul.
                    Semantics(liveRegion: true, child: notice),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Kerangka layar admin: AppBar baku, isi yang bisa digulir, dan batang aksi
/// opsional yang menempel di bawah.
class AdminPageScaffold extends StatelessWidget {
  const AdminPageScaffold({
    required this.title,
    required this.children,
    this.description,
    this.onBack,
    this.bottomBar,
    super.key,
  });

  final String title;
  final String? description;
  final List<Widget> children;

  /// Tanpa ini layar tidak menampilkan tombol kembali.
  final VoidCallback? onBack;
  final Widget? bottomBar;

  @override
  Widget build(BuildContext context) {
    final bottomBar = this.bottomBar;
    final description = this.description;
    final body = AuroraBackground(
      child: AdminBody(
        children: [
          if (description != null)
            AppPageHeading(title: title, description: description),
          ...children,
        ],
      ),
    );

    return Scaffold(
      appBar: SkyAppBar(
        leading: onBack == null ? null : AdminBackButton(onPressed: onBack),
        // Tanpa tombol kembali, judul sejajar dengan tepi isi layar.
        titleSpacing: onBack == null ? AppSpacing.page : null,
        title: description == null ? Text(title) : const WordmarkPill(),
      ),
      body: bottomBar == null
          ? body
          : Column(
              children: [
                Expanded(
                  // Jarak aman bawah sudah ditangani batang aksi.
                  child: MediaQuery.removePadding(
                    context: context,
                    removeBottom: true,
                    child: body,
                  ),
                ),
                bottomBar,
              ],
            ),
    );
  }
}

/// Kerangka semua form admin: AppBar dengan tombol kembali, isi yang bisa
/// digulir, dan tombol simpan di batang bawah.
class AdminFormScaffold extends StatelessWidget {
  const AdminFormScaffold({
    super.key,
    required this.title,
    required this.form,
    required this.onSave,
    this.description,
    this.saveLabel,
    this.onBack,
    this.isSaving = false,
    this.notice,
  });

  final String title;
  final Widget form;
  final VoidCallback onSave;
  final String? description;

  /// Bawaan: "Simpan", atau "Simpan Perubahan" untuk layar edit.
  final String? saveLabel;

  /// Bawaan: kembali ke layar sebelumnya, atau ke daftar mata kuliah.
  final VoidCallback? onBack;

  /// Menonaktifkan tombol simpan selagi data dikirim.
  final bool isSaving;

  /// Pesan di atas tombol simpan, misalnya alasan data ditolak.
  final Widget? notice;

  @override
  Widget build(BuildContext context) {
    return AdminPageScaffold(
      title: title,
      description: description,
      onBack:
          onBack ??
          () => context.canPop()
              ? context.pop()
              : context.go(AdminRoutePaths.mataKuliah),
      bottomBar: AdminBottomBar(
        notice: notice,
        child: AppGradientButton(
          onPressed: isSaving ? null : onSave,
          isBusy: isSaving,
          label:
              saveLabel ??
              (title.startsWith('Edit') ? 'Simpan Perubahan' : 'Simpan'),
        ),
      ),
      children: [form],
    );
  }
}
