import '../database/app_database.dart';
import '../database/tables/onboarding_profile_table.dart';
import '../models/onboarding_profile.dart';

class OnboardingService {
  // CREATE
  Future<void> createOnboardingProfile(OnboardingProfile profile) async {
    final database = await AppDatabase.database;

    await database.insert(OnboardingProfileTable.tableName, profile.toMap());
  }

  // READ
  Future<OnboardingProfile?> getOnboardingProfileByUserId(String userId) async {
    final database = await AppDatabase.database;

    final result = await database.query(
      OnboardingProfileTable.tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return OnboardingProfile.fromMap(result.first);
  }

  // UPDATE
  Future<void> updateOnboardingProfile(OnboardingProfile profile) async {
    final database = await AppDatabase.database;

    await database.update(
      OnboardingProfileTable.tableName,
      profile.toMap(),
      where: 'onboarding_profile_id = ?',
      whereArgs: [profile.onboardingProfileId],
    );
  }

  // DELETE
  Future<void> deleteOnboardingProfile(String onboardingProfileId) async {
    final database = await AppDatabase.database;

    await database.delete(
      OnboardingProfileTable.tableName,
      where: 'onboarding_profile_id = ?',
      whereArgs: [onboardingProfileId],
    );
  }
}
