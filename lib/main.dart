import 'package:flutter/material.dart';

import 'controllers/blocking_mode_session.dart';
import 'controllers/morning_routine_session.dart';
import 'controllers/night_routine_session.dart';
import 'database/app_database.dart';
import 'models/blocking_mode.dart';
import 'models/user.dart';
import 'screens/home/app_shell.dart';
import 'screens/login_screen.dart';
import 'services/session_store.dart';
import 'services/user_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppDatabase.database;

  runApp(
    const MyApp(),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({
    super.key,
  });

  @override
  State<MyApp> createState() =>
      _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final BlockingModeSession
      _focusTimerController;

  late final BlockingModeSession
      _readingSession;

  late final MorningRoutineSession
      _morningSession;

  late final NightRoutineSession
      _nightSession;

  final SessionStore _sessionStore = SessionStore();

  User? _currentUser;

  // True while the app checks whether someone was already logged in.
  bool _restoringLogin = true;

  @override
  void initState() {
    super.initState();

    _restoreLogin();

    final coordinator =
        BlockingSessionCoordinator();

    _focusTimerController =
        BlockingModeSession(
      mode: BlockingMode.focus,
      coordinator: coordinator,
    );

    _readingSession =
        BlockingModeSession(
      mode: BlockingMode.reading,
      coordinator: coordinator,
    );

    _morningSession =
        MorningRoutineSession();

    _nightSession =
        NightRoutineSession();
  }

  /// Looks for a login saved on this phone, so the user does not have to
  /// type the email and password again.
  Future<void> _restoreLogin() async {
    User? user;

    try {
      final userId = await _sessionStore.read();

      if (userId != null) {
        user = await UserService().getUserById(userId);

        // The saved user no longer exists: forget the login.
        if (user == null) {
          await _sessionStore.clear();
        }
      }
    } catch (error) {
      debugPrint('Could not restore the login: $error');
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _currentUser = user;
      _restoringLogin = false;
    });
  }

  void _handleLogin(User user) {
    // Remember the user on this phone.
    _sessionStore.save(user.userId);

    setState(() {
      _currentUser = user;
    });
  }

  void _handleLogout() {
    // Forget the user, so the login screen shows next time.
    _sessionStore.clear();

    setState(() {
      _currentUser = null;
    });
  }

  @override
  void dispose() {
    _focusTimerController.dispose();
    _readingSession.dispose();
    _morningSession.dispose();
    _nightSession.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rest For More',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,

      // No logged-in user:
      // Login is the first screen.
      home: _restoringLogin
          // Short moment while the saved login is checked.
          ? const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            )
          : _currentUser == null
          ? LoginScreen(
              onLogin: _handleLogin,
            )

          // Logged-in user:
          // Open the actual application (Today, Insights and Settings).
          : AppShell(
              user: _currentUser!,
              onLogout: _handleLogout,
              focusSession:
                  _focusTimerController,
              readingSession:
                  _readingSession,
              morningSession:
                  _morningSession,
              nightSession:
                  _nightSession,
            ),
    );
  }
}
