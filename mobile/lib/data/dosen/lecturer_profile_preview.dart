import '../../models/dosen/lecturer_profile.dart';
import 'dummy_lecturer_auth_repository.dart';

/// Profil awal dosen sebelum data dari backend tersedia.
final LecturerProfile lecturerProfilePreview =
    DummyLecturerAuthRepository.demoAccount.toProfile();
