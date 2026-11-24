import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../data/admin/jadwal.dart';
import '../../data/admin/mata_kuliah.dart';
import '../../data/admin/tahun_ajaran.dart';
import '../../routing/admin_route_paths.dart';
import '../../widgets/widgets.dart';
import 'widgets/admin_scaffold.dart';
import 'widgets/jadwal_form_widgets.dart';
import 'widgets/labeled_fields.dart';

class TambahJadwalPage extends StatefulWidget {
  const TambahJadwalPage({super.key});

  @override
  State<TambahJadwalPage> createState() => _TambahJadwalPageState();
}

class _TambahJadwalPageState extends State<TambahJadwalPage> {
  final _formKey = GlobalKey<FormState>();

  /// Bumped after a successful save to rebuild every field with a clean state.
  int _formGeneration = 0;

  late String _tahunAjaran = _defaultTahunAjaran();
  ProgramStudi _programStudi = JadwalMasterData.programStudi.first;
  MataKuliah? _mataKuliah;
  Dosen? _dosen;
  KelasKuliah? _kelas;
  Ruangan? _ruangan;
  HariKuliah? _hari;
  SesiKuliah? _sesiMulai;
  SesiKuliah? _sesiSelesai;

  bool _isSubmitting = false;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  /// Rincian bentrok dari percobaan simpan terakhir. Tampil di atas tombol
  /// simpan sampai isian diubah.
  String? _conflictMessage;

  static String _defaultTahunAjaran() {
    final all = tahunAjaranRepository.getAll();
    final aktif = all.where((item) => item.status == TahunAjaranStatus.aktif);
    return (aktif.isNotEmpty ? aktif.first : all.first).tahun;
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() {
      _conflictMessage = null;
      _autovalidateMode = AutovalidateMode.onUserInteraction;
    });
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    // Simulate network latency
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    final jadwal = JadwalKuliah(
      id: jadwalRepository.generateId(),
      tahunAjaran: _tahunAjaran,
      mataKuliah: _mataKuliah!,
      dosen: _dosen!,
      programStudi: _programStudi,
      kelas: _kelas!,
      ruangan: _ruangan!,
      hari: _hari!,
      sesiMulai: _sesiMulai!,
      sesiSelesai: _sesiSelesai!,
    );

    try {
      jadwalRepository.add(jadwal);
    } on JadwalConflictException catch (error) {
      // Isian dibiarkan apa adanya: cukup bagian yang bentrok yang diperbaiki.
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      setState(() {
        _isSubmitting = false;
        _conflictMessage = error.message;
      });
      return;
    }

    setState(() {
      _isSubmitting = false;
      _mataKuliah = null;
      _dosen = null;
      _kelas = null;
      _ruangan = null;
      _hari = null;
      _sesiMulai = null;
      _sesiSelesai = null;
      _autovalidateMode = AutovalidateMode.disabled;
      _formGeneration++;
    });
    _showMessage(
      'Jadwal ${jadwal.mataKuliah.nama} untuk ${jadwal.kelas.nama} '
      'berhasil disimpan.',
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _clearConflict() {
    if (_conflictMessage != null) setState(() => _conflictMessage = null);
  }

  String? _validateKelas(KelasKuliah? kelas) {
    if (kelas == null) return 'Kelas wajib dipilih.';
    final mataKuliah = _mataKuliah;
    if (mataKuliah != null && mataKuliah.tingkat != kelas.tingkat) {
      return '${mataKuliah.nama} (semester ${mataKuliah.semester}) '
          'untuk tingkat ${mataKuliah.tingkat}.';
    }
    return null;
  }

  String? _validateSesiSelesai(SesiKuliah? sesi) {
    if (sesi == null) return 'Wajib dipilih.';
    final mulai = _sesiMulai;
    if (mulai != null && sesi.nomor < mulai.nomor) {
      return 'Harus setelah sesi mulai.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final conflictMessage = _conflictMessage;

    return AdminFormScaffold(
      title: 'Tambah Jadwal Baru',
      description: 'Atur mata kuliah, ruang, dan waktu perkuliahan.',
      onBack: () => context.go(AdminRoutePaths.dataAkademik),
      onSave: _submit,
      saveLabel: 'Simpan Jadwal',
      isSaving: _isSubmitting,
      notice: conflictMessage == null
          ? null
          : AppBanner(
              tone: StatusTone.danger,
              title: 'Jadwal bentrok',
              message: conflictMessage,
            ),
      form: Form(
        key: _formKey,
        autovalidateMode: _autovalidateMode,
        onChanged: _clearConflict,
        child: KeyedSubtree(
          key: ValueKey(_formGeneration),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppSectionHeader(title: 'Informasi Akademik'),
              ..._buildAkademikFields(context),
              const SizedBox(height: AppSpacing.sm),
              const AppSectionHeader(title: 'Alokasi Waktu & Tempat'),
              ..._buildWaktuFields(context),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAkademikFields(BuildContext context) {
    final tahunAjaranOptions = [
      for (final item in tahunAjaranRepository.getAll()) item.tahun,
    ];
    final mataKuliah = _mataKuliah;

    return [
      AdminLabeledField(
        label: 'Tahun Ajaran',
        required: true,
        child: JadwalDropdownField<String>(
          value: _tahunAjaran,
          items: tahunAjaranOptions,
          itemLabel: (tahun) => tahun,
          onChanged: (tahun) {
            if (tahun != null) setState(() => _tahunAjaran = tahun);
          },
          validator: (tahun) =>
              tahun == null ? 'Tahun ajaran wajib dipilih.' : null,
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      AdminLabeledField(
        label: 'Mata Kuliah',
        required: true,
        child: JadwalSearchPickerField<MataKuliah>(
          value: _mataKuliah,
          options: mataKuliahRepository.getActive(),
          itemLabel: (item) => item.nama,
          itemSubtitle: (item) =>
              '${item.kode} · Semester ${item.semester} · ${item.sks} SKS',
          searchText: (item) => '${item.nama} ${item.kode}',
          hintText: 'Cari & Pilih Mata Kuliah...',
          sheetTitle: 'Pilih Mata Kuliah',
          onChanged: (item) => setState(() => _mataKuliah = item),
          validator: (item) =>
              item == null ? 'Mata kuliah wajib dipilih.' : null,
        ),
      ),
      if (mataKuliah != null)
        _FieldHint(
          'Semester ${mataKuliah.semester} (${mataKuliah.periode.label}) · '
          '${mataKuliah.sks} SKS',
        ),
      const SizedBox(height: AppSpacing.lg),
      AdminLabeledField(
        label: 'Dosen Pengampu',
        required: true,
        child: JadwalSearchPickerField<Dosen>(
          value: _dosen,
          options: JadwalMasterData.dosen,
          itemLabel: (item) => item.nama,
          itemSubtitle: (item) => 'NIP ${item.nip}',
          searchText: (item) => '${item.nama} ${item.nip}',
          hintText: 'Cari Nama/NIP Dosen...',
          sheetTitle: 'Pilih Dosen Pengampu',
          onChanged: (item) => setState(() => _dosen = item),
          validator: (item) => item == null ? 'Dosen wajib dipilih.' : null,
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      AdminLabeledField(
        label: 'Program Studi',
        child: JadwalDropdownField<ProgramStudi>(
          value: _programStudi,
          items: JadwalMasterData.programStudi,
          itemLabel: (item) => item.nama,
          onChanged: (item) {
            if (item == null || item == _programStudi) return;
            setState(() {
              _programStudi = item;
              _kelas = null;
            });
          },
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      AdminLabeledField(
        label: 'Kelas',
        required: true,
        child: JadwalSearchPickerField<KelasKuliah>(
          key: ValueKey('kelas-${_programStudi.kode}'),
          value: _kelas,
          options: JadwalMasterData.kelasByProgramStudi(_programStudi.kode),
          itemLabel: (item) => item.nama,
          itemSubtitle: (item) => 'Tingkat ${item.tingkat}',
          searchText: (item) => item.nama,
          hintText: 'Cari Kelas (TI-2A)...',
          sheetTitle: 'Pilih Kelas',
          onChanged: (item) => setState(() => _kelas = item),
          validator: _validateKelas,
        ),
      ),
    ];
  }

  List<Widget> _buildWaktuFields(BuildContext context) {
    final sesiMulai = _sesiMulai;
    final sesiSelesai = _sesiSelesai;

    return [
      AdminFieldPair(
        // Petunjuk pencarian ruangan butuh kolom yang lebar; di ponsel
        // kedua isian ditumpuk.
        minColumnWidth: 240,
        first: AdminLabeledField(
          label: 'Ruangan',
          required: true,
          child: JadwalSearchPickerField<Ruangan>(
            value: _ruangan,
            options: JadwalMasterData.ruangan,
            itemLabel: (item) => item.nama,
            searchText: (item) => '${item.nama} ${item.kode}',
            hintText: 'Cari Ruang (LPR)...',
            sheetTitle: 'Pilih Ruangan',
            onChanged: (item) => setState(() => _ruangan = item),
            validator: (item) => item == null ? 'Wajib dipilih.' : null,
          ),
        ),
        second: AdminLabeledField(
          label: 'Hari',
          required: true,
          child: JadwalDropdownField<HariKuliah>(
            value: _hari,
            items: HariKuliah.values,
            itemLabel: (item) => item.label,
            hintText: 'Pilih Hari...',
            prefixIcon: PhosphorIconsRegular.calendarBlank,
            onChanged: (item) => setState(() => _hari = item),
            validator: (item) => item == null ? 'Wajib dipilih.' : null,
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      AdminFieldPair(
        minColumnWidth: 140,
        first: AdminLabeledField(
          label: 'Jam / Sesi Mulai',
          required: true,
          child: _buildSesiDropdown(
            value: _sesiMulai,
            onChanged: (item) => setState(() => _sesiMulai = item),
            validator: (item) => item == null ? 'Wajib dipilih.' : null,
          ),
        ),
        second: AdminLabeledField(
          label: 'Jam / Sesi Selesai',
          required: true,
          child: _buildSesiDropdown(
            value: _sesiSelesai,
            onChanged: (item) => setState(() => _sesiSelesai = item),
            validator: _validateSesiSelesai,
          ),
        ),
      ),
      if (sesiMulai != null &&
          sesiSelesai != null &&
          sesiSelesai.nomor >= sesiMulai.nomor)
        _FieldHint(
          'Waktu kuliah: ${sesiMulai.jamMulai} – ${sesiSelesai.jamSelesai}',
        ),
    ];
  }

  Widget _buildSesiDropdown({
    required SesiKuliah? value,
    required ValueChanged<SesiKuliah?> onChanged,
    required FormFieldValidator<SesiKuliah> validator,
  }) {
    return JadwalDropdownField<SesiKuliah>(
      value: value,
      items: JadwalMasterData.sesi,
      itemLabel: (item) =>
          'Sesi ${item.nomor} (${item.jamMulai}–${item.jamSelesai})',
      selectedItemLabel: (item) => '${item.nomor}',
      hintText: 'Sesi',
      prefixIcon: PhosphorIconsRegular.clock,
      onChanged: onChanged,
      validator: validator,
    );
  }
}

/// Keterangan kecil di bawah kolom isian.
class _FieldHint extends StatelessWidget {
  const _FieldHint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.tabular
            .copyWith(color: AppColors.inkMuted),
      ),
    );
  }
}
