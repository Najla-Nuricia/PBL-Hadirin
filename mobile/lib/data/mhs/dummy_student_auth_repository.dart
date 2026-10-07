import 'student_account.dart';

class NimAlreadyRegisteredException implements Exception {
  const NimAlreadyRegisteredException(this.nim);

  final String nim;

  @override
  String toString() => 'NimAlreadyRegisteredException: $nim';
}

/// In-memory stand-in for the student auth API until the backend is ready.
/// Registered accounts are lost when the app restarts.
class DummyStudentAuthRepository {
  DummyStudentAuthRepository({
    Iterable<StudentAccount> seedAccounts = const [demoAccount],
    this.latency = const Duration(milliseconds: 600),
  }) : _accounts = {for (final account in seedAccounts) account.nim: account};

  static const demoAccount = StudentAccount(
    nim: '2341720001',
    fullName: 'Mahasiswa Demo',
    className: '3F-TI',
    password: 'mahasiswa123',
  );

  final Duration latency;
  final Map<String, StudentAccount> _accounts;

  Future<StudentAccount?> login({
    required String nim,
    required String password,
  }) async {
    await Future<void>.delayed(latency);
    final account = _accounts[nim];
    if (account == null || account.password != password) return null;
    return account;
  }

  Future<bool> isNimRegistered(String nim) async {
    await Future<void>.delayed(latency);
    return _accounts.containsKey(nim);
  }

  Future<StudentAccount> register(
    StudentRegistrationDraft draft, {
    required List<String> facePhotoPaths,
  }) async {
    await Future<void>.delayed(latency);
    if (_accounts.containsKey(draft.nim)) {
      throw NimAlreadyRegisteredException(draft.nim);
    }

    final account = StudentAccount(
      nim: draft.nim,
      fullName: draft.fullName,
      className: draft.className,
      password: draft.password,
      facePhotoPaths: List.unmodifiable(facePhotoPaths),
    );
    _accounts[account.nim] = account;
    return account;
  }
}

final studentAuthRepository = DummyStudentAuthRepository();
