class SessionBlockedApp {
  final String sessionBlockedAppId;
  final String sessionId;
  final String appIdentifier;
  final String appName;

  const SessionBlockedApp({
    required this.sessionBlockedAppId,
    required this.sessionId,
    required this.appIdentifier,
    required this.appName,
  });

  Map<String, Object?> toMap() {
    return {
      'session_blocked_app_id': sessionBlockedAppId,
      'session_id': sessionId,
      'app_identifier': appIdentifier,
      'app_name': appName,
    };
  }

  factory SessionBlockedApp.fromMap(Map<String, Object?> map) {
    return SessionBlockedApp(
      sessionBlockedAppId: map['session_blocked_app_id'] as String,
      sessionId: map['session_id'] as String,
      appIdentifier: map['app_identifier'] as String,
      appName: map['app_name'] as String,
    );
  }
}
