import DeviceActivity
import FamilyControls
import Flutter
import ManagedSettings
import SwiftUI
import UIKit
import UserNotifications

enum DeepLinkBridge {
  static var channel: FlutterMethodChannel?
  static var pending: String?

  static func send(_ uri: String) {
    if let channel {
      channel.invokeMethod("opened", arguments: uri)
    } else {
      pending = uri
    }
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var blockingChannel: FlutterMethodChannel?
  private let blocker = FocusAppBlocker()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    blocker.clearExpiredSession()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "FocusAppBlocker") else { return }
    let messenger = registrar.messenger()
    let channel = FlutterMethodChannel(
      name: "rest_for_more/ios_app_blocking", binaryMessenger: messenger)
    blockingChannel = channel
    channel.setMethodCallHandler { [weak self] call, result in
      self?.blocker.handle(call, result: result)
    }

    FlutterMethodChannel(
      name: "com.example.rest_for_more/focus_notification",
      binaryMessenger: messenger
    ).setMethodCallHandler { call, result in
      FocusTimerNotifications.handle(call, result: result)
    }

    let deepLink = FlutterMethodChannel(
      name: "rest_for_more/deep_link",
      binaryMessenger: messenger)
    DeepLinkBridge.channel = deepLink
    deepLink.setMethodCallHandler { call, result in
      if call.method == "getInitial" {
        result(DeepLinkBridge.pending)
        DeepLinkBridge.pending = nil
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    if url.scheme?.lowercased() == "restformore" {
      DeepLinkBridge.send(url.absoluteString)
      return true
    }
    return super.application(app, open: url, options: options)
  }
}

private enum FocusTimerNotifications {
  private static let focusId = "focus_timer"
  private static let routineId = "routine_timer"

  static func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "showFocusTimer", "showRoutineTimer":
      guard let args = call.arguments as? [String: Any],
        let finishingAt = args["finishingAtMilliseconds"] as? Int
      else {
        result(
          FlutterError(
            code: "missing_finishing_time",
            message: "A finishing timestamp is required.",
            details: nil))
        return
      }
      let title = args["title"] as? String
      schedule(
        id: call.method == "showRoutineTimer" ? routineId : focusId,
        title: title ?? (call.method == "showRoutineTimer" ? "Morning routine" : "Focus Mode"),
        finishingAt: Date(timeIntervalSince1970: TimeInterval(finishingAt) / 1000),
        result: result)
    case "hideFocusTimer":
      UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [focusId])
      UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [focusId])
      result(nil)
    case "hideRoutineTimer":
      UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [routineId])
      UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [routineId])
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private static func schedule(
    id: String,
    title: String,
    finishingAt: Date,
    result: @escaping FlutterResult
  ) {
    let center = UNUserNotificationCenter.current()
    center.requestAuthorization(options: [.alert, .sound]) { granted, error in
      if let error = error {
        result(FlutterError(code: "notification_failed", message: error.localizedDescription, details: nil))
        return
      }
      guard granted else {
        result(nil)
        return
      }
      let content = UNMutableNotificationContent()
      content.title = title
      content.body = "Your session is complete."
      content.sound = .default
      let delay = max(finishingAt.timeIntervalSinceNow, 1)
      let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
      let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
      center.removePendingNotificationRequests(withIdentifiers: [id])
      center.add(request) { error in
        if let error = error {
          result(FlutterError(code: "notification_failed", message: error.localizedDescription, details: nil))
        } else {
          result(nil)
        }
      }
    }
  }
}

// Session-specific stores prevent a delayed callback from an old session
// from clearing the shields belonging to a newer session.
private final class FocusAppBlocker {
  private let defaults = UserDefaults.standard
  private let center = DeviceActivityCenter()
  private let selectionKey = "focus.blockedSelection"
  private let sessionKey = "focus.activeSession"
  private let endKey = "focus.sessionEnd"
  private var pickerIsPresented = false

  private var selection: FamilyActivitySelection {
    guard let data = defaults.data(forKey: selectionKey),
      let value = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data)
    else { return FamilyActivitySelection() }
    return value
  }

  private func count(_ value: FamilyActivitySelection) -> Int {
    value.applicationTokens.count + value.categoryTokens.count + value.webDomainTokens.count
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isAuthorized":
      clearExpiredSession()
      result(AuthorizationCenter.shared.authorizationStatus == .approved)
    case "requestPermission":
      Task { @MainActor in
        do {
          try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
          result(AuthorizationCenter.shared.authorizationStatus == .approved)
        } catch { result(failure("permission_denied", error)) }
      }
    case "selectionCount": result(count(selection))
    case "selectApps": presentPicker(result: result)
    case "startBlocking":
      guard let args = call.arguments as? [String: Any],
        let seconds = args["durationSeconds"] as? Int, seconds > 0, seconds <= 10800
      else {
        result(FlutterError(code: "invalid_duration", message: "Choose a focus duration between 1 second and 3 hours.", details: nil))
        return
      }
      do { try start(seconds: seconds); result(nil) }
      catch { result(failure("blocking_failed", error)) }
    case "stopBlocking": stop(); result(nil)
    default: result(FlutterMethodNotImplemented)
    }
  }

  private func start(seconds: Int) throws {
    guard AuthorizationCenter.shared.authorizationStatus == .approved else {
      throw NSError(domain: "FocusBlocking", code: 1,
        userInfo: [NSLocalizedDescriptionKey: "Allow Screen Time access before starting focus."])
    }
    let selected = selection
    guard count(selected) > 0 else {
      throw NSError(domain: "FocusBlocking", code: 2,
        userInfo: [NSLocalizedDescriptionKey: "Choose apps or categories to pause first."])
    }
    // DeviceActivity requires an interval of at least 15 minutes. Backdate
    // the start for shorter sessions; shields are applied immediately below.
    let end = Date().addingTimeInterval(TimeInterval(seconds))
    let start = min(Date(), end.addingTimeInterval(-16 * 60))
    let calendar = Calendar.current
    let components: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second]
    let schedule = DeviceActivitySchedule(
      intervalStart: calendar.dateComponents(components, from: start),
      intervalEnd: calendar.dateComponents(components, from: end), repeats: false)
    let id = "focus." + UUID().uuidString
    // Do not clear existing shields if the OS rejects the new schedule.
    try center.startMonitoring(DeviceActivityName(id), during: schedule)
    stop()
    defaults.set(id, forKey: sessionKey)
    defaults.set(end.timeIntervalSince1970, forKey: endKey)
    let store = ManagedSettingsStore(named: ManagedSettingsStore.Name(id))
    store.shield.applications = selected.applicationTokens.isEmpty ? nil : selected.applicationTokens
    store.shield.applicationCategories = selected.categoryTokens.isEmpty ? nil : .specific(selected.categoryTokens)
    store.shield.webDomains = selected.webDomainTokens.isEmpty ? nil : selected.webDomainTokens
    store.shield.webDomainCategories = selected.categoryTokens.isEmpty ? nil : .specific(selected.categoryTokens)
  }

  private func stop() {
    guard let id = defaults.string(forKey: sessionKey) else { return }
    ManagedSettingsStore(named: ManagedSettingsStore.Name(id)).clearAllSettings()
    center.stopMonitoring([DeviceActivityName(id)])
    defaults.removeObject(forKey: sessionKey)
    defaults.removeObject(forKey: endKey)
  }

  func clearExpiredSession() {
    if defaults.string(forKey: sessionKey) != nil,
       defaults.double(forKey: endKey) <= Date().timeIntervalSince1970 { stop() }
  }

  private func presentPicker(result: @escaping FlutterResult) {
    guard AuthorizationCenter.shared.authorizationStatus == .approved else {
      result(FlutterError(code: "permission_denied", message: "Allow Screen Time access first.", details: nil)); return
    }
    guard !pickerIsPresented,
      let root = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene })
        .flatMap({ $0.windows }).first(where: { $0.isKeyWindow })?.rootViewController
    else {
      result(FlutterError(code: "picker_unavailable", message: "App selection is unavailable right now.", details: nil)); return
    }
    var presenter = root
    while let next = presenter.presentedViewController { presenter = next }
    pickerIsPresented = true
    let view = FocusAppsPicker(initialSelection: selection) { [weak self, weak presenter] value in
      guard let self = self else { return }
      var response: Any? = nil
      if let value = value {
        do {
          let data = try PropertyListEncoder().encode(value)
          self.defaults.set(data, forKey: self.selectionKey)
          response = self.count(value)
        } catch { response = self.failure("selection_failed", error) }
      }
      presenter?.dismiss(animated: true) {
        self.pickerIsPresented = false
        result(response)
      }
    }
    let controller = UIHostingController(rootView: view)
    controller.modalPresentationStyle = .fullScreen
    controller.isModalInPresentation = true
    presenter.present(controller, animated: true)
  }

  private func failure(_ code: String, _ error: Error) -> FlutterError {
    FlutterError(code: code, message: error.localizedDescription, details: nil)
  }
}

private struct FocusAppsPicker: View {
  @State private var selection: FamilyActivitySelection
  let completion: (FamilyActivitySelection?) -> Void

  init(initialSelection: FamilyActivitySelection,
       completion: @escaping (FamilyActivitySelection?) -> Void) {
    _selection = State(initialValue: initialSelection)
    self.completion = completion
  }

  var body: some View {
    NavigationStack {
      FamilyActivityPicker(selection: $selection)
        .navigationTitle("Apps to pause")
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { completion(nil) }
          }
          ToolbarItem(placement: .confirmationAction) {
            Button("Save") { completion(selection) }
          }
        }
    }
  }
}
