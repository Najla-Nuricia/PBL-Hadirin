import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/admin/admin_auth_repository.dart';
import '../../data/admin/admin_whitelist_nim_service.dart';
import '../../data/admin/whitelist_nim.dart';
import '../../routing/admin_route_paths.dart';
import 'tambah_mata_kuliah_page.dart';
import 'widgets/labeled_fields.dart';

class TambahWhitelistNimPage extends StatefulWidget {
  const TambahWhitelistNimPage({this.initialItem, super.key});

  final WhitelistNim? initialItem;

  @override
  State<TambahWhitelistNimPage> createState() => _TambahWhitelistNimPageState();
}

class _TambahWhitelistNimPageState extends State<TambahWhitelistNimPage> {
  final _formKey = GlobalKey<FormState>();
  final _nimController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;
    if (item != null) {
      _nimController.text = item.nim;
    }
  }

  @override
  void dispose() {
    _nimController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final nim = _nimController.text.trim();
      if (widget.initialItem == null) {
        await adminWhitelistNimService.create(nim);
      } else {
        await adminWhitelistNimService.update(
          oldNim: widget.initialItem!.nim,
          nim: nim,
        );
      }
    } on AdminRemoteApiException catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showError(error.message);
      return;
    }

    if (!mounted) return;
    if (context.canPop()) {
      context.pop(true);
    } else {
      context.go(AdminRoutePaths.dataAkademik);
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
          ? 'Tambah Whitelist NIM'
          : 'Edit Whitelist NIM',
      form: Form(
        key: _formKey,
        child: LabeledTextField(
          label: 'NIM',
          required: true,
          controller: _nimController,
          hint: '2341720001',
          numeric: true,
          helper: 'Masukkan NIM mahasiswa yang diizinkan registrasi',
          validator: _validateNim,
        ),
      ),
      onSave: _isSubmitting ? null : _save,
    );
  }

  String? _validateNim(String? value) {
    final nim = (value ?? '').trim();
    if (nim.isEmpty) return 'NIM wajib diisi';
    if (nim.length < 3 || nim.length > 20) return 'NIM harus 3–20 digit';
    if (!RegExp(r'^\d+$').hasMatch(nim)) return 'NIM hanya boleh berisi angka';
    return null;
  }
}
