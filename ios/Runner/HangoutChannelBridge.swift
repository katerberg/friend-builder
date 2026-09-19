import Flutter
import Foundation

/// Invokes Flutter hangout MethodChannel methods when the engine is warm.
enum HangoutChannelBridge {
  static let channelName = "com.example.friend_builder/hangouts"

  private static var methodChannel: FlutterMethodChannel?

  static func register(with messenger: FlutterBinaryMessenger) {
    if methodChannel != nil {
      return
    }
    methodChannel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: messenger
    )
  }

  static func logHangout(
    pendingId: String,
    contactIdentifier: String,
    displayName: String
  ) async -> Bool {
    guard let methodChannel else {
      return false
    }

    return await withCheckedContinuation { continuation in
      DispatchQueue.main.async {
        methodChannel.invokeMethod(
          "logHangout",
          arguments: [
            "pendingId": pendingId,
            "contactIdentifier": contactIdentifier,
            "displayName": displayName,
          ]
        ) { result in
          if result is FlutterError {
            continuation.resume(returning: false)
            return
          }
          if let map = result as? [String: Any], map["ok"] as? Bool == true {
            continuation.resume(returning: true)
            return
          }
          continuation.resume(returning: false)
        }
      }
    }
  }

  /// Live ranking when Flutter is awake; nil when the engine is unavailable.
  static func getTopPerson() async -> [String: Any]? {
    guard let methodChannel else {
      return nil
    }

    return await withCheckedContinuation { continuation in
      DispatchQueue.main.async {
        methodChannel.invokeMethod("getTopPerson", arguments: nil) { result in
          if result is FlutterError {
            continuation.resume(returning: nil)
            return
          }
          if let map = result as? [String: Any] {
            continuation.resume(returning: map)
            return
          }
          continuation.resume(returning: nil)
        }
      }
    }
  }
}
