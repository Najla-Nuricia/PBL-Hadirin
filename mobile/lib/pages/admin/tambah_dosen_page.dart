import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../routing/admin_route_paths.dart';
import '../../widgets/widgets.dart';
import 'widgets/admin_scaffold.dart';
import 'widgets/labeled_fields.dart';

const _programStudi = [
  'D4 Teknik Informatika',
  'D4 Sistem Informasi Bisnis',
  'D2 Pengembangan Perangkat Lunak Situs',
];
const _statusOptions = ['Aktif', 'Non-Aktif'];

class TambahDosenPage extends StatefulWidget {
  const TambahDosenPage({super.key});

  @override
  State<TambahDosenPage> createState() => _TambahDosenPageState();
}

class _TambahDosenPageState extends State<TambahDosenPage> {
  final _formKey = GlobalKey<FormState>();
  final _nipController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  String _prodi = _programStudi.first;
  String _status = _statusOptions.first;

  @override
  void dispose() {
    _nipController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Dosen berhasil ditambahkan')));
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AdminRoutePaths.dataAkademik);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminFormScaffold(
      title: 'Tambah Dosen',
      onSave: _save,
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
              hint: '197710302005012001',
              numeric: true,
              helper: 'Masukkan NIP dosen',
              validator: _required('NIP'),
            ),
            const SizedBox(height: AppSpacing.lg),
            LabeledTextField(
              label: 'Nama Dosen',
              required: true,
              controller: _nameController,
              hint: 'Agung Nugroho Pramudhita, S.T., M.T.',
              validator: _required('Nama dosen'),
            ),
            const SizedBox(height: AppSpacing.lg),
            LabeledTextField(
              label: 'Email',
              controller: _emailController,
              hint: 'agung@polinema.ac.id',
              validator: (value) {
                final email = (value ?? '').trim();
                if (email.isEmpty) return null;
                return email.contains('@') ? null : 'Email tidak valid';
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            LabeledDropdown(
              label: 'Program Studi',
              required: true,
              value: _prodi,
              items: _programStudi,
              onChanged: (value) => setState(() => _prodi = value),
            ),
            const SizedBox(height: AppSpacing.lg),
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
    );
  }

  FormFieldValidator<String> _required(String label) {
    return (value) =>
        (value ?? '').trim().isEmpty ? '$label wajib diisi' : null;
  }
}
