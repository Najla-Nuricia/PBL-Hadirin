import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/admin/jadwal.dart';
import '../../data/admin/tahun_ajaran.dart';
import '../../routing/admin_route_paths.dart';
import 'widgets/jadwal_form_widgets.dart';

typedef _JadwalFilter = ({
  String tahunAjaran,
  SemesterPeriode semester,
  KelasKuliah kelas,
});

class JadwalListPage extends StatefulWidget {
  const JadwalListPage({super.key});

  @override
  State<JadwalListPage> createState() => _JadwalListPageState();
}

class _JadwalListPageState extends State<JadwalListPage> {
  late _JadwalFilter _appliedFilter = _defaultFilter();
  late String _tahunAjaran = _appliedFilter.tahunAjaran;
  late SemesterPeriode _semester = _appliedFilter.semester;
  late int _tingkat = _appliedFilter.kelas.tingkat;
  late KelasKuliah _kelas = _appliedFilter.kelas;
  bool _isFilterExpanded = true;

  static _JadwalFilter _defaultFilter() {
    final tahunAjaranList = tahunAjaranRepository.getAll();
    final aktif = tahunAjaranList.where(
      (item) => item.status == TahunAjaranStatus.aktif,
    );
    final tahunAjaran =
        (aktif.isNotEmpty ? aktif.first : tahunAjaranList.first).tahun;
    final firstJadwal = jadwalRepository.getAll().where(
      (item) => item.tahunAjaran == tahunAjaran,
    );

    return (
      tahunAjaran: tahunAjaran,
      semester: firstJadwal.isNotEmpty
          ? firstJadwal.first.semester
          : SemesterPeriode.ganjil,
      kelas: firstJadwal.isNotEmpty
          ? firstJadwal.first.kelas
          : JadwalMasterData.kelas.first,
    );
  }

  void _applyFilter() {
    setState(() {
      _appliedFilter = (
        tahunAjaran: _tahunAjaran,
        semester: _semester,
        kelas: _kelas,
      );
    });
  }

  void _changeTingkat(int? tingkat) {
    if (tingkat == null || tingkat == _tingkat) return;
    setState(() {
      _tingkat = tingkat;
      _kelas = JadwalMasterData.kelasByTingkat(tingkat).first;
    });
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
              child: ListenableBuilder(
                listenable: jadwalRepository,
                builder: (context, _) {
                  final jadwalList = jadwalRepository.filter(
                    tahunAjaran: _appliedFilter.tahunAjaran,
                    semester: _appliedFilter.semester,
                    kelasNama: _appliedFilter.kelas.nama,
                  );

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      _buildFilterCard(colorScheme),
                      const SizedBox(height: 16),
                      Text(
                        'Kelas ${_appliedFilter.kelas.nama} · Semester '
                        '${_appliedFilter.semester.label} '
                        '${_appliedFilter.tahunAjaran}',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (jadwalList.isEmpty)
                        _buildEmptyState(colorScheme)
                      else
                        for (final hari in HariKuliah.values)
                          if (jadwalList.any((item) => item.hari == hari)) ...[
                            _HariSection(
                              hari: hari,
                              jadwalList: jadwalList
                                  .where((item) => item.hari == hari)
                                  .toList(),
                            ),
                            const SizedBox(height: 10),
                          ],
                    ],
                  );
                },
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
            'Daftar Jadwal',
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

  Widget _buildFilterCard(ColorScheme colorScheme) {
    final tahunAjaranOptions = [
      for (final item in tahunAjaranRepository.getAll()) item.tahun,
    ];

    return JadwalSectionCard(
      icon: Icons.filter_alt_outlined,
      title: 'Filter Jadwal',
      isExpanded: _isFilterExpanded,
      onToggle: () => setState(() => _isFilterExpanded = !_isFilterExpanded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const JadwalFieldLabel(label: 'Tahun Ajaran'),
                    JadwalDropdownField<String>(
                      value: _tahunAjaran,
                      items: tahunAjaranOptions,
                      itemLabel: (tahun) => tahun,
                      onChanged: (tahun) {
                        if (tahun != null) {
                          setState(() => _tahunAjaran = tahun);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const JadwalFieldLabel(label: 'Semester'),
                    _SemesterSwitcher(
                      value: _semester,
                      onChanged: (semester) =>
                          setState(() => _semester = semester),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const JadwalFieldLabel(label: 'Tingkat'),
                    JadwalDropdownField<int>(
                      value: _tingkat,
                      items: JadwalMasterData.tingkat,
                      itemLabel: (tingkat) => '$tingkat',
                      onChanged: _changeTingkat,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const JadwalFieldLabel(label: 'Kelas'),
                    JadwalDropdownField<KelasKuliah>(
                      key: ValueKey('kelas-filter-$_tingkat'),
                      value: _kelas,
                      items: JadwalMasterData.kelasByTingkat(_tingkat),
                      itemLabel: (kelas) => kelas.nama,
                      onChanged: (kelas) {
                        if (kelas != null) setState(() => _kelas = kelas);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 44,
            child: FilledButton.icon(
              onPressed: _applyFilter,
              icon: const Icon(Icons.search, size: 20),
              label: const Text(
                'Tampilkan Jadwal',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_busy_outlined,
            size: 40,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 10),
          Text(
            'Belum ada jadwal untuk filter ini.',
            textAlign: TextAlign.center,
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => context.go(AdminRoutePaths.tambahJadwal),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Tambah Jadwal Baru'),
          ),
        ],
      ),
    );
  }
}

class _SemesterSwitcher extends StatelessWidget {
  const _SemesterSwitcher({required this.value, required this.onChanged});

  final SemesterPeriode value;
  final ValueChanged<SemesterPeriode> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outline),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          for (final semester in SemesterPeriode.values)
            Expanded(
              child: Semantics(
                button: true,
                selected: semester == value,
                child: InkWell(
                  onTap: () => onChanged(semester),
                  borderRadius: BorderRadius.circular(8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: semester == value
                          ? colorScheme.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      semester.label,
                      style: TextStyle(
                        color: semester == value
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HariSection extends StatelessWidget {
  const _HariSection({required this.hari, required this.jadwalList});

  final HariKuliah hari;
  final List<JadwalKuliah> jadwalList;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: colorScheme.primaryContainer.withValues(alpha: 0.6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              hari.label,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          for (var index = 0; index < jadwalList.length; index++) ...[
            if (index > 0)
              Divider(height: 1, color: colorScheme.outlineVariant),
            _JadwalTile(jadwal: jadwalList[index]),
          ],
        ],
      ),
    );
  }
}

class _JadwalTile extends StatelessWidget {
  const _JadwalTile({required this.jadwal});

  final JadwalKuliah jadwal;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final mutedColor = colorScheme.onSurfaceVariant;
    final opacity = jadwal.isAktif ? 1.0 : 0.5;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      child: Row(
        children: [
          Expanded(
            child: Opacity(
              opacity: opacity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    jadwal.mataKuliah.nama,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 14, color: mutedColor),
                      const SizedBox(width: 4),
                      Text(
                        jadwal.rentangWaktu,
                        style: TextStyle(color: mutedColor, fontSize: 12),
                      ),
                      const SizedBox(width: 14),
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: mutedColor,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          jadwal.ruangan.nama,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: mutedColor, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    jadwal.isAktif
                        ? jadwal.dosen.nama
                        : '${jadwal.dosen.nama} · Nonaktif',
                    style: TextStyle(color: mutedColor, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          Semantics(
            label: 'Jadwal ${jadwal.mataKuliah.nama} aktif',
            child: Switch(
              value: jadwal.isAktif,
              onChanged: (isAktif) =>
                  jadwalRepository.setAktif(jadwal.id, isAktif: isAktif),
            ),
          ),
        ],
      ),
    );
  }
}
