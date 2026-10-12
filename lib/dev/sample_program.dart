import '../models/program_day.dart';

/// TEMPORARY: a fake 14-day programme, so the programme screens can be built
/// and tested before the database and the plan generator are ready.
///
/// The texts are placeholders. The real texts will be made by the plan
/// generator from the user's onboarding answers, and the clients should
/// approve the final wording. Delete this file when the real plan is
/// connected.
abstract final class SampleProgram {
  static const String programId = 'sample-program';

  static ProgramDay day(int number) => days[number - 1];

  static final List<ProgramDay> days = [
    _day(
      1,
      title: 'Notice your evening',
      paragraphs: [
        "Today is only about noticing. You don't need to change anything yet.",
        'Tonight, pay attention to the moment you pick up your phone and what '
            'you do with it.',
      ],
      action: "Tonight, notice when you reach for your phone. Don't change "
          'anything.',
      smaller: 'Notice it just once.',
      why: 'A good plan starts with knowing your own habits. Noticing first '
          'makes the next steps easier.',
      servesGoal: false,
    ),
    _day(
      2,
      title: 'Choose a spot for your phone',
      paragraphs: [
        'Your phone needs a place of its own for the evening, away from your '
            'bed.',
        'Pick a spot that is easy to reach in the morning, but not from your '
            'pillow.',
      ],
      action: 'Choose one spot for your phone and put it there before bed.',
      smaller: 'Put your phone on the other side of the room for 5 minutes.',
      why: 'A fixed place turns a decision into a habit, so it takes less '
          'effort.',
    ),
    _day(
      3,
      title: 'Phone out of reach',
      paragraphs: [
        'Today you put your phone away a little before you go to bed.',
        'Use the spot you chose yesterday.',
      ],
      action: 'Put your phone in its spot 10 minutes before bed.',
      smaller: 'Put it in its spot 5 minutes before bed.',
      why: 'Distance makes it easier to stop scrolling.',
    ),
    _day(
      4,
      title: 'Five quiet minutes',
      paragraphs: [
        'After you put your phone away, do something calm.',
        'Sit, stretch, or just breathe.',
      ],
      action: 'After you put your phone away, sit quietly for 5 minutes.',
      smaller: 'Sit quietly for 2 minutes.',
      why: 'A short calm moment gives your mind something to do instead of '
          'reaching for the phone.',
    ),
    _day(
      5,
      title: 'Something to read',
      paragraphs: [
        'Today you fill the time with something to read.',
        'A few pages is enough.',
      ],
      action: 'After you put your phone away, read a few pages.',
      smaller: 'Read one page.',
      why: 'Having something ready makes it easier to stay away from your '
          'phone.',
    ),
    _day(
      6,
      title: 'A little longer',
      paragraphs: [
        'Today you stay away from your phone a bit longer.',
        "If it feels like too much, use the smaller step. That's fine.",
      ],
      action: 'Keep your phone away for 15 minutes before bed.',
      smaller: 'Keep it away for 10 minutes.',
      why: 'Small increases are easier to keep than big jumps.',
    ),
    _day(
      7,
      title: 'Look back on week one',
      paragraphs: [
        'Take a moment to look back on the first week.',
        'What was easy? What was hard?',
      ],
      action: 'Think about which step helped you most this week.',
      smaller: 'Think of just one thing that went well.',
      why: 'Looking back helps you see what works for you. There is no score '
          'and nothing to pass.',
      servesGoal: false,
    ),
    _day(
      8,
      title: 'Get ready for tomorrow',
      paragraphs: [
        'Today you use your phone-free time to prepare for tomorrow.',
        'Lay out your clothes, or check what you need to bring.',
      ],
      action: 'Prepare one thing for tomorrow before you put your phone away.',
      smaller: 'Prepare one small thing, like your keys.',
      why: 'A calmer morning starts the evening before.',
    ),
    _day(
      9,
      title: 'Put it away earlier',
      paragraphs: [
        'Now try putting your phone away a little earlier than before.',
      ],
      action: 'Put your phone in its spot 5 minutes earlier than yesterday.',
      smaller: 'Do it at the same time as yesterday.',
      why: 'Moving earlier in small steps keeps it realistic.',
    ),
    _day(
      10,
      title: "When it's hard",
      paragraphs: [
        'Some evenings are harder than others. That is normal.',
        'Today, plan what you will do when you want to pick up your phone.',
      ],
      action: 'Choose one thing to do when you feel like reaching for your '
          'phone.',
      smaller: 'Take 3 slow breaths instead.',
      why: 'A plan that is ready is easier to follow than a decision in the '
          'moment.',
    ),
    _day(
      11,
      title: 'Make it yours',
      paragraphs: [
        'Adjust your evening so it fits you.',
      ],
      action: 'Change one thing about your evening to make it easier for you.',
      smaller: 'Keep everything the same and notice what feels good.',
      why: 'A routine you chose yourself is easier to keep.',
    ),
    _day(
      12,
      title: 'Keep the spot',
      paragraphs: [
        "Your phone's spot is part of your routine now.",
      ],
      action: 'Put your phone in its spot and leave it there for the rest of '
          'the evening.',
      smaller: 'Leave it there for 30 minutes.',
      why: 'A steady place helps your evening feel the same every day.',
    ),
    _day(
      13,
      title: 'Your own evening',
      paragraphs: [
        'Put the steps together in your own way.',
      ],
      action: 'Do your whole evening routine: phone away, then your quiet '
          'activity.',
      smaller: 'Do just the phone-away part.',
      why: 'Putting the steps together is how a routine starts to feel '
          'natural.',
    ),
    _day(
      14,
      title: 'Look back and keep going',
      paragraphs: [
        'You have reached the last day of the programme.',
        "Your routine doesn't end here.",
      ],
      action: 'Think about which steps you want to keep.',
      smaller: 'Pick one step to keep.',
      why: 'Choosing what to keep makes the routine yours.',
      servesGoal: false,
    ),
  ];

  static ProgramDay _day(
    int number, {
    required String title,
    required List<String> paragraphs,
    required String action,
    required String smaller,
    required String why,
    bool servesGoal = true,
  }) {
    return ProgramDay(
      programDayId: 'sample-day-$number',
      programId: programId,
      dayNumber: number,
      title: title,
      body: paragraphs.join('\n\n'),
      primaryAction: action,
      smallerAlternative: smaller,
      whyThisStep: why,
      supportsPrimaryGoal: servesGoal,
      createdAt: DateTime(2026, 10, 5),
    );
  }
}
