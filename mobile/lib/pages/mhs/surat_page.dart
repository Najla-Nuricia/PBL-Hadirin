import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../data/mhs/student_data_service.dart';
import '../../widgets/widgets.dart';
import 'widgets/content_width.dart';
import 'widgets/friendly_error.dart';

class SuratPage extends StatelessWidget {
  const SuratPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Messenger sendiri supaya SnackBar muncul di atas tombol "Kirim Surat".
    // Lewat Scaffold navigasi di luar halaman ini, SnackBar menutupi tombol.
    return const ScaffoldMessenger(child: _SuratForm());
  }
}

class _SuratForm extends StatefulWidget {
  const _SuratForm();

  @override
  State<_SuratForm> createState() => _SuratPageState();
}

class _SuratPageState extends State<_SuratForm> {
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
    try {
      final schedules = await studentDataService.loadSchedules();
      final names =
          schedules
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Tab yang disembunyikan tidak menjalankan animasi, jadi SnackBar yang
    // masih tampil akan tertinggal sampai tab ini dibuka lagi.
    if (!TickerMode.valuesOf(context).enabled) {
      final messenger = ScaffoldMessenger.of(context);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        messenger
          ..clearSnackBars()
          ..removeCurrentSnackBar();
      });
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
      final tanggal = (_selectedDate ?? DateTime.now())
          .toIso8601String()
          .split('T')
          .first;
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
        final msg = friendlyError(
          e,
          fallback: 'Periksa koneksi internet, lalu coba lagi.',
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mengirim surat: $msg')));
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
        SnackBar(
          content: Text(
            'Gagal memilih file: ${friendlyError(e, fallback: 'Coba pilih ulang filenya.')}',
          ),
        ),
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

  void _removeFile() {
    setState(() {
      _fileName = null;
      _fileBytes = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: SkyAppBar(
        leading: IconButton(
          onPressed: () => context.go('/mhs/beranda'),
          icon: const Icon(PhosphorIconsRegular.arrowLeft),
          tooltip: 'Kembali',
        ),
        title: const Text('Upload Surat'),
      ),
      body: AuroraBackground(
        child: SafeArea(
          top: false,
          bottom: false,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.md,
              AppSpacing.page,
              AppSpacing.xxl,
            ),
            child: ContentWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildIntroCard(text),
                  const SizedBox(height: AppSpacing.lg),
                  _buildTypeSelector(),
                  AnimatedSize(
                    duration: AppMotion.fast,
                    curve: AppMotion.curve,
                    alignment: Alignment.topCenter,
                    child: _selectedType == 0
                        ? Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.lg),
                            child: _buildField(
                              text,
                              'Jenis ketidakhadiran',
                              _buildAbsenceTypeSelector(),
                            ),
                          )
                        : const SizedBox(width: double.infinity),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildField(text, 'Mata Kuliah', _buildCourseDropdown(text)),
                  const SizedBox(height: AppSpacing.lg),
                  _buildField(text, 'Tanggal', _buildDateField(text)),
                  const SizedBox(height: AppSpacing.lg),
                  _buildField(text, 'Catatan (opsional)', _buildNotesField()),
                  const SizedBox(height: AppSpacing.lg),
                  _buildField(text, 'Lampiran', _buildAttachment(text)),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(color: AppColors.canvas),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.md,
              AppSpacing.page,
              AppSpacing.lg,
            ),
            child: ContentWidth(
              child: AppGradientButton(
                onPressed: _isSubmitting ? null : _submitSurat,
                label: 'Kirim Surat',
                icon: PhosphorIconsRegular.paperPlaneTilt,
                isBusy: _isSubmitting,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIntroCard(TextTheme text) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: AppRadius.hero,
        boxShadow: AppColors.shadowLifted,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: const Icon(
              PhosphorIconsRegular.envelopeSimple,
              size: 22,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ajukan surat dalam satu menit',
                  style: text.titleSmall?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  'Lampirkan bukti agar dosen bisa langsung meninjau.',
                  style: text.bodySmall?.copyWith(
                    color: AppColors.onBrandMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(TextTheme text, String label, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: text.titleSmall),
        const SizedBox(height: 6),
        field,
      ],
    );
  }

  Widget _buildTypeSelector() {
    return SegmentedButton<int>(
      segments: const [
        ButtonSegment(
          value: 0,
          label: Text('Izin/Sakit', textAlign: TextAlign.center),
        ),
        ButtonSegment(
          value: 1,
          label: Text('Upload Surat Kompensasi', textAlign: TextAlign.center),
        ),
      ],
      selected: {_selectedType},
      showSelectedIcon: false,
      onSelectionChanged: (selection) =>
          setState(() => _selectedType = selection.first),
    );
  }

  Widget _buildAbsenceTypeSelector() {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'sakit', label: Text('Sakit')),
        ButtonSegment(value: 'izin', label: Text('Izin')),
      ],
      selected: {_selectedAbsenceType},
      showSelectedIcon: false,
      onSelectionChanged: (selection) =>
          setState(() => _selectedAbsenceType = selection.first),
    );
  }

  Widget _buildCourseDropdown(TextTheme text) {
    final safeValue = _courses.contains(_selectedCourse)
        ? _selectedCourse
        : null;
    // Menu dibuat selebar kolom isian; bawaannya melebar sampai tepi layar.
    return ButtonTheme(
      alignedDropdown: true,
      child: DropdownButtonFormField<String>(
        key: ValueKey(safeValue),
        initialValue: safeValue,
        isExpanded: true,
        hint: Text(
          'Pilih mata kuliah...',
          style: text.bodyLarge?.copyWith(color: AppColors.inkFaint),
        ),
        icon: const Icon(PhosphorIconsRegular.caretDown),
        iconEnabledColor: AppColors.inkFaint,
        style: text.bodyLarge,
        borderRadius: AppRadius.control,
        items: _courses
            .map(
              (course) => DropdownMenuItem(
                value: course,
                child: Text(course, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: (course) => setState(() => _selectedCourse = course),
      ),
    );
  }

  Widget _buildDateField(TextTheme text) {
    final scheme = Theme.of(context).colorScheme;
    final effectiveDate = _selectedDate ?? DateTime.now();
    final formatted =
        '${effectiveDate.day.toString().padLeft(2, '0')}/'
        '${effectiveDate.month.toString().padLeft(2, '0')}/'
        '${effectiveDate.year}';
    final displayText = _selectedDate == null
        ? '$formatted (Hari ini)'
        : formatted;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: _pickDate,
        borderRadius: AppRadius.control,
        child: InputDecorator(
          decoration: const InputDecoration(
            suffixIcon: Icon(PhosphorIconsRegular.calendarBlank, size: 20),
          ),
          child: Text(
            displayText,
            style: text.bodyLarge?.tabular.copyWith(
              color: _selectedDate == null
                  ? scheme.onSurfaceVariant
                  : scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      maxLines: 3,
      minLines: 3,
      textCapitalization: TextCapitalization.sentences,
      decoration: const InputDecoration(hintText: 'Tulis keterangan...'),
    );
  }

  Widget _buildAttachment(TextTheme text) {
    final fileName = _fileName;
    final faint = text.bodySmall?.copyWith(color: AppColors.inkFaint);

    return Material(
      color: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.control,
        side: BorderSide(color: AppColors.fieldLine),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _isSubmitting ? null : _pickFile,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              fileName == null ? AppSpacing.lg : AppSpacing.xs,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(
                  fileName == null
                      ? PhosphorIconsRegular.fileArrowUp
                      : PhosphorIconsRegular.fileText,
                  color: AppColors.brand600,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        fileName ?? _documentDescription,
                        maxLines: fileName == null ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleSmall,
                      ),
                      Text(
                        fileName == null
                            ? 'JPG, PNG, atau PDF. Maksimal 5 MB.'
                            : 'Ketuk untuk mengganti file.',
                        style: faint,
                      ),
                    ],
                  ),
                ),
                if (fileName != null)
                  IconButton(
                    onPressed: _isSubmitting ? null : _removeFile,
                    tooltip: 'Hapus lampiran',
                    icon: const Icon(PhosphorIconsRegular.x),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
