import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/mhs/dummy_student_auth_repository.dart';

void main() {
  test('DummyStudentAuthRepository connects to live backend API and authenticates', () async {
    final repo = DummyStudentAuthRepository(useRemoteApi: true);

    // Login with valid credentials
    final account = await repo.login(
      nim: '2341720001',
      password: 'mahasiswa123',
    );

    expect(account, isNotNull);
    expect(account?.nim, '2341720001');
    expect(account?.fullName, 'Mahasiswa Demo');
    expect(account?.token, isNotNull);
    expect(account?.token?.startsWith('jwt_'), isTrue);

    // Login with wrong credentials
    final failedAccount = await repo.login(
      nim: '2341720001',
      password: 'salah_password',
    );
    expect(failedAccount, isNull);
  });
}
