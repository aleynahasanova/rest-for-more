import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

import 'ios_app_blocking_service.dart';

class AppBlockService {
  static bool get isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  static const MethodChannel _channel = MethodChannel(
    'rest_for_more/app_blocking',
  );

  static Future<void> setBlockedApps(List<String> apps) async {
    if (isIOS) return;
    await _channel.invokeMethod('setBlockedApps', {'apps': apps});
  }

  static Future<void> startBlocking({Duration? duration}) async {
    if (isIOS) {
      if (duration == null || duration <= Duration.zero) {
        throw ArgumentError(
          'An iOS focus session requires a positive duration.',
        );
      }
      return IOSAppBlockingService.startBlocking(duration);
    }
    await _channel.invokeMethod('startBlocking');
  }

  static Future<void> stopBlocking() async {
    if (isIOS) return IOSAppBlockingService.stopBlocking();
    await _channel.invokeMethod('stopBlocking');
  }

  static Future<void> openAccessibilitySettings() async {
    if (isIOS) return IOSAppBlockingService.requestPermission();
    await _channel.invokeMethod('openAccessibilitySettings');
  }

  static Future<bool> isAccessibilityEnabled() async {
    if (isIOS) return IOSAppBlockingService.isAuthorized();
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
