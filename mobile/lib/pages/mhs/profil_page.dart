import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../data/mhs/dummy_student_auth_repository.dart';
import '../../data/mhs/student_account.dart';
import '../../data/mhs/student_data_service.dart';
import '../../routing/student_route_paths.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({required this.account, super.key});

  final StudentAccount account;

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  Uint8List? _profilePhoto;
  late String _fullName;
  late String _nim;
  String _email = '';
  late String _phoneNumber;

  @override
  void initState() {
    super.initState();
    _syncFromWidgetAccount();
    _loadLiveProfile();
  }

  @override
  void didUpdateWidget(covariant ProfilPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.account.nim != widget.account.nim) {
      _syncFromWidgetAccount();
      _loadLiveProfile();
    }
  }

  void _syncFromWidgetAccount() {
    _fullName = widget.account.fullName;
    _nim = widget.account.nim;
    _email = '';
    _phoneNumber = 'Belum diisi';
  }

  Future<void> _loadLiveProfile() async {
    if (!studentAuthRepository.hasRemoteSession) return;
    try {
      final profile = await studentDataService.loadProfile();
      if (!mounted) return;
      setState(() {
        _fullName = profile.fullName.isNotEmpty ? profile.fullName : _fullName;
        _nim = profile.studentId.isNotEmpty ? profile.studentId : _nim;
        _email = profile.email;
        _phoneNumber =
            profile.phoneNumber.trim().isEmpty ? 'Belum diisi' : profile.phoneNumber;
      });
    } catch (_) {}
  }

  Future<void> _editProfile() async {
    final updatedProfile = await showDialog<_StudentProfileEdit>(
      context: context,
      builder: (context) => _EditStudentProfileDialog(
        fullName: _fullName,
        nim: _nim,
        email: _email,
        phoneNumber: _phoneNumber == 'Belum diisi' ? '' : _phoneNumber,
      ),
    );
    if (!mounted || updatedProfile == null) return;

    if (studentAuthRepository.hasRemoteSession) {
      try {
        final saved = await studentDataService.updateMyProfile(
          fullName: updatedProfile.fullName,
          email: updatedProfile.email,
          phoneNumber: updatedProfile.phoneNumber,
        );
        if (!mounted) return;
        setState(() {
          _fullName = saved.fullName;
          _email = saved.email;
          _phoneNumber = saved.phoneNumber.trim().isEmpty
              ? 'Belum diisi'
              : saved.phoneNumber;
        });
        studentAuthRepository.updateProfile(
          fullName: saved.fullName,
        );
        _showMessage('Profil berhasil diperbarui.');
      } catch (error) {
        if (!mounted) return;
        _showMessage('$error');
      }
      return;
    }

    setState(() {
      _fullName = updatedProfile.fullName;
      _nim = updatedProfile.nim;
      _email = updatedProfile.email;
      _phoneNumber = updatedProfile.phoneNumber;
    });
    studentAuthRepository.updateProfile(
      fullName: updatedProfile.fullName,
    );
    _showMessage('Profil berhasil diperbarui.');
  }

  Future<void> _pickProfilePhoto() async {
    try {
      final pickedFile = await FilePicker.pickFile(type: FileType.image);
      if (!mounted || pickedFile == null) return;

      final photo = await pickedFile.readAsBytes();
      if (!mounted) return;
      if (photo.isEmpty) {
        _showMessage('Foto tidak dapat dibaca. Silakan pilih gambar lain.');
        return;
      }

      setState(() => _profilePhoto = photo);
      _showMessage('Foto profil berhasil diperbarui.');
    } on PlatformException catch (error) {
      if (!mounted) return;
      final detail = error.message;
      _showMessage(
        detail == null
            ? 'Gagal memilih foto profil.'
            : 'Gagal memilih foto profil: $detail',
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest,
      body: SafeArea(
        child: Column(
          children: [
            // App bar
            Container(
              height: 52,
              color: colorScheme.surface,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    color: colorScheme.onSurfaceVariant,
                    onPressed: () => context.go(StudentRoutePaths.beranda),
                    tooltip: 'Kembali',
                  ),
                  Text(
                    'Informasi Akun',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    // Avatar & Name card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          Tooltip(
                            message: 'Ubah foto profil',
                            child: InkWell(
                              onTap: _pickProfilePhoto,
                              customBorder: const CircleBorder(),
                              child: Container(
                                width: 80,
                                height: 80,
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: colorScheme.outlineVariant,
                                    width: 1.5,
                                  ),
                                ),
                                child: _profilePhoto == null
                                    ? Icon(
                                        Icons.person,
                                        size: 44,
                                        color: colorScheme.onSurfaceVariant,
                                      )
                                    : Image.memory(
                                        _profilePhoto!,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _fullName,
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'MAHASISWA',
                              style: TextStyle(
                                color: colorScheme.onPrimaryContainer,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Info card
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          _InfoRow(
                            icon: Icons.badge_outlined,
                            label: 'NIM/NIDN',
                            value: _nim,
                            colorScheme: colorScheme,
                          ),
                          _Divider(colorScheme: colorScheme),
                          _InfoRow(
                            icon: Icons.email_outlined,
                            label: 'Email',
                            value: _email.isEmpty ? 'Belum diisi' : _email,
                            colorScheme: colorScheme,
                          ),
                          _Divider(colorScheme: colorScheme),
                          _InfoRow(
                            icon: Icons.phone_outlined,
                            label: 'Nomor HP',
                            value: _phoneNumber,
                            colorScheme: colorScheme,
                          ),
                          _Divider(colorScheme: colorScheme),
                          _InfoRow(
                            icon: Icons.person_outline,
                            label: 'Role',
                            value: 'Mahasiswa',
                            colorScheme: colorScheme,
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Actions card
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          _ActionRow(
                            icon: Icons.manage_accounts_outlined,
                            iconColor: colorScheme.primary,
                            iconBg: colorScheme.primaryContainer,
                            label: 'Ubah Profil',
                            colorScheme: colorScheme,
                            onTap: _editProfile,
                          ),
                          _Divider(colorScheme: colorScheme),
                          _ActionRow(
                            key: const ValueKey('profile-change-password'),
                            icon: Icons.key_outlined,
                            iconColor: const Color(0xFFF5A623),
                            iconBg: const Color(0xFFFEF3C7),
                            label: 'Ubah Kata Sandi',
                            colorScheme: colorScheme,
                            onTap: () =>
                                context.push(StudentRoutePaths.changePassword),
                          ),
                          _Divider(colorScheme: colorScheme),
                          _ActionRow(
                            icon: Icons.logout,
                            iconColor: colorScheme.error,
                            iconBg: colorScheme.errorContainer,
                            label: 'Keluar',
                            labelColor: colorScheme.error,
                            colorScheme: colorScheme,
                            showChevron: false,
                            onTap: () {
                              studentAuthRepository.logout();
                              context.go(StudentRoutePaths.login);
                            },
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentProfileEdit {
  const _StudentProfileEdit({
    required this.fullName,
    required this.nim,
    required this.email,
    required this.phoneNumber,
  });

  final String fullName;
  final String nim;
  final String email;
  final String phoneNumber;
}

class _EditStudentProfileDialog extends StatefulWidget {
  const _EditStudentProfileDialog({
    required this.fullName,
    required this.nim,
    required this.email,
    required this.phoneNumber,
  });

  final String fullName;
  final String nim;
  final String email;
  final String phoneNumber;

  @override
  State<_EditStudentProfileDialog> createState() =>
      _EditStudentProfileDialogState();
}

class _EditStudentProfileDialogState extends State<_EditStudentProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _nimController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneNumberController;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.fullName);
    _nimController = TextEditingController(text: widget.nim);
    _emailController = TextEditingController(text: widget.email);
    _phoneNumberController = TextEditingController(text: widget.phoneNumber);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _nimController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      _StudentProfileEdit(
        fullName: _fullNameController.text.trim(),
        nim: _nimController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneNumberController.text.trim(),
      ),
    );
  }

  String? _requiredField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Bagian ini wajib diisi.';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email wajib diisi.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Format email tidak valid.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ubah Profil'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const ValueKey('edit-profile-name'),
                controller: _fullNameController,
                decoration: const InputDecoration(labelText: 'Nama'),
                textCapitalization: TextCapitalization.words,
                validator: _requiredField,
              ),
              TextFormField(
                key: const ValueKey('edit-profile-nim'),
                controller: _nimController,
                decoration: const InputDecoration(labelText: 'NIM/NIDN'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: _requiredField,
              ),
              TextFormField(
                key: const ValueKey('edit-profile-phone'),
                controller: _phoneNumberController,
                decoration: const InputDecoration(labelText: 'Nomor HP'),
                keyboardType: TextInputType.phone,
                validator: _requiredField,
              ),
              TextFormField(
                key: const ValueKey('edit-profile-email'),
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(onPressed: _save, child: const Text('Simpan')),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// Info Row widget
// ─────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.colorScheme,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final ColorScheme colorScheme;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, isLast ? 14 : 14, 16, isLast ? 14 : 14),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.onSurfaceVariant, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Action Row widget
// ─────────────────────────────────────────────────────────
class _ActionRow extends StatelessWidget {
  const _ActionRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.colorScheme,
    required this.onTap,
    this.labelColor,
    this.showChevron = true,
    this.isLast = false,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final Color? labelColor;
  final ColorScheme colorScheme;
  final VoidCallback onTap;
  final bool showChevron;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: isLast ? Radius.zero : Radius.zero,
        bottom: isLast ? const Radius.circular(14) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: labelColor ?? colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (showChevron)
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Divider helper
// ─────────────────────────────────────────────────────────
class _Divider extends StatelessWidget {
  const _Divider({required this.colorScheme});
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: colorScheme.outlineVariant,
      indent: 16,
      endIndent: 16,
    );
  }
}
