import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'ios_app_blocking_service.dart';

class AppBlockService {
  static bool get isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static const MethodChannel _channel = MethodChannel(
    'rest_for_more/app_blocking',
  );

  static Future<void> setBlockedApps(List<String> apps) async {
    if (isIOS) {
      return;
    }
    await _invokeAndroid('setBlockedApps', {'apps': apps});
  }

  static Future<void> startBlocking({Duration? duration}) async {
    if (isIOS) {
      if (duration == null || duration <= Duration.zero) {
        throw ArgumentError(
          'An iOS session requires a positive duration.',
        );
      }
      await IOSAppBlockingService.startBlocking(duration);
      return;
    }
    await _invokeAndroid('startBlocking');
  }

  static Future<void> stopBlocking() async {
    if (isIOS) {
      await IOSAppBlockingService.stopBlocking();
      return;
    }
    await _invokeAndroid('stopBlocking');
  }

  static Future<void> openAccessibilitySettings() async {
    if (isIOS) {
      await IOSAppBlockingService.requestPermission();
      return;
    }
    await _invokeAndroid('openAccessibilitySettings');
  }

  static Future<bool> isAccessibilityEnabled() async {
    if (isIOS) {
      return IOSAppBlockingService.isAuthorized();
    }
    final enabled = await _invokeAndroid<bool>('isAccessibilityEnabled');
    return enabled ?? false;
  }

  static Future<void> setTemporaryUnblock({
    required String packageName,
    required DateTime until,
  }) async {
    if (isIOS) {
      return;
    }
    await _invokeAndroid('setTemporaryUnblock', {
      'packageName': packageName,
      'untilEpochMs': until.millisecondsSinceEpoch,
    });
  }

  static Future<void> clearTemporaryUnblock(String packageName) async {
    if (isIOS) {
      return;
    }
    await _invokeAndroid('clearTemporaryUnblock', {
      'packageName': packageName,
    });
  }

  static Future<void> setNotificationSuppressionEnabled(bool enabled) async {
    if (isIOS) {
      return;
    }
    await _invokeAndroid('setNotificationSuppressionEnabled', {
      'enabled': enabled,
    });
  }

  static Future<bool> isNotificationAccessEnabled() async {
    if (isIOS) {
      return true;
    }
    final enabled = await _invokeAndroid<bool>('isNotificationAccessEnabled');
    return enabled ?? false;
  }

  static Future<void> openNotificationAccessSettings() async {
    if (isIOS) {
      return;
    }
    await _invokeAndroid('openNotificationAccessSettings');
  }

  static Future<T?> _invokeAndroid<T>(
    String method, [
    Map<String, Object?>? arguments,
  ]) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on MissingPluginException {
      return null;
    }
  }
}
