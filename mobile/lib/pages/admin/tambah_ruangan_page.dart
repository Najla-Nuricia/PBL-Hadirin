import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/admin/admin_auth_repository.dart';
import '../../data/admin/admin_master_data_service.dart';
import '../../data/admin/jadwal.dart';
import '../../routing/admin_route_paths.dart';
import '../../widgets/widgets.dart';
import 'widgets/admin_scaffold.dart';
import 'widgets/labeled_fields.dart';

/// Form ruangan untuk tambah dan edit (PUT `/admin/ruangan/{kode_lama}`).
class TambahRuanganPage extends StatefulWidget {
  const TambahRuanganPage({this.initialItem, super.key});

  final Ruangan? initialItem;

  @override
  State<TambahRuanganPage> createState() => _TambahRuanganPageState();
}

class _TambahRuanganPageState extends State<TambahRuanganPage> {
  final _formKey = GlobalKey<FormState>();
  final _kodeController = TextEditingController();
  final _namaController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;
    if (item != null) {
      _kodeController.text = item.kode;
      _namaController.text = item.nama;
    }
  }

  @override
  void dispose() {
    _kodeController.dispose();
    _namaController.dispose();
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
    setState(() => _isSaving = true);
    final isEdit = widget.initialItem != null;
    try {
      if (isEdit) {
        await adminMasterDataService.updateRuangan(
          kodeLama: widget.initialItem!.kode,
          kode: _kodeController.text,
          nama: _namaController.text,
        );
      } else {
        await adminMasterDataService.createRuangan(
          kode: _kodeController.text,
          nama: _namaController.text,
        );
      }
    } on AdminRemoteApiException catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showError(error.message);
      return;
    }
    if (!mounted) return;
    setState(() => _isSaving = false);
    _showSnackBar(
      isEdit
          ? 'Ruangan berhasil diperbarui.'
          : 'Ruangan berhasil dibuat.',
    );
    if (context.canPop()) {
      context.pop(true);
    } else {
      context.go(AdminRoutePaths.ruangan);
    }
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

  @override
  Widget build(BuildContext context) {
    return AdminFormScaffold(
      title: widget.initialItem == null ? 'Tambah Ruangan' : 'Edit Ruangan',
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
              label: 'Kode Ruangan',
              required: true,
              controller: _kodeController,
              hint: 'Contoh: J301',
              validator: (value) {
                final kode = (value ?? '').trim();
                if (kode.isEmpty) return 'Kode ruangan wajib diisi';
                if (kode.length > 50) return 'Kode maksimal 50 karakter';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            LabeledTextField(
              label: 'Nama Ruangan',
              required: true,
              controller: _namaController,
              hint: 'Contoh: Ruang J301',
              validator: (value) {
                final nama = (value ?? '').trim();
                if (nama.isEmpty) return 'Nama ruangan wajib diisi';
                if (nama.length < 2 || nama.length > 100) {
                  return 'Nama ruangan harus 2–100 karakter';
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
