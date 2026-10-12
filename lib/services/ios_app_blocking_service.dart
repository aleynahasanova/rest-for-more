import 'dart:io';

import 'package:flutter_screentime/flutter_screentime.dart';

class IOSAppBlockingService {
  IOSAppBlockingService._();

  static const FlutterScreentime _screenTime = FlutterScreentime();

  static void _checkPlatform() {
    if (!Platform.isIOS) {
      throw UnsupportedError('This service is only available on iOS.');
    }
  }

  // Request Screen Time permission
  static Future<void> requestPermission() async {
    _checkPlatform();
    await _screenTime.requestAuthorization();
  }

  // Open the native iOS app picker
  static Future<void> selectApps() async {
    _checkPlatform();
    await _screenTime.selectBlockedApps();
  }

  // Start blocking the selected apps
  static Future<void> startBlocking() async {
    _checkPlatform();
    await _screenTime.startBlocking();
  }

  // Stop blocking the selected apps
  static Future<void> stopBlocking() async {
    _checkPlatform();
    await _screenTime.stopBlocking();
  }
}
