import '../../models/onboarding_options.dart';
import '../../models/onboarding_profile.dart';

/// One choice in a question. [value] is what gets saved in the database,
/// [label] is what the user reads.
class OnboardingOption {
  const OnboardingOption(this.value, this.label);

  final String value;
  final String label;
}

/// One onboarding question. The flow screen is generic: to change or add a
/// question, only this file needs to change.
class OnboardingQuestion {
  const OnboardingQuestion({
    required this.title,
    this.subtitle,
    required this.options,
    required this.readAnswer,
    required this.writeAnswer,
  });

  final String title;
  final String? subtitle;
  final List<OnboardingOption> options;

  /// Gets the saved answer from the profile (null = not answered yet).
  final String? Function(OnboardingProfile profile) readAnswer;

  /// Returns a copy of the profile with the new answer filled in.
  final OnboardingProfile Function(OnboardingProfile profile, String value)
      writeAnswer;
}

// The order here is the order the user sees the questions (App design, Flow A).
//
// Not built yet: rest time for each day, the "my own" choices (own phone-away
// minutes, own step size, own activity) and the reminder time.
final List<OnboardingQuestion> onboardingQuestions = [
  OnboardingQuestion(
    title: 'How old are you?',
    subtitle: "Pick the group that fits. We don't ask for your date of birth.",
    options: [
      OnboardingOption(AgeBand.under16.name, 'Under 16'),
      OnboardingOption(AgeBand.age16to17.name, '16 to 17'),
      OnboardingOption(AgeBand.age18to24.name, '18 to 24'),
      OnboardingOption(AgeBand.age25to34.name, '25 to 34'),
      OnboardingOption(AgeBand.age35to49.name, '35 to 49'),
      OnboardingOption(AgeBand.age50plus.name, '50 or older'),
    ],
    readAnswer: (profile) => profile.ageGroup,
    writeAnswer: (profile, value) => profile.copyWith(ageGroup: value),
  ),
  OnboardingQuestion(
    title: 'What do you want most?',
    subtitle: 'You can change this later.',
    options: [
      OnboardingOption(
        PrimaryGoal.phoneAwayEarlier.name,
        'Put my phone away earlier',
      ),
      OnboardingOption(PrimaryGoal.buildRoutine.name, 'Build a routine'),
      OnboardingOption(
        PrimaryGoal.useLessSocialMedia.name,
        'Use less social media',
      ),
    ],
    readAnswer: (profile) => profile.mainGoal,
    writeAnswer: (profile, value) => profile.copyWith(mainGoal: value),
  ),
  OnboardingQuestion(
    title: 'What makes it hardest?',
    subtitle: 'Pick the one that is true most often.',
    options: [
      OnboardingOption(Obstacle.scrolling.name, 'I keep scrolling'),
      OnboardingOption(
        Obstacle.availability.name,
        'I feel I must always be available',
      ),
      OnboardingOption(
        Obstacle.restlessThoughts.name,
        'My thoughts keep running',
      ),
      OnboardingOption(Obstacle.planning.name, 'I find it hard to plan'),
      OnboardingOption(Obstacle.phoneAsAlarm.name, 'My phone is my alarm'),
      OnboardingOption(Obstacle.noRoutine.name, "I don't have a routine yet"),
    ],
    readAnswer: (profile) => profile.biggestChallenge,
    writeAnswer: (profile, value) =>
        profile.copyWith(biggestChallenge: value),
  ),
  OnboardingQuestion(
    title: 'What does your day look like?',
    options: [
      OnboardingOption(Rhythm.regular.name, 'About the same every day'),
      OnboardingOption(Rhythm.variable.name, 'It changes from day to day'),
      OnboardingOption(Rhythm.shifts.name, 'I work shifts'),
    ],
    readAnswer: (profile) => profile.rhythm,
    writeAnswer: (profile, value) => profile.copyWith(rhythm: value),
  ),
  OnboardingQuestion(
    title: 'How long do you want your phone away?',
    subtitle: 'This is your own goal, not a medical rule.',
    options: [
      OnboardingOption('15', '15 minutes'),
      OnboardingOption('30', '30 minutes'),
      OnboardingOption('45', '45 minutes'),
      OnboardingOption('60', '60 minutes'),
    ],
    readAnswer: (profile) => profile.phoneFreeTargetMinutes?.toString(),
    writeAnswer: (profile, value) =>
        profile.copyWith(phoneFreeTargetMinutes: int.parse(value)),
  ),
  OnboardingQuestion(
    title: 'How big should each daily step be?',
    options: [
      OnboardingOption(FeasibleStep.short.name, 'Small and quick'),
      OnboardingOption(FeasibleStep.standard.name, 'Normal'),
    ],
    readAnswer: (profile) => profile.feasibleStep,
    writeAnswer: (profile, value) => profile.copyWith(feasibleStep: value),
  ),
  OnboardingQuestion(
    title: 'What would you like to do instead?',
    subtitle: 'This is what you do after you put your phone away.',
    options: [
      OnboardingOption(PreferredActivity.reading.name, 'Read something'),
      OnboardingOption(
        PreferredActivity.preparation.name,
        'Get ready for tomorrow',
      ),
      OnboardingOption(PreferredActivity.quietSitting.name, 'Sit quietly'),
    ],
    readAnswer: (profile) => profile.preferredActivity,
    writeAnswer: (profile, value) =>
        profile.copyWith(preferredActivity: value),
  ),
];