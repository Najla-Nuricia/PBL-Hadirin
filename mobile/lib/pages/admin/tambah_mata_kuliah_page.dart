import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:go_router/go_router.dart';

import '../../data/admin/admin_auth_repository.dart';
import '../../data/admin/admin_master_data_service.dart';
import '../../data/admin/jadwal.dart';
import '../../routing/admin_route_paths.dart';
import 'widgets/labeled_fields.dart';

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
  String _semester = '3';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;
    if (item != null) {
      _kodeController.text = item.kode;
      _namaController.text = item.nama;
      _sks = item.sks.toString();
      _semester = item.semester.toString();
    }
  }

  @override
  void dispose() {
    _kodeController.dispose();
    _namaController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      if (widget.initialItem == null) {
        await adminMasterDataService.createMataKuliah(
          kode: _kodeController.text,
          nama: _namaController.text,
          semester: int.parse(_semester),
          sks: int.parse(_sks),
        );
      } else {
        await adminMasterDataService.updateMataKuliah(
          originalKode: widget.initialItem!.kode,
          kode: _kodeController.text,
          nama: _namaController.text,
          semester: int.parse(_semester),
          sks: int.parse(_sks),
        );
      }
    } on AdminRemoteApiException catch (error) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showError(error.message);
      }
      return;
    }

    if (!mounted) return;
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
              label: 'Semester',
              required: true,
              value: _semester,
              items: _semesterOptions,
              onChanged: (value) => setState(() => _semester = value),
            ),
          ],
        ),
      ),
      onSave: _isSubmitting ? null : _save,
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
  final VoidCallback? onSave;

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
              : context.go(AdminRoutePaths.mataKuliah),
          icon: Icon(PhosphorIconsRegular.arrowLeft, color: cs.primary),
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
