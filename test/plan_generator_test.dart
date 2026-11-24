import 'package:flutter_test/flutter_test.dart';

import '../lib/models/onboarding_options.dart';
import '../lib/models/onboarding_profile.dart';
import '../lib/models/program_day.dart';
import '../lib/services/plan_generator.dart';

OnboardingProfile profile({
  PrimaryGoal goal = PrimaryGoal.phoneAwayEarlier,
  Obstacle obstacle = Obstacle.scrolling,
  Rhythm rhythm = Rhythm.regular,
  int? minutes = 30,
  FeasibleStep step = FeasibleStep.short,
  PreferredActivity activity = PreferredActivity.reading,
}) {
  return OnboardingProfile(
    onboardingProfileId: 'test-profile',
    userId: 'test-user',
    mainGoal: goal == PrimaryGoal.unknown ? null : goal.name,
    biggestChallenge: obstacle == Obstacle.unknown ? null : obstacle.name,
    rhythm: rhythm == Rhythm.unknown ? null : rhythm.name,
    phoneFreeTargetMinutes: minutes,
    feasibleStep: step == FeasibleStep.unknown ? null : step.name,
    preferredActivity:
        activity == PreferredActivity.unknown ? null : activity.name,
    createdAt: DateTime(2026, 10, 19),
  );
}

void main() {
  const generator = PlanGenerator();

  List<ProgramDay> makePlan(OnboardingProfile p) {
    var counter = 0;

    return generator.generate(
      p,
      programId: 'program-1',
      startDate: DateTime(2026, 10, 19),
      timeZoneId: 'Europe/Amsterdam',
      now: DateTime(2026, 10, 19, 12),
      newId: () => 'day-id-${counter++}',
    );
  }

  test('makes 14 days in order with one date per day', () {
    final plan = makePlan(profile());

    expect(plan.length, 14);
    expect([for (final d in plan) d.dayNumber], [for (var i = 1; i <= 14; i++) i]);
    expect(plan.first.scheduledDate, '2026-10-19');
    expect(plan[12].scheduledDate, '2026-10-31');
    // Day 14 falls in the next month: the date must roll over correctly.
    expect(plan.last.scheduledDate, '2026-11-01');
    expect(plan.every((d) => d.programId == 'program-1'), isTrue);
    expect({for (final d in plan) d.programDayId}.length, 14);
  });

  test('at least 10 of 14 days serve the main goal, days 7 and 14 are reviews', () {
    final plan = makePlan(profile());

    expect(plan.where((d) => d.supportsPrimaryGoal).length, greaterThanOrEqualTo(10));
    expect(plan[6].isReviewDay, isTrue);
    expect(plan[13].isReviewDay, isTrue);
  });

  test('every day has text in every part, for every goal, challenge and rhythm', () {
    for (final goal in PrimaryGoal.values) {
      for (final obstacle in Obstacle.values) {
        for (final rhythm in Rhythm.values) {
          final plan = makePlan(
            profile(goal: goal, obstacle: obstacle, rhythm: rhythm),
          );

          for (final day in plan) {
            expect(day.title.trim(), isNotEmpty);
            expect(day.body.trim(), isNotEmpty);
            expect(day.primaryAction.trim(), isNotEmpty);
            expect(day.smallerAlternative.trim(), isNotEmpty);
            expect(day.whyThisStep.trim(), isNotEmpty);
          }
        }
      }
    }
  });

  test('works when nothing was answered (neutral defaults)', () {
    final plan = makePlan(
      profile(
        goal: PrimaryGoal.unknown,
        obstacle: Obstacle.unknown,
        rhythm: Rhythm.unknown,
        minutes: null,
        step: FeasibleStep.unknown,
        activity: PreferredActivity.unknown,
      ),
    );

    expect(plan.length, 14);
    expect(plan[2].primaryAction, contains('5 minutes'));
  });

  test('the step grows from the start to the target and never goes down', () {
    final plan = makePlan(profile(minutes: 60, step: FeasibleStep.standard));
    final minutes = [
      for (final index in [2, 5, 8, 11, 12])
        int.parse(
          RegExp(r'(\d+) minutes').firstMatch(plan[index].primaryAction)!.group(1)!,
        ),
    ];

    expect(minutes.first, 10);
    expect(minutes.last, 60);
    for (var i = 1; i < minutes.length; i++) {
      expect(minutes[i], greaterThanOrEqualTo(minutes[i - 1]));
    }
  });

  test('the answers change the text', () {
    final reading = makePlan(profile(activity: PreferredActivity.reading));
    final sitting = makePlan(profile(activity: PreferredActivity.quietSitting));
    final shifts = makePlan(profile(rhythm: Rhythm.shifts));
    final social = makePlan(profile(goal: PrimaryGoal.useLessSocialMedia));

    expect(reading[3].primaryAction, contains('read'));
    expect(sitting[3].primaryAction, contains('sit quietly'));
    expect(shifts[2].primaryAction, contains('before you sleep'));
    expect(social[2].primaryAction, contains('social media'));
  });

  test('a day keeps all its parts when saved and read back from the database', () {
    final day = makePlan(profile())[4];
    final back = ProgramDay.fromMap(day.toMap());

    expect(back.title, day.title);
    expect(back.body, day.body);
    expect(back.primaryAction, day.primaryAction);
    expect(back.smallerAlternative, day.smallerAlternative);
    expect(back.whyThisStep, day.whyThisStep);
    expect(back.supportsPrimaryGoal, day.supportsPrimaryGoal);
    expect(back.scheduledDate, day.scheduledDate);
    expect(back.timeZoneId, 'Europe/Amsterdam');
  });

  test('older rows with plain text in content still load', () {
    final map = makePlan(profile())[0].toMap()..['content'] = 'Just some text';
    final back = ProgramDay.fromMap(map);

    expect(back.body, 'Just some text');
  });
}
