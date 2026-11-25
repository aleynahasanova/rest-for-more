import 'package:flutter_test/flutter_test.dart';
import 'package:rest_for_more/services/mode_launch_service.dart';

void main() {
  test('parses NFC URLs for each bracelet mode', () {
    expect(ModeLaunchService.parse('restformore://focus'), LaunchMode.focus);
    expect(
      ModeLaunchService.parse('restformore://reading'),
      LaunchMode.reading,
    );
    expect(
      ModeLaunchService.parse('restformore://morning'),
      LaunchMode.morning,
    );
    expect(
      ModeLaunchService.parse('restformore://evening'),
      LaunchMode.evening,
    );
  });

  test('accepts aliases and path forms used by NFC writer apps', () {
    expect(ModeLaunchService.parse('restformore://read'), LaunchMode.reading);
    expect(ModeLaunchService.parse('restformore://night'), LaunchMode.evening);
    expect(
      ModeLaunchService.parse('restformore://open/focus'),
      LaunchMode.focus,
    );
    expect(
      ModeLaunchService.parse('RESTFORMORE://Morning'),
      LaunchMode.morning,
    );
  });

  test('ignores unrelated links', () {
    expect(ModeLaunchService.parse(null), isNull);
    expect(ModeLaunchService.parse(''), isNull);
    expect(ModeLaunchService.parse('https://example.com/focus'), isNull);
    expect(ModeLaunchService.parse('restformore://unknown'), isNull);
  });

  test('keeps the latest scan until the home screen takes it', () {
    final service = ModeLaunchService();
    service.handle('restformore://reading');
    expect(service.pending, LaunchMode.reading);
    service.handle('restformore://evening');
    expect(service.take(), LaunchMode.evening);
    expect(service.take(), isNull);
  });
}
