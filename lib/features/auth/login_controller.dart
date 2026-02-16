// login_controller.dart
import 'dart:async';

// Result class untuk mengembalikan hasil login
class LoginResult {
  final bool success;
  final String message;
  final bool shouldLock;
  final bool isLocked;

  LoginResult({
    required this.success,
    required this.message,
    this.shouldLock = false,
    this.isLocked = false,
  });
}

class LoginController {
  // Database sederhana (Hardcoded)
  final Map<String, String> _userDatabase = {
    'revan': '12345',
    'admin': 'admin123',
    'user1': 'pass123',
  };
  int _failedAttempts = 0;
  bool _isLocked = false;
  int _lockSeconds = 10;

  bool get isLocked => _isLocked;
  int get failedAttempts => _failedAttempts;
  int get lockSeconds => _lockSeconds;

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
    if (_userDatabase.containsKey(username) &&
        _userDatabase[username] == password) {
      _failedAttempts = 0;
      return LoginResult(success: true, message: "Login berhasil!");
    }

    // Login failed
    _failedAttempts++;

    // Check if should lock after this attempt
    if (_failedAttempts >= 3) {
      return LoginResult(
        success: false,
        message:
            "Akun terkunci selama $_lockSeconds detik karena terlalu banyak percobaan gagal.",
        shouldLock: true,
      );
    }

    // Regular failed attempt
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
      onUnlock(); // Notify View to rebuild
    });
  }
}
