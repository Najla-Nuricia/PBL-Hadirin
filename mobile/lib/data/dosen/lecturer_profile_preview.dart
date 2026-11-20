import '../../models/dosen/lecturer_profile.dart';
import 'dummy_lecturer_auth_repository.dart';

/// Profil awal dosen sebelum data dari backend tersedia.
final LecturerProfile lecturerProfilePreview =
    DummyLecturerAuthRepository.demoAccount.toProfile();

/// Profil dosen yang sedang login (fallback ke preview saat mode demo).
LecturerProfile currentLecturerProfile() =>
    lecturerAuthRepository.currentAccount?.toProfile() ?? lecturerProfilePreview;
