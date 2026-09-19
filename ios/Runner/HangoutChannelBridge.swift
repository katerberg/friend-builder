import Flutter
import Foundation

/// Invokes Flutter `logHangout` when the engine is warm; otherwise callers rely on the pending queue.
enum HangoutChannelBridge {
  static let channelName = "com.example.friend_builder/hangouts"

  private static var methodChannel: FlutterMethodChannel?

  static func register(with messenger: FlutterBinaryMessenger) {
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
          if (result is FlutterError) {
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
}
