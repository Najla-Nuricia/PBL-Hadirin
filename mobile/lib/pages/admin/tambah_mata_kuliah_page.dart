import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/admin/jadwal.dart';
import '../../data/admin/mata_kuliah.dart';
import '../../routing/admin_route_paths.dart';
import '../../widgets/widgets.dart';
import 'widgets/admin_scaffold.dart';
import 'widgets/labeled_fields.dart';

const _programStudi = {
  'D4-TI': 'D4 Teknik Informatika',
  'D4-SIB': 'D4 Sistem Informasi Bisnis',
  'D2-PPLS': 'D2 Pengembangan Perangkat Lunak Situs',
};
const _sksOptions = ['1', '2', '3', '4'];
const _semesterOptions = ['1', '2', '3', '4', '5', '6', '7', '8'];

class TambahMataKuliahPage extends StatefulWidget {
  const TambahMataKuliahPage({this.initialItem, super.key});

  final MataKuliah? initialItem;

  @override
  State<TambahMataKuliahPage> createState() => _TambahMataKuliahPageState();
}

class _TambahMataKuliahPageState extends State<TambahMataKuliahPage> {
  final _formKey = GlobalKey<FormState>();
  final _kodeController = TextEditingController();
  final _namaController = TextEditingController();

  String _sks = '3';
  String _prodi = _programStudi.keys.first;
  String _semester = '3';
  MataKuliahStatus _status = MataKuliahStatus.aktif;

  /// Alasan data ditolak saat disimpan; tampil di atas tombol simpan.
  String? _error;

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;
    if (item != null) {
      _kodeController.text = item.kode;
      _namaController.text = item.nama;
      _sks = item.sks.toString();
      _prodi = _programStudi.containsKey(item.programStudiKode)
          ? item.programStudiKode
          : _programStudi.keys.first;
      _semester = item.semester.toString();
      _status = item.status;
    }
  }

  @override
  void dispose() {
    _kodeController.dispose();
    _namaController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final kode = _kodeController.text.trim();
    if (mataKuliahRepository.codeExists(
      kode,
      excludingId: widget.initialItem?.id,
    )) {
      setState(() => _error = 'Kode mata kuliah tersebut sudah terdaftar.');
      return;
    }

    final item = MataKuliah(
      id: widget.initialItem?.id ?? mataKuliahRepository.generateId(),
      kode: kode,
      nama: _namaController.text.trim(),
      sks: int.parse(_sks),
      programStudiKode: _prodi,
      semester: int.parse(_semester),
      status: _status,
    );

    if (widget.initialItem == null) {
      mataKuliahRepository.add(item);
    } else {
      mataKuliahRepository.update(item);
    }

    if (context.canPop()) {
      context.pop(true);
    } else {
      context.go(AdminRoutePaths.mataKuliah);
    }
  }

  void _clearError() {
    if (_error != null) setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    return AdminFormScaffold(
      title: widget.initialItem == null
          ? 'Tambah Mata Kuliah'
          : 'Edit Mata Kuliah',
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
            LabeledTextField(
              label: 'Kode Mata Kuliah',
              required: true,
              controller: _kodeController,
              hint: 'TI101',
              helper: 'Contoh: TI101',
              validator: _required('Kode mata kuliah'),
            ),
            const SizedBox(height: AppSpacing.lg),
            LabeledTextField(
              label: 'Nama Mata Kuliah',
              required: true,
              controller: _namaController,
              hint: 'Basis Data',
              validator: _required('Nama mata kuliah'),
            ),
            const SizedBox(height: AppSpacing.lg),
            LabeledDropdown(
              label: 'SKS',
              required: true,
              value: _sks,
              items: _sksOptions,
              onChanged: (value) => setState(() => _sks = value),
            ),
            const SizedBox(height: AppSpacing.lg),
            LabeledDropdown(
              label: 'Program Studi',
              required: true,
              value: _prodi,
              items: _programStudi.keys.toList(),
              itemLabels: _programStudi,
              onChanged: (value) => setState(() => _prodi = value),
            ),
            const SizedBox(height: AppSpacing.lg),
            LabeledDropdown(
              label: 'Semester',
              required: true,
              value: _semester,
              items: _semesterOptions,
              onChanged: (value) => setState(() => _semester = value),
            ),
            const SizedBox(height: AppSpacing.lg),
            LabeledDropdown(
              label: 'Status',
              required: true,
              value: _status.name == 'aktif' ? 'Aktif' : 'Non-Aktif',
              items: const ['Aktif', 'Non-Aktif'],
              onChanged: (value) => setState(
                () => _status = value == 'Aktif'
                    ? MataKuliahStatus.aktif
                    : MataKuliahStatus.nonAktif,
              ),
            ),
          ],
        ),
      ),
    );
  }

  FormFieldValidator<String> _required(String label) {
    return (value) =>
        (value ?? '').trim().isEmpty ? '$label wajib diisi' : null;
  }
}
