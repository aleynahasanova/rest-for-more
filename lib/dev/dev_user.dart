import '../models/user.dart';
import '../services/user_service.dart';

/// TEMPORARY: lets onboarding and the 14-day programme be built and tested
/// before login/sign up is connected.
///
/// onboarding_profiles.user_id is a foreign key to users, so a users row must
/// exist before a profile can be saved. This creates a placeholder one.
///
/// Delete this file, and its call sites, once the real login flow provides
/// the userId.
abstract final class DevUser {
  static const String userId = 'dev-user';

  /// Creates the placeholder user if it doesn't exist yet and returns its id.
  static Future<String> ensure() async {
    final userService = UserService();

    final existing = await userService.getUserById(userId);

    if (existing == null) {
      await userService.createUser(
        User(
          userId: userId,
          email: 'dev@restformore.local',
          passwordHash: 'dev-only-not-a-real-hash',
          firstName: 'Dev',
          username: 'dev-user',
          createdAt: DateTime.now(),
        ),
      );
    }

    return userId;
  }
}
