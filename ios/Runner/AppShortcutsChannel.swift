import AppIntents
import Flutter
import UIKit

/// MethodChannel for refreshing App Shortcut parameters and opening the Shortcuts app.
enum AppShortcutsChannel {
  static let channelName = "com.example.friend_builder/app_shortcuts"

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
      switch call.method {
      case "updateParameters":
        updateParametersIfAvailable()
        result(true)
      case "openShortcuts":
        openShortcutsApp(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  /// Notifies App Intents that parameterized App Shortcut values may have changed.
  static func updateParametersIfAvailable() {
    guard #available(iOS 16.0, *) else {
      return
    }
    FriendBuilderAppShortcuts.updateAppShortcutParameters()
  }

  private static func openShortcutsApp(result: @escaping FlutterResult) {
    guard let url = URL(string: "shortcuts://") else {
      result(false)
      return
    }
    DispatchQueue.main.async {
      UIApplication.shared.open(url, options: [:]) { success in
        result(success)
      }
    }
  }
}
