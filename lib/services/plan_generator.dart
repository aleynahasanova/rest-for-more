import '../models/onboarding_options.dart';
import '../models/onboarding_profile.dart';
import '../models/program_day.dart';
import '../utils/id_generator.dart';

/// Makes the personal 14-day plan from the onboarding answers.
///
/// There is no AI and no database here. The plan is made from fixed day
/// templates. The answers only choose which words go into the blanks, so the
/// same answers always give the same plan.
///
/// Which answer changes what:
/// - main goal: what the "away" step is (phone away, routine, social media)
///   and what days 1 and 2 are about
/// - biggest challenge: the tip and plan on days 5 and 10
/// - rhythm: when the step happens ("in the evening", "before you sleep")
/// - phone-away minutes: the target that days 3 to 13 build up to
/// - step size: how many minutes the first step is (5 or 10)
/// - preferred activity: what the user does after putting the phone away
///
/// An answer that is missing or unknown gets a neutral default, as the design
/// document asks.
///
/// The texts are a first version. The clients should approve the final wording.
class PlanGenerator {
  const PlanGenerator();

  // Days that are not about the main goal: noticing (1) and the two reviews
  // (7 and 14). That leaves 11 days that do serve the goal, and the rule (R01)
  // asks for at least 10.
  static const List<int> _daysNotAboutGoal = [1, 7, 14];

  static const int _defaultTargetMinutes = 30;

  /// Makes the 14 [ProgramDay]s, ready to be saved.
  ///
  /// [startDate] is the date of day 1. Day 2 is the next date, and so on.
  /// [timeZoneId] is saved with each day. [newId] is only for tests.
  List<ProgramDay> generate(
    OnboardingProfile profile, {
    required String programId,
    required DateTime startDate,
    required String timeZoneId,
    required DateTime now,
    String Function()? newId,
  }) {
    final plan = _Plan.fromProfile(profile);
    final makeId = newId ?? IdGenerator.newId;

    return [
      for (var day = 1; day <= ProgramDay.totalDays; day++)
        _buildDay(
          day,
          plan,
          programDayId: makeId(),
          programId: programId,
          date: DateTime(startDate.year, startDate.month, startDate.day + day - 1),
          timeZoneId: timeZoneId,
          now: now,
        ),
    ];
  }

  ProgramDay _buildDay(
    int day,
    _Plan plan, {
    required String programDayId,
    required String programId,
    required DateTime date,
    required String timeZoneId,
    required DateTime now,
  }) {
    final content = _content(day, plan);

    return ProgramDay(
      programDayId: programDayId,
      programId: programId,
      dayNumber: day,
      title: content.title,
      body: content.paragraphs.join('\n\n'),
      primaryAction: content.action,
      smallerAlternative: content.smaller,
      whyThisStep: content.why,
      supportsPrimaryGoal: !_daysNotAboutGoal.contains(day),
      scheduledDate: _dateText(date),
      timeZoneId: timeZoneId,
      createdAt: now.toUtc(),
    );
  }

  /// 'yyyy-MM-dd', the local calendar date.
  static String _dateText(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  _Content _content(int day, _Plan plan) {
    switch (day) {
      case 1:
        return _day1(plan);
      case 2:
        return _day2(plan);
      case 3:
        return _awayDay(
          plan,
          day: 3,
          title: 'Your first minutes',
          paragraphs: [
            'Today your phone stays away for a short while.',
            'If it feels like too much, use the smaller step. That is fine.',
          ],
          why: 'A short start is easier to repeat. You can build on it.',
        );
      case 4:
        return _day4(plan);
      case 5:
        return _day5(plan);
      case 6:
        return _awayDay(
          plan,
          day: 6,
          title: 'A little longer',
          paragraphs: [
            'Today you stay away from your phone a bit longer.',
            'The smaller step is always fine.',
          ],
          why: 'Small increases are easier to keep than big jumps.',
        );
      case 7:
        return _day7();
      case 8:
        return _day8();
      case 9:
        return _awayDay(
          plan,
          day: 9,
          title: 'A bit more',
          paragraphs: [
            'You are building up step by step.',
            'Stay a little longer than last time.',
          ],
          why: 'Moving up in small steps keeps it realistic.',
        );
      case 10:
        return _day10(plan);
      case 11:
        return _day11();
      case 12:
        return _awayDay(
          plan,
          day: 12,
          title: 'Your full goal',
          paragraphs: [
            'Your routine is taking shape.',
            'Today you reach your full goal.',
          ],
          why: 'A steady routine feels more natural every day.',
        );
      case 13:
        return _day13(plan);
      default:
        return _day14();
    }
  }

  // ---------------------------------------------------------------------
  // The days. Each one returns its text. Keep paragraphs short.
  // ---------------------------------------------------------------------

  _Content _day1(_Plan plan) {
    final String notice;
    switch (plan.goal) {
      case PrimaryGoal.buildRoutine:
        notice = 'what you usually do to wind down';
        break;
      case PrimaryGoal.useLessSocialMedia:
        notice = 'which apps you open first';
        break;
      default:
        notice = 'how often you reach for your phone';
    }

    return _Content(
      title: 'Notice your evening',
      paragraphs: [
        "Today is only about noticing. You don't need to change anything yet.",
      ],
      action: "Notice $notice ${plan.when}. Don't change anything.",
      smaller: 'Notice it just once.',
      why: 'Knowing your own habits makes the next steps easier.',
    );
  }

  _Content _day2(_Plan plan) {
    switch (plan.goal) {
      case PrimaryGoal.buildRoutine:
        return const _Content(
          title: 'Choose your starting moment',
          paragraphs: [
            'Small steps help your routine feel natural.',
            'It does not need to be exact.',
          ],
          action: 'Choose the moment your wind-down starts, like after dinner '
              'or after brushing your teeth.',
          smaller: 'Choose a rough time.',
          why: 'A fixed starting moment makes a routine easier to repeat.',
        );
      case PrimaryGoal.useLessSocialMedia:
        return const _Content(
          title: 'Make social apps harder to open',
          paragraphs: [
            'Small steps help you use social media less.',
            'You can put the apps back any time.',
          ],
          action: 'Move social apps off your home screen, or into a folder.',
          smaller: 'Move just one app.',
          why: 'A little extra effort gives you time to choose.',
        );
      default:
        return const _Content(
          title: 'Give your phone a place',
          paragraphs: [
            'Small steps help you put your phone away earlier.',
            'Pick a spot that is easy to reach in the morning, but not from '
                'your bed.',
          ],
          action: 'Choose one spot for your phone and put it there once.',
          smaller: 'Put it there for 5 minutes.',
          why: 'A fixed place turns a decision into a habit, so it takes '
              'less effort.',
        );
    }
  }

  _Content _day4(_Plan plan) {
    return _Content(
      title: 'Something calm to do',
      paragraphs: [
        'Now fill the time with something calm.',
        'It helps to know what you will do before you put your phone away.',
      ],
      action: 'After you put your phone away, ${plan.activity.doing}.',
      smaller: 'After you put your phone away, ${plan.activity.small}.',
      why: 'Having something to do makes it easier to stay away from your '
          'phone.',
    );
  }

  _Content _day5(_Plan plan) {
    final tips = plan.obstacleTips;

    return _Content(
      title: 'Plan for your hardest moment',
      paragraphs: [tips.tip, 'Today you get ready for it.'],
      action: tips.plan,
      smaller: tips.small,
      why: tips.why,
    );
  }

  _Content _day7() {
    return const _Content(
      title: 'Look back on week one',
      paragraphs: [
        'Take a moment to look back on the first week.',
        'What was easy? What was hard?',
      ],
      action: 'Think about which step helped you most this week.',
      smaller: 'Think of just one thing that went well.',
      why: 'Looking back helps you see what works for you. There is no score '
          'and nothing to pass.',
    );
  }

  _Content _day8() {
    return const _Content(
      title: 'Something to look forward to',
      paragraphs: [
        'Choose what you will do after your phone is away.',
        'Have it ready before you start.',
      ],
      action: 'Choose what you will do after your phone is away, and put it '
          'where you can see it.',
      smaller: 'Just choose it. You do not have to put it out.',
      why: 'Something ready in sight is easier to start than something you '
          'have to find.',
    );
  }

  _Content _day10(_Plan plan) {
    return _Content(
      title: 'When it is hard',
      paragraphs: [
        'Some evenings are harder than others. That is normal.',
        'Remember the plan you made on day 5.',
      ],
      action: 'When you feel like reaching for your phone, '
          '${plan.activity.doing} instead.',
      smaller: 'Take 3 slow breaths instead.',
      why: 'A plan that is ready is easier to follow than a decision in the '
          'moment.',
    );
  }

  _Content _day11() {
    return const _Content(
      title: 'Make it yours',
      paragraphs: ['Adjust your evening so it fits you.'],
      action: 'Change one thing about your evening to make it easier for you.',
      smaller: 'Keep everything the same and notice what feels good.',
      why: 'A routine you chose yourself is easier to keep.',
    );
  }

  _Content _day13(_Plan plan) {
    final minutes = plan.minutesForDay(13);

    return _Content(
      title: 'Put it together',
      paragraphs: [
        'Today you put the steps together in your own way.',
        'First your phone goes away, then your calm activity.',
      ],
      action: 'Do your whole evening: ${plan.awayPhrase(minutes)}, then '
          '${plan.activity.doing}.',
      smaller: 'Do just the phone-away part: '
          '${plan.awayPhrase(_Plan.smallerMinutes(minutes))}.',
      why: 'Putting the steps together is how a routine starts to feel '
          'natural.',
    );
  }

  _Content _day14() {
    return const _Content(
      title: 'Look back and keep going',
      paragraphs: [
        'You have reached the last day of the programme.',
        'Your routine does not end here.',
      ],
      action: 'Think about which steps you want to keep.',
      smaller: 'Pick one step to keep.',
      why: 'Choosing what to keep makes the routine yours.',
    );
  }

  /// Days 3, 6, 9 and 12: the same step, a little longer each time.
  _Content _awayDay(
    _Plan plan, {
    required int day,
    required String title,
    required List<String> paragraphs,
    required String why,
  }) {
    final minutes = plan.minutesForDay(day);

    return _Content(
      title: title,
      paragraphs: paragraphs,
      action: _sentence(plan.awayPhrase(minutes)),
      smaller: _sentence(plan.awayPhrase(_Plan.smallerMinutes(minutes))),
      why: why,
    );
  }

  static String _sentence(String phrase) {
    if (phrase.isEmpty) return phrase;
    return '${phrase[0].toUpperCase()}${phrase.substring(1)}.';
  }
}

/// The text of one day, before it becomes a [ProgramDay].
class _Content {
  const _Content({
    required this.title,
    required this.paragraphs,
    required this.action,
    required this.smaller,
    required this.why,
  });

  final String title;
  final List<String> paragraphs;
  final String action;
  final String smaller;
  final String why;
}

/// The answers, turned into the words and numbers the templates need.
class _Plan {
  _Plan({
    required this.goal,
    required this.obstacleTips,
    required this.when,
    required this.activity,
    required this.startMinutes,
    required this.targetMinutes,
  });

  final PrimaryGoal goal;
  final _ObstacleTips obstacleTips;

  /// When the step happens, for example "in the evening".
  final String when;
  final _Activity activity;
  final int startMinutes;
  final int targetMinutes;

  factory _Plan.fromProfile(OnboardingProfile profile) {
    // Not answered: the goal falls back to the most general one, the step
    // falls back to the gentle one.
    var goal = profile.primaryGoal;
    if (goal == PrimaryGoal.unknown) goal = PrimaryGoal.phoneAwayEarlier;

    var target =
        profile.phoneFreeTargetMinutes ?? PlanGenerator._defaultTargetMinutes;
    if (target < 5) target = 5;

    final standardStep = profile.feasibleStepOption == FeasibleStep.standard;
    var start = standardStep ? 10 : 5;
    if (start > target) start = target;

    return _Plan(
      goal: goal,
      obstacleTips: _ObstacleTips.forObstacle(profile.obstacle),
      when: _whenFor(profile.rhythmOption),
      activity: _Activity.forActivity(profile.preferredActivityOption),
      startMinutes: start,
      targetMinutes: target,
    );
  }

  static String _whenFor(Rhythm rhythm) {
    switch (rhythm) {
      case Rhythm.regular:
        return 'in the evening';
      case Rhythm.shifts:
        return 'before you sleep';
      default:
        // Variable and unknown: no fixed time of day is assumed.
        return 'when you start to wind down';
    }
  }

  /// How many minutes the step is on a given day. It grows from the start
  /// to the target between day 3 and day 12 and is rounded to 5 minutes.
  int minutesForDay(int day) {
    final double fraction;
    if (day <= 3) {
      fraction = 0;
    } else if (day <= 6) {
      fraction = 1 / 3;
    } else if (day <= 9) {
      fraction = 2 / 3;
    } else {
      fraction = 1;
    }

    final raw = startMinutes + (targetMinutes - startMinutes) * fraction;
    var rounded = (raw / 5).round() * 5;

    if (rounded < startMinutes) rounded = startMinutes;
    if (rounded > targetMinutes) rounded = targetMinutes;
    return rounded;
  }

  /// About half the minutes, never less than 2.
  static int smallerMinutes(int minutes) {
    final half = (minutes / 2 / 5).floor() * 5;
    return half < 2 ? 2 : half;
  }

  /// The "away" step in words, without a capital or a full stop, so it can be
  /// used inside a longer sentence. It depends on the main goal.
  String awayPhrase(int minutes) {
    switch (goal) {
      case PrimaryGoal.buildRoutine:
        return 'wind down at the same time and keep your phone away for '
            '$minutes minutes';
      case PrimaryGoal.useLessSocialMedia:
        return 'keep social media closed for $minutes minutes $when';
      default:
        return 'keep your phone away for $minutes minutes $when';
    }
  }
}

/// What the user does after putting the phone away.
class _Activity {
  const _Activity({required this.doing, required this.small});

  final String doing;
  final String small;

  static _Activity forActivity(PreferredActivity activity) {
    switch (activity) {
      case PreferredActivity.reading:
        return const _Activity(
          doing: 'read a few pages',
          small: 'read one page',
        );
      case PreferredActivity.preparation:
        return const _Activity(
          doing: 'get one thing ready for tomorrow',
          small: 'get one small thing ready, like your keys',
        );
      case PreferredActivity.quietSitting:
        return const _Activity(
          doing: 'sit quietly for 5 minutes',
          small: 'sit quietly for 2 minutes',
        );
      default:
        // Unknown or "custom" (not built yet): something neutral.
        return const _Activity(
          doing: 'do something calm',
          small: 'take 3 slow breaths',
        );
    }
  }
}

/// The tip and the plan for the biggest challenge (days 5 and 10).
class _ObstacleTips {
  const _ObstacleTips({
    required this.tip,
    required this.plan,
    required this.small,
    required this.why,
  });

  final String tip;
  final String plan;
  final String small;
  final String why;

  static _ObstacleTips forObstacle(Obstacle obstacle) {
    switch (obstacle) {
      case Obstacle.scrolling:
        return const _ObstacleTips(
          tip: 'Scrolling is easier when your phone is within reach.',
          plan: "Keep your phone out of arm's reach, so scrolling takes a few "
              'more steps.',
          small: 'Put it one step further away.',
          why: 'A little extra effort gives you time to choose.',
        );
      case Obstacle.availability:
        return const _ObstacleTips(
          tip: 'It is okay to be unavailable for a short while.',
          plan: 'Tell one person that you are away from your phone for a '
              'while.',
          small: 'Tell just one person.',
          why: 'When others know, it is easier to relax.',
        );
      case Obstacle.restlessThoughts:
        return const _ObstacleTips(
          tip: 'Busy thoughts are common when you try to wind down.',
          plan: 'Write down what is on your mind on paper before you put '
              'your phone away.',
          small: 'Write down just one thing.',
          why: 'A note on paper can make it easier to let a thought wait '
              'until tomorrow.',
        );
      case Obstacle.planning:
        return const _ObstacleTips(
          tip: 'Planning is easier when you decide it in advance.',
          plan: 'Choose your time and your place now, so you need no '
              'decisions later.',
          small: 'Choose just the time.',
          why: 'Fewer decisions make a routine easier to start.',
        );
      case Obstacle.phoneAsAlarm:
        return const _ObstacleTips(
          tip: 'If your phone is your alarm, it is hard to leave it away.',
          plan: 'Find another way to wake up, such as a simple alarm clock.',
          small: 'Think of one option.',
          why: 'When your phone is not your alarm, it can stay away from '
              'your bed.',
        );
      case Obstacle.noRoutine:
        return const _ObstacleTips(
          tip: 'A routine starts with one fixed moment.',
          plan: 'Pick something you already do every day, and do your step '
              'right after it.',
          small: 'Pick any moment. It does not need to be exact.',
          why: 'Linking a step to something you already do makes it easier '
              'to remember.',
        );
      default:
        return const _ObstacleTips(
          tip: 'Some moments are harder than others.',
          plan: 'Choose one thing to do when you feel like reaching for your '
              'phone.',
          small: 'Take 3 slow breaths instead.',
          why: 'A plan that is ready is easier to follow than a decision in '
              'the moment.',
        );
    }
  }
}
