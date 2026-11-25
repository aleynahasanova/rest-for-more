import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum LaunchMode { focus, reading, morning, evening }

class ModeLaunchService extends ChangeNotifier {
  ModeLaunchService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('rest_for_more/deep_link');

  static final instance = ModeLaunchService();

  static const scheme = 'restformore';

  final MethodChannel _channel;
  var _listening = false;
  LaunchMode? _pending;

  LaunchMode? get pending => _pending;

  static LaunchMode? parse(String? raw) {
    if (raw == null) {
      return null;
    }
    final value = raw.trim();
    if (value.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme.toLowerCase() != scheme) {
      return null;
    }
    final tokens = [
      uri.host,
      ...uri.pathSegments,
    ].map((part) => part.toLowerCase()).where((part) => part.isNotEmpty);
    for (final token in tokens) {
      if (token == 'open' || token == 'mode') {
        continue;
      }
      switch (token) {
        case 'focus':
          return LaunchMode.focus;
        case 'reading':
        case 'read':
          return LaunchMode.reading;
        case 'morning':
          return LaunchMode.morning;
        case 'evening':
        case 'night':
          return LaunchMode.evening;
      }
    }
    return null;
  }

  Future<void> start() async {
    if (_listening) {
      return;
    }
    _listening = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'opened') {
        handle(call.arguments as String?);
      }
    });
    try {
      handle(await _channel.invokeMethod<String>('getInitial'));
    } on Exception {
      // Tests and platforms without the native handler.
    }
  }

  void handle(String? raw) {
    final mode = parse(raw);
    if (mode == null) {
      return;
    }
    _pending = mode;
    notifyListeners();
  }

  LaunchMode? take() {
    final mode = _pending;
    _pending = null;
    return mode;
  }
}
