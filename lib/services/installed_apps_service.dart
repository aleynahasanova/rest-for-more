import '../data/app_icon_styles.dart';
import '../data/mock_blockable_apps.dart';
import '../models/blockable_app.dart';
import 'app_block_service.dart';

class InstalledAppsService {
  InstalledAppsService._();

  static List<BlockableApp> _apps = MockBlockableApps.all;
  static var _loaded = false;

  static List<BlockableApp> get apps => List.unmodifiable(_apps);

  static Future<List<BlockableApp>> load() async {
    if (_loaded) {
      return apps;
    }
    if (AppBlockService.isIOS) {
      _apps = MockBlockableApps.all;
      _loaded = true;
      return apps;
    }
    final raw = await AppBlockService.getInstalledApps();
    if (raw.isEmpty) {
      _apps = MockBlockableApps.all;
      _loaded = true;
      return apps;
    }
    final mapped = <BlockableApp>[];
    for (final row in raw) {
      final app = _fromNative(row);
      if (app != null) {
        mapped.add(app);
      }
    }
    _apps = mapped.isEmpty ? MockBlockableApps.all : mapped;
    _loaded = true;
    return apps;
  }

  static BlockableApp resolve(String id) {
    for (final app in _apps) {
      if (app.id == id) {
        return app;
      }
    }
    final known = MockBlockableApps.byId(id);
    if (known != null) {
      return known;
    }
    final packageName = MockBlockableApps.packageForId(id);
    final style = AppIconStyles.forApp(packageName: packageName, name: id);
    return BlockableApp(
      id: id,
      name: id,
      packageName: packageName,
      icon: style.icon,
      iconColor: style.color,
    );
  }

  static BlockableApp? _fromNative(Map<Object?, Object?> row) {
    final packageName = row['packageName'] as String?;
    final name = row['name'] as String?;
    if (packageName == null || packageName.isEmpty) {
      return null;
    }
    final known = MockBlockableApps.byPackage(packageName);
    final displayName =
        (name == null || name.isEmpty) ? known?.name ?? packageName : name;
    final style = AppIconStyles.forApp(
      packageName: packageName,
      name: displayName,
    );
    return BlockableApp(
      id: known?.id ?? packageName,
      name: displayName,
      packageName: packageName,
      icon: style.icon,
      iconColor: style.color,
    );
  }
}
