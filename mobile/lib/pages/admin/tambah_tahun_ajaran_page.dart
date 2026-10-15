import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/admin/tahun_ajaran.dart';
import '../../routing/admin_route_paths.dart';

class TambahTahunAjaranPage extends StatefulWidget {
  const TambahTahunAjaranPage({super.key});

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

  @override
  void dispose() {
    _tahunController.dispose();
    super.dispose();
  }

  // ── Date picker ──────────────────────────────────────────
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
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme,
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _tanggalMulai = picked;
        // Reset end date if it's before start
        if (_tanggalSelesai != null &&
            _tanggalSelesai!.isBefore(picked)) {
          _tanggalSelesai = null;
        }
      } else {
        _tanggalSelesai = picked;
      }
    });
  }

  // ── Submit ────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_semesterGanjil && !_semesterGenap) {
      _showError('Pilih minimal satu semester.');
      return;
    }
    if (_tanggalMulai == null) {
      _showError('Tanggal mulai wajib diisi.');
      return;
    }
    if (_tanggalSelesai == null) {
      _showError('Tanggal selesai wajib diisi.');
      return;
    }
    if (_tanggalSelesai!.isBefore(_tanggalMulai!)) {
      _showError('Tanggal selesai harus setelah tanggal mulai.');
      return;
    }

    setState(() => _isSubmitting = true);

    // Simulate network latency
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    final newItem = TahunAjaran(
      id: tahunAjaranRepository.generateId(),
      tahun: _tahunController.text.trim(),
      status: _status,
      semesterGanjil: _semesterGanjil,
      semesterGenap: _semesterGenap,
      tanggalMulai: _tanggalMulai,
      tanggalSelesai: _tanggalSelesai,
    );

    tahunAjaranRepository.add(newItem);
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

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: _back,
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: colorScheme.primary,
          ),
          tooltip: 'Kembali',
        ),
        title: Text(
          'Tambah Tahun Ajaran',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: colorScheme.outlineVariant,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                      // ── Section 01 ──────────────────────────
                      _SectionHeader(
                        number: '01',
                        title: 'Informasi periode',
                        subtitle: 'Masukkan identitas dan semester yang tersedia.',
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: 20),
                      _FieldLabel(
                        label: 'Tahun ajaran',
                        required: true,
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _tahunController,
                        decoration: _fieldDecoration(
                          colorScheme,
                          hintText: '2026/2027',
                          helperText: 'Contoh: 2026/2027',
                        ),
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 14,
                        ),
                        validator: (v) {
                          final val = (v ?? '').trim();
                          if (val.isEmpty) return 'Tahun ajaran wajib diisi.';
                          final pattern = RegExp(r'^\d{4}/\d{4}$');
                          if (!pattern.hasMatch(val)) {
                            return 'Format: YYYY/YYYY, contoh 2026/2027';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _FieldLabel(
                        label: 'Status',
                        required: true,
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: 6),
                      _StatusDropdown(
                        value: _status,
                        colorScheme: colorScheme,
                        onChanged: (v) => setState(() => _status = v!),
                      ),
                      const SizedBox(height: 16),
                      _FieldLabel(
                        label: 'Semester',
                        required: true,
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: _SemesterToggleCard(
                              label: defaultSemesterInfo.namaGanjil,
                              period: defaultSemesterInfo.periodGanjil,
                              selected: _semesterGanjil,
                              colorScheme: colorScheme,
                              onTap: () => setState(
                                  () => _semesterGanjil = !_semesterGanjil),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _SemesterToggleCard(
                              label: defaultSemesterInfo.namaGenap,
                              period: defaultSemesterInfo.periodGenap,
                              selected: _semesterGenap,
                              colorScheme: colorScheme,
                              onTap: () => setState(
                                  () => _semesterGenap = !_semesterGenap),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // ── Section 02 ──────────────────────────
                      _SectionHeader(
                        number: '02',
                        title: 'Rentang tanggal',
                        subtitle:
                            'Tentukan waktu mulai dan berakhirnya periode.',
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: 20),
                      _FieldLabel(
                        label: 'Tanggal mulai',
                        required: true,
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: 6),
                      _DatePickerField(
                        date: _tanggalMulai,
                        colorScheme: colorScheme,
                        onTap: () => _pickDate(isStart: true),
                      ),
                      const SizedBox(height: 16),
                      _FieldLabel(
                        label: 'Tanggal selesai',
                        required: true,
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: 6),
                      _DatePickerField(
                        date: _tanggalSelesai,
                        colorScheme: colorScheme,
                        onTap: () => _pickDate(isStart: false),
                        firstSelectableDate: _tanggalMulai,
                      ),
                      const SizedBox(height: 32),

                      // ── Buttons ─────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isSubmitting ? null : _back,
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                side: BorderSide(
                                    color: colorScheme.outlineVariant),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                foregroundColor: colorScheme.onSurface,
                              ),
                              child: const Text(
                                'Batal',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: FilledButton(
                              onPressed: _isSubmitting ? null : _submit,
                              style: FilledButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                disabledBackgroundColor:
                                    colorScheme.primary.withValues(alpha: 0.38),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isSubmitting
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: colorScheme.onPrimary,
                                      ),
                                    )
                                  : const Text(
                                      'Simpan tahun ajaran',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
  }

  InputDecoration _fieldDecoration(
    ColorScheme colorScheme, {
    String? hintText,
    String? helperText,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle:
          TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
      helperText: helperText,
      helperStyle:
          TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 11),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
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
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colorScheme.error, width: 1.5),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Section header (numbered)
// ─────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.colorScheme,
  });

  final String number;
  final String title;
  final String subtitle;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: TextStyle(
              color: colorScheme.primary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// Field label with asterisk for required
// ─────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  const _FieldLabel({
    required this.label,
    this.required = false,
    required this.colorScheme,
  });

  final String label;
  final bool required;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: label,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (required)
            TextSpan(
              text: ' *',
              style: TextStyle(
                color: colorScheme.error,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Status dropdown
// ─────────────────────────────────────────────────────────
class _StatusDropdown extends StatelessWidget {
  const _StatusDropdown({
    required this.value,
    required this.colorScheme,
    required this.onChanged,
  });

  final TahunAjaranStatus value;
  final ColorScheme colorScheme;
  final ValueChanged<TahunAjaranStatus?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<TahunAjaranStatus>(
      initialValue: value,
      items: TahunAjaranStatus.values
          .map(
            (s) => DropdownMenuItem(
              value: s,
              child: Text(
                s.label,
                style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
      icon: Icon(Icons.keyboard_arrow_down, color: colorScheme.onSurfaceVariant),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
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
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Semester toggle card
// ─────────────────────────────────────────────────────────
class _SemesterToggleCard extends StatelessWidget {
  const _SemesterToggleCard({
    required this.label,
    required this.period,
    required this.selected,
    required this.colorScheme,
    required this.onTap,
  });

  final String label;
  final String period;
  final bool selected;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? colorScheme.primaryContainer : colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? colorScheme.primary : colorScheme.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: selected ? colorScheme.primary : colorScheme.surface,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.outlineVariant,
                ),
              ),
              child: selected
                  ? Icon(Icons.check, size: 12, color: colorScheme.onPrimary)
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: selected
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    period,
                    style: TextStyle(
                      color: selected
                          ? colorScheme.onPrimaryContainer.withValues(alpha: 0.7)
                          : colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Date picker field
// ─────────────────────────────────────────────────────────
class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.date,
    required this.colorScheme,
    required this.onTap,
    this.firstSelectableDate,
  });

  final DateTime? date;
  final ColorScheme colorScheme;
  final VoidCallback onTap;
  final DateTime? firstSelectableDate;

  String get _formattedDate {
    if (date == null) return '';
    return '${date!.day.toString().padLeft(2, '0')} / '
        '${date!.month.toString().padLeft(2, '0')} / '
        '${date!.year}';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: InputDecoration(
          suffixIcon: Icon(
            Icons.calendar_today_outlined,
            size: 18,
            color: colorScheme.onSurfaceVariant,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
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
            borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
          ),
        ),
        child: Text(
          _formattedDate,
          style: TextStyle(
            color: date != null
                ? colorScheme.onSurface
                : colorScheme.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
