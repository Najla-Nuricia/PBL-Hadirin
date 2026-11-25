import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/admin/kelas.dart';
import '../../data/admin/tahun_ajaran.dart';
import '../../routing/admin_route_paths.dart';
import '../../widgets/widgets.dart';
import 'widgets/admin_scaffold.dart';
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

  /// Alasan data ditolak saat disimpan; tampil di atas tombol simpan.
  String? _error;

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
      setState(() => _error = 'Kelas $nama sudah ada di tahun ajaran $_tahun');
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

  void _clearError() {
    if (_error != null) setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    return AdminFormScaffold(
      title: 'Tambah Kelas',
      onBack: _back,
      onSave: _save,
      notice: _error == null
          ? null
          : AppBanner(tone: StatusTone.danger, message: _error!),
      form: Form(
        key: _formKey,
        onChanged: _clearError,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.md),
            LabeledDropdown(
              label: 'Tahun Ajaran',
              required: true,
              value: _tahun,
              items: _tahunOptions,
              onChanged: (v) => setState(() => _tahun = v),
            ),
            const SizedBox(height: AppSpacing.lg),
            LabeledDropdown(
              label: 'Program Studi',
              required: true,
              value: _prodi,
              items: _programStudi,
              onChanged: (v) => setState(() => _prodi = v),
            ),
            const SizedBox(height: AppSpacing.lg),
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
            const SizedBox(height: AppSpacing.lg),
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
            const SizedBox(height: AppSpacing.lg),
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
    );
  }
}
