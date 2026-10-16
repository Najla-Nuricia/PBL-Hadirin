import 'package:flutter/material.dart';

import '../../data/mhs/student_attendance.dart';

class RiwayatPage extends StatefulWidget {
  const RiwayatPage({super.key});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  String _selectedSemester = 'Genap 2023/2024';
  AttendanceStatus? _selectedStatus;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final records = dummyAttendanceRecords
        .where(
          (record) =>
              _selectedStatus == null || record.status == _selectedStatus,
        )
        .toList();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildAppBar(colorScheme),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildFilter(
                      label: 'Semester',
                      value: _selectedSemester,
                      items: const ['Genap 2023/2024', 'Ganjil 2023/2024'],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedSemester = value);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    _buildFilter(
                      label: 'Status',
                      value: _selectedStatus == null
                          ? 'Semua Status'
                          : _statusLabel(_selectedStatus!),
                      items: const [
                        'Semua Status',
                        'Hadir',
                        'Izin',
                        'Sakit',
                        'Alfa',
                      ],
                      onChanged: (value) => setState(
                        () => _selectedStatus = value == 'Semua Status'
                            ? null
                            : _statusFromLabel(value!),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildCounters(colorScheme),
                    const SizedBox(height: 12),
                    if (records.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Text(
                          'Belum ada riwayat untuk status ini.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      )
                    else
                      ...records.map((record) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _AttendanceTile(record: record),
                          )),
                  ],
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        'Riwayat Absensi',
        style: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildFilter({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          initialValue: value,
          isDense: true,
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
          ),
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          items: items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildCounters(ColorScheme colorScheme) {
    return Row(
      children: [
        _Counter(label: 'Hadir', value: 12, color: colorScheme.secondary),
        const SizedBox(width: 8),
        _Counter(label: 'Izin', value: 2, color: colorScheme.primary),
        const SizedBox(width: 8),
        _Counter(label: 'Sakit', value: 1, color: colorScheme.tertiary),
        const SizedBox(width: 8),
        _Counter(label: 'Alfa', value: 1, color: colorScheme.error),
      ],
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text('$value',
                style: TextStyle(
                    color: color, fontSize: 16, fontWeight: FontWeight.w800)),
            Text(label, style: TextStyle(color: color, fontSize: 9)),
          ],
        ),
      ),
    );
  }
}

class _AttendanceTile extends StatelessWidget {
  const _AttendanceTile({required this.record});

  final StudentAttendanceRecord record;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = _statusColor(colorScheme, record.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              record.date,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.courseName,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(record.time,
                    style: TextStyle(
                        color: colorScheme.onSurfaceVariant, fontSize: 9)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _statusLabel(record.status),
              style: TextStyle(
                  color: color, fontSize: 9, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

String _statusLabel(AttendanceStatus status) => switch (status) {
      AttendanceStatus.hadir => 'Hadir',
      AttendanceStatus.izin => 'Izin',
      AttendanceStatus.sakit => 'Sakit',
      AttendanceStatus.alfa => 'Alfa',
    };

AttendanceStatus _statusFromLabel(String label) => switch (label) {
      'Hadir' => AttendanceStatus.hadir,
      'Izin' => AttendanceStatus.izin,
      'Sakit' => AttendanceStatus.sakit,
      _ => AttendanceStatus.alfa,
    };

Color _statusColor(ColorScheme colorScheme, AttendanceStatus status) =>
    switch (status) {
      AttendanceStatus.hadir => colorScheme.secondary,
      AttendanceStatus.izin => colorScheme.primary,
      AttendanceStatus.sakit => colorScheme.tertiary,
      AttendanceStatus.alfa => colorScheme.error,
    };
