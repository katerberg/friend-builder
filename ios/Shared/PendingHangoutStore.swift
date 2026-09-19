import Foundation

/// App Group queue of hangouts logged via Siri before Dart drains them into SQLite.
enum PendingHangoutStore {
  static let appGroupId = "group.com.example.friendBuilder"
  static let keyPendingJson = "pending_hangouts_json"

  struct Item: Equatable {
    let pendingId: String
    let contactIdentifier: String
    let displayName: String
    let enqueuedAt: String

    func toDictionary() -> [String: String] {
      [
        "pendingId": pendingId,
        "contactIdentifier": contactIdentifier,
        "displayName": displayName,
        "enqueuedAt": enqueuedAt,
      ]
    }

    static func fromDictionary(_ item: [String: Any]) -> Item? {
      guard
        let pendingId = item["pendingId"] as? String,
        !pendingId.isEmpty,
        let contactIdentifier = item["contactIdentifier"] as? String,
        !contactIdentifier.isEmpty
      else {
        return nil
      }
      return Item(
        pendingId: pendingId,
        contactIdentifier: contactIdentifier,
        displayName: item["displayName"] as? String ?? "",
        enqueuedAt: item["enqueuedAt"] as? String ?? ""
      )
    }
  }

  private static var defaults: UserDefaults? {
    UserDefaults(suiteName: appGroupId)
  }

  static func load() -> [Item] {
    guard
      let json = defaults?.string(forKey: keyPendingJson),
      !json.isEmpty,
      let data = json.data(using: .utf8),
      let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
    else {
      return []
    }
    return array.compactMap(Item.fromDictionary)
  }

  static func save(_ items: [Item]) {
    let dictionaries = items.map { $0.toDictionary() }
    guard
      let data = try? JSONSerialization.data(withJSONObject: dictionaries),
      let json = String(data: data, encoding: .utf8)
    else {
      return
    }
    defaults?.set(json, forKey: keyPendingJson)
  }

  static func enqueue(
    pendingId: String,
    contactIdentifier: String,
    displayName: String
  ) {
    var items = load()
    items.append(
      Item(
        pendingId: pendingId,
        contactIdentifier: contactIdentifier,
        displayName: displayName,
        enqueuedAt: ISO8601DateFormatter().string(from: Date())
      )
    )
    save(items)
  }

  static func remove(pendingId: String) {
    let remaining = load().filter { $0.pendingId != pendingId }
    save(remaining)
  }
}
