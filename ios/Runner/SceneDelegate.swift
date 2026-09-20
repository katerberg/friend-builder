import Flutter
import UIKit

/// UIScene entry point required by the iOS 27 SDK (TN3187 / Flutter UIScene adoption).
class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    if let controller = window?.rootViewController as? FlutterViewController {
      HangoutChannelBridge.register(with: controller.binaryMessenger)
      PendingHangoutChannel.register(with: controller.binaryMessenger)
      AppShortcutsChannel.register(with: controller.binaryMessenger)
    }
    AppShortcutsChannel.updateParametersIfAvailable()
  }
}
