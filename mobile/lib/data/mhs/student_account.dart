class StudentAccount {
  const StudentAccount({
    required this.nim,
    required this.fullName,
    required this.className,
    required this.password,
    this.facePhotoPaths = const [],
    this.token,
  });

  final String nim;
  final String fullName;
  final String className;
  final String password;
  final List<String> facePhotoPaths;
  final String? token;
}

class StudentRegistrationDraft {
  const StudentRegistrationDraft({
    required this.fullName,
    required this.nim,
    required this.className,
    required this.password,
  });

  final String fullName;
  final String nim;
  final String className;
  final String password;
}
