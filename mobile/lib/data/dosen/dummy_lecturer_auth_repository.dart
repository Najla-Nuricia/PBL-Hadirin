import 'lecturer_account.dart';

class EmailAlreadyRegisteredException implements Exception {
  const EmailAlreadyRegisteredException(this.email);

  final String email;

  @override
  String toString() => 'EmailAlreadyRegisteredException: $email';
}

class WrongPasswordException implements Exception {
  const WrongPasswordException();

  @override
  String toString() => 'WrongPasswordException';
}

/// In-memory stand-in for the lecturer auth API until the backend is ready.
/// Registered accounts are lost when the app restarts.
class DummyLecturerAuthRepository {
  DummyLecturerAuthRepository({
    Iterable<LecturerAccount> seedAccounts = const [demoAccount],
    this.latency = const Duration(milliseconds: 600),
  }) : _accounts = {
         for (final account in seedAccounts) _key(account.email): account,
       };

  static const demoAccount = LecturerAccount(
    staffId: '1985061520121003',
    fullName: 'Dr. Andi Pratama, S.T., M.Kom.',
    email: 'dosen@hadirin.id',
    password: 'dosen123',
    phoneNumber: '0812 3456 7890',
  );

  final Duration latency;
  final Map<String, LecturerAccount> _accounts;

  static String _key(String email) => email.trim().toLowerCase();

  Future<LecturerAccount?> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(latency);
    final account = _accounts[_key(email)];
    if (account == null || account.password != password) return null;
    return account;
  }

  Future<bool> isEmailRegistered(String email) async {
    await Future<void>.delayed(latency);
    return _accounts.containsKey(_key(email));
  }

  Future<LecturerAccount> register(LecturerRegistrationDraft draft) async {
    await Future<void>.delayed(latency);
    final key = _key(draft.email);
    if (_accounts.containsKey(key)) {
      throw EmailAlreadyRegisteredException(draft.email);
    }

    final account = LecturerAccount(
      staffId: draft.staffId,
      fullName: draft.fullName,
      email: draft.email.trim(),
      password: draft.password,
    );
    _accounts[key] = account;
    return account;
  }

  Future<LecturerAccount> changePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    await Future<void>.delayed(latency);
    final key = _key(email);
    final account = _accounts[key];
    if (account == null || account.password != currentPassword) {
      throw const WrongPasswordException();
    }

    final updated = account.copyWith(password: newPassword);
    _accounts[key] = updated;
    return updated;
  }
}

final lecturerAuthRepository = DummyLecturerAuthRepository();
