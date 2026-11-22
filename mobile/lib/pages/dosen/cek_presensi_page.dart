// lib/pages/dosen/cek_presensi_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/dosen/lecturer_providers.dart';
import '../../data/dosen/presensi_options.dart';
import '../../models/dosen/dosen_dashboard.dart';
import '../../models/dosen/matkul_option.dart';
import '../../routing/lecturer_route_paths.dart';
import 'widgets/attendance_counts_card.dart';

const _hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
const _bulan = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
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

  bool _isDemo(DosenDashboard? dashboard) =>
      dashboard == null || dashboard.isDemo || dashboard.jadwal.isEmpty;

  String _kelasId(DosenDashboard? dashboard) =>
      _isDemo(dashboard) ? '' : (dashboard!.kelasIdFor(_kelas) ?? '');

  List<MatkulOption> _apiOptions(DosenDashboard? dashboard) {
    if (_isDemo(dashboard)) return const <MatkulOption>[];
    return ref
            .read(dosenMatkulProvider((
              kelasId: _kelasId(dashboard),
              tanggal: _tanggal,
            )))
            .value ??
        const <MatkulOption>[];
  }

  /// Opsi backend dipakai bila tersedia, opsi demo tetap menjadi fallback.
  List<String> get _kelasOptions {
    final backend = ref.watch(dosenDashboardProvider).value?.kelasOptions ?? const <String>[];
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

    ref.read(attendanceQueryProvider.notifier).select(
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
    final cs = Theme.of(context).colorScheme;
    final dashboard = ref.watch(dosenDashboardProvider).value;
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

    return Scaffold(
      backgroundColor: cs.surfaceContainerHighest,
      appBar: AppBar(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16, top: 10, bottom: 10),
          child: Material(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: _back,
              child: Icon(Icons.chevron_left_rounded,
                  size: 24, color: cs.onSurface),
            ),
          ),
        ),
        title: Text(
          'Cek Daftar Presensi',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: cs.outlineVariant),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Label('Kelas'),
                  _SelectBox(
                    icon: Icons.school_outlined,
                    value: _kelas,
                    items: _kelasOptions,
                    onChanged: (v) => setState(() {
                      _kelas = v!;
                      _selectedMatkul = null;
                      _syncMataKuliah();
                    }),
                  ),
                  const SizedBox(height: 16),
                  const _Label('Tanggal'),
                  _DateBox(text: _formatTanggal(_tanggal), onTap: _pickDate),
                  const SizedBox(height: 16),
                  const _Label('Mata Kuliah'),
                  _SelectBox(
                    icon: Icons.calendar_today_outlined,
                    value: _mataKuliah,
                    items: mataKuliahItems,
                    onChanged: (v) => setState(() {
                      _selectMatkul(v!, apiOptions);
                    }),
                  ),
                  const SizedBox(height: 20),
                  _SummaryCard(
                    kelas: _kelas,
                    tanggal: _formatTanggal(_tanggal),
                    mataKuliah: _mataKuliah,
                  ),
                  const SizedBox(height: 12),
                  if (ringkasan != null)
                    AttendanceCountsCard(summary: ringkasan),
                  if (dashboard?.isDemo ?? false)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Belum ada data jadwal dari server. Menampilkan data contoh.',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _tampilkan,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
                child: const Text('Tampilkan Data'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: cs.onSurface.withValues(alpha: 0.75))),
    );
  }
}

BoxDecoration _boxDecoration(ColorScheme cs) => BoxDecoration(
      color: cs.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: cs.outlineVariant),
      boxShadow: const [
        BoxShadow(
            color: Color(0x0D000000), blurRadius: 6, offset: Offset(0, 2)),
      ],
    );

class _SelectBox extends StatelessWidget {
  const _SelectBox({
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final IconData icon;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: _boxDecoration(cs),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: cs.onSurfaceVariant),
          borderRadius: BorderRadius.circular(12),
          dropdownColor: cs.surface,
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w500, color: cs.onSurface),
          selectedItemBuilder: (_) => [
            for (final i in items)
              Row(children: [
                Icon(icon, size: 18, color: cs.primary),
                const SizedBox(width: 12),
                Text(i),
              ]),
          ],
          items: [
            for (final i in items) DropdownMenuItem(value: i, child: Text(i)),
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
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: _boxDecoration(cs),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined, size: 18, color: cs.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface)),
            ),
            Icon(Icons.keyboard_arrow_down_rounded,
                color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.kelas,
    required this.tanggal,
    required this.mataKuliah,
  });
  final String kelas, tanggal, mataKuliah;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget row(String k, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Text(k,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(v,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface)),
              ),
            ],
          ),
        );

    final divider = Divider(height: 1, thickness: 1, color: cs.outlineVariant);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      decoration: _boxDecoration(cs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ringkasan Pilihan',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface)),
          const SizedBox(height: 6),
          row('Kelas', kelas),
          divider,
          row('Tanggal', tanggal),
          divider,
          row('Mata Kuliah', mataKuliah),
        ],
      ),
    );
  }
}