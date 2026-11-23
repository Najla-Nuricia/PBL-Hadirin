import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/admin/admin_auth_repository.dart';
import '../../data/admin/admin_whitelist_nim_service.dart';
import '../../data/admin/whitelist_nim.dart';
import '../../routing/admin_route_paths.dart';

class WhitelistNimPage extends StatefulWidget {
  const WhitelistNimPage({super.key});

  @override
  State<WhitelistNimPage> createState() => _WhitelistNimPageState();
}

class _WhitelistNimPageState extends State<WhitelistNimPage> {
  final _searchController = TextEditingController();
  List<WhitelistNim> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    _searchController.removeListener(_load);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await adminWhitelistNimService.list(
        search: _searchController.text,
      );
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } on AdminRemoteApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message;
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

  Future<void> _showForm({WhitelistNim? item}) async {
    final controller = TextEditingController(text: item?.nim ?? '');
    final formKey = GlobalKey<FormState>();
    var submitting = false;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(item == null ? 'Tambah Whitelist NIM' : 'Ubah NIM'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'NIM',
                hintText: 'Masukkan NIM mahasiswa',
              ),
              validator: (value) {
                final nim = (value ?? '').trim();
                if (nim.isEmpty) return 'NIM wajib diisi.';
                if (nim.length < 3 || nim.length > 20) {
                  return 'NIM harus 3–20 digit.';
                }
                if (!RegExp(r'^\d+$').hasMatch(nim)) {
                  return 'NIM hanya boleh berisi angka.';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: submitting ? null : () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: submitting
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => submitting = true);
                      try {
                        if (item == null) {
                          await adminWhitelistNimService.create(controller.text);
                        } else {
                          await adminWhitelistNimService.update(
                            oldNim: item.nim,
                            nim: controller.text,
                          );
                        }
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext, true);
                        }
                      } on AdminRemoteApiException catch (error) {
                        if (dialogContext.mounted) {
                          setDialogState(() => submitting = false);
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(content: Text(error.message)),
                          );
                        }
                      }
                    },
              child: submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (saved == true) await _load();
  }

  Future<void> _delete(WhitelistNim item) async {
    if (item.sudahRegistrasi) {
      _showMessage('NIM yang sudah terdaftar tidak dapat dihapus.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus whitelist?'),
        content: Text('NIM ${item.nim} akan dihapus dari whitelist.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await adminWhitelistNimService.delete(item.nim);
      await _load();
    } on AdminRemoteApiException catch (error) {
      _showMessage(error.message);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        leading: IconButton(onPressed: _back, icon: const Icon(Icons.arrow_back)),
        title: const Text('Whitelist NIM'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah NIM'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Cari NIM...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(child: Text(_error!, textAlign: TextAlign.center))
                : _items.isEmpty
                ? const Center(child: Text('Belum ada NIM di whitelist.'))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                    itemCount: _items.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return Card(
                        child: ListTile(
                          title: Text(
                            item.nim,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            '${item.namaMahasiswa} · ${item.kelas}\n${item.status}',
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') _showForm(item: item);
                              if (value == 'delete') _delete(item);
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(value: 'edit', child: Text('Ubah')),
                              PopupMenuItem(value: 'delete', child: Text('Hapus')),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
