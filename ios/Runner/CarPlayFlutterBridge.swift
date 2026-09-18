import Foundation
import Flutter
import UIKit

/// Bridges CarPlay native UI to the Dart MethodChannel `friend_builder/carplay`.
final class CarPlayFlutterBridge {
  static let shared = CarPlayFlutterBridge()

  static let channelName = "friend_builder/carplay"

  private var methodChannel: FlutterMethodChannel?
  private var isMessengerReady = false
  private var pendingReadyHandlers: [() -> Void] = []

  var onRefreshRequested: (() -> Void)?

  private init() {}

  func setup(binaryMessenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: CarPlayFlutterBridge.channelName,
      binaryMessenger: binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(nil)
        return
      }
      if call.method == "refresh" {
        self.onRefreshRequested?()
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    methodChannel = channel
    isMessengerReady = true
    let handlers = pendingReadyHandlers
    pendingReadyHandlers.removeAll()
    handlers.forEach { $0() }
  }

  func whenReady(_ handler: @escaping () -> Void) {
    if isMessengerReady {
      handler()
    } else {
      pendingReadyHandlers.append(handler)
    }
  }

  func getTopPerson(completion: @escaping ([String: Any]?) -> Void) {
    whenReady { [weak self] in
      self?.methodChannel?.invokeMethod("getTopPerson", arguments: nil) { result in
        if let payload = result as? [String: Any] {
          completion(payload)
        } else {
          completion(nil)
        }
      }
    }
  }

  func logHangout(
    contactIdentifier: String,
    completion: @escaping (Bool) -> Void
  ) {
    whenReady { [weak self] in
      self?.methodChannel?.invokeMethod(
        "logHangout",
        arguments: ["contactIdentifier": contactIdentifier]
      ) { result in
        if let payload = result as? [String: Any],
           let ok = payload["ok"] as? Bool {
          completion(ok)
        } else {
          completion(false)
        }
      }
    }
  }
}
