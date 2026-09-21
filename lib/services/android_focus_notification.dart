import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AndroidFocusNotification {
  const AndroidFocusNotification();

  static const _channel = MethodChannel(
    'com.example.rest_for_more/focus_notification',
  );

  Future<void> show({required DateTime finishingAt}) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    try {
      await _channel.invokeMethod<void>('showFocusTimer', {
        'finishingAtMilliseconds': finishingAt.millisecondsSinceEpoch,
      });
    } on PlatformException catch (error) {
      debugPrint('Could not show the focus timer notification: $error');
    }
  }

  Future<void> hide() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    try {
      await _channel.invokeMethod<void>('hideFocusTimer');
    } on PlatformException catch (error) {
      debugPrint('Could not hide the focus timer notification: $error');
    }
  }
}
