import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/admin/jadwal.dart';
import '../../data/admin/ruangan.dart';
import '../../routing/admin_route_paths.dart';
import 'widgets/labeled_fields.dart';

class TambahRuanganPage extends StatefulWidget {
  const TambahRuanganPage({super.key});

  @override
  State<TambahRuanganPage> createState() => _TambahRuanganPageState();
}

class _TambahRuanganPageState extends State<TambahRuanganPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ruangan $nama sudah terdaftar'),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
          'Tambah Ruangan',
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
                  child: const Text('Simpan'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
