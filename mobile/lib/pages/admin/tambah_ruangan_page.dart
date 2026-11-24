import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/admin/jadwal.dart';
import '../../data/admin/ruangan.dart';
import '../../routing/admin_route_paths.dart';
import '../../widgets/widgets.dart';
import 'widgets/admin_scaffold.dart';
import 'widgets/labeled_fields.dart';

class TambahRuanganPage extends StatefulWidget {
  const TambahRuanganPage({super.key});

  @override
  State<TambahRuanganPage> createState() => _TambahRuanganPageState();
}

class _TambahRuanganPageState extends State<TambahRuanganPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();

  /// Alasan data ditolak saat disimpan; tampil di atas tombol simpan.
  String? _error;

  @override
  void dispose() {
    _namaController.dispose();
    super.dispose();
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AdminRoutePaths.dataAkademik);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final nama = _namaController.text.trim();
    if (ruanganRepository.exists(nama)) {
      setState(() => _error = 'Ruangan $nama sudah terdaftar');
      return;
    }

    ruanganRepository.add(Ruangan(kode: nama, nama: nama));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ruangan berhasil ditambahkan'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    _back();
  }

  void _clearError() {
    if (_error != null) setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    return AdminFormScaffold(
      title: 'Tambah Ruangan',
      onBack: _back,
      onSave: _save,
      notice: _error == null
          ? null
          : AppBanner(tone: StatusTone.danger, message: _error!),
      form: Form(
        key: _formKey,
        onChanged: _clearError,
        child: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: LabeledTextField(
            label: 'Nama Ruangan',
            required: true,
            controller: _namaController,
            hint: 'Contoh : LPR1',
            validator: (value) => (value == null || value.trim().isEmpty)
                ? 'Nama ruangan wajib diisi'
                : null,
          ),
        ),
      ),
    );
  }
}
