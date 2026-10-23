import DeviceActivity
import ManagedSettings

final class FocusActivityMonitor: DeviceActivityMonitor {
  override func intervalDidEnd(for activity: DeviceActivityName) {
    super.intervalDidEnd(for: activity)
    guard activity.rawValue.hasPrefix("focus.") else { return }
    ManagedSettingsStore(named: ManagedSettingsStore.Name(activity.rawValue)).clearAllSettings()
  }
}
