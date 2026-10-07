import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/mhs/dummy_student_auth_repository.dart';
import 'package:mobile/data/mhs/student_account.dart';

void main() {
  const draft = StudentRegistrationDraft(
    fullName: 'Joni Mahasiswa',
    nim: '2341720099',
    className: '3F-TI',
    password: 'rahasia123',
  );

  late DummyStudentAuthRepository repository;

  setUp(() {
    repository = DummyStudentAuthRepository(latency: Duration.zero);
  });

  test('logs in the seeded demo account', () async {
    final account = await repository.login(
      nim: DummyStudentAuthRepository.demoAccount.nim,
      password: DummyStudentAuthRepository.demoAccount.password,
    );

    expect(account?.nim, DummyStudentAuthRepository.demoAccount.nim);
  });

  test('rejects an unknown NIM or a wrong password', () async {
    expect(
      await repository.login(nim: '0000000000', password: 'mahasiswa123'),
      isNull,
    );
    expect(
      await repository.login(
        nim: DummyStudentAuthRepository.demoAccount.nim,
        password: 'salah',
      ),
      isNull,
    );
  });

  test('registers a new account that can then log in', () async {
    expect(await repository.isNimRegistered(draft.nim), isFalse);

    final account = await repository.register(
      draft,
      facePhotoPaths: const ['depan.jpg', 'kiri.jpg'],
    );

    expect(account.facePhotoPaths, ['depan.jpg', 'kiri.jpg']);
    expect(await repository.isNimRegistered(draft.nim), isTrue);
    expect(
      (await repository.login(
        nim: draft.nim,
        password: draft.password,
      ))?.fullName,
      draft.fullName,
    );
  });

  test('refuses to register the same NIM twice', () async {
    await repository.register(draft, facePhotoPaths: const []);

    expect(
      () => repository.register(draft, facePhotoPaths: const []),
      throwsA(isA<NimAlreadyRegisteredException>()),
    );
  });
}
