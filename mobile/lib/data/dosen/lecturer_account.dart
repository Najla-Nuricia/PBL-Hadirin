import 'dart:typed_data';

import '../../models/dosen/lecturer_profile.dart';

class LecturerAccount {
  const LecturerAccount({
    required this.staffId,
    required this.fullName,
    required this.email,
    required this.password,
    this.phoneNumber = '-',
    this.role = 'Dosen',
    this.photoBytes,
    this.token,
  });

  final String staffId;
  final String fullName;
  final String email;
  final String password;
  final String phoneNumber;
  final String role;
  final Uint8List? photoBytes;
  final String? token;

  LecturerAccount copyWith({String? password, Uint8List? photoBytes}) {
    return LecturerAccount(
      staffId: staffId,
      fullName: fullName,
      email: email,
      password: password ?? this.password,
      phoneNumber: phoneNumber,
      role: role,
      photoBytes: photoBytes ?? this.photoBytes,
      token: token,
    );
  }

  LecturerProfile toProfile() {
    return LecturerProfile(
      fullName: fullName,
      staffId: staffId,
      email: email,
      phoneNumber: phoneNumber,
      role: role,
      photoBytes: photoBytes,
    );
  }
}

class LecturerRegistrationDraft {
  const LecturerRegistrationDraft({
    required this.fullName,
    required this.staffId,
    required this.email,
    required this.password,
  });

  final String fullName;
  final String staffId;
  final String email;
  final String password;
}
