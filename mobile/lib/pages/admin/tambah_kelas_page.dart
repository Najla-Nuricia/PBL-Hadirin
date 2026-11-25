import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/admin/admin_auth_repository.dart';
import '../../data/admin/admin_master_data_service.dart';
import '../../data/admin/jadwal.dart';
import '../../data/admin/kelas.dart';
import '../../data/admin/tahun_ajaran.dart';
import '../../routing/admin_route_paths.dart';
import '../../widgets/widgets.dart';
import 'widgets/admin_scaffold.dart';
import 'widgets/labeled_fields.dart';

/// Form kelas untuk tambah dan edit.
///
/// Pilihan program studi dan tahun ajaran diambil dari endpoint master data
/// yang sudah dipakai modul lain (`/admin/program-studi`,
/// `/admin/tahun-ajaran`).
class TambahKelasPage extends StatefulWidget {
  const TambahKelasPage({
    this.initialItem,
    this.programStudi,
    this.tahunAjaran,
    super.key,
  });

  final Kelas? initialItem;
  final List<ProgramStudi>? programStudi;
  final List<TahunAjaran>? tahunAjaran;

  @override
  State<TambahKelasPage> createState() => _TambahKelasPageState();
}

class _TambahKelasPageState extends State<TambahKelasPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaCtrl = TextEditingController();
  final _kapasitasCtrl = TextEditingController(text: '30');

  static const _tingkatOptions = ['1', '2', '3', '4', '5', '6', '7', '8'];
  static const _statusOptions = ['aktif', 'non_aktif'];
  static final _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
    r'[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  List<ProgramStudi> _programStudi = const [];
  List<TahunAjaran> _tahunAjaran = const [];
  String? _prodiKode;
  String? _tahunAjaranId;
  String _tingkat = '1';
  String _status = 'aktif';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;
    if (item != null) {
      _namaCtrl.text = item.nama;
      _tingkat = '${item.tingkat}';
      _kapasitasCtrl.text = '${item.kapasitas}';
      _status = item.status.apiValue;
      _prodiKode = item.programStudiKode;
      _tahunAjaranId = item.tahunAjaranId;
    }
    _programStudi = widget.programStudi ?? const [];
    _tahunAjaran = widget.tahunAjaran ?? const [];
    if (_programStudi.isEmpty || _tahunAjaran.isEmpty) {
      _loadOptions();
    } else {
      _setDefaults();
    }
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _kapasitasCtrl.dispose();
    super.dispose();
  }

  /// Fallback lokal membuat form tetap terisi saat backend belum tersedia.
  Future<void> _loadOptions() async {
    try {
      final results = await Future.wait<Object>([
        adminMasterDataService.listProgramStudi(),
        adminMasterDataService.listTahunAjaran(),
      ]);
      if (!mounted) return;
      _programStudi = results[0] as List<ProgramStudi>;
      _tahunAjaran = results[1] as List<TahunAjaran>;
    } on AdminRemoteApiException {
      if (!mounted) return;
      if (_programStudi.isEmpty) _programStudi = JadwalMasterData.programStudi;
      if (_tahunAjaran.isEmpty) {
        _tahunAjaran = tahunAjaranRepository.getAll();
      }
    }
    if (!mounted) return;
    setState(_setDefaults);
  }

  void _setDefaults() {
    if (_programStudi.isNotEmpty &&
        (_prodiKode == null ||
            !_programStudi.any((item) => item.kode == _prodiKode))) {
      _prodiKode = _programStudi.first.kode;
    }
    if (_tahunAjaran.isNotEmpty &&
        (_tahunAjaranId == null ||
            !_tahunAjaran.any((item) => item.id == _tahunAjaranId))) {
      final active = _tahunAjaran.where(
        (item) => item.status == TahunAjaranStatus.aktif,
      );
      _tahunAjaranId = (active.isNotEmpty ? active : _tahunAjaran).first.id;
    }
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
    if (_prodiKode == null || _prodiKode!.isEmpty) {
      _showError('Program studi wajib dipilih.');
      return;
    }
    if (_tahunAjaranId == null || !_uuidPattern.hasMatch(_tahunAjaranId!)) {
      _showError('Tahun ajaran harus dipilih dengan ID UUID yang valid.');
      return;
    }

    final isEdit = widget.initialItem != null;
    setState(() => _isSaving = true);
    try {
      if (isEdit) {
        await adminMasterDataService.updateKelas(
          id: widget.initialItem!.id,
          nama: _namaCtrl.text,
          tingkat: int.parse(_tingkat),
          programStudiKode: _prodiKode!,
          tahunAjaranId: _tahunAjaranId!,
          kapasitas: int.parse(_kapasitasCtrl.text),
          status: _status == 'aktif'
              ? KelasStatus.aktif
              : KelasStatus.nonAktif,
        );
      } else {
        await adminMasterDataService.createKelas(
          nama: _namaCtrl.text,
          tingkat: int.parse(_tingkat),
          programStudiKode: _prodiKode!,
          tahunAjaranId: _tahunAjaranId!,
          kapasitas: int.parse(_kapasitasCtrl.text),
          status: _status == 'aktif'
              ? KelasStatus.aktif
              : KelasStatus.nonAktif,
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
      isEdit ? 'Kelas berhasil diperbarui.' : 'Kelas berhasil dibuat.',
    );
    if (context.canPop()) {
      context.pop(true);
    } else {
      context.go(AdminRoutePaths.kelas);
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
      title: widget.initialItem == null ? 'Tambah Kelas' : 'Edit Kelas',
      onBack: _back,
      onSave: _save,
      isSaving: _isSaving,
      form: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.md),
            LabeledDropdown(
              label: 'Tahun Ajaran',
              required: true,
              value: _tahunAjaranId,
              items: [for (final item in _tahunAjaran) item.id],
              itemLabels: {
                for (final item in _tahunAjaran) item.id: item.tahun,
              },
              onChanged: (value) =>
                  setState(() => _tahunAjaranId = value),
            ),
            const SizedBox(height: AppSpacing.lg),
            LabeledDropdown(
              label: 'Program Studi',
              required: true,
              value: _prodiKode,
              items: [for (final item in _programStudi) item.kode],
              itemLabels: {
                for (final item in _programStudi) item.kode: item.nama,
              },
              onChanged: (value) => setState(() => _prodiKode = value),
            ),
            const SizedBox(height: AppSpacing.lg),
            LabeledTextField(
              label: 'Nama Kelas',
              required: true,
              controller: _namaCtrl,
              hint: 'TI-3F',
              helper: 'Contoh: TI-3A, SIB-2C',
              validator: (value) {
                final nama = (value ?? '').trim();
                if (nama.isEmpty) return 'Nama kelas wajib diisi';
                if (nama.length > 50) return 'Nama kelas maksimal 50 karakter';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            LabeledDropdown(
              label: 'Tingkat',
              required: true,
              value: _tingkat,
              items: _tingkatOptions,
              onChanged: (value) => setState(() => _tingkat = value),
            ),
            const SizedBox(height: AppSpacing.lg),
            LabeledTextField(
              label: 'Kapasitas',
              required: true,
              controller: _kapasitasCtrl,
              numeric: true,
              hint: '30',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Kapasitas wajib diisi';
                }
                final kapasitas = int.tryParse(value.trim());
                if (kapasitas == null || kapasitas < 1 || kapasitas > 200) {
                  return 'Kapasitas harus 1–200';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            LabeledDropdown(
              label: 'Status',
              required: true,
              value: _status,
              items: _statusOptions,
              itemLabels: const {'aktif': 'Aktif', 'non_aktif': 'Non-Aktif'},
              onChanged: (value) => setState(() => _status = value),
            ),
          ],
        ),
      ),
    );
  }
}
