// lib/pages/dosen/cek_presensi_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/dosen/presensi_options.dart';
import '../../routing/lecturer_route_paths.dart';

const _hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
const _bulan = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];


String _formatTanggal(DateTime d) =>
    '${_hari[d.weekday - 1]}, ${d.day} ${_bulan[d.month - 1]} ${d.year}';

class CekPresensiPage extends StatefulWidget {
  const CekPresensiPage({super.key});

  @override
  State<CekPresensiPage> createState() => _CekPresensiPageState();
}

class _CekPresensiPageState extends State<CekPresensiPage> {
  String _kelas = lecturerKelasOptions.first;
  String _mataKuliah = lecturerMataKuliahOptions.first;
  DateTime _tanggal = DateTime.now();

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(LecturerRoutePaths.beranda);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _tanggal = picked);
  }

  void _tampilkan() {
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
                    items: lecturerKelasOptions,
                    onChanged: (v) => setState(() => _kelas = v!),
                  ),
                  const SizedBox(height: 16),
                  const _Label('Tanggal'),
                  _DateBox(text: _formatTanggal(_tanggal), onTap: _pickDate),
                  const SizedBox(height: 16),
                  const _Label('Mata Kuliah'),
                  _SelectBox(
                    icon: Icons.calendar_today_outlined,
                    value: _mataKuliah,
                    items: lecturerMataKuliahOptions,
                    onChanged: (v) => setState(() => _mataKuliah = v!),
                  ),
                  const SizedBox(height: 20),
                  _SummaryCard(
                    kelas: _kelas,
                    tanggal: _formatTanggal(_tanggal),
                    mataKuliah: _mataKuliah,
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