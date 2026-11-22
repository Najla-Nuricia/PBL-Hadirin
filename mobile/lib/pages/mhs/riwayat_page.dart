import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/mhs/dummy_student_auth_repository.dart';
import '../../data/mhs/student_attendance.dart';
import '../../data/mhs/student_data_service.dart';

class RiwayatPage extends StatefulWidget {
  const RiwayatPage({super.key});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  String _selectedSemester = 'Ganjil 2026/2027';
  AttendanceStatus? _selectedStatus;
  List<StudentAttendanceRecord> _records = const [];
  StudentAttendanceSummary _summary = const StudentAttendanceSummary(
    hadir: 0,
    izin: 0,
    sakit: 0,
    alfa: 0,
  );
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!studentAuthRepository.hasRemoteSession) {
      setState(() {
        _records = dummyAttendanceRecords;
        _summary = dummyAttendanceSummary;
      });
      return;
    }

    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        studentDataService.loadAttendanceSummary(),
        studentDataService.loadAttendanceHistory(),
      ]);
      if (!mounted) return;
      setState(() {
        _summary = results[0] as StudentAttendanceSummary;
        _records = results[1] as List<StudentAttendanceRecord>;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final records = _records
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
              child: RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildFilter(
                        label: 'Semester',
                        value: _selectedSemester,
                        items: const [
                          'Ganjil 2026/2027',
                          'Genap 2025/2026',
                        ],
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
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (records.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Text(
                            'Belum ada riwayat untuk status ini.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: colorScheme.onSurfaceVariant),
                          ),
                        )
                      else
                        ...records.map(
                          (record) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _AttendanceTile(record: record),
                          ),
                        ),
                    ],
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
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Riwayat Absensi',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          IconButton(
            onPressed: _isLoading ? null : _loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang',
          ),
        ],
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
        _Counter(
          label: 'Hadir',
          value: _summary.hadir,
          color: colorScheme.secondary,
        ),
        const SizedBox(width: 8),
        _Counter(
          label: 'Izin',
          value: _summary.izin,
          color: colorScheme.primary,
        ),
        const SizedBox(width: 8),
        _Counter(
          label: 'Sakit',
          value: _summary.sakit,
          color: colorScheme.tertiary,
        ),
        const SizedBox(width: 8),
        _Counter(
          label: 'Alfa',
          value: _summary.alfa,
          color: colorScheme.error,
        ),
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
            Text(
              '$value',
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
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
    final showDocument =
        (record.status == AttendanceStatus.izin ||
            record.status == AttendanceStatus.alfa) &&
        record.hasDocument;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
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
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.courseName,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      record.time,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 9,
                      ),
                    ),
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
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (showDocument) ...[
            const SizedBox(height: 8),
            Divider(height: 1, color: colorScheme.outlineVariant),
            const SizedBox(height: 4),
            InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => _showDocument(context, record),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Surat: ${record.documentName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.open_in_new,
                      size: 13,
                      color: colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

void _showDocument(BuildContext context, StudentAttendanceRecord record) {
  final scheme = Theme.of(context).colorScheme;
  final url = record.dokumenUrl!;
  final name = record.documentName;
  final isImage = RegExp(
    r'\.(jpg|jpeg|png|webp)(\?|$)',
    caseSensitive: false,
  ).hasMatch(name) || RegExp(
    r'\.(jpg|jpeg|png|webp)(\?|$)',
    caseSensitive: false,
  ).hasMatch(url);

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: scheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.description_outlined, color: scheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    tooltip: 'Tutup',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (isImage)
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.55,
                  ),
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    },
                    errorBuilder: (_, _, _) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'Pratinjau surat gagal dimuat.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Pratinjau PDF belum tersedia. Salin tautan di bawah untuk membuka surat.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: url));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(content: Text('Tautan surat disalin.')),
                    );
                },
                child: const Text('Salin tautan surat'),
              ),
            ],
          ),
        ),
      );
    },
  );
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
