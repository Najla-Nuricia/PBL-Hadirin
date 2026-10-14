import 'package:flutter/material.dart';

InputDecoration jadwalInputDecoration(
  ColorScheme colorScheme, {
  String? hintText,
  IconData? prefixIcon,
  bool filled = false,
  String? errorText,
}) {
  OutlineInputBorder border(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  return InputDecoration(
    hintText: hintText,
    hintMaxLines: 1,
    hintStyle: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
    errorText: errorText,
    prefixIcon: prefixIcon == null
        ? null
        : Icon(prefixIcon, size: 18, color: colorScheme.onSurfaceVariant),
    filled: filled,
    fillColor: colorScheme.surfaceContainerHighest,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
    border: border(colorScheme.outline),
    enabledBorder: border(colorScheme.outline),
    focusedBorder: border(colorScheme.primary, 1.5),
    errorBorder: border(colorScheme.error),
    focusedErrorBorder: border(colorScheme.error, 1.5),
  );
}

class JadwalFieldLabel extends StatelessWidget {
  const JadwalFieldLabel({
    required this.label,
    this.required = false,
    super.key,
  });

  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(
          text: label,
          children: [
            if (required)
              TextSpan(
                text: ' *',
                style: TextStyle(
                  color: colorScheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
        style: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class JadwalSectionCard extends StatelessWidget {
  const JadwalSectionCard({
    required this.icon,
    required this.title,
    required this.isExpanded,
    required this.onToggle,
    required this.child,
    super.key,
  });

  final IconData icon;
  final String title;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: colorScheme.onSurface),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: colorScheme.onSurfaceVariant,
                    semanticLabel: isExpanded ? 'Tutup $title' : 'Buka $title',
                  ),
                ],
              ),
            ),
          ),
          // Collapsed fields stay mounted so the form still validates them.
          Visibility(
            visible: isExpanded,
            maintainState: true,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class JadwalDropdownField<T> extends StatelessWidget {
  const JadwalDropdownField({
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.value,
    this.selectedItemLabel,
    this.hintText,
    this.prefixIcon,
    this.validator,
    this.filled = false,
    super.key,
  });

  final List<T> items;
  final T? value;
  final String Function(T item) itemLabel;
  final String Function(T item)? selectedItemLabel;
  final ValueChanged<T?> onChanged;
  final String? hintText;
  final IconData? prefixIcon;
  final FormFieldValidator<T>? validator;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textStyle = TextStyle(color: colorScheme.onSurface, fontSize: 14);

    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      validator: validator,
      onChanged: onChanged,
      icon: Icon(
        Icons.keyboard_arrow_down,
        color: colorScheme.onSurfaceVariant,
      ),
      hint: hintText == null
          ? null
          : Text(
              hintText!,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
      decoration: jadwalInputDecoration(
        colorScheme,
        prefixIcon: prefixIcon,
        filled: filled,
      ),
      style: textStyle,
      selectedItemBuilder: selectedItemLabel == null
          ? null
          : (context) => [
              for (final item in items)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    selectedItemLabel!(item),
                    overflow: TextOverflow.ellipsis,
                    style: textStyle,
                  ),
                ),
            ],
      items: [
        for (final item in items)
          DropdownMenuItem<T>(
            value: item,
            child: Text(itemLabel(item), overflow: TextOverflow.ellipsis),
          ),
      ],
    );
  }
}

/// Field that opens a searchable bottom sheet, for long option lists.
class JadwalSearchPickerField<T> extends StatelessWidget {
  const JadwalSearchPickerField({
    required this.options,
    required this.itemLabel,
    required this.searchText,
    required this.hintText,
    required this.sheetTitle,
    required this.onChanged,
    this.value,
    this.itemSubtitle,
    this.validator,
    super.key,
  });

  final List<T> options;
  final T? value;
  final String Function(T item) itemLabel;
  final String Function(T item)? itemSubtitle;

  /// Text matched against the search query, e.g. name plus code.
  final String Function(T item) searchText;
  final String hintText;
  final String sheetTitle;
  final ValueChanged<T> onChanged;
  final FormFieldValidator<T>? validator;

  @override
  Widget build(BuildContext context) {
    return FormField<T>(
      initialValue: value,
      validator: validator,
      builder: (field) {
        final colorScheme = Theme.of(context).colorScheme;
        final selected = field.value;

        Future<void> openPicker() async {
          final picked = await showModalBottomSheet<T>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            showDragHandle: true,
            builder: (context) => _SearchPickerSheet<T>(
              title: sheetTitle,
              options: options,
              selected: selected,
              itemLabel: itemLabel,
              itemSubtitle: itemSubtitle,
              searchText: searchText,
            ),
          );
          if (picked == null) return;
          field.didChange(picked);
          onChanged(picked);
        }

        return Semantics(
          button: true,
          label: sheetTitle,
          child: InkWell(
            onTap: openPicker,
            borderRadius: BorderRadius.circular(10),
            child: InputDecorator(
              isEmpty: selected == null,
              decoration:
                  jadwalInputDecoration(
                    colorScheme,
                    hintText: hintText,
                    prefixIcon: Icons.search,
                    errorText: field.errorText,
                  ).copyWith(
                    suffixIcon: Icon(
                      Icons.keyboard_arrow_down,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
              child: selected == null
                  ? null
                  : Text(
                      itemLabel(selected),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 14,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _SearchPickerSheet<T> extends StatefulWidget {
  const _SearchPickerSheet({
    required this.title,
    required this.options,
    required this.selected,
    required this.itemLabel,
    required this.itemSubtitle,
    required this.searchText,
  });

  final String title;
  final List<T> options;
  final T? selected;
  final String Function(T item) itemLabel;
  final String Function(T item)? itemSubtitle;
  final String Function(T item) searchText;

  @override
  State<_SearchPickerSheet<T>> createState() => _SearchPickerSheetState<T>();
}

class _SearchPickerSheetState<T> extends State<_SearchPickerSheet<T>> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final query = _query.trim().toLowerCase();
    final results = query.isEmpty
        ? widget.options
        : widget.options
              .where(
                (item) => widget.searchText(item).toLowerCase().contains(query),
              )
              .toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                widget.title,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (value) => setState(() => _query = value),
                style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
                decoration: jadwalInputDecoration(
                  colorScheme,
                  hintText: 'Ketik untuk mencari...',
                  prefixIcon: Icons.search,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: results.isEmpty
                  ? Center(
                      child: Text(
                        'Tidak ditemukan.',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    )
                  : ListView.builder(
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final item = results[index];
                        return ListTile(
                          title: Text(widget.itemLabel(item)),
                          subtitle: widget.itemSubtitle == null
                              ? null
                              : Text(widget.itemSubtitle!(item)),
                          selected: item == widget.selected,
                          trailing: item == widget.selected
                              ? Icon(Icons.check, color: colorScheme.primary)
                              : null,
                          onTap: () => Navigator.of(context).pop(item),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
