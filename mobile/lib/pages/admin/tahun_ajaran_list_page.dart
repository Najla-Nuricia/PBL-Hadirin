import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/admin/tahun_ajaran.dart';
import '../../routing/admin_route_paths.dart';
import 'tambah_tahun_ajaran_page.dart';

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
      MaterialPageRoute(
        builder: (_) => const TambahTahunAjaranPage(),
      ),
    );
    if (added == true) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(colorScheme),
            _buildSearchBar(colorScheme),
            const SizedBox(height: 8),
            Expanded(
              child: _displayed.isEmpty
                  ? _buildEmpty(colorScheme)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: _displayed.length,
                      separatorBuilder: (_, i) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        return _TahunAjaranCard(
                          item: _displayed[index],
                          onTap: () {
                            // TODO: buka halaman detail / edit
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 16, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: _back,
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: colorScheme.primary,
            ),
            tooltip: 'Kembali',
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              'Tahun Ajaran',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          FilledButton.icon(
            onPressed: _openTambah,
            icon: const Icon(Icons.add, size: 18),
            label: const Text(
              'Tambah',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Cari tahun ajaran...',
          hintStyle: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 13,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: colorScheme.onSurfaceVariant,
            size: 20,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close,
                      color: colorScheme.onSurfaceVariant, size: 18),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.primary),
          ),
        ),
        style: TextStyle(color: colorScheme.onSurface, fontSize: 13),
      ),
    );
  }

  Widget _buildEmpty(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today_outlined,
              size: 48, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            'Tidak ada tahun ajaran ditemukan.',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Card item tahun ajaran
// ─────────────────────────────────────────────────────────
class _TahunAjaranCard extends StatelessWidget {
  const _TahunAjaranCard({required this.item, required this.onTap});

  final TahunAjaran item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isAktif = item.status == TahunAjaranStatus.aktif;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              // Ikon kalender
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.calendar_month_outlined,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          item.tahun,
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (isAktif) ...[
                          const SizedBox(width: 8),
                          _AktifBadge(colorScheme: colorScheme),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.semesterLabel,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AktifBadge extends StatelessWidget {
  const _AktifBadge({required this.colorScheme});
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: colorScheme.secondary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'Aktif',
            style: TextStyle(
              color: colorScheme.onSecondaryContainer,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
