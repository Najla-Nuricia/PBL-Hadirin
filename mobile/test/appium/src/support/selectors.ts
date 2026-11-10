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
      duplicateNimSnackbar:
        'android=new UiSelector().textContains("sudah terdaftar. Silakan login.")',
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
      title: 'Registrasi Dosen',
    },
  },
} as const;
