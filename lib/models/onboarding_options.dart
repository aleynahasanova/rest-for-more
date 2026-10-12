// Answer options for the onboarding intake (App design, Flow A).
//
// The database stores these as text using the enum name (e.g. 'buildRoutine'),
// matching the String columns in onboarding_profiles. Every enum has an
// `unknown` value: an unanswered question gets a neutral fallback and stays
// editable later.

enum AgeBand { unknown, under16, age16to17, age18to24, age25to34, age35to49, age50plus }

enum PrimaryGoal { unknown, phoneAwayEarlier, buildRoutine, useLessSocialMedia }

enum Obstacle {
  unknown,
  scrolling,
  availability,
  restlessThoughts,
  planning,
  phoneAsAlarm,
  noRoutine,
}

enum Rhythm { unknown, regular, variable, shifts }

enum FeasibleStep { unknown, short, standard, custom }

enum PreferredActivity { unknown, reading, preparation, quietSitting, custom }

enum ProductOwnership { unknown, none, restNest, card, both }

/// Finds an enum value by its stored name. Falls back when the value is null,
/// missing or no longer exists (for example after a rename in a later update).
T enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}
