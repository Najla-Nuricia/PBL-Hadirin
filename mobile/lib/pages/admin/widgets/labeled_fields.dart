import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:flutter/services.dart';

import '../../../widgets/widgets.dart';

/// Label di atas kolom isian; tanda bintang menandai isian wajib.
class AdminFieldLabel extends StatelessWidget {
  const AdminFieldLabel({
    required this.label,
    this.required = false,
    super.key,
  });

  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(
          text: label,
          children: [
            if (required)
              TextSpan(
                text: ' *',
                style: TextStyle(color: theme.colorScheme.error),
              ),
          ],
        ),
        semanticsLabel: required ? '$label, wajib diisi' : null,
        style: theme.textTheme.titleSmall,
      ),
    );
  }
}

/// Label di atas satu kolom isian.
class AdminLabeledField extends StatelessWidget {
  const AdminLabeledField({
    required this.label,
    required this.child,
    this.required = false,
    super.key,
  });

  final String label;
  final bool required;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminFieldLabel(label: label, required: required),
        child,
      ],
    );
  }
}

/// Dua kolom isian berdampingan. Keduanya ditumpuk bila layar sempit atau
/// teks sistem diperbesar, supaya isinya tidak terpotong.
class AdminFieldPair extends StatelessWidget {
  const AdminFieldPair({
    required this.first,
    required this.second,
    this.minColumnWidth = 132,
    super.key,
  });

  final Widget first;
  final Widget second;

  /// Lebar terkecil satu kolom pada ukuran teks normal.
  final double minColumnWidth;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    return LayoutBuilder(
      builder: (context, constraints) {
        final columnWidth = (constraints.maxWidth - AppSpacing.md) / 2;
        final stacked = columnWidth < minColumnWidth * textScale;

        // Jenis anak tetap sama di kedua susunan agar isian yang sudah
        // dipilih tidak hilang saat layar diputar.
        return Flex(
          direction: stacked ? Axis.vertical : Axis.horizontal,
          crossAxisAlignment: stacked
              ? CrossAxisAlignment.stretch
              : CrossAxisAlignment.start,
          spacing: stacked ? AppSpacing.lg : AppSpacing.md,
          children: [
            Flexible(flex: stacked ? 0 : 1, fit: FlexFit.tight, child: first),
            Flexible(flex: stacked ? 0 : 1, fit: FlexFit.tight, child: second),
          ],
        );
      },
    );
  }
}

class LabeledDropdown extends StatelessWidget {
  const LabeledDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.required = false,
    this.itemLabels,
  });

  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String> onChanged;
  final bool required;
  final Map<String, String>? itemLabels;

  @override
  Widget build(BuildContext context) {
    return AdminLabeledField(
      label: label,
      required: required,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        icon: const Icon(PhosphorIconsRegular.caretDown, color: AppColors.inkFaint),
        borderRadius: AppRadius.control,
        style: Theme.of(context).textTheme.bodyLarge,
        items: [
          for (final item in items)
            DropdownMenuItem(
              value: item,
              child: Text(
                itemLabels?[item] ?? item,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
      ),
    );
  }
}

class LabeledTextField extends StatelessWidget {
  const LabeledTextField({
    super.key,
    required this.label,
    required this.controller,
    this.required = false,
    this.helper,
    this.hint,
    this.numeric = false,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final bool required, numeric;
  final String? helper, hint;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return AdminLabeledField(
      label: label,
      required: required,
      child: TextFormField(
        controller: controller,
        style: numeric ? Theme.of(context).textTheme.bodyLarge?.tabular : null,
        keyboardType: numeric ? TextInputType.number : TextInputType.text,
        inputFormatters: numeric
            ? [FilteringTextInputFormatter.digitsOnly]
            : null,
        decoration: InputDecoration(hintText: hint, helperText: helper),
        validator: validator,
      ),
    );
  }
}
