import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../data/admin/admin_auth_repository.dart';
import '../../data/admin/admin_master_data_service.dart';
import '../../data/admin/jadwal.dart';
import '../../data/admin/kelas.dart';
import '../../data/admin/tahun_ajaran.dart';
import '../../routing/admin_route_paths.dart';
import '../../widgets/widgets.dart';
import 'tambah_kelas_page.dart';
import 'widgets/admin_list.dart';

/// Master data Kelas: daftar + pencarian/filter server-side + CRUD.
class KelasListPage extends StatefulWidget {
  const KelasListPage({super.key});

  @override
  State<KelasListPage> createState() => _KelasListPageState();
}

class _KelasListPageState extends State<KelasListPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  List<Kelas> _items = const [];
  List<ProgramStudi> _programStudi = const [];
  List<TahunAjaran> _tahunAjaran = const [];

  String? _programStudiKode;
  String? _tahunAjaranId;
  String? _status;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadOptions();
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

  /// Pilihan dropdown diambil dari endpoint master data yang sudah ada.
  Future<void> _loadOptions() async {
    try {
      final results = await Future.wait<Object>([
        adminMasterDataService.listProgramStudi(),
        adminMasterDataService.listTahunAjaran(),
      ]);
      if (!mounted) return;
      setState(() {
        _programStudi = results[0] as List<ProgramStudi>;
        _tahunAjaran = results[1] as List<TahunAjaran>;
      });
    } on AdminRemoteApiException {
      // Daftar kelas tetap bisa dipakai walau opsi filter gagal dimuat.
    }
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final items = await adminMasterDataService.listKelasMaster(
        search: _searchController.text,
        programStudiKode: _programStudiKode,
        tahunAjaranId: _tahunAjaranId,
        status: _status == null ? null : KelasStatusLabel.fromApiValue(_status),
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

  Future<void> _openForm({Kelas? item}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TambahKelasPage(
          initialItem: item,
          programStudi: _programStudi,
          tahunAjaran: _tahunAjaran,
        ),
      ),
    );
    if (saved == true && mounted) await _load();
  }

  Future<void> _delete(Kelas item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus kelas?'),
        content: Text(
          'Kelas ${item.nama} akan dihapus dan tidak dapat dikembalikan.',
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
      final message = await adminMasterDataService.deleteKelas(item.id);
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
                      'Kelas',
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
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.page,
                vertical: AppSpacing.xs,
              ),
              child: AdminSearchField(
                controller: _searchController,
                hintText: 'Cari nama kelas...',
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.page,
              ),
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  _FilterDropdown(
                    hint: 'Semua prodi',
                    value: _programStudiKode,
                    items: [
                      for (final item in _programStudi)
                        DropdownMenuItem(
                          value: item.kode,
                          child: Text(item.nama, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (value) {
                      _programStudiKode = value;
                      _load();
                    },
                  ),
                  _FilterDropdown(
                    hint: 'Semua tahun ajaran',
                    value: _tahunAjaranId,
                    items: [
                      for (final item in _tahunAjaran)
                        DropdownMenuItem(value: item.id, child: Text(item.tahun)),
                    ],
                    onChanged: (value) {
                      _tahunAjaranId = value;
                      _load();
                    },
                  ),
                  _FilterDropdown(
                    hint: 'Semua status',
                    value: _status,
                    items: const [
                      DropdownMenuItem(value: 'aktif', child: Text('Aktif')),
                      DropdownMenuItem(
                        value: 'non_aktif',
                        child: Text('Non-Aktif'),
                      ),
                    ],
                    onChanged: (value) {
                      _status = value;
                      _load();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                  ? AppErrorState(message: _errorMessage!, onRetry: _load)
                  : _items.isEmpty
                  ? const AppEmptyState(
                      title: 'Tidak ada kelas ditemukan.',
                      icon: PhosphorIconsRegular.usersThree,
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
                                icon: PhosphorIconsRegular.usersThree,
                                title: item.nama,
                                subtitle:
                                    '${item.programStudiLabel} · '
                                    '${item.tahunAjaranLabel} · '
                                    'Tingkat ${item.tingkat} · '
                                    'Kapasitas ${item.kapasitas}',
                                badge: AdminStatusBadge(
                                  label: item.status.label,
                                  active: item.status == KelasStatus.aktif,
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () => _openForm(item: item),
                                      tooltip: 'Edit kelas',
                                      icon: Icon(
                                        PhosphorIconsRegular.pencilSimple,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => _delete(item),
                                      tooltip: 'Hapus kelas',
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

/// Dropdown ringkas untuk filter; pilihan "Semua" diwakili nilai null.
class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String hint;
  final String? value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 220),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
          hintText: hint,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: AppRadius.control,
            borderSide: BorderSide(color: colorScheme.outlineVariant),
          ),
        ),
        items: [
          DropdownMenuItem<String>(value: null, child: Text(hint)),
          ...items,
        ],
        onChanged: onChanged,
      ),
    );
  }
}
