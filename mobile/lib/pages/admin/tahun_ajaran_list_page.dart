import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:go_router/go_router.dart';

import '../../data/admin/tahun_ajaran.dart';
import '../../routing/admin_route_paths.dart';
import '../../widgets/widgets.dart';
import 'tambah_tahun_ajaran_page.dart';
import 'widgets/admin_list.dart';
import 'widgets/admin_scaffold.dart';

class TahunAjaranListPage extends StatefulWidget {
  const TahunAjaranListPage({super.key});

  @override
  State<TahunAjaranListPage> createState() => _TahunAjaranListPageState();
}

class _TahunAjaranListPageState extends State<TahunAjaranListPage> {
  final _searchController = TextEditingController();
  List<TahunAjaran> _displayed = [];

  @override
  void initState() {
    super.initState();
    _displayed = tahunAjaranRepository.getAll();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearch);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    setState(() {
      _displayed = tahunAjaranRepository.search(_searchController.text);
    });
  }

  void _refresh() {
    setState(() {
      _displayed = tahunAjaranRepository.search(_searchController.text);
    });
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AdminRoutePaths.dataAkademik);
    }
  }

  Future<void> _openTambah() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const TambahTahunAjaranPage()),
    );
    if (added == true) _refresh();
  }

  Future<void> _openEdit(TahunAjaran item) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TambahTahunAjaranPage(initialItem: item),
      ),
    );
    if (updated == true) _refresh();
  }

  Future<void> _delete(TahunAjaran item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus tahun ajaran?'),
        content: Text(
          'Data ${item.tahun} akan dihapus dan tidak dapat dikembalikan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    tahunAjaranRepository.delete(item.id);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AdminPageScaffold(
      title: 'Tahun Ajaran',
      onBack: _back,
      bottomBar: AdminBottomBar(
        child: AppGradientButton(
          onPressed: _openTambah,
          icon: PhosphorIconsRegular.plus,
          label: 'Tambah',
        ),
      ),
      children: [
        const SizedBox(height: AppSpacing.sm),
        AdminSearchField(
          controller: _searchController,
          hintText: 'Cari tahun ajaran...',
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_displayed.isEmpty)
          AppEmptyState(
            icon: PhosphorIconsRegular.calendarBlank,
            title: 'Tidak ada tahun ajaran ditemukan.',
            message: _searchController.text.trim().isEmpty
                ? 'Tahun ajaran yang ditambahkan akan muncul di sini.'
                : 'Coba kata kunci lain.',
          )
        else
          AdminListCard(
            children: [
              for (final item in _displayed)
                AdminListRow(
                  icon: PhosphorIconsRegular.calendarBlank,
                  title: item.tahun,
                  subtitle: item.semesterLabel,
                  badge: AdminStatusBadge(
                    label: item.status.label,
                    active: item.status == TahunAjaranStatus.aktif,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _openEdit(item),
                        tooltip: 'Edit tahun ajaran',
                        icon: const Icon(PhosphorIconsRegular.pencilSimple),
                      ),
                      IconButton(
                        onPressed: () => _delete(item),
                        tooltip: 'Hapus tahun ajaran',
                        color: colorScheme.error,
                        icon: const Icon(PhosphorIconsRegular.trash),
                      ),
                    ],
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
