import DeviceActivity
import FamilyControls
import Flutter
import ManagedSettings
import SwiftUI
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var blockingChannel: FlutterMethodChannel?
  private let blocker = FocusAppBlocker()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    blocker.clearExpiredSession()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "FocusAppBlocker") else { return }
    let channel = FlutterMethodChannel(
      name: "rest_for_more/ios_app_blocking", binaryMessenger: registrar.messenger())
    blockingChannel = channel
    channel.setMethodCallHandler { [weak self] call, result in
      self?.blocker.handle(call, result: result)
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
