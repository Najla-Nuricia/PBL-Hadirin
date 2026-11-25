import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../data/mhs/dummy_student_auth_repository.dart';
import '../../data/mhs/student_account.dart';
import '../../data/mhs/student_data_service.dart';
import '../../routing/student_route_paths.dart';
import '../../widgets/widgets.dart';

const _notFilled = 'Belum diisi';

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
  late String _className;
  String _email = '';
  late String _phoneNumber;
  bool _isLoadingLiveProfile = false;
  bool _liveProfileFailed = false;

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
    _className = widget.account.className;
    _email = '';
    _phoneNumber = _notFilled;
  }

  Future<void> _loadLiveProfile() async {
    if (!studentAuthRepository.hasRemoteSession) return;
    // Tanpa setState: pemanggilnya (initState, didUpdateWidget, atau
    // _retryLiveProfile) selalu diikuti build.
    _isLoadingLiveProfile = true;
    _liveProfileFailed = false;
    try {
      final profile = await studentDataService.loadProfile();
      if (!mounted) return;
      setState(() {
        _fullName = profile.fullName.isNotEmpty ? profile.fullName : _fullName;
        _nim = profile.studentId.isNotEmpty ? profile.studentId : _nim;
        _className = profile.className.isNotEmpty
            ? profile.className
            : _className;
        _email = profile.email;
        _phoneNumber = profile.phoneNumber.trim().isEmpty
            ? _notFilled
            : profile.phoneNumber;
        _isLoadingLiveProfile = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingLiveProfile = false;
        _liveProfileFailed = true;
      });
    }
  }

  void _retryLiveProfile() {
    setState(() {
      _loadLiveProfile();
    });
  }

  Future<void> _editProfile() async {
    final updatedProfile = await showDialog<_StudentProfileEdit>(
      context: context,
      builder: (context) => _EditStudentProfileDialog(
        fullName: _fullName,
        nim: _nim,
        email: _email,
        phoneNumber: _phoneNumber == _notFilled ? '' : _phoneNumber,
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
              ? _notFilled
              : saved.phoneNumber;
        });
        studentAuthRepository.updateProfile(fullName: saved.fullName);
        _showMessage('Profil berhasil diperbarui.');
      } catch (error) {
        if (!mounted) return;
        _showMessage(_saveErrorMessage(error));
      }
      return;
    }

    setState(() {
      _fullName = updatedProfile.fullName;
      _nim = updatedProfile.nim;
      _email = updatedProfile.email;
      _phoneNumber = updatedProfile.phoneNumber;
    });
    studentAuthRepository.updateProfile(fullName: updatedProfile.fullName);
    _showMessage('Profil berhasil diperbarui.');
  }

  /// Pesan yang sengaja dilempar layanan (`Exception('...')`) ditampilkan tanpa
  /// awalan teknisnya; galat lain diganti kalimat yang bisa ditindaklanjuti.
  String _saveErrorMessage(Object error) {
    if (error is RemoteApiException) return error.message;
    const prefix = 'Exception: ';
    final raw = error.toString();
    if (raw.startsWith(prefix) && raw.length > prefix.length) {
      return raw.substring(prefix.length);
    }
    return 'Profil belum bisa disimpan. Periksa koneksi internet, lalu coba '
        'lagi.';
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
    } on PlatformException {
      if (!mounted) return;
      _showMessage('Gagal memilih foto profil. Coba lagi.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _logout() {
    studentAuthRepository.logout();
    context.go(StudentRoutePaths.login);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: SkyAppBar(
        title: const Text('Profil'),
        titleSpacing: AppSpacing.page,
      ),
      body: AuroraBackground(
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.md,
              AppSpacing.page,
              AppSpacing.xxl,
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSizes.contentMaxWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_liveProfileFailed) ...[
                      AppBanner(
                        tone: StatusTone.warning,
                        message:
                            'Profil terbaru belum bisa dimuat. Menampilkan data '
                            'tersimpan.',
                        action: TextButton(
                          onPressed: _retryLiveProfile,
                          style: TextButton.styleFrom(
                            foregroundColor: StatusTone.warning.ink,
                            padding: EdgeInsets.zero,
                            alignment: Alignment.centerLeft,
                          ),
                          child: const Text('Coba lagi'),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    _ProfileHeader(
                      fullName: _fullName,
                      identity: _className.isEmpty
                          ? _nim
                          : '$_nim · $_className',
                      photo: _profilePhoto,
                      onPickPhoto: _pickProfilePhoto,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppSectionHeader(
                      title: 'Informasi Akun',
                      action: TextButton(
                        onPressed: _editProfile,
                        child: const Text('Ubah Profil'),
                      ),
                    ),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.xs,
                        ),
                        child: Column(
                          children: [
                            _InfoRow(
                              label: 'NIM',
                              value: _nim,
                              isNumeric: true,
                            ),
                            const Divider(),
                            _InfoRow(
                              label: 'Email',
                              value: _email.isEmpty ? _notFilled : _email,
                              isLoading: _isLoadingLiveProfile,
                            ),
                            const Divider(),
                            _InfoRow(
                              label: 'Nomor HP',
                              value: _phoneNumber,
                              isNumeric: true,
                              isLoading: _isLoadingLiveProfile,
                            ),
                            const Divider(),
                            const _InfoRow(
                              label: 'Peran',
                              value: 'Mahasiswa',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Card(
                      child: ListTile(
                        key: const ValueKey('profile-change-password'),
                        leading: Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            color: AppColors.brand50,
                            borderRadius: AppRadius.control,
                          ),
                          child: const Icon(
                            PhosphorIconsRegular.lock,
                            size: 19,
                            color: AppColors.brand700,
                          ),
                        ),
                        title: Text(
                          'Ubah Kata Sandi',
                          style: text.titleSmall,
                        ),
                        trailing: const Icon(
                          PhosphorIconsRegular.caretRight,
                          color: AppColors.inkFaint,
                        ),
                        onTap: () =>
                            context.push(StudentRoutePaths.changePassword),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    OutlinedButton.icon(
                      onPressed: _logout,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.error,
                        backgroundColor: Colors.white.withValues(alpha: 0.6),
                        side: BorderSide(
                          color: colorScheme.error.withValues(alpha: 0.45),
                        ),
                      ),
                      icon: const Icon(PhosphorIconsRegular.signOut, size: 20),
                      label: const Text('Keluar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.fullName,
    required this.identity,
    required this.photo,
    required this.onPickPhoto,
  });

  final String fullName;

  /// NIM, diikuti kelas bila ada.
  final String identity;
  final Uint8List? photo;
  final VoidCallback onPickPhoto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: AppRadius.hero,
        boxShadow: AppColors.shadowLifted,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.45),
                width: 2,
              ),
            ),
            child: ExcludeSemantics(
              child: _ProfileAvatar(fullName: fullName, photo: photo),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  identity,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyMedium?.tabular.copyWith(
                    color: AppColors.onBrandMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            onPressed: onPickPhoto,
            tooltip: 'Ubah foto profil',
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.14),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(PhosphorIconsRegular.camera),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.fullName, required this.photo});

  static const double _size = 64;

  final String fullName;
  final Uint8List? photo;

  String get _initials => fullName
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .take(2)
      .map((word) => word.characters.first.toUpperCase())
      .join();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final initials = _initials;
    final fallback = ColoredBox(
      color: AppColors.brand100,
      child: Center(
        child: initials.isEmpty
            ? const Icon(
                PhosphorIconsRegular.userCircle,
                size: 28,
                color: AppColors.brand800,
              )
            : Text(
                initials,
                // Avatar berukuran tetap, jadi inisialnya tidak ikut membesar.
                textScaler: TextScaler.noScaling,
                style: text.titleLarge?.copyWith(color: AppColors.brand800),
              ),
      ),
    );

    return ClipOval(
      child: SizedBox.square(
        dimension: _size,
        child: photo == null
            ? fallback
            : Image.memory(
                photo!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => fallback,
              ),
      ),
    );
  }
}

/// Satu baris Informasi Akun. Angka memakai digit selebar sama, nilai yang
/// belum diisi tampil lebih redup, dan nilai yang sedang dimuat berupa kerangka.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.isNumeric = false,
    this.isLoading = false,
  });

  final String label;
  final String value;
  final bool isNumeric;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;

    if (isLoading) {
      return AppKeyValueRow(
        label: label,
        trailing: Semantics(
          label: 'Memuat',
          child: const AppSkeleton(width: 96, height: 20),
        ),
      );
    }

    final style = value == _notFilled
        ? text.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)
        : isNumeric
        ? text.titleSmall?.tabular
        : text.titleSmall;
    return AppKeyValueRow(
      label: label,
      trailing: Text(value, textAlign: TextAlign.right, style: style),
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
    final text = Theme.of(context).textTheme;

    return AlertDialog(
      title: const Text('Ubah Profil'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.lg,
            children: [
              _DialogField(
                label: 'Nama',
                child: TextFormField(
                  key: const ValueKey('edit-profile-name'),
                  controller: _fullNameController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: _requiredField,
                ),
              ),
              _DialogField(
                label: 'NIM',
                child: TextFormField(
                  key: const ValueKey('edit-profile-nim'),
                  controller: _nimController,
                  style: text.bodyLarge?.tabular,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: _requiredField,
                ),
              ),
              _DialogField(
                label: 'Nomor HP',
                child: TextFormField(
                  key: const ValueKey('edit-profile-phone'),
                  controller: _phoneNumberController,
                  style: text.bodyLarge?.tabular,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  validator: _requiredField,
                ),
              ),
              _DialogField(
                label: 'Email',
                child: TextFormField(
                  key: const ValueKey('edit-profile-email'),
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _save(),
                  validator: _validateEmail,
                ),
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

/// Label di atas kolom isian, sama seperti formulir lain.
class _DialogField extends StatelessWidget {
  const _DialogField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
