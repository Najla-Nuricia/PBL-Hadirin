import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SuratPage extends StatefulWidget {
  const SuratPage({super.key});

  @override
  State<SuratPage> createState() => _SuratPageState();
}

class _SuratPageState extends State<SuratPage> {
  static const _courses = [
    'Matakuliah 1',
    'Matakuliah 2',
    'Matakuliah 3',
    'Matakuliah 4',
    'Matakuliah 5',
  ];

  int _selectedType = 0;
  String? _fileName;
  String? _selectedCourse;
  DateTime? _selectedDate;

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );
    if (!mounted || result.isEmpty) return;
    setState(() => _fileName = result.single.name);
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
              onPressed: null,
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
              child: const Text(
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
    return DropdownButtonFormField<String>(
      initialValue: _selectedCourse,
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
    final dateText = _selectedDate == null
        ? ''
        : '${_selectedDate!.day.toString().padLeft(2, '0')}/'
              '${_selectedDate!.month.toString().padLeft(2, '0')}/'
              '${_selectedDate!.year}';
    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: _fieldDecoration(colorScheme),
        child: Text(
          dateText,
          style: TextStyle(color: colorScheme.onSurface, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildNotesField(ColorScheme colorScheme) {
    return TextFormField(
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
