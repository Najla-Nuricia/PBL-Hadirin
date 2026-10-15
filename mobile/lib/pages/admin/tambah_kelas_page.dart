// lib/pages/admin/tambah_kelas_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/admin/tahun_ajaran.dart';
import '../../routing/admin_route_paths.dart';
import '../../data/admin/kelas.dart';
import 'widgets/labeled_fields.dart';

// TODO: ganti dengan data program studi dari backend/repository.
const _programStudi = [
  'D4 Teknik Informatika',
  'D4 Sistem Informasi Bisnis',
  'D2 Pengembangan Perangkat Lunak Situs',
];

const _statusOptions = ['Aktif', 'Non-Aktif'];

class TambahKelasPage extends StatefulWidget {
  const TambahKelasPage({super.key});

  @override
  State<TambahKelasPage> createState() => _TambahKelasPageState();
}

class _TambahKelasPageState extends State<TambahKelasPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaCtrl = TextEditingController();
  final _kapasitasCtrl = TextEditingController();

  late final List<String> _tahunOptions;
  late String _tahun;
  String _prodi = _programStudi.first;
  String _status = _statusOptions.first;

  @override
  void initState() {
    super.initState();
    final all = tahunAjaranRepository.getAll();
    _tahunOptions = [for (final t in all) t.tahun];
    // Default: tahun ajaran aktif, jika tidak ada pakai yang pertama.
    _tahun = all
        .firstWhere(
          (t) => t.status == TahunAjaranStatus.aktif,
          orElse: () => all.first,
        )
        .tahun;
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _kapasitasCtrl.dispose();
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

    final nama = _namaCtrl.text.trim();

    if (kelasRepository.exists(tahunAjaran: _tahun, nama: nama)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kelas $nama sudah ada di tahun ajaran $_tahun'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    kelasRepository.add(
      Kelas(
        id: kelasRepository.generateId(),
        tahunAjaran: _tahun,
        programStudi: _prodi,
        nama: nama,
        kapasitas: int.parse(_kapasitasCtrl.text),
        status: _status == 'Aktif' ? KelasStatus.aktif : KelasStatus.nonAktif,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kelas berhasil ditambahkan'),
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
          'Tambah Kelas',
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
                      LabeledDropdown(
                        label: 'Tahun Ajaran',
                        required: true,
                        value: _tahun,
                        items: _tahunOptions,
                        onChanged: (v) => setState(() => _tahun = v),
                      ),
                      const SizedBox(height: 16),
                      LabeledDropdown(
                        label: 'Program Studi',
                        required: true,
                        value: _prodi,
                        items: _programStudi,
                        onChanged: (v) => setState(() => _prodi = v),
                      ),
                      const SizedBox(height: 16),
                      LabeledTextField(
                        label: 'Nama Kelas',
                        required: true,
                        controller: _namaCtrl,
                        hint: 'TI-3F',
                        helper: 'Contoh: TI-3A, SIB-2C',
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Nama kelas wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      LabeledTextField(
                        label: 'Kapasitas',
                        required: true,
                        controller: _kapasitasCtrl,
                        numeric: true,
                        hint: '26',
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Kapasitas wajib diisi';
                          }
                          return int.parse(v) <= 0
                              ? 'Kapasitas harus lebih dari 0'
                              : null;
                        },
                      ),
                      const SizedBox(height: 16),
                      LabeledDropdown(
                        label: 'Status',
                        required: true,
                        value: _status,
                        items: _statusOptions,
                        onChanged: (v) => setState(() => _status = v),
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
