import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/admin/jadwal.dart';
import '../../data/admin/mata_kuliah.dart';
import '../../routing/admin_route_paths.dart';
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
      _showError('Kode mata kuliah tersebut sudah terdaftar.');
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

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return AdminFormScaffold(
      title: widget.initialItem == null
          ? 'Tambah Mata Kuliah'
          : 'Edit Mata Kuliah',
      form: Form(
        key: _formKey,
        child: Column(
          children: [
            LabeledTextField(
              label: 'Kode Mata Kuliah',
              required: true,
              controller: _kodeController,
              hint: 'TI101',
              helper: 'Contoh: TI101',
              validator: _required('Kode mata kuliah'),
            ),
            const SizedBox(height: 16),
            LabeledTextField(
              label: 'Nama Mata Kuliah',
              required: true,
              controller: _namaController,
              hint: 'Basis Data',
              validator: _required('Nama mata kuliah'),
            ),
            const SizedBox(height: 16),
            LabeledDropdown(
              label: 'SKS',
              required: true,
              value: _sks,
              items: _sksOptions,
              onChanged: (value) => setState(() => _sks = value),
            ),
            const SizedBox(height: 16),
            LabeledDropdown(
              label: 'Program Studi',
              required: true,
              value: _prodi,
              items: _programStudi.keys.toList(),
              itemLabels: _programStudi,
              onChanged: (value) => setState(() => _prodi = value),
            ),
            const SizedBox(height: 16),
            LabeledDropdown(
              label: 'Semester',
              required: true,
              value: _semester,
              items: _semesterOptions,
              onChanged: (value) => setState(() => _semester = value),
            ),
            const SizedBox(height: 16),
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
      onSave: _save,
    );
  }

  FormFieldValidator<String> _required(String label) {
    return (value) =>
        (value ?? '').trim().isEmpty ? '$label wajib diisi' : null;
  }
}

class AdminFormScaffold extends StatelessWidget {
  const AdminFormScaffold({
    super.key,
    required this.title,
    required this.form,
    required this.onSave,
    this.onBack,
  });

  final String title;
  final Widget form;
  final VoidCallback onSave;

  /// Override aksi tombol kembali (default: pop / kembali ke data akademik).
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          onPressed:
              onBack ??
              () => context.canPop()
                  ? context.pop()
                  : context.go(AdminRoutePaths.dataAkademik),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(AdminRoutePaths.mataKuliah),
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: cs.primary),
          tooltip: 'Kembali',
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: cs.outlineVariant),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: form,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border(top: BorderSide(color: cs.outlineVariant)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: onSave,
                  child: Text(
                    title.startsWith('Edit') ? 'Simpan Perubahan' : 'Simpan',
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
