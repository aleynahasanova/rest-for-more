import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rest_for_more/services/app_block_service.dart';
import 'package:rest_for_more/services/ios_app_blocking_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const ios = MethodChannel('rest_for_more/ios_app_blocking');
  const android = MethodChannel('rest_for_more/app_blocking');
  final calls = <MethodCall>[];

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ios, (call) async {
          calls.add(call);
          return switch (call.method) {
            'isAuthorized' || 'requestPermission' => true,
            'selectionCount' => 3,
            'selectApps' => null,
            _ => null,
          };
        });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(android, (call) async {
          fail('Unexpected Android call on iOS: ${call.method}');
        });
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    calls.clear();
    for (final channel in [ios, android]) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    }
  });

  test('iOS routes permission and session lifecycle to Screen Time', () async {
    expect(await AppBlockService.isAccessibilityEnabled(), isTrue);
    await AppBlockService.openAccessibilitySettings();
    await AppBlockService.setBlockedApps(['android.package']);
    await AppBlockService.startBlocking(duration: const Duration(minutes: 25));
    await AppBlockService.stopBlocking();
    expect(calls.map((call) => call.method), [
      'isAuthorized',
      'requestPermission',
      'startBlocking',
      'stopBlocking',
    ]);
    expect(calls[2].arguments, {'durationSeconds': 1500});
  });

  test('iOS requires a duration so blocked apps can be released', () async {
    await expectLater(AppBlockService.startBlocking(), throwsArgumentError);
    await expectLater(
      AppBlockService.startBlocking(duration: Duration.zero),
      throwsArgumentError,
    );
    expect(calls, isEmpty);
  });

  test(
    'selection counts are restored; cancelling picker stays distinct from zero',
    () async {
      expect(await IOSAppBlockingService.selectionCount(), 3);
      expect(await IOSAppBlockingService.selectApps(), isNull);
    },
  );

  test('denied permission fails explicitly', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ios, (_) async => false);
    await expectLater(
      IOSAppBlockingService.requestPermission(),
      throwsA(isA<PlatformException>()),
    );
  });

  test('Android keeps the existing channel contract', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(android, (call) async {
          calls.add(call);
          return call.method == 'isAccessibilityEnabled' ? true : null;
        });
    await AppBlockService.setBlockedApps(['com.example.app']);
    await AppBlockService.startBlocking(duration: const Duration(minutes: 25));
    await AppBlockService.stopBlocking();
    expect(calls.map((call) => call.method), [
      'setBlockedApps',
      'startBlocking',
      'stopBlocking',
    ]);
    expect(calls.first.arguments, {
      'apps': ['com.example.app'],
    });
    expect(calls[1].arguments, isNull);
  });
}
