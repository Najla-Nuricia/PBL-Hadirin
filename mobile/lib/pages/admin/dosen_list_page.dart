import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/admin/dosen.dart';
import '../../data/admin/jadwal.dart';
import '../../routing/admin_route_paths.dart';
import 'tambah_dosen_page.dart';
import 'widgets/master_data_list_widgets.dart';

class DosenListPage extends StatefulWidget {
  const DosenListPage({super.key});

  @override
  State<DosenListPage> createState() => _DosenListPageState();
}

class _DosenListPageState extends State<DosenListPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearch);
    dosenRepository.addListener(_onRepositoryChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearch);
    _searchController.dispose();
    dosenRepository.removeListener(_onRepositoryChanged);
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

  Future<void> _openForm({Dosen? dosen}) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => TambahDosenPage(dosen: dosen)),
    );
  }

  Future<void> _confirmDelete(Dosen dosen) async {
    final confirmed = await confirmDelete(
      context,
      title: 'Hapus Dosen',
      message: 'Yakin ingin menghapus ${dosen.nama} (${dosen.nip})?',
    );
    if (!confirmed) return;
    dosenRepository.remove(dosen.nip);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Dosen ${dosen.nama} berhasil dihapus'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = dosenRepository.search(_searchController.text);

    return MasterDataListScaffold(
      title: 'Dosen',
      subtitle: 'Kelola data dosen pengampu',
      searchHint: 'Cari nama / NIP dosen...',
      searchController: _searchController,
      onAdd: () => _openForm(),
      onBack: _back,
      body: items.isEmpty
          ? const MasterDataEmptyState(
              icon: Icons.people_outline,
              message: 'Belum ada data dosen.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final dosen = items[index];
                return MasterDataCard(
                  icon: Icons.person_outline,
                  title: dosen.nama,
                  subtitle: [
                    'NIP ${dosen.nip}',
                    if (dosen.programStudi != null) dosen.programStudi!,
                    if (dosen.email != null) dosen.email!,
                  ].join(' · '),
                  statusLabel: dosen.status.label,
                  statusIsPositive: dosen.status == DosenStatus.aktif,
                  onEdit: () => _openForm(dosen: dosen),
                  onDelete: () => _confirmDelete(dosen),
                );
              },
            ),
    );
  }
}
