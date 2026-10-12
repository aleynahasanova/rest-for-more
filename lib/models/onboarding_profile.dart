class OnboardingProfile {
  final String onboardingProfileId;
  final String userId;
  final String? ageGroup;
  final String? mainGoal;
  final String? biggestChallenge;
  final String? phoneUseInBed;
  final int? phoneFreeTargetMinutes;
  final String? reminderTime;

  final String? rhythm;
  final String? restMoments;
  final String? feasibleStep;
  final String? preferredActivity;
  final String? customActivity;
  final String? productOwnership;
  final int? onboardingStep;

  final String productExpectation;
  final String? productIssue;
  final bool wantsSupport;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const OnboardingProfile({
    required this.onboardingProfileId,
    required this.userId,
    this.ageGroup,
    this.mainGoal,
    this.biggestChallenge,
    this.phoneUseInBed,
    this.phoneFreeTargetMinutes,
    this.reminderTime,
    this.rhythm,
    this.restMoments,
    this.feasibleStep,
    this.preferredActivity,
    this.customActivity,
    this.productOwnership,
    this.onboardingStep,
    this.productExpectation = 'UNKNOWN',
    this.productIssue,
    this.wantsSupport = false,
    this.completedAt,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, Object?> toMap() {
    return {
      'onboarding_profile_id': onboardingProfileId,
      'user_id': userId,
      'age_group': ageGroup,
      'main_goal': mainGoal,
      'biggest_challenge': biggestChallenge,
      'phone_use_in_bed': phoneUseInBed,
      'phone_free_target_minutes': phoneFreeTargetMinutes,
      'reminder_time': reminderTime,
      'rhythm': rhythm,
      'rest_moments': restMoments,
      'feasible_step': feasibleStep,
      'preferred_activity': preferredActivity,
      'custom_activity': customActivity,
      'product_ownership': productOwnership,
      'onboarding_step': onboardingStep,
      'product_expectation': productExpectation,
      'product_issue': productIssue,
      'wants_support': wantsSupport ? 1 : 0,
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory OnboardingProfile.fromMap(Map<String, Object?> map) {
    return OnboardingProfile(
      onboardingProfileId: map['onboarding_profile_id'] as String,
      userId: map['user_id'] as String,
      ageGroup: map['age_group'] as String?,
      mainGoal: map['main_goal'] as String?,
      biggestChallenge: map['biggest_challenge'] as String?,
      phoneUseInBed: map['phone_use_in_bed'] as String?,
      phoneFreeTargetMinutes: map['phone_free_target_minutes'] as int?,
      reminderTime: map['reminder_time'] as String?,
      rhythm: map['rhythm'] as String?,
      restMoments: map['rest_moments'] as String?,
      feasibleStep: map['feasible_step'] as String?,
      preferredActivity: map['preferred_activity'] as String?,
      customActivity: map['custom_activity'] as String?,
      productOwnership: map['product_ownership'] as String?,
      onboardingStep: map['onboarding_step'] as int?,
      productExpectation: map['product_expectation'] as String,
      productIssue: map['product_issue'] as String?,
      wantsSupport: (map['wants_support'] as int) == 1,
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }
}
