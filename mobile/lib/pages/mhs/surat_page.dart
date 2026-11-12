import 'dart:math' as math;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/mhs/dummy_student_auth_repository.dart';
import '../../data/mhs/student_data_service.dart';

class SuratPage extends StatefulWidget {
  const SuratPage({super.key});

  @override
  State<SuratPage> createState() => _SuratPageState();
}

class _SuratPageState extends State<SuratPage> {
  static const _fallbackCourses = [
    'Pemrograman Web Lanjut',
    'Basis Data Lanjut',
    'Interaksi Manusia Komputer',
    'Kecerdasan Buatan',
    'Jaringan Komputer',
  ];
  static const int _maxFileBytes = 5 * 1024 * 1024;

  List<String> _courses = List<String>.from(_fallbackCourses);
  int _selectedType = 0;
  String _selectedAbsenceType = 'izin';
  String? _fileName;
  Uint8List? _fileBytes;
  String? _selectedCourse;
  DateTime? _selectedDate;
  bool _isSubmitting = false;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCourseOptions();
  }

  Future<void> _loadCourseOptions() async {
    if (!studentAuthRepository.hasRemoteSession) return;
    try {
      final schedules = await studentDataService.loadSchedules();
      final names = schedules
          .map((item) => item.courseName.trim())
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      if (!mounted || names.isEmpty) return;
      setState(() {
        _courses = names;
        if (_selectedCourse != null && !_courses.contains(_selectedCourse)) {
          _selectedCourse = null;
        }
      });
    } catch (_) {
      // Fallback course list remains available if schedules fail to load.
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitSurat() async {
    if (_selectedCourse == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih mata kuliah terlebih dahulu.')),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final jenis = _selectedType == 0 ? _selectedAbsenceType : 'kompensasi';
      final tanggal =
          (_selectedDate ?? DateTime.now()).toIso8601String().split('T').first;
      final alasan = _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : 'Pengajuan surat $jenis';

      await studentDataService.submitPengajuan(
        jenis: jenis,
        alasan: alasan,
        matakuliah: _selectedCourse!,
        tanggal: tanggal,
        dokumenPath: _fileName ?? '',
        fileBytes: _fileBytes,
        fileName: _fileName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengajuan surat berhasil dikirim!')),
        );
        setState(() {
          _fileName = null;
          _fileBytes = null;
          _selectedCourse = null;
          _selectedDate = null;
          _notesController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim surat: $msg')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _pickFile() async {
    try {
      final picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      if (bytes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File kosong atau gagal dibaca.')),
        );
        return;
      }
      if (bytes.length > _maxFileBytes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ukuran file maksimal 5 MB.')),
        );
        return;
      }
      setState(() {
        _fileName = picked.name;
        _fileBytes = bytes;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih file: $e')),
      );
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  String get _documentDescription => _selectedType == 0
      ? 'Unggah surat keterangan (Izin/Sakit)'
      : 'Unggah surat kompensasi';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(colorScheme),
            _buildTypeSelector(colorScheme),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
                child: _buildFormCard(colorScheme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Container(
      height: 52,
      color: colorScheme.surface,
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.go('/mhs/beranda'),
            icon: const Icon(Icons.chevron_left),
            color: colorScheme.onSurfaceVariant,
            tooltip: 'Kembali',
          ),
          Text(
            'Upload Surat',
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

  Widget _buildTypeSelector(ColorScheme colorScheme) {
    const labels = ['Izin/Sakit', 'Upload Surat Kompensasi'];

    return Container(
      height: 36,
      margin: const EdgeInsets.fromLTRB(12, 14, 12, 0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          for (var index = 0; index < labels.length; index++)
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _selectedType = index),
                child: Container(
                  alignment: Alignment.center,
                  color: _selectedType == index
                      ? colorScheme.primary
                      : colorScheme.surface,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      labels[index],
                      style: TextStyle(
                        color: _selectedType == index
                            ? colorScheme.onPrimary
                            : colorScheme.onSurfaceVariant,
                        fontSize: 12,
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

  Widget _buildAbsenceTypeSelector(ColorScheme colorScheme) {
    return RadioGroup<String>(
      groupValue: _selectedAbsenceType,
      onChanged: (selected) {
        if (selected != null) {
          setState(() => _selectedAbsenceType = selected);
        }
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildAbsenceRadio('sakit', 'Sakit', colorScheme),
          const SizedBox(width: 20),
          _buildAbsenceRadio('izin', 'Izin', colorScheme),
        ],
      ),
    );
  }

  Widget _buildAbsenceRadio(
    String value,
    String label,
    ColorScheme colorScheme,
  ) {
    return Semantics(
      label: label,
      selected: _selectedAbsenceType == value,
      child: InkWell(
        onTap: () => setState(() => _selectedAbsenceType = value),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Radio<String>(
              value: value,
              activeColor: colorScheme.primary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            Text(
              label,
              style: TextStyle(color: colorScheme.onSurface, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFilePicker(colorScheme),
          if (_selectedType == 0) ...[
            const SizedBox(height: 8),
            _buildAbsenceTypeSelector(colorScheme),
          ],
          const SizedBox(height: 14),
          _buildFieldLabel('Mata Kuliah', colorScheme),
          const SizedBox(height: 6),
          _buildCourseDropdown(colorScheme),
          const SizedBox(height: 14),
          _buildFieldLabel('Tanggal', colorScheme),
          const SizedBox(height: 6),
          _buildDateField(colorScheme),
          const SizedBox(height: 14),
          _buildFieldLabel('Catatan (Optional):', colorScheme),
          const SizedBox(height: 6),
          _buildNotesField(colorScheme),
          const SizedBox(height: 18),
          SizedBox(
            height: 42,
            child: FilledButton(
              onPressed: _isSubmitting ? null : _submitSurat,
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                disabledBackgroundColor: colorScheme.primary.withValues(
                  alpha: 0.38,
                ),
                foregroundColor: colorScheme.onPrimary,
                disabledForegroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Kirim Surat',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilePicker(ColorScheme colorScheme) {
    return CustomPaint(
      foregroundPainter: _DashedRoundedBorderPainter(
        color: colorScheme.outlineVariant,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 22),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                Icons.upload_file_outlined,
                color: colorScheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _fileName ?? _documentDescription,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Format: JPG, PNG, PDF (Maks. 5 MB)',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _pickFile,
              icon: Icon(
                Icons.attach_file,
                size: 16,
                color: colorScheme.primary,
              ),
              label: Text(
                _fileName == null ? 'Kirim File' : 'Ganti File',
                style: TextStyle(color: colorScheme.primary, fontSize: 11),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(98, 34),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                side: BorderSide(color: colorScheme.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, ColorScheme colorScheme) {
    return Text(
      label,
      style: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildCourseDropdown(ColorScheme colorScheme) {
    final safeValue =
        _courses.contains(_selectedCourse) ? _selectedCourse : null;
    return DropdownButtonFormField<String>(
      key: ValueKey(safeValue),
      initialValue: safeValue,
      isExpanded: true,
      hint: const Text('Pilih mata kuliah...'),
      icon: const Icon(Icons.keyboard_arrow_down),
      items: _courses
          .map((course) => DropdownMenuItem(value: course, child: Text(course)))
          .toList(),
      onChanged: (course) => setState(() => _selectedCourse = course),
      decoration: _fieldDecoration(colorScheme),
      style: TextStyle(color: colorScheme.onSurface, fontSize: 12),
    );
  }

  Widget _buildDateField(ColorScheme colorScheme) {
    final effectiveDate = _selectedDate ?? DateTime.now();
    final formatted = '${effectiveDate.day.toString().padLeft(2, '0')}/'
        '${effectiveDate.month.toString().padLeft(2, '0')}/'
        '${effectiveDate.year}';
    final displayText =
        _selectedDate == null ? '$formatted (Hari ini)' : formatted;
    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: _fieldDecoration(colorScheme),
        child: Row(
          children: [
            Expanded(
              child: Text(
                displayText,
                style: TextStyle(
                  color: _selectedDate == null
                      ? colorScheme.onSurfaceVariant
                      : colorScheme.onSurface,
                  fontSize: 12,
                ),
              ),
            ),
            Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesField(ColorScheme colorScheme) {
    return TextFormField(
      controller: _notesController,
      maxLines: 3,
      minLines: 3,
      decoration: _fieldDecoration(colorScheme)
          .copyWith(hintText: 'Tulis keterangan...'),
      style: TextStyle(color: colorScheme.onSurface, fontSize: 12),
    );
  }

  InputDecoration _fieldDecoration(ColorScheme colorScheme) {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colorScheme.primary),
      ),
      hintStyle: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
    );
  }
}

class _DashedRoundedBorderPainter extends CustomPainter {
  const _DashedRoundedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(14)),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + 5, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + 4;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoundedBorderPainter oldDelegate) {
    return color != oldDelegate.color;
  }
}
