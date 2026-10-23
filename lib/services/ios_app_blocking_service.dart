import 'package:flutter/services.dart';

/// Screen Time keeps app identities on the device; Flutter receives counts only.
class IOSAppBlockingService {
  IOSAppBlockingService._();
  static const _channel = MethodChannel('rest_for_more/ios_app_blocking');

  static Future<bool> isAuthorized() async =>
      await _channel.invokeMethod<bool>('isAuthorized') ?? false;

  static Future<void> requestPermission() async {
    final approved = await _channel.invokeMethod<bool>('requestPermission');
    if (approved != true) {
      throw PlatformException(
        code: 'permission_denied',
        message: 'Allow Screen Time access to pause apps during focus.',
      );
    }
  }

  static Future<int> selectionCount() async =>
      await _channel.invokeMethod<int>('selectionCount') ?? 0;

  /// Null means Cancel; an empty selection is a valid saved selection.
  static Future<int?> selectApps() => _channel.invokeMethod<int>('selectApps');

  static Future<void> startBlocking(Duration duration) =>
      _channel.invokeMethod<void>('startBlocking', {
        'durationSeconds': duration.inSeconds,
      });

  static Future<void> stopBlocking() =>
      _channel.invokeMethod<void>('stopBlocking');
}
