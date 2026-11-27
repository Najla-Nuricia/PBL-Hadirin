// lib/pages/dosen/cek_presensi_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../data/dosen/dosen_data_service.dart';
import '../../data/dosen/lecturer_providers.dart';
import '../../data/dosen/presensi_options.dart';
import '../../models/dosen/dosen_dashboard.dart';
import '../../models/dosen/matkul_option.dart';
import '../../routing/lecturer_route_paths.dart';
import '../../theme/style/lecturer_style.dart';
import '../../widgets/widgets.dart';
import 'widgets/attendance_counts_card.dart';
import 'widgets/content_constraint.dart';
import 'widgets/load_state.dart';
import 'widgets/section_card.dart';

const _hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
const _bulan = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

String _formatTanggal(DateTime d) =>
    '${_hari[d.weekday - 1]}, ${d.day} ${_bulan[d.month - 1]} ${d.year}';

class CekPresensiPage extends ConsumerStatefulWidget {
  const CekPresensiPage({super.key});

  @override
  ConsumerState<CekPresensiPage> createState() => _CekPresensiPageState();
}

class _CekPresensiPageState extends ConsumerState<CekPresensiPage> {
  String _kelas = lecturerKelasOptions.first;
  String _mataKuliah = lecturerMataKuliahOptions.first;
  DateTime _tanggal = DateTime.now();
  bool _tanggalDipilih = false;
  MatkulOption? _selectedMatkul;
  bool _bypassLocation = false;
  bool _savingBypass = false;

  @override
  void initState() {
    super.initState();
    _loadLocationBypass();
  }

  Future<void> _loadLocationBypass() async {
    try {
      final enabled = await dosenDataService.loadLocationBypass();
      if (!mounted) return;
      setState(() => _bypassLocation = enabled);
    } catch (_) {
      // Mode demo / backend tidak tersedia: biarkan nilai bawaan.
    }
  }

  Future<void> _onBypassChanged(bool value) async {
    setState(() {
      _bypassLocation = value;
      _savingBypass = true;
    });
    try {
      final saved = await dosenDataService.setLocationBypass(value);
      if (!mounted) return;
      setState(() => _bypassLocation = saved);
    } catch (error) {
      if (!mounted) return;
      setState(() => _bypassLocation = !value);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _savingBypass = false);
    }
  }

  bool _isDemo(DosenDashboard? dashboard) =>
      dashboard == null || dashboard.isDemo || dashboard.jadwal.isEmpty;

  String _kelasId(DosenDashboard? dashboard) =>
      _isDemo(dashboard) ? '' : (dashboard!.kelasIdFor(_kelas) ?? '');

  List<MatkulOption> _apiOptions(DosenDashboard? dashboard) {
    if (_isDemo(dashboard)) return const <MatkulOption>[];
    return ref
            .read(
              dosenMatkulProvider((
                kelasId: _kelasId(dashboard),
                tanggal: _tanggal,
              )),
            )
            .value ??
        const <MatkulOption>[];
  }

  /// Opsi backend dipakai bila tersedia, opsi demo tetap menjadi fallback.
  List<String> get _kelasOptions {
    final backend =
        ref.watch(dosenDashboardProvider).value?.kelasOptions ??
        const <String>[];
    return {...backend, _kelas}.toList();
  }

  /// Nama mata kuliah dari endpoint `/dosen/matkul`; fallback ke jadwal
  /// dashboard saat endpoint belum merespons / mode demo.
  List<String> _courseNames({
    required DosenDashboard? dashboard,
    required List<MatkulOption> apiOptions,
  }) {
    if (_isDemo(dashboard)) return lecturerMataKuliahOptions;
    if (apiOptions.isNotEmpty) {
      return apiOptions.map((m) => m.nama).where((n) => n.isNotEmpty).toList();
    }
    return dashboard!.mataKuliahOptionsFor(kelas: _kelas, tanggal: _tanggal);
  }

  List<String> _mataKuliahItems({
    required DosenDashboard? dashboard,
    required List<MatkulOption> apiOptions,
  }) {
    final names = _courseNames(dashboard: dashboard, apiOptions: apiOptions);
    if (names.isEmpty) return [_mataKuliah];
    return {_mataKuliah, ...names}.toList();
  }

  void _selectMatkul(String nama, List<MatkulOption> apiOptions) {
    _mataKuliah = nama;
    for (final option in apiOptions) {
      if (option.nama == nama) {
        _selectedMatkul = option;
        return;
      }
    }
    _selectedMatkul = null;
  }

  /// Reset pilihan saat kelas/tanggal berubah.
  void _syncMataKuliah() {
    final dashboard = ref.read(dosenDashboardProvider).value;
    final apiOptions = _apiOptions(dashboard);
    final names = _courseNames(dashboard: dashboard, apiOptions: apiOptions);
    if (names.isNotEmpty && !names.contains(_mataKuliah)) {
      setState(() => _selectMatkul(names.first, apiOptions));
    }
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(LecturerRoutePaths.beranda);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _tanggal = picked;
        _tanggalDipilih = true;
        _syncMataKuliah();
      });
    }
  }

  void _tampilkan() {
    final dashboardAsync = ref.read(dosenDashboardProvider);
    if (dashboardAsync.isLoading) {
      _showMessage('Data jadwal masih dimuat.');
      return;
    }

    final dashboard = dashboardAsync.value;
    final apiOptions = _apiOptions(dashboard);
    var selected = _selectedMatkul;
    if (selected == null) {
      for (final option in apiOptions) {
        if (option.nama == _mataKuliah) {
          selected = option;
          break;
        }
      }
    }
    final jadwal = dashboard?.findJadwal(
      kelas: _kelas,
      mataKuliah: _mataKuliah,
      tanggal: _tanggal,
    );
    if (!_isDemo(dashboard) && jadwal == null && selected == null) {
      _showMessage('Jadwal untuk pilihan ini tidak ditemukan.');
      return;
    }

    ref
        .read(attendanceQueryProvider.notifier)
        .select(
          AttendanceQuery(
            jadwalId: selected?.jadwalId ?? jadwal?.jadwalId ?? 'demo',
            // Tanpa pilihan tanggal, backend memakai sesi terakhir jadwal.
            tanggal: _tanggalDipilih ? _tanggal : null,
          ),
        );
    ref.invalidate(attendanceSessionProvider);

    context.push(
      LecturerRoutePaths.daftarKehadiran,
      extra: PresensiFilter(
        kelas: _kelas,
        tanggal: _tanggal,
        mataKuliah: _mataKuliah,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dosenDashboardProvider);
    final dashboard = dashboardAsync.value;
    final ringkasan = dashboard?.summary;
    final kelasId = _kelasId(dashboard);
    final matkulQuery = (kelasId: kelasId, tanggal: _tanggal);
    final matkulAsync = ref.watch(dosenMatkulProvider(matkulQuery));

    ref.listen(dosenMatkulProvider(matkulQuery), (previous, next) {
      final items = next.value;
      if (items == null || items.isEmpty || !mounted) return;
      if (!items.any((m) => m.nama == _mataKuliah)) {
        setState(() => _selectMatkul(items.first.nama, items));
      } else {
        _selectedMatkul = items.firstWhere((m) => m.nama == _mataKuliah);
      }
    });

    final apiOptions = matkulAsync.value ?? const <MatkulOption>[];
    final mataKuliahItems = _mataKuliahItems(
      dashboard: dashboard,
      apiOptions: apiOptions,
    );
    final tanggal = _formatTanggal(_tanggal);

    return Scaffold(
      appBar: SkyAppBar(
        leading: IconButton(
          tooltip: 'Kembali',
          onPressed: _back,
          icon: const Icon(PhosphorIconsRegular.arrowLeft),
        ),
        title: const WordmarkPill(),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            child: IconButton(
              tooltip: 'Buka profil dosen',
              onPressed: () => context.go(LecturerRoutePaths.profil),
              icon: Container(
                padding: const EdgeInsets.all(2.5),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: AppColors.shadowSoft,
                ),
                child: const CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.brand50,
                  foregroundColor: AppColors.brand700,
                  child: Icon(PhosphorIconsRegular.userCircle, size: 20),
                ),
              ),
            ),
          ),
        ],
      ),
      body: AuroraBackground(
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: LecturerStyle.pageInsets,
            child: ContentConstraint(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AppPageHeading(
                    title: 'Cek Daftar Presensi',
                    description: 'Pilih sesi untuk melihat kehadiran mahasiswa.',
                  ),
                  SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final classField = _Field(
                              label: 'Kelas',
                              child: _SelectBox(
                                value: _kelas,
                                items: _kelasOptions,
                                onChanged: (v) => setState(() {
                                  _kelas = v!;
                                  _selectedMatkul = null;
                                  _syncMataKuliah();
                                }),
                              ),
                            );
                            final dateField = _Field(
                              label: 'Tanggal',
                              child: _DateBox(text: tanggal, onTap: _pickDate),
                            );
                            if (constraints.maxWidth < 308 ||
                                MediaQuery.textScalerOf(context).scale(14) >
                                    18) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  classField,
                                  const SizedBox(height: AppSpacing.md),
                                  dateField,
                                ],
                              );
                            }
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 2, child: classField),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(flex: 3, child: dateField),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _Field(
                          label: 'Mata Kuliah',
                          child: _SelectBox(
                            value: _mataKuliah,
                            items: mataKuliahItems,
                            onChanged: (v) => setState(() {
                              _selectMatkul(v!, apiOptions);
                            }),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppGradientButton(
                          onPressed: _tampilkan,
                          label: 'Tampilkan Data',
                          icon: PhosphorIconsRegular.listMagnifyingGlass,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const AppSectionHeader(title: 'Ringkasan Pilihan'),
                  _SelectionCard(
                    kelas: _kelas,
                    tanggal: tanggal,
                    mataKuliah: _mataKuliah,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (ringkasan != null)
                    AttendanceCountsCard(summary: ringkasan)
                  else if (dashboardAsync.showsError)
                    AppErrorState(
                      title: 'Ringkasan kehadiran belum bisa dimuat',
                      message: lecturerErrorMessage(dashboardAsync.error!),
                      onRetry: () => ref.invalidate(dosenDashboardProvider),
                    )
                  else
                    const _CountsSkeleton(),
                  if (dashboard?.isDemo ?? false) ...[
                    const SizedBox(height: AppSpacing.md),
                    const AppBanner(
                      tone: StatusTone.neutral,
                      message:
                          'Belum ada data jadwal dari server. Menampilkan data '
                          'contoh.',
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  SectionCard(
                    child: SwitchListTile(
                      value: _bypassLocation,
                      onChanged: _savingBypass ? null : _onBypassChanged,
                      title: const Text('Lewati validasi lokasi (mode test)'),
                      subtitle: const Text(
                        'Berlaku untuk sesi kelas Anda. Mahasiswa tidak perlu '
                        'berada di area kampus.',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: LecturerStyle.fieldLabelGap),
        child,
      ],
    );
  }
}

/// Kotak bergaris setinggi kolom isian tema, untuk pilihan yang bukan
/// kolom teks.
class _FieldBox extends StatelessWidget {
  const _FieldBox({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.control,
        side: BorderSide(color: scheme.outline),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.control),
        child: child,
      ),
    );
  }
}

class _SelectBox extends StatelessWidget {
  const _SelectBox({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return _FieldBox(
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          // Tinggi mengikuti isi supaya nama panjang dan teks besar muat.
          itemHeight: null,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          icon: const Icon(
            PhosphorIconsRegular.caretDown,
            color: AppColors.inkFaint,
          ),
          iconSize: 20,
          borderRadius: AppRadius.control,
          style: Theme.of(context).textTheme.bodyLarge,
          selectedItemBuilder: (_) => [
            for (final item in items)
              Text(item, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
          items: [
            for (final item in items)
              DropdownMenuItem(value: item, child: Text(item)),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _DateBox extends StatelessWidget {
  const _DateBox({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _FieldBox(
      // Appium mencari kotak ini lewat teks tanggalnya, jadi isi InkWell
      // hanya teks tanggal dan ikon tanpa label semantik.
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.bodyMedium?.tabular,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(
                PhosphorIconsRegular.calendarBlank,
                size: 20,
                color: AppColors.inkFaint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  const _SelectionCard({
    required this.kelas,
    required this.tanggal,
    required this.mataKuliah,
  });

  final String kelas;
  final String tanggal;
  final String mataKuliah;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: LecturerStyle.detailCardInsets,
      child: Column(
        children: [
          AppKeyValueRow(label: 'Kelas', value: kelas),
          const Divider(),
          AppKeyValueRow(
            label: 'Tanggal',
            trailing: Text(
              tanggal,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.titleSmall?.tabular,
            ),
          ),
          const Divider(),
          AppKeyValueRow(label: 'Mata Kuliah', value: mataKuliah),
        ],
      ),
    );
  }
}

class _CountsSkeleton extends StatelessWidget {
  const _CountsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Memuat ringkasan kehadiran',
      child: const SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSkeleton(width: 160, height: 16),
            SizedBox(height: AppSpacing.lg),
            AppSkeleton(height: 10),
            SizedBox(height: AppSpacing.md),
            AppSkeleton(width: 220, height: 12),
          ],
        ),
      ),
    );
  }
}
