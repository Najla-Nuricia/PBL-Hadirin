import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/admin/jadwal.dart';
import '../../data/admin/ruangan.dart';
import '../../routing/admin_route_paths.dart';
import 'widgets/labeled_fields.dart';

class TambahRuanganPage extends StatefulWidget {
  const TambahRuanganPage({super.key, this.ruangan});

  /// Jika diisi, halaman berjalan dalam mode ubah (update).
  final Ruangan? ruangan;

  bool get isEditing => ruangan != null;

  @override
  State<TambahRuanganPage> createState() => _TambahRuanganPageState();
}

class _TambahRuanganPageState extends State<TambahRuanganPage> {
  final _formKey = GlobalKey<FormState>();
  final _kodeController = TextEditingController();
  final _namaController = TextEditingController();
  final _kapasitasController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final ruangan = widget.ruangan;
    if (ruangan != null) {
      _kodeController.text = ruangan.kode;
      _namaController.text = ruangan.nama;
      _kapasitasController.text = ruangan.kapasitas?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _kodeController.dispose();
    _namaController.dispose();
    _kapasitasController.dispose();
    super.dispose();
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AdminRoutePaths.ruangan);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final kode = _kodeController.text.trim().toUpperCase();
    final nama = _namaController.text.trim();
    final kapasitasText = _kapasitasController.text.trim();
    final current = widget.ruangan;

    if (kode != current?.kode && ruanganRepository.exists(kode)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ruangan $kode sudah terdaftar'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final ruangan = Ruangan(
      kode: kode,
      nama: nama,
      kapasitas: kapasitasText.isEmpty ? null : int.parse(kapasitasText),
    );

    if (current == null) {
      ruanganRepository.add(ruangan);
    } else {
      ruanganRepository.update(current.kode, ruangan);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          current == null
              ? 'Ruangan berhasil ditambahkan'
              : 'Ruangan berhasil diperbarui',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
    _back();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: _back,
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: cs.primary,
          ),
        ),
        title: Text(
          widget.isEditing ? 'Ubah Ruangan' : 'Tambah Ruangan',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: cs.outlineVariant),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      LabeledTextField(
                        label: 'Kode Ruangan',
                        required: true,
                        controller: _kodeController,
                        hint: 'LPR1',
                        helper: 'Kode unik ruangan, contoh: LPR1, J301',
                        validator: (value) {
                          final v = (value ?? '').trim();
                          if (v.isEmpty) return 'Kode ruangan wajib diisi';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      LabeledTextField(
                        label: 'Nama Ruangan',
                        required: true,
                        controller: _namaController,
                        hint: 'Contoh : LPR1',
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? 'Nama ruangan wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      LabeledTextField(
                        label: 'Kapasitas',
                        controller: _kapasitasController,
                        numeric: true,
                        hint: '40',
                        helper: 'Opsional, isi jumlah kursi ruangan',
                        validator: (value) {
                          final v = (value ?? '').trim();
                          if (v.isEmpty) return null;
                          return int.parse(v) <= 0
                              ? 'Kapasitas harus lebih dari 0'
                              : null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border(top: BorderSide(color: cs.outlineVariant)),
              ),
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: Text(widget.isEditing ? 'Simpan Perubahan' : 'Simpan'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
