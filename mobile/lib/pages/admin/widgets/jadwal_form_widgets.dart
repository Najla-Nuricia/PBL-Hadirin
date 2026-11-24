import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../widgets/widgets.dart';
import 'labeled_fields.dart';

/// Dekorasi kolom isian jadwal. Bentuk, garis, dan warna datang dari tema;
/// [filled] memberi latar abu-abu untuk nilai bawaan.
InputDecoration jadwalInputDecoration(
  ColorScheme colorScheme, {
  String? hintText,
  IconData? prefixIcon,
  bool filled = false,
  String? errorText,
}) {
  return InputDecoration(
    hintText: hintText,
    hintMaxLines: 1,
    errorText: errorText,
    prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 20),
    fillColor: filled ? colorScheme.surfaceContainerHigh : null,
  );
}

class JadwalFieldLabel extends AdminFieldLabel {
  const JadwalFieldLabel({required super.label, super.required, super.key});
}

/// Kartu berjudul yang isinya bisa dilipat.
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
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggle,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  children: [
                    Icon(icon, size: 20, color: AppColors.inkMuted),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Icon(
                      isExpanded
                          ? PhosphorIconsRegular.caretUp
                          : PhosphorIconsRegular.caretDown,
                      color: AppColors.inkFaint,
                      semanticLabel: isExpanded
                          ? 'Tutup $title'
                          : 'Buka $title',
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : AppMotion.fast,
            curve: AppMotion.curve,
            alignment: Alignment.topCenter,
            // Isian yang dilipat tetap terpasang agar form masih memvalidasinya.
            child: Visibility(
              visible: isExpanded,
              maintainState: true,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: child,
              ),
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
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodyLarge;

    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      validator: validator,
      onChanged: onChanged,
      borderRadius: AppRadius.control,
      icon: const Icon(
        PhosphorIconsRegular.caretDown,
        color: AppColors.inkFaint,
      ),
      hint: hintText == null
          ? null
          : Text(
              hintText!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle?.copyWith(color: AppColors.inkFaint),
            ),
      decoration: jadwalInputDecoration(
        theme.colorScheme,
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textStyle?.tabular,
                  ),
                ),
            ],
      items: [
        for (final item in items)
          DropdownMenuItem<T>(
            value: item,
            child: Text(
              itemLabel(item),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
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
        final theme = Theme.of(context);
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
            borderRadius: AppRadius.control,
            child: InputDecorator(
              isEmpty: selected == null,
              decoration:
                  jadwalInputDecoration(
                    theme.colorScheme,
                    hintText: hintText,
                    prefixIcon: PhosphorIconsRegular.magnifyingGlass,
                    errorText: field.errorText,
                  ).copyWith(
                    suffixIcon: const Icon(
                      PhosphorIconsRegular.caretDown,
                      color: AppColors.inkFaint,
                    ),
                  ),
              child: selected == null
                  ? null
                  : Text(
                      itemLabel(selected),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge,
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
    final theme = Theme.of(context);
    final text = theme.textTheme;
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
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                0,
                AppSpacing.page,
                AppSpacing.md,
              ),
              child: Text(widget.title, style: text.titleLarge),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: (value) => setState(() => _query = value),
                decoration: jadwalInputDecoration(
                  theme.colorScheme,
                  hintText: 'Ketik untuk mencari...',
                  prefixIcon: PhosphorIconsRegular.magnifyingGlass,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: results.isEmpty
                  ? const SingleChildScrollView(
                      child: AppEmptyState(
                        icon: PhosphorIconsRegular.magnifyingGlassMinus,
                        title: 'Tidak ditemukan.',
                        message: 'Coba kata kunci lain.',
                      ),
                    )
                  : ListView.builder(
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final item = results[index];
                        final isSelected = item == widget.selected;
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.page,
                          ),
                          title: Text(
                            widget.itemLabel(item),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: text.titleSmall?.copyWith(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : null,
                            ),
                          ),
                          subtitle: widget.itemSubtitle == null
                              ? null
                              : Text(
                                  widget.itemSubtitle!(item),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: text.bodySmall?.tabular.copyWith(
                                    color: AppColors.inkFaint,
                                  ),
                                ),
                          selected: isSelected,
                          trailing: isSelected
                              ? Icon(
                                  PhosphorIconsRegular.check,
                                  color: theme.colorScheme.primary,
                                )
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
