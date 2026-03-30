// login_controller.dart
import 'dart:async';

class LoginResult {
  final bool success;
  final String message;
  final bool shouldLock;
  final bool isLocked;
  final Map<String, dynamic>? userData; // Tambahkan ini

  LoginResult({
    required this.success,
    required this.message,
    this.shouldLock = false,
    this.isLocked = false,
    this.userData, // User data saat login berhasil
  });
}

class LoginController {
  // Sumber data user dipusatkan di layer auth.
  static final List<Map<String, dynamic>> _userDatabase = [
    {
      'uid': 'user_001',
      'username': 'revan',
      'password': '12345',
      'teamId': 'team_001',
      'role': 'Ketua',
      'fullName': 'Revan Ramdani Permana',
    },
    {
      'uid': 'user_002',
      'username': 'phocita',
      'password': 'admin123',
      'teamId': 'team_001',
      'role': 'anggota',
      'fullName': 'Admin User',
    },
    {
      'uid': 'user_003',
      'username': 'denji',
      'password': 'pass123',
      'teamId': 'team_002', //
      'role': 'Anggota',
      'fullName': 'din',
    },
    {
      'uid': 'user_004',
      'username': 'asisten',
      'password': 'asisten123',
      'teamId': 'team_001',
      'role': 'Asisten',
      'fullName': 'Asisten Tim',
    },
    {
      'uid': 'user_005',
      'username': 'anggota2',
      'password': 'pass123',
      'teamId': 'team_001',
      'role': 'Anggota',
      'fullName': 'Anggota Dua',
    },
  ];

  int _failedAttempts = 0;
  bool _isLocked = false;
  int _lockSeconds = 10;

  bool get isLocked => _isLocked;
  int get failedAttempts => _failedAttempts;
  int get lockSeconds => _lockSeconds;

  /// Dipakai oleh fitur lain untuk menampilkan identitas user.
  static Map<String, String> getPublicUserInfo(String uid) {
    final user = _userDatabase.firstWhere(
      (u) => u['uid'] == uid,
      orElse: () => {'uid': uid, 'fullName': 'Unknown User', 'role': 'Unknown'},
    );

    return {
      'fullName': user['fullName'] as String,
      'role': user['role'] as String,
    };
  }

  LoginResult attemptLogin(String username, String password) {
    // Validasi 1: Empty fields
    if (username.isEmpty || password.isEmpty) {
      return LoginResult(
        success: false,
        message: "Username dan Password tidak boleh kosong!",
      );
    }

    // Validasi 2: Account locked
    if (_isLocked) {
      return LoginResult(
        success: false,
        message: "Akun terkunci. Silakan tunggu beberapa saat.",
        isLocked: true,
      );
    }

    // Validasi 3: Check credentials
    final user = _userDatabase.firstWhere(
      (u) => u['username'] == username && u['password'] == password,
      orElse: () => {},
    );

    if (user.isNotEmpty) {
      _failedAttempts = 0;

      // Return user data (tanpa password untuk keamanan)
      final userData = Map<String, dynamic>.from(user);
      userData.remove('password'); // Hapus password dari hasil

      return LoginResult(
        success: true,
        message: "Login berhasil!",
        userData: userData,
      );
    }

    // Login failed
    _failedAttempts++;

    if (_failedAttempts >= 3) {
      return LoginResult(
        success: false,
        message:
            "Akun terkunci selama $_lockSeconds detik karena terlalu banyak percobaan gagal.",
        shouldLock: true,
      );
    }

    return LoginResult(
      success: false,
      message: "Username atau Password salah! Percobaan: $_failedAttempts/3",
    );
  }

  void lockAccount(Function() onUnlock) {
    _isLocked = true;
    Timer(Duration(seconds: _lockSeconds), () {
      _isLocked = false;
      _failedAttempts = 0;
      onUnlock();
    });
  }
}
