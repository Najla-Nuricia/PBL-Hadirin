/**
 * Named locators / selectors per screen for the Hadirin QA suite.
 *
 * Login selectors use Android widget classes until explicit accessibility IDs
 * are available from the Flutter app.
 */

export const LOCATORS = {
  onboarding: {
    next: '~Next',
    mahasiswa: '~Mahasiswa',
    dosen: '~Dosen',
    admin: '~Login Sebagai Sekretaris Jurusan',
  },
  admin: {
    login: {
      title: '~Login Sekretaris Jurusan',
      usernameField: 'android=new UiSelector().className("android.widget.EditText").instance(0)',
      passwordField: 'android=new UiSelector().className("android.widget.EditText").instance(1)',
      submitButton: '~Masuk',
      errorSnackbar: '~Username atau password salah.',
    },
    dataAcademic: {
      title: 'Data Akademik',
    },
    dashboard: {
      title: 'android=new UiSelector().text("Data Akademik")',
    },
  },
  mahasiswa: {
    login: {
      title: '~Login Mahasiswa',
      nimField: 'android=new UiSelector().className("android.widget.EditText").instance(0)',
      passwordField: 'android=new UiSelector().className("android.widget.EditText").instance(1)',
      submitButton: '~Masuk',
      errorSnackbar: '~NIM atau password salah.',
      forgotPassword: 'Forgot password?',
    },
    register: {
      title: '~Registrasi Mahasiswa',
      fullNameField:
        'android=new UiSelector().className("android.widget.EditText").instance(0)',
      nimField:
        'android=new UiSelector().className("android.widget.EditText").instance(1)',
      classField:
        'android=new UiSelector().className("android.widget.EditText").instance(2)',
      passwordField:
        'android=new UiSelector().className("android.widget.EditText").instance(3)',
      confirmPasswordField:
        'android=new UiSelector().className("android.widget.EditText").instance(4)',
      submitButton: '~Lanjut ke Scan Wajah →',
      successSnackbar: '~Registrasi berhasil. Silakan login dengan NIM kamu.',
      duplicateNimSnackbar: '//*[contains(@content-desc,"NIM sudah terdaftar")]',
    },
  },
  dosen: {
    login: {
      title: '~Login Dosen',
      emailField: 'android=new UiSelector().className("android.widget.EditText").instance(0)',
      passwordField: 'android=new UiSelector().className("android.widget.EditText").instance(1)',
      submitButton: '~Masuk',
      errorSnackbar: '~Email atau password salah.',
    },
    register: {
      title: '~Registrasi Dosen',
      fullNameField:
        'android=new UiSelector().className("android.widget.EditText").instance(0)',
      staffIdField:
        'android=new UiSelector().className("android.widget.EditText").instance(1)',
      emailField:
        'android=new UiSelector().className("android.widget.EditText").instance(2)',
      passwordField:
        'android=new UiSelector().className("android.widget.EditText").instance(3)',
      confirmPasswordField:
        'android=new UiSelector().className("android.widget.EditText").instance(4)',
      submitButton: '~Daftar',
      successSnackbar: '~Registrasi dosen berhasil. Silakan login.',
    },
    attendance: {
      title: '~Cek Daftar Presensi',
      // Kotak tanggal berisi teks "Kamis, 13 November 2026"; instance(0)
      // adalah kotak tanggal, instance berikutnya adalah baris ringkasan.
      dateBox:
        'android=new UiSelector().descriptionMatches("(Senin|Selasa|Rabu|Kamis|Jumat|Sabtu|Minggu), .*").instance(0)',
      datePickerOk: '~OK',
      // Sel tanggal pada dialog DatePicker, mis. "15, May 15, 2024".
      datePickerDay: (day: number) =>
        `//*[starts-with(@content-desc,"${day}, ")]`,
      // DropdownButton (Kelas / Mata Kuliah): nilai terpilih lalu item menu.
      selectedOption: (value: string) =>
        `android=new UiSelector().description("${value}").instance(0)`,
      option: (value: string) => `//*[@content-desc="${value}"]`,
      showDataButton: '~Tampilkan Data',
      listTitle: '~Daftar Kehadiran',
      summary: '//*[contains(@content-desc,"Total Mahasiswa")]',
      statusChip: {
        hadir: '~Hadir',
        izin: '~Izin',
        sakit: '~Sakit',
        alfa: '~Alfa',
      },
    },
    navigation: {
      profileTab: '~Profil',
    },
    profile: {
      uploadPhoto: '~Ubah foto profil',
      changePhoto: '//*[contains(@text,"Ubah Foto Profil")]',
      changePassword: '//*[contains(@text,"Ubah Kata Sandi")]',
      logout: '//*[contains(@text,"Keluar")]',
    },
    changePassword: {
      currentPasswordField:
        'android=new UiSelector().className("android.widget.EditText").instance(0)',
      newPasswordField:
        'android=new UiSelector().className("android.widget.EditText").instance(1)',
      confirmationField:
        'android=new UiSelector().className("android.widget.EditText").instance(2)',
      submitButton: '~Simpan',
      successSnackbar: '//*[contains(@content-desc,"Kata sandi berhasil diperbarui")]',
    },
  },
} as const;
