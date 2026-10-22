// lib/pages/admin/widgets/labeled_fields.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

InputDecoration _decoration(BuildContext context, {String? hint}) {
  final cs = Theme.of(context).colorScheme;

  OutlineInputBorder border(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c),
      );

  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.6),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: border(cs.outline),
    enabledBorder: border(cs.outline),
    focusedBorder: border(cs.primary),
    errorBorder: border(cs.error),
    focusedErrorBorder: border(cs.error),
    hintStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label, this.required);
  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text.rich(TextSpan(
        text: label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: cs.onSurface,
        ),
        children: [
          if (required)
            TextSpan(text: ' *', style: TextStyle(color: cs.error)),
        ],
      )),
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
  });

  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String> onChanged;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label, required),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: cs.onSurfaceVariant),
          borderRadius: BorderRadius.circular(12),
          style: TextStyle(fontSize: 13, color: cs.onSurface),
          decoration: _decoration(context),
          items: [
            for (final i in items) DropdownMenuItem(value: i, child: Text(i)),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
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
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label, required),
        TextFormField(
          controller: controller,
          style: TextStyle(fontSize: 13, color: cs.onSurface),
          keyboardType: numeric ? TextInputType.number : TextInputType.text,
          inputFormatters:
              numeric ? [FilteringTextInputFormatter.digitsOnly] : null,
          decoration: _decoration(context, hint: hint),
          validator: validator,
        ),
        if (helper != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(helper!,
                style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
          ),
      ],
    );
  }
}