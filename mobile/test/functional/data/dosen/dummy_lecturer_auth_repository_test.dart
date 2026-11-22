import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/dosen/dummy_lecturer_auth_repository.dart';
import 'package:mobile/data/dosen/lecturer_account.dart';

void main() {
  const draft = LecturerRegistrationDraft(
    fullName: 'Dra. Siti Rahmawati, M.Pd.',
    staffId: '1987012020150420',
    email: 'siti.rahmawati@univ.ac.id',
    password: 'rahasia123',
  );

  late DummyLecturerAuthRepository repository;

  setUp(() {
    repository = DummyLecturerAuthRepository(latency: Duration.zero);
  });

  test('logs in the seeded demo account', () async {
    final account = await repository.login(
      email: DummyLecturerAuthRepository.demoAccount.email,
      password: DummyLecturerAuthRepository.demoAccount.password,
    );

    expect(account?.email, DummyLecturerAuthRepository.demoAccount.email);
    expect(account?.staffId, DummyLecturerAuthRepository.demoAccount.staffId);
  });

  test('email matching ignores surrounding spaces and casing', () async {
    final account = await repository.login(
      email: '  Dosen@Hadirin.ID ',
      password: DummyLecturerAuthRepository.demoAccount.password,
    );

    expect(account, isNotNull);
  });

  test('rejects an unknown email or a wrong password', () async {
    expect(
      await repository.login(email: 'tidak@ada.id', password: 'dosen123'),
      isNull,
    );
    expect(
      await repository.login(
        email: DummyLecturerAuthRepository.demoAccount.email,
        password: 'salah',
      ),
      isNull,
    );
  });

  test('registers a new account that can then log in', () async {
    expect(await repository.isEmailRegistered(draft.email), isFalse);

    final account = await repository.register(draft);

    expect(account.fullName, draft.fullName);
    expect(account.staffId, draft.staffId);
    expect(account.role, 'Dosen');
    expect(await repository.isEmailRegistered(draft.email), isTrue);
    expect(
      (await repository.login(
        email: draft.email,
        password: draft.password,
      ))?.fullName,
      draft.fullName,
    );
  });

  test('refuses to register the same email twice', () async {
    await repository.register(draft);

    expect(
      () => repository.register(draft),
      throwsA(isA<EmailAlreadyRegisteredException>()),
    );
  });

  test('changes the password and invalidates the old one', () async {
    await repository.changePassword(
      email: DummyLecturerAuthRepository.demoAccount.email,
      currentPassword: DummyLecturerAuthRepository.demoAccount.password,
      newPassword: 'sandiBaru99',
    );

    expect(
      await repository.login(
        email: DummyLecturerAuthRepository.demoAccount.email,
        password: DummyLecturerAuthRepository.demoAccount.password,
      ),
      isNull,
    );
    expect(
      await repository.login(
        email: DummyLecturerAuthRepository.demoAccount.email,
        password: 'sandiBaru99',
      ),
      isNotNull,
    );
  });

  test('change password throws when the current password is wrong', () async {
    expect(
      () => repository.changePassword(
        email: DummyLecturerAuthRepository.demoAccount.email,
        currentPassword: 'salah',
        newPassword: 'sandiBaru99',
      ),
      throwsA(isA<WrongPasswordException>()),
    );
  });
}
