import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/admin/kelas.dart';
import '../../routing/admin_route_paths.dart';
import 'tambah_kelas_page.dart';
import 'widgets/master_data_list_widgets.dart';

class KelasListPage extends StatefulWidget {
  const KelasListPage({super.key});

  @override
  State<KelasListPage> createState() => _KelasListPageState();
}

class _KelasListPageState extends State<KelasListPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearch);
    kelasRepository.addListener(_onRepositoryChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearch);
    _searchController.dispose();
    kelasRepository.removeListener(_onRepositoryChanged);
    super.dispose();
  }

  void _onSearch() => setState(() {});

  void _onRepositoryChanged() {
    if (mounted) setState(() {});
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AdminRoutePaths.dataAkademik);
    }
  }

  Future<void> _openForm({Kelas? kelas}) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => TambahKelasPage(kelas: kelas)),
    );
  }

  Future<void> _confirmDelete(Kelas kelas) async {
    final confirmed = await confirmDelete(
      context,
      title: 'Hapus Kelas',
      message:
          'Yakin ingin menghapus kelas ${kelas.nama} '
          '(${kelas.tahunAjaran})?',
    );
    if (!confirmed) return;
    kelasRepository.remove(kelas.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Kelas ${kelas.nama} berhasil dihapus'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = kelasRepository.search(_searchController.text);

    return MasterDataListScaffold(
      title: 'Kelas',
      subtitle: 'Kelola data kelas per program studi',
      searchHint: 'Cari nama kelas / prodi...',
      searchController: _searchController,
      onAdd: () => _openForm(),
      onBack: _back,
      body: items.isEmpty
          ? const MasterDataEmptyState(
              icon: Icons.groups_outlined,
              message: 'Belum ada data kelas.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final kelas = items[index];
                return MasterDataCard(
                  icon: Icons.groups_outlined,
                  title: kelas.nama,
                  subtitle:
                      '${kelas.programStudi} · ${kelas.tahunAjaran} · '
                      '${kelas.kapasitas} mahasiswa',
                  statusLabel: kelas.status.label,
                  statusIsPositive: kelas.status == KelasStatus.aktif,
                  onEdit: () => _openForm(kelas: kelas),
                  onDelete: () => _confirmDelete(kelas),
                );
              },
            ),
    );
  }
}
