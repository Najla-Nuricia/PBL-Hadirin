import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/admin/jadwal.dart';
import '../../data/admin/ruangan.dart';
import '../../routing/admin_route_paths.dart';
import 'tambah_ruangan_page.dart';
import 'widgets/master_data_list_widgets.dart';

class RuanganListPage extends StatefulWidget {
  const RuanganListPage({super.key});

  @override
  State<RuanganListPage> createState() => _RuanganListPageState();
}

class _RuanganListPageState extends State<RuanganListPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearch);
    ruanganRepository.addListener(_onRepositoryChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearch);
    _searchController.dispose();
    ruanganRepository.removeListener(_onRepositoryChanged);
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

  Future<void> _openForm({Ruangan? ruangan}) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => TambahRuanganPage(ruangan: ruangan)),
    );
  }

  Future<void> _confirmDelete(Ruangan ruangan) async {
    final confirmed = await confirmDelete(
      context,
      title: 'Hapus Ruangan',
      message: 'Yakin ingin menghapus ruangan ${ruangan.nama}?',
    );
    if (!confirmed) return;
    ruanganRepository.remove(ruangan.kode);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ruangan ${ruangan.nama} berhasil dihapus'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = ruanganRepository.search(_searchController.text);

    return MasterDataListScaffold(
      title: 'Ruangan',
      subtitle: 'Kelola data ruangan',
      searchHint: 'Cari kode / nama ruangan...',
      searchController: _searchController,
      onAdd: () => _openForm(),
      onBack: _back,
      body: items.isEmpty
          ? const MasterDataEmptyState(
              icon: Icons.meeting_room_outlined,
              message: 'Belum ada data ruangan.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final ruangan = items[index];
                return MasterDataCard(
                  icon: Icons.meeting_room_outlined,
                  title: ruangan.nama,
                  subtitle: ruangan.kapasitas == null
                      ? 'Kode ${ruangan.kode}'
                      : 'Kode ${ruangan.kode} · Kapasitas '
                            '${ruangan.kapasitas} orang',
                  onEdit: () => _openForm(ruangan: ruangan),
                  onDelete: () => _confirmDelete(ruangan),
                );
              },
            ),
    );
  }
}
