class ModeBlockedApp {
  final String modeBlockedAppId;
  final String modeId;
  final String appIdentifier;
  final String appName;
  final DateTime createdAt;

  const ModeBlockedApp({
    required this.modeBlockedAppId,
    required this.modeId,
    required this.appIdentifier,
    required this.appName,
    required this.createdAt,
  });

  Map<String, Object?> toMap() {
    return {
      'mode_blocked_app_id': modeBlockedAppId,
      'mode_id': modeId,
      'app_identifier': appIdentifier,
      'app_name': appName,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ModeBlockedApp.fromMap(Map<String, Object?> map) {
    return ModeBlockedApp(
      modeBlockedAppId: map['mode_blocked_app_id'] as String,
      modeId: map['mode_id'] as String,
      appIdentifier: map['app_identifier'] as String,
      appName: map['app_name'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
