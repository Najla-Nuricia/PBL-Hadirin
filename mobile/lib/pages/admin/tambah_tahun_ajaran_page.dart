import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:go_router/go_router.dart';

import '../../data/admin/tahun_ajaran.dart';
import '../../routing/admin_route_paths.dart';
import '../../widgets/widgets.dart';
import 'widgets/admin_scaffold.dart';
import 'widgets/jadwal_form_widgets.dart';
import 'widgets/labeled_fields.dart';

class TambahTahunAjaranPage extends StatefulWidget {
  const TambahTahunAjaranPage({this.initialItem, super.key});

  final TahunAjaran? initialItem;

  @override
  State<TambahTahunAjaranPage> createState() => _TambahTahunAjaranPageState();
}

class _TambahTahunAjaranPageState extends State<TambahTahunAjaranPage> {
  final _formKey = GlobalKey<FormState>();
  final _tahunController = TextEditingController();

  TahunAjaranStatus _status = TahunAjaranStatus.aktif;
  bool _semesterGanjil = true;
  bool _semesterGenap = true;
  DateTime? _tanggalMulai;
  DateTime? _tanggalSelesai;
  bool _isSubmitting = false;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  /// Alasan data ditolak saat disimpan; tampil di atas tombol simpan.
  String? _error;

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;
    if (item != null) {
      _tahunController.text = item.tahun;
      _status = item.status;
      _semesterGanjil = item.semesterGanjil;
      _semesterGenap = item.semesterGenap;
      _tanggalMulai = item.tanggalMulai;
      _tanggalSelesai = item.tanggalSelesai;
    }
  }

  @override
  void dispose() {
    _tahunController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart
        ? (_tanggalMulai ?? now)
        : (_tanggalSelesai ?? (_tanggalMulai ?? now));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: isStart ? 'Pilih tanggal mulai' : 'Pilih tanggal selesai',
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isStart) {
        _tanggalMulai = picked;
        // Reset end date if it's before start
        if (_tanggalSelesai != null && _tanggalSelesai!.isBefore(picked)) {
          _tanggalSelesai = null;
        }
      } else {
        _tanggalSelesai = picked;
      }
    });
  }

  String? _validateTahun(String? value) {
    final tahun = (value ?? '').trim();
    if (tahun.isEmpty) return 'Tahun ajaran wajib diisi.';
    final pattern = RegExp(r'^\d{4}/\d{4}$');
    if (!pattern.hasMatch(tahun)) {
      return 'Format: YYYY/YYYY, contoh 2026/2027';
    }
    return null;
  }

  String? _validateSemester() {
    return !_semesterGanjil && !_semesterGenap
        ? 'Pilih minimal satu semester.'
        : null;
  }

  String? _validateTanggalSelesai() {
    final selesai = _tanggalSelesai;
    if (selesai == null) return 'Tanggal selesai wajib diisi.';
    final mulai = _tanggalMulai;
    if (mulai != null && selesai.isBefore(mulai)) {
      return 'Tanggal selesai harus setelah tanggal mulai.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() {
      _error = null;
      _autovalidateMode = AutovalidateMode.onUserInteraction;
    });
    if (!_formKey.currentState!.validate()) return;

    if (tahunAjaranRepository.exists(
      _tahunController.text,
      excludingId: widget.initialItem?.id,
    )) {
      setState(() => _error = 'Tahun ajaran tersebut sudah terdaftar.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    // Simulate network latency
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    final item = TahunAjaran(
      id: widget.initialItem?.id ?? tahunAjaranRepository.generateId(),
      tahun: _tahunController.text.trim(),
      status: _status,
      semesterGanjil: _semesterGanjil,
      semesterGenap: _semesterGenap,
      tanggalMulai: _tanggalMulai,
      tanggalSelesai: _tanggalSelesai,
    );

    if (widget.initialItem == null) {
      tahunAjaranRepository.add(item);
    } else {
      tahunAjaranRepository.update(item);
    }
    setState(() => _isSubmitting = false);

    if (!mounted) return;
    if (context.canPop()) {
      context.pop(true);
    } else {
      context.go(AdminRoutePaths.tahunAjaran);
    }
  }

  void _back() {
    if (context.canPop()) {
      context.pop(false);
    } else {
      context.go(AdminRoutePaths.tahunAjaran);
    }
  }

  void _clearError() {
    if (_error != null) setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.initialItem == null;

    return AdminFormScaffold(
      title: isNew ? 'Tambah Tahun Ajaran' : 'Edit Tahun Ajaran',
      onBack: _back,
      onSave: _submit,
      saveLabel: isNew ? 'Simpan tahun ajaran' : 'Simpan perubahan',
      isSaving: _isSubmitting,
      notice: _error == null
          ? null
          : AppBanner(tone: StatusTone.danger, message: _error!),
      form: Form(
        key: _formKey,
        autovalidateMode: _autovalidateMode,
        onChanged: _clearError,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppSectionHeader(title: 'Informasi periode'),
            const _SectionHint(
              'Masukkan identitas dan semester yang tersedia.',
            ),
            const SizedBox(height: AppSpacing.lg),
            LabeledTextField(
              label: 'Tahun ajaran',
              required: true,
              controller: _tahunController,
              hint: '2026/2027',
              helper: 'Contoh: 2026/2027',
              validator: _validateTahun,
            ),
            const SizedBox(height: AppSpacing.lg),
            const AdminFieldLabel(label: 'Status', required: true),
            JadwalDropdownField<TahunAjaranStatus>(
              value: _status,
              items: TahunAjaranStatus.values,
              itemLabel: (status) => status.label,
              onChanged: (status) {
                if (status != null) setState(() => _status = status);
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            const AdminFieldLabel(label: 'Semester', required: true),
            FormField<bool>(
              validator: (_) => _validateSemester(),
              builder: (field) => _SemesterChoices(
                ganjil: _semesterGanjil,
                genap: _semesterGenap,
                errorText: field.errorText,
                onGanjilChanged: (selected) {
                  setState(() => _semesterGanjil = selected);
                  field.didChange(_semesterGanjil || _semesterGenap);
                },
                onGenapChanged: (selected) {
                  setState(() => _semesterGenap = selected);
                  field.didChange(_semesterGanjil || _semesterGenap);
                },
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const AppSectionHeader(title: 'Rentang tanggal'),
            const _SectionHint('Tentukan waktu mulai dan berakhirnya periode.'),
            const SizedBox(height: AppSpacing.lg),
            const AdminFieldLabel(label: 'Tanggal mulai', required: true),
            FormField<DateTime>(
              validator: (_) =>
                  _tanggalMulai == null ? 'Tanggal mulai wajib diisi.' : null,
              builder: (field) => _DatePickerField(
                date: _tanggalMulai,
                errorText: field.errorText,
                semanticLabel: 'Pilih tanggal mulai',
                onTap: () async {
                  await _pickDate(isStart: true);
                  if (field.mounted) field.didChange(_tanggalMulai);
                },
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const AdminFieldLabel(label: 'Tanggal selesai', required: true),
            FormField<DateTime>(
              validator: (_) => _validateTanggalSelesai(),
              builder: (field) => _DatePickerField(
                date: _tanggalSelesai,
                errorText: field.errorText,
                semanticLabel: 'Pilih tanggal selesai',
                onTap: () async {
                  await _pickDate(isStart: false);
                  if (field.mounted) field.didChange(_tanggalSelesai);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHint extends StatelessWidget {
  const _SectionHint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall
          ?.copyWith(color: AppColors.inkMuted),
    );
  }
}

/// Pilihan semester ganjil dan genap; keduanya boleh dicentang.
class _SemesterChoices extends StatelessWidget {
  const _SemesterChoices({
    required this.ganjil,
    required this.genap,
    required this.onGanjilChanged,
    required this.onGenapChanged,
    this.errorText,
  });

  final bool ganjil;
  final bool genap;
  final ValueChanged<bool> onGanjilChanged;
  final ValueChanged<bool> onGenapChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget choice({
      required String label,
      required String period,
      required bool selected,
      required ValueChanged<bool> onChanged,
    }) {
      return CheckboxListTile(
        value: selected,
        onChanged: (value) => onChanged(value ?? false),
        title: Text(label, style: theme.textTheme.titleSmall),
        subtitle: Text(
          period,
          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.inkFaint),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Column(
            children: [
              choice(
                label: defaultSemesterInfo.namaGanjil,
                period: defaultSemesterInfo.periodGanjil,
                selected: ganjil,
                onChanged: onGanjilChanged,
              ),
              const Divider(),
              choice(
                label: defaultSemesterInfo.namaGenap,
                period: defaultSemesterInfo.periodGenap,
                selected: genap,
                onChanged: onGenapChanged,
              ),
            ],
          ),
        ),
        if (errorText != null)
          Padding(
            // Sejajar dengan pesan galat di bawah kolom isian tema.
            padding: const EdgeInsets.only(top: 6, left: 18),
            child: Text(
              errorText!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }
}

/// Kolom tanggal yang membuka pemilih tanggal saat diketuk.
class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.date,
    required this.onTap,
    required this.semanticLabel,
    this.errorText,
  });

  final DateTime? date;
  final VoidCallback onTap;
  final String semanticLabel;
  final String? errorText;

  String get _formattedDate {
    if (date == null) return '';
    return '${date!.day.toString().padLeft(2, '0')} / '
        '${date!.month.toString().padLeft(2, '0')} / '
        '${date!.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.control,
        child: InputDecorator(
          isEmpty: date == null,
          decoration: InputDecoration(
            hintText: 'Pilih tanggal',
            errorText: errorText,
            suffixIcon: const Icon(PhosphorIconsRegular.calendarBlank, size: 20),
          ),
          child: date == null
              ? null
              : Text(
                  _formattedDate,
                  style: Theme.of(context).textTheme.bodyLarge?.tabular,
                ),
        ),
      ),
    );
  }
}
