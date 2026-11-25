import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../data/admin/admin_auth_repository.dart';
import '../../data/admin/admin_master_data_service.dart';
import '../../data/admin/jadwal.dart';
import '../../routing/admin_route_paths.dart';
import '../../widgets/widgets.dart';
import 'tambah_dosen_page.dart';
import 'widgets/admin_list.dart';

/// Master data Dosen: daftar + pencarian server-side + CRUD.
class DosenListPage extends StatefulWidget {
  const DosenListPage({super.key});

  @override
  State<DosenListPage> createState() => _DosenListPageState();
}

class _DosenListPageState extends State<DosenListPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<Dosen> _items = const [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _load);
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final items = await adminMasterDataService.listDosen(
        search: _searchController.text,
      );
      if (!mounted) return;
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } on AdminRemoteApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = error.message;
      });
    }
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AdminRoutePaths.dataAkademik);
    }
  }

  Future<void> _openForm({Dosen? item}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => TambahDosenPage(initialItem: item)),
    );
    if (saved == true && mounted) await _load();
  }

  Future<void> _delete(Dosen item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus dosen?'),
        content: Text(
          'Data ${item.nama} (NIP ${item.nip}) akan dihapus dan tidak '
          'dapat dikembalikan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      final message = await adminMasterDataService.deleteDosen(item.nip);
      if (mounted) {
        _showSnackBar(message);
        await _load();
      }
    } on AdminRemoteApiException catch (error) {
      if (mounted) _showError(error.message);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
            SkyHeader(
              includeStatusBar: false,
              child: Row(
                children: [
                  IconButton(
                    onPressed: _back,
                    icon: const Icon(
                      PhosphorIconsRegular.arrowLeft,
                      size: 20,
                    ),
                    color: AppColors.gownNavy,
                    tooltip: 'Kembali',
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Dosen',
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(color: AppColors.gownNavy),
                    ),
                  ),
                  IconButton(
                    onPressed: _load,
                    icon: const Icon(PhosphorIconsRegular.arrowsClockwise),
                    color: AppColors.gownNavy,
                    tooltip: 'Muat ulang',
                  ),
                  FilledButton.icon(
                    onPressed: () => _openForm(),
                    icon: const Icon(PhosphorIconsRegular.plus, size: 18),
                    label: const Text('Tambah'),
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.control,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.sm,
                AppSpacing.page,
                AppSpacing.xs,
              ),
              child: AdminSearchField(
                controller: _searchController,
                hintText: 'Cari nama atau NIP dosen...',
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                  ? AppErrorState(message: _errorMessage!, onRetry: _load)
                  : _items.isEmpty
                  ? const AppEmptyState(
                      title: 'Tidak ada dosen ditemukan.',
                      icon: PhosphorIconsRegular.users,
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.page,
                        AppSpacing.xs,
                        AppSpacing.page,
                        AppSpacing.xxl,
                      ),
                      children: [
                        AdminListCard(
                          children: [
                            for (final item in _items)
                              AdminListRow(
                                icon: PhosphorIconsRegular.users,
                                title: item.nama,
                                subtitle: [
                                  'NIP: ${item.nip}',
                                  if (item.email != null) item.email!,
                                  if (item.noHp != null) item.noHp!,
                                ].join(' · '),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () => _openForm(item: item),
                                      tooltip: 'Edit dosen',
                                      icon: Icon(
                                        PhosphorIconsRegular.pencilSimple,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => _delete(item),
                                      tooltip: 'Hapus dosen',
                                      icon: Icon(
                                        PhosphorIconsRegular.trash,
                                        color: colorScheme.error,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
