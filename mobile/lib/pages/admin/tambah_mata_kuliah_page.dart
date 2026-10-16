import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../routing/admin_route_paths.dart';
import 'widgets/labeled_fields.dart';

const _programStudi = [
  'D4 Teknik Informatika',
  'D4 Sistem Informasi Bisnis',
  'D2 Pengembangan Perangkat Lunak Situs',
];
const _statusOptions = ['Aktif', 'Non-Aktif'];
const _sksOptions = ['1', '2', '3', '4'];
const _semesterOptions = ['1', '2', '3', '4', '5', '6', '7', '8'];

class TambahMataKuliahPage extends StatefulWidget {
  const TambahMataKuliahPage({super.key});

  @override
  State<TambahMataKuliahPage> createState() => _TambahMataKuliahPageState();
}

class _TambahMataKuliahPageState extends State<TambahMataKuliahPage> {
  final _formKey = GlobalKey<FormState>();
  final _kodeController = TextEditingController();
  final _namaController = TextEditingController();
  String _sks = '3';
  String _prodi = _programStudi.first;
  String _semester = '3';
  String _status = _statusOptions.first;

  @override
  void dispose() {
    _kodeController.dispose();
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mata kuliah berhasil ditambahkan')),
    );
    _back();
  }

  @override
  Widget build(BuildContext context) {
    return AdminFormScaffold(
      title: 'Tambah Mata Kuliah',
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
              items: _programStudi,
              onChanged: (value) => setState(() => _prodi = value),
            ),
            const SizedBox(height: 16),
            LabeledDropdown(
              label: 'Semester Saran',
              value: _semester,
              items: _semesterOptions,
              onChanged: (value) => setState(() => _semester = value),
            ),
            const SizedBox(height: 16),
            LabeledDropdown(
              label: 'Status',
              required: true,
              value: _status,
              items: _statusOptions,
              onChanged: (value) => setState(() => _status = value),
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
  });

  final String title;
  final Widget form;
  final VoidCallback onSave;

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
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(AdminRoutePaths.dataAkademik),
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: cs.primary),
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
