import Flutter
import UIKit

/// Switches the home-screen icon to the alternate icon matching the theme color.
enum AppIconChannel {
  static let channelName = "com.example.friend_builder/app_icon"

  private static var isRegistered = false

  static func register(with registrar: FlutterPluginRegistrar) {
    register(with: registrar.messenger())
  }

  static func register(with messenger: FlutterBinaryMessenger) {
    if isRegistered {
      return
    }
    isRegistered = true
    let channel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "setIcon" else {
        result(FlutterMethodNotImplemented)
        return
      }
      let arguments = call.arguments as? [String: Any]
      let iconName = (arguments?["iconName"] as? String).map { "AppIcon-\($0)" }
      setIcon(iconName, result: result)
    }
  }

  private static func setIcon(_ iconName: String?, result: @escaping FlutterResult) {
    DispatchQueue.main.async {
      let application = UIApplication.shared
      guard application.supportsAlternateIcons else {
        result(nil)
        return
      }
      if application.alternateIconName == iconName {
        result(nil)
        return
      }
      application.setAlternateIconName(iconName) { error in
        if let error {
          result(
            FlutterError(
              code: "set_icon_failed",
              message: error.localizedDescription,
              details: nil
            )
          )
        } else {
          result(nil)
        }
      }
    }
  }
}
