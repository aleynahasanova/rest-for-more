/// Values for the existing `programs.status` column.
/// 'ACTIVE' is already used by ProgramService.getActiveProgramByUserId.
abstract final class ProgramStatus {
  static const String active = 'ACTIVE';

  /// Pausing stops future programme notifications. On resume the user
  /// continues with the next day that has not been offered yet.
  static const String paused = 'PAUSED';

  /// All 14 days have been offered ("Your own routine continues").
  static const String completed = 'COMPLETED';
}
