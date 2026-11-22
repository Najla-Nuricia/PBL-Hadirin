import 'dart:typed_data';

class LecturerProfile {
  const LecturerProfile({
    required this.fullName,
    required this.staffId,
    required this.email,
    required this.phoneNumber,
    required this.role,
    this.photoBytes,
  });

  final String fullName;
  final String staffId;
  final String email;
  final String phoneNumber;
  final String role;
  final Uint8List? photoBytes;

  /// Profil dosen dari respons login/dashboard backend.
  factory LecturerProfile.fromJson(Map<String, dynamic> json) {
    return LecturerProfile(
      fullName: (json['fullName'] as String?) ?? '',
      staffId: (json['staffId'] as String?) ?? (json['nip'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      phoneNumber: (json['phoneNumber'] as String?) ?? '',
      role: (json['role'] as String?) ?? 'Dosen',
    );
  }

  LecturerProfile copyWith({Uint8List? photoBytes}) {
    return LecturerProfile(
      fullName: fullName,
      staffId: staffId,
      email: email,
      phoneNumber: phoneNumber,
      role: role,
      photoBytes: photoBytes ?? this.photoBytes,
    );
  }
}
