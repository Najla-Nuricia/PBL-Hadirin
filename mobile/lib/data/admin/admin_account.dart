/// Profil admin hasil autentikasi backend Hadirin.
class AdminAccount {
  const AdminAccount({
    required this.username,
    required this.name,
    required this.role,
    this.token,
    this.expiresIn,
  });

  final String username;
  final String name;
  final String role;
  final String? token;
  final int? expiresIn;

  bool get isAdmin => role.toLowerCase() == 'admin';
}
