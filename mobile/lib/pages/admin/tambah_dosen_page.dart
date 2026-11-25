import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../data/admin/admin_auth_repository.dart';
import '../../data/admin/admin_master_data_service.dart';
import '../../data/admin/jadwal.dart';
import '../../routing/admin_route_paths.dart';
import '../../widgets/widgets.dart';
import 'widgets/admin_scaffold.dart';
import 'widgets/labeled_fields.dart';

/// Form dosen untuk tambah dan edit (PUT `/admin/dosen/{nip}`).
class TambahDosenPage extends StatefulWidget {
  const TambahDosenPage({this.initialItem, super.key});

  final Dosen? initialItem;

  @override
  State<TambahDosenPage> createState() => _TambahDosenPageState();
}

class _TambahDosenPageState extends State<TambahDosenPage> {
  final _formKey = GlobalKey<FormState>();
  final _nipController = TextEditingController();
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _noHpController = TextEditingController();
  bool _isSaving = false;

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;
    if (item != null) {
      _nipController.text = item.nip;
      _namaController.text = item.nama;
      _emailController.text = item.email ?? '';
      _noHpController.text = item.noHp ?? '';
    }
  }

  @override
  void dispose() {
    _nipController.dispose();
    _namaController.dispose();
    _emailController.dispose();
    _noHpController.dispose();
    super.dispose();
  }

  void _back() {
    if (context.canPop()) {
      context.pop(false);
    } else {
      context.go(AdminRoutePaths.dataAkademik);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final isEdit = widget.initialItem != null;
    // Endpoint dosen memakai NIP pada path; saat edit NIP tidak diubah.
    final nip = widget.initialItem?.nip ?? _nipController.text.trim();
    setState(() => _isSaving = true);
    try {
      if (isEdit) {
        await adminMasterDataService.updateDosen(
          nip: nip,
          nama: _namaController.text,
          email: _emailController.text,
          noHp: _noHpController.text,
        );
      } else {
        final result = await adminMasterDataService.createDosen(
          nip: nip,
          nama: _namaController.text,
          email: _emailController.text,
          noHp: _noHpController.text,
        );
        if (!mounted) return;
        setState(() => _isSaving = false);
        // initial_password dikirim backend hanya sekali pada response 201.
        await _showInitialPassword(result.initialPassword);
      }
    } on AdminRemoteApiException catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showError(error.message);
      return;
    }
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (!isEdit) {
      _showSnackBar('Dosen berhasil dibuat.');
    } else {
      _showSnackBar('Dosen berhasil diperbarui.');
    }
    if (context.canPop()) {
      context.pop(true);
    } else {
      context.go(AdminRoutePaths.dosen);
    }
  }

  /// Dialog wajib ditutup admin sebelum form ditutup agar password awal
  /// benar-benar terlihat/catat.
  Future<void> _showInitialPassword(String? password) async {
    if (password == null || password.isEmpty || !mounted) return;
    final colorScheme = Theme.of(context).colorScheme;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Akun dosen berhasil dibuat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Password awal hanya ditampilkan sekali. Catat atau salin '
              'sekarang sebelum melanjutkan.',
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: AppRadius.control,
              ),
              child: SelectableText(
                password,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: password));
              Navigator.pop(context);
            },
            child: const Text('Salin & Tutup'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Sudah Dicatat'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  FormFieldValidator<String> _required(String label) => (value) =>
      (value ?? '').trim().isEmpty ? '$label wajib diisi' : null;

  @override
  Widget build(BuildContext context) {
    return AdminFormScaffold(
      title: widget.initialItem == null ? 'Tambah Dosen' : 'Edit Dosen',
      onBack: _back,
      onSave: _save,
      isSaving: _isSaving,
      form: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.md),
            LabeledTextField(
              label: 'NIP',
              required: true,
              controller: _nipController,
              hint: '198501012010121001',
              numeric: true,
              enabled: widget.initialItem == null,
              helper: widget.initialItem == null
                  ? 'Masukkan NIP dosen'
                  : 'NIP tidak dapat diubah saat mengedit data.',
              validator: _required('NIP'),
            ),
            const SizedBox(height: AppSpacing.lg),
            LabeledTextField(
              label: 'Nama Dosen',
              required: true,
              controller: _namaController,
              hint: 'Budi Santoso',
              validator: (value) {
                final nama = (value ?? '').trim();
                if (nama.isEmpty) return 'Nama dosen wajib diisi';
                if (nama.length < 2 || nama.length > 100) {
                  return 'Nama dosen harus 2–100 karakter';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            LabeledTextField(
              label: 'Email',
              controller: _emailController,
              hint: 'budi@polinema.ac.id',
              helper: 'Opsional. Kosongkan jika tidak ada.',
              validator: (value) {
                final email = (value ?? '').trim();
                if (email.isEmpty) return null;
                return _emailPattern.hasMatch(email) ? null : 'Email tidak valid';
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            LabeledTextField(
              label: 'No. HP',
              controller: _noHpController,
              hint: '081234567890',
              numeric: true,
              helper: 'Opsional. Kosongkan jika tidak ada.',
              validator: (value) {
                final noHp = (value ?? '').trim();
                if (noHp.isEmpty) return null;
                if (noHp.length < 8 || noHp.length > 20) {
                  return 'No. HP harus 8–20 digit';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}
