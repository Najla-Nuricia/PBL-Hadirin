import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:go_router/go_router.dart';

import '../../data/admin/jadwal.dart';
import '../../data/admin/mata_kuliah.dart';
import '../../routing/admin_route_paths.dart';
import '../../widgets/widgets.dart';
import 'tambah_mata_kuliah_page.dart';
import 'widgets/admin_list.dart';
import 'widgets/admin_scaffold.dart';

class MataKuliahListPage extends StatefulWidget {
  const MataKuliahListPage({super.key});

  @override
  State<MataKuliahListPage> createState() => _MataKuliahListPageState();
}

class _MataKuliahListPageState extends State<MataKuliahListPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_refreshSearch);
  }

  @override
  void dispose() {
    _searchController.removeListener(_refreshSearch);
    _searchController.dispose();
    super.dispose();
  }

  void _refreshSearch() => setState(() {});

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AdminRoutePaths.dataAkademik);
    }
  }

  Future<void> _openForm({MataKuliah? item}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TambahMataKuliahPage(initialItem: item),
      ),
    );
    if (saved == true && mounted) setState(() {});
  }

  Future<void> _delete(MataKuliah item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus mata kuliah?'),
        content: Text(
          '${item.kode} · ${item.nama} akan dihapus dan tidak dapat dikembalikan.',
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
    mataKuliahRepository.delete(item.id);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: mataKuliahRepository,
      builder: (context, _) {
        final displayed = mataKuliahRepository.search(_searchController.text);

        return AdminPageScaffold(
          title: 'Mata Kuliah',
          onBack: _back,
          bottomBar: AdminBottomBar(
            child: AppGradientButton(
              onPressed: () => _openForm(),
              icon: PhosphorIconsRegular.plus,
              label: 'Tambah',
            ),
          ),
          children: [
            const SizedBox(height: AppSpacing.sm),
            AdminSearchField(
              controller: _searchController,
              hintText: 'Cari kode atau nama mata kuliah...',
            ),
            const SizedBox(height: AppSpacing.lg),
            if (displayed.isEmpty)
              AppEmptyState(
                icon: PhosphorIconsRegular.bookOpen,
                title: 'Tidak ada mata kuliah ditemukan.',
                message: _searchController.text.trim().isEmpty
                    ? 'Mata kuliah yang ditambahkan akan muncul di sini.'
                    : 'Coba kata kunci lain.',
              )
            else
              AdminListCard(
                children: [
                  for (final item in displayed)
                    AdminListRow(
                      icon: PhosphorIconsRegular.bookOpen,
                      title: item.nama,
                      titleMaxLines: 2,
                      subtitle:
                          '${item.kode} · Semester ${item.semester} · '
                          '${item.sks} SKS',
                      badge: AdminStatusBadge(
                        label: item.status.label,
                        active: item.status == MataKuliahStatus.aktif,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => _openForm(item: item),
                            tooltip: 'Edit mata kuliah',
                            icon: const Icon(PhosphorIconsRegular.pencilSimple),
                          ),
                          IconButton(
                            onPressed: () => _delete(item),
                            tooltip: 'Hapus mata kuliah',
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
      },
    );
  }
}
