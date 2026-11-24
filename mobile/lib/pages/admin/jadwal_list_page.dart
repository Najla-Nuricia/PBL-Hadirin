import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../data/admin/jadwal.dart';
import '../../data/admin/tahun_ajaran.dart';
import '../../routing/admin_route_paths.dart';
import '../../widgets/widgets.dart';
import 'widgets/admin_scaffold.dart';
import 'widgets/jadwal_form_widgets.dart';
import 'widgets/labeled_fields.dart';

typedef _JadwalFilter = ({
  String tahunAjaran,
  SemesterPeriode semester,
  KelasKuliah kelas,
});

/// Tinggi kolom isian tema (satu baris teks 24 dp + padding 2 × 15 dp),
/// supaya pemilih semester sejajar dengan dropdown di sebelahnya.
const double _fieldHeight = 54;

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
    final text = Theme.of(context).textTheme;

    return ListenableBuilder(
      listenable: jadwalRepository,
      builder: (context, _) {
        final jadwalList = jadwalRepository.filter(
          tahunAjaran: _appliedFilter.tahunAjaran,
          semester: _appliedFilter.semester,
          kelasNama: _appliedFilter.kelas.nama,
        );

        return AdminPageScaffold(
          title: 'Daftar Jadwal',
          description: 'Lihat jadwal kuliah per kelas dan semester.',
          onBack: () => context.go(AdminRoutePaths.dataAkademik),
          children: [
            _buildFilterCard(),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Kelas ${_appliedFilter.kelas.nama} · Semester '
              '${_appliedFilter.semester.label} '
              '${_appliedFilter.tahunAjaran}',
              style: text.bodyMedium?.tabular.copyWith(
                color: AppColors.inkMuted,
              ),
            ),
            if (jadwalList.isEmpty)
              AppEmptyState(
                icon: PhosphorIconsRegular.calendarSlash,
                title: 'Belum ada jadwal untuk filter ini.',
                message: 'Ubah filter atau tambah jadwal baru.',
                action: OutlinedButton.icon(
                  onPressed: () => context.go(AdminRoutePaths.tambahJadwal),
                  icon: const Icon(PhosphorIconsRegular.plusCircle, size: 20),
                  label: const Text('Tambah Jadwal Baru'),
                ),
              )
            else
              for (final hari in HariKuliah.values)
                if (jadwalList.any((item) => item.hari == hari))
                  _HariSection(
                    hari: hari,
                    jadwalList: jadwalList
                        .where((item) => item.hari == hari)
                        .toList(),
                  ),
          ],
        );
      },
    );
  }

  Widget _buildFilterCard() {
    final tahunAjaranOptions = [
      for (final item in tahunAjaranRepository.getAll()) item.tahun,
    ];

    return JadwalSectionCard(
      icon: PhosphorIconsRegular.funnelSimple,
      title: 'Filter Jadwal',
      isExpanded: _isFilterExpanded,
      onToggle: () => setState(() => _isFilterExpanded = !_isFilterExpanded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminFieldPair(
            first: AdminLabeledField(
              label: 'Tahun Ajaran',
              child: JadwalDropdownField<String>(
                value: _tahunAjaran,
                items: tahunAjaranOptions,
                itemLabel: (tahun) => tahun,
                onChanged: (tahun) {
                  if (tahun != null) {
                    setState(() => _tahunAjaran = tahun);
                  }
                },
              ),
            ),
            second: AdminLabeledField(
              label: 'Semester',
              child: _SemesterSwitcher(
                value: _semester,
                onChanged: (semester) => setState(() => _semester = semester),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AdminFieldPair(
            first: AdminLabeledField(
              label: 'Tingkat',
              child: JadwalDropdownField<int>(
                value: _tingkat,
                items: JadwalMasterData.tingkat,
                itemLabel: (tingkat) => '$tingkat',
                onChanged: _changeTingkat,
              ),
            ),
            second: AdminLabeledField(
              label: 'Kelas',
              child: JadwalDropdownField<KelasKuliah>(
                key: ValueKey('kelas-filter-$_tingkat'),
                value: _kelas,
                items: JadwalMasterData.kelasByTingkat(_tingkat),
                itemLabel: (kelas) => kelas.nama,
                onChanged: (kelas) {
                  if (kelas != null) setState(() => _kelas = kelas);
                },
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton(
            onPressed: _applyFilter,
            child: const Text('Tampilkan Jadwal'),
          ),
        ],
      ),
    );
  }
}

/// Pemilih dua segmen untuk semester ganjil atau genap.
class _SemesterSwitcher extends StatelessWidget {
  const _SemesterSwitcher({required this.value, required this.onChanged});

  final SemesterPeriode value;
  final ValueChanged<SemesterPeriode> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.control,
        side: BorderSide(color: colorScheme.outline),
      ),
      child: Row(
        children: [
          for (final semester in SemesterPeriode.values)
            Expanded(
              child: Semantics(
                button: true,
                selected: semester == value,
                child: InkWell(
                  onTap: () => onChanged(semester),
                  child: AnimatedContainer(
                    duration: AppMotion.fast,
                    height: _fieldHeight,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    color: colorScheme.primaryContainer.withValues(
                      alpha: semester == value ? 1 : 0,
                    ),
                    child: Text(
                      semester.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: semester == value
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurfaceVariant,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.sm),
        AppSectionHeader(title: hari.label),
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < jadwalList.length; index++) ...[
                if (index > 0) const Divider(),
                _JadwalTile(jadwal: jadwalList[index]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _JadwalTile extends StatelessWidget {
  const _JadwalTile({required this.jadwal});

  final JadwalKuliah jadwal;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final timeStyle = text.titleSmall?.tabular;
    final jamMulai = jadwal.sesiMulai.jamMulai;

    return MergeSemantics(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Jam mulai tebal, jam selesai pudar; tetap satu teks utuh
              // "07:50 – 09:30".
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: jamMulai,
                      style: timeStyle?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(
                      text: jadwal.rentangWaktu.substring(jamMulai.length),
                      style: timeStyle?.copyWith(
                        color: AppColors.inkFaint,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                softWrap: false,
                style: timeStyle,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      jadwal.mataKuliah.nama,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      children: [
                        _MetaPart(jadwal.kelas.nama, separated: true),
                        _MetaPart(jadwal.ruangan.nama, separated: true),
                        _MetaPart(jadwal.dosen.nama),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Satu bagian dari baris "kelas · ruangan · dosen". Tiap bagian berupa teks
/// sendiri supaya bisa pindah baris utuh di layar sempit.
class _MetaPart extends StatelessWidget {
  const _MetaPart(this.label, {this.separated = false});

  final String label;

  /// Menambahkan pemisah " · " setelah teks.
  final bool separated;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.tabular
        .copyWith(color: AppColors.inkFaint);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
        if (separated) Text(' · ', style: style),
      ],
    );
  }
}
