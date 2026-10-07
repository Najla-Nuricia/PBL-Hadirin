import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../theme/style/auth_style.dart';

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

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  final _visibilityToggleFocusNode = FocusNode(skipTraversal: true);
  bool _isObscured = true;

  @override
  void dispose() {
    _visibilityToggleFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: AuthStyle.bodySize,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: widget.controller,
          validator: widget.validator,
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
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: AuthStyle.bodySize,
          ),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: AuthStyle.bodySize,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            suffixIcon: widget.isPassword && widget.showVisibilityToggle
                ? IconButton(
                    focusNode: _visibilityToggleFocusNode,
                    onPressed: () => setState(() => _isObscured = !_isObscured),
                    icon: Icon(
                      _isObscured
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 18,
                    ),
                    color: colorScheme.onSurfaceVariant,
                    tooltip: _isObscured
                        ? 'Tampilkan kata sandi'
                        : 'Sembunyikan kata sandi',
                  )
                : null,
            border: _border(colorScheme.outline),
            enabledBorder: _border(colorScheme.outline),
            disabledBorder: _border(colorScheme.outlineVariant),
            focusedBorder: _border(colorScheme.primary),
            errorBorder: _border(colorScheme.error),
            focusedErrorBorder: _border(colorScheme.error),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _border(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AuthStyle.fieldRadius),
      borderSide: BorderSide(color: color),
    );
  }
}
