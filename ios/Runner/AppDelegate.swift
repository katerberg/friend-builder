import UIKit
import Flutter
import Intents

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    let launched = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    attachCarPlayBridgeIfPossible()
    // Flutter may finish wiring the root controller slightly after launch.
    DispatchQueue.main.async { [weak self] in
      self?.attachCarPlayBridgeIfPossible()
    }
    return launched
  }

  override func application(
    _ application: UIApplication,
    configurationForConnecting connectingSceneSession: UISceneSession,
    options: UIScene.ConnectionOptions
  ) -> UISceneConfiguration {
    if connectingSceneSession.role.rawValue == "CPTemplateApplicationSceneSessionRoleApplication" {
      let configuration = UISceneConfiguration(
        name: "CarPlay Configuration",
        sessionRole: connectingSceneSession.role
      )
      configuration.delegateClass = CarPlaySceneDelegate.self
      return configuration
    }
    return super.application(
      application,
      configurationForConnecting: connectingSceneSession,
      options: options
    )
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    attachCarPlayBridgeIfPossible()
    CarPlayFlutterBridge.shared.onRefreshRequested?()
  }

  override func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
    if userActivity.activityType == "com.example.friendBuilder.sendMessage" {
      openSmsHandoff(from: userActivity)
      return true
    }
    return super.application(
      application,
      continue: userActivity,
      restorationHandler: restorationHandler
    )
  }

  private func openSmsHandoff(from userActivity: NSUserActivity) {
    let recipients = userActivity.userInfo?["recipients"] as? [String] ?? []
    let content = userActivity.userInfo?["content"] as? String ?? ""
    var components = URLComponents()
    components.scheme = "sms"
    if !recipients.isEmpty {
      components.path = recipients.joined(separator: ",")
    }
    if !content.isEmpty {
      components.queryItems = [URLQueryItem(name: "body", value: content)]
    }
    guard let url = components.url else { return }
    UIApplication.shared.open(url, options: [:], completionHandler: nil)
  }

  private func attachCarPlayBridgeIfPossible() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return
    }
    CarPlayFlutterBridge.shared.setup(binaryMessenger: controller.binaryMessenger)
  }
}
