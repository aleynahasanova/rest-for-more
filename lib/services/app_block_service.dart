import 'package:flutter/services.dart';

class AppBlockService {
  static const MethodChannel _channel = MethodChannel(
    'rest_for_more/app_blocking',
  );

  static Future<void> setBlockedApps(List<String> apps) async {
    await _channel.invokeMethod('setBlockedApps', {'apps': apps});
  }

  static Future<void> startBlocking() async {
    await _channel.invokeMethod('startBlocking');
  }

  static Future<void> stopBlocking() async {
    await _channel.invokeMethod('stopBlocking');
  }

  static Future<void> openAccessibilitySettings() async {
    await _channel.invokeMethod('openAccessibilitySettings');
  }

  static Future<bool> isAccessibilityEnabled() async {
    final enabled = await _channel.invokeMethod<bool>('isAccessibilityEnabled');
    return enabled ?? false;
  }

  static Future<void> setTemporaryUnblock({
    required String packageName,
    required DateTime until,
  }) async {
    await _channel.invokeMethod('setTemporaryUnblock', {
      'packageName': packageName,
      'untilEpochMs': until.millisecondsSinceEpoch,
    });
  }

  static Future<void> clearTemporaryUnblock(String packageName) async {
    await _channel.invokeMethod('clearTemporaryUnblock', {
      'packageName': packageName,
    });
  }
}
