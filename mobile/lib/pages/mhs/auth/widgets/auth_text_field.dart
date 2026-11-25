import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:flutter/services.dart';

import '../../../../theme/style/auth_style.dart';
import '../../../../widgets/widgets.dart';

/// Kolom isian berlabel: label di atas, lalu kolomnya. Galat dan teks bantuan
/// tampil di bawah kolom.
class AuthTextField extends StatefulWidget {
  const AuthTextField({
    required this.label,
    required this.hintText,
    required this.controller,
    this.validator,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.autofillHints,
    this.onFieldSubmitted,
    this.isPassword = false,
    this.showVisibilityToggle = false,
    this.enabled = true,
    this.helperText,
    this.autovalidateMode,
    this.fieldKey,
    super.key,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onFieldSubmitted;
  final bool isPassword;
  final bool showVisibilityToggle;
  final bool enabled;

  /// Syarat atau petunjuk singkat di bawah kolom.
  final String? helperText;
  final AutovalidateMode? autovalidateMode;

  /// Key untuk [TextFormField] di dalamnya.
  final Key? fieldKey;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  // Tombol mata dilewati saat pindah fokus dengan tombol "next" di keyboard.
  final _visibilityToggleFocusNode = FocusNode(skipTraversal: true);
  bool _isObscured = true;

  @override
  void dispose() {
    _visibilityToggleFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final isNumeric = widget.keyboardType == TextInputType.number;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.label, style: text.titleSmall),
        const SizedBox(height: AuthStyle.labelGap),
        TextFormField(
          key: widget.fieldKey,
          controller: widget.controller,
          validator: widget.validator,
          autovalidateMode: widget.autovalidateMode,
          enabled: widget.enabled,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          textCapitalization: widget.textCapitalization,
          inputFormatters: widget.inputFormatters,
          autofillHints: widget.autofillHints,
          onFieldSubmitted: widget.onFieldSubmitted,
          obscureText: widget.isPassword && _isObscured,
          enableSuggestions: !widget.isPassword,
          autocorrect: !widget.isPassword,
          style: isNumeric ? text.bodyLarge?.tabular : text.bodyLarge,
          decoration: InputDecoration(
            hintText: widget.hintText,
            helperText: widget.helperText,
            helperStyle: text.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            helperMaxLines: 3,
            errorMaxLines: 3,
            suffixIcon: widget.isPassword && widget.showVisibilityToggle
                ? IconButton(
                    focusNode: _visibilityToggleFocusNode,
                    onPressed: widget.enabled
                        ? () => setState(() => _isObscured = !_isObscured)
                        : null,
                    tooltip: _isObscured
                        ? 'Tampilkan kata sandi'
                        : 'Sembunyikan kata sandi',
                    icon: Icon(
                      _isObscured
                          ? PhosphorIconsRegular.eye
                          : PhosphorIconsRegular.eyeSlash,
                      size: 20,
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
