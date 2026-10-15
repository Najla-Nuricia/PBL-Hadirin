import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/admin/jadwal.dart';
import '../../data/admin/tahun_ajaran.dart';
import '../../routing/admin_route_paths.dart';
import 'widgets/jadwal_form_widgets.dart';

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

  bool _isAkademikExpanded = true;
  bool _isWaktuExpanded = true;
  bool _isSubmitting = false;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  static String _defaultTahunAjaran() {
    final all = tahunAjaranRepository.getAll();
    final aktif = all.where((item) => item.status == TahunAjaranStatus.aktif);
    return (aktif.isNotEmpty ? aktif.first : all.first).tahun;
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() {
      _isAkademikExpanded = true;
      _isWaktuExpanded = true;
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
      setState(() => _isSubmitting = false);
      _showMessage('Jadwal bentrok: ${error.message}');
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildAppBar(colorScheme),
            Expanded(
              child: Form(
                key: _formKey,
                autovalidateMode: _autovalidateMode,
                child: SingleChildScrollView(
                  key: ValueKey(_formGeneration),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      JadwalSectionCard(
                        icon: Icons.school_outlined,
                        title: 'Informasi Akademik',
                        isExpanded: _isAkademikExpanded,
                        onToggle: () => setState(
                          () => _isAkademikExpanded = !_isAkademikExpanded,
                        ),
                        child: _buildAkademikFields(colorScheme),
                      ),
                      const SizedBox(height: 12),
                      JadwalSectionCard(
                        icon: Icons.schedule,
                        title: 'Alokasi Waktu & Tempat',
                        isExpanded: _isWaktuExpanded,
                        onToggle: () => setState(
                          () => _isWaktuExpanded = !_isWaktuExpanded,
                        ),
                        child: _buildWaktuFields(colorScheme),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    disabledBackgroundColor: colorScheme.primary.withValues(
                      alpha: 0.38,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.onPrimary,
                          ),
                        )
                      : const Text(
                          'Simpan Jadwal',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 6, 16, 6),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            color: colorScheme.onSurface,
            onPressed: () => context.go(AdminRoutePaths.dataAkademik),
            tooltip: 'Kembali',
          ),
          const SizedBox(width: 8),
          Text(
            'Tambah Jadwal Baru',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAkademikFields(ColorScheme colorScheme) {
    final tahunAjaranOptions = [
      for (final item in tahunAjaranRepository.getAll()) item.tahun,
    ];
    final mataKuliah = _mataKuliah;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const JadwalFieldLabel(label: 'Tahun Ajaran', required: true),
        JadwalDropdownField<String>(
          value: _tahunAjaran,
          items: tahunAjaranOptions,
          itemLabel: (tahun) => tahun,
          onChanged: (tahun) {
            if (tahun != null) setState(() => _tahunAjaran = tahun);
          },
          validator: (tahun) =>
              tahun == null ? 'Tahun ajaran wajib dipilih.' : null,
        ),
        const SizedBox(height: 14),
        const JadwalFieldLabel(label: 'Mata Kuliah', required: true),
        JadwalSearchPickerField<MataKuliah>(
          value: _mataKuliah,
          options: JadwalMasterData.mataKuliah,
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
        if (mataKuliah != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Semester ${mataKuliah.semester} (${mataKuliah.periode.label}) · '
              '${mataKuliah.sks} SKS',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ),
        const SizedBox(height: 14),
        const JadwalFieldLabel(label: 'Dosen Pengampu', required: true),
        JadwalSearchPickerField<Dosen>(
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
        const SizedBox(height: 14),
        const JadwalFieldLabel(label: 'Program Studi'),
        JadwalDropdownField<ProgramStudi>(
          value: _programStudi,
          items: JadwalMasterData.programStudi,
          itemLabel: (item) => item.nama,
          filled: true,
          onChanged: (item) {
            if (item == null || item == _programStudi) return;
            setState(() {
              _programStudi = item;
              _kelas = null;
            });
          },
        ),
        const SizedBox(height: 14),
        const JadwalFieldLabel(label: 'Kelas', required: true),
        JadwalSearchPickerField<KelasKuliah>(
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
      ],
    );
  }

  Widget _buildWaktuFields(ColorScheme colorScheme) {
    final sesiMulai = _sesiMulai;
    final sesiSelesai = _sesiSelesai;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const JadwalFieldLabel(label: 'Ruangan', required: true),
                  JadwalSearchPickerField<Ruangan>(
                    value: _ruangan,
                    options: JadwalMasterData.ruangan,
                    itemLabel: (item) => item.nama,
                    searchText: (item) => '${item.nama} ${item.kode}',
                    hintText: 'Cari Ruang (LPR)...',
                    sheetTitle: 'Pilih Ruangan',
                    onChanged: (item) => setState(() => _ruangan = item),
                    validator: (item) => item == null ? 'Wajib dipilih.' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const JadwalFieldLabel(label: 'Hari', required: true),
                  JadwalDropdownField<HariKuliah>(
                    value: _hari,
                    items: HariKuliah.values,
                    itemLabel: (item) => item.label,
                    hintText: 'Pilih Hari...',
                    prefixIcon: Icons.calendar_today_outlined,
                    onChanged: (item) => setState(() => _hari = item),
                    validator: (item) => item == null ? 'Wajib dipilih.' : null,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const JadwalFieldLabel(
                    label: 'Jam / Sesi Mulai',
                    required: true,
                  ),
                  _buildSesiDropdown(
                    value: _sesiMulai,
                    onChanged: (item) => setState(() => _sesiMulai = item),
                    validator: (item) => item == null ? 'Wajib dipilih.' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const JadwalFieldLabel(
                    label: 'Jam / Sesi Selesai',
                    required: true,
                  ),
                  _buildSesiDropdown(
                    value: _sesiSelesai,
                    onChanged: (item) => setState(() => _sesiSelesai = item),
                    validator: _validateSesiSelesai,
                  ),
                ],
              ),
            ),
          ],
        ),
        if (sesiMulai != null &&
            sesiSelesai != null &&
            sesiSelesai.nomor >= sesiMulai.nomor)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Waktu kuliah: ${sesiMulai.jamMulai} – ${sesiSelesai.jamSelesai}',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ),
      ],
    );
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
      prefixIcon: Icons.schedule,
      onChanged: onChanged,
      validator: validator,
    );
  }
}
