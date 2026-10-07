class FakeAuthService {
  FakeAuthService._();

  // Fake accounts stored only while the app is running.
  static final Map<String, String> _accounts = {
    'demo@restformore.app': 'Demo1234',
  };

  static String _normalizeEmail(String email) {
    return email.trim().toLowerCase();
  }

  static bool emailExists(String email) {
    return _accounts.containsKey(_normalizeEmail(email));
  }

  static bool register({
    required String email,
    required String password,
  }) {
    final normalizedEmail = _normalizeEmail(email);

    if (_accounts.containsKey(normalizedEmail)) {
      return false;
    }

    _accounts[normalizedEmail] = password;
    return true;
  }

  // We will use this when we create the login screen.
  static bool canLogin({
    required String email,
    required String password,
  }) {
    final normalizedEmail = _normalizeEmail(email);

    return _accounts[normalizedEmail] == password;
  }
}