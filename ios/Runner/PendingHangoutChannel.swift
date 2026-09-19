import Flutter
import Foundation

/// Early-registered channel so Dart can list/delete per-id App Group pending keys during startup.
enum PendingHangoutChannel {
  static let channelName = "com.example.friend_builder/pending_hangouts"

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
      case "listPendingHangouts":
        let items = PendingHangoutStore.load().map { $0.toDictionary() }
        result(items)
      case "removePendingHangout":
        guard
          let arguments = call.arguments as? [String: Any],
          let pendingId = arguments["pendingId"] as? String,
          !pendingId.isEmpty
        else {
          result(
            FlutterError(
              code: "invalid_arguments",
              message: "removePendingHangout requires pendingId",
              details: nil
            )
          )
          return
        }
        result(PendingHangoutStore.remove(pendingId: pendingId))
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
