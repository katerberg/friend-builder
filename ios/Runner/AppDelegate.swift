import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let registrar = self.registrar(forPlugin: "PendingHangoutChannel") {
      PendingHangoutChannel.register(with: registrar)
    }
    if let registrar = self.registrar(forPlugin: "AppShortcutsChannel") {
      AppShortcutsChannel.register(with: registrar)
    }
    AppShortcutsChannel.updateParametersIfAvailable()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
