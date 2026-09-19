import Foundation

/// App Group queue of hangouts logged via Siri before Dart drains them into SQLite.
///
/// Each pending hangout is its own UserDefaults key (`pending_hangout.<pendingId>`),
/// so concurrent Siri enqueues and Dart deletes cannot last-write-wins a shared JSON array.
enum PendingHangoutStore {
  static let appGroupId = "group.com.example.friendBuilder"
  /// Legacy single-blob key; migrated into per-id keys on first load/enqueue/remove.
  static let keyPendingJsonLegacy = "pending_hangouts_json"
  static let keyPrefix = "pending_hangout."

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

  static func storageKey(for pendingId: String) -> String {
    "\(keyPrefix)\(pendingId)"
  }

  /// All pending items (migrates legacy blob first). Safe under concurrent per-id writers.
  static func load() -> [Item] {
    migrateLegacyBlobIfNeeded()
    guard let defaults else {
      return []
    }
    var items: [Item] = []
    for (key, value) in defaults.dictionaryRepresentation() {
      guard key.hasPrefix(keyPrefix), let item = decodeItem(value) else {
        continue
      }
      items.append(item)
    }
    return items.sorted { $0.enqueuedAt < $1.enqueuedAt }
  }

  /// Writes one key for [pendingId] and verifies that key round-trips (no shared array).
  @discardableResult
  static func enqueue(
    pendingId: String,
    contactIdentifier: String,
    displayName: String
  ) -> Bool {
    migrateLegacyBlobIfNeeded()
    guard !pendingId.isEmpty, let defaults else {
      return false
    }
    let item = Item(
      pendingId: pendingId,
      contactIdentifier: contactIdentifier,
      displayName: displayName,
      enqueuedAt: ISO8601DateFormatter().string(from: Date())
    )
    guard let json = encodeItem(item) else {
      return false
    }
    let key = storageKey(for: pendingId)
    defaults.set(json, forKey: key)
    defaults.synchronize()
    return loadItem(pendingId: pendingId) == item
  }

  /// Deletes only the claimed id's key.
  @discardableResult
  static func remove(pendingId: String) -> Bool {
    migrateLegacyBlobIfNeeded()
    guard !pendingId.isEmpty, let defaults else {
      return false
    }
    defaults.removeObject(forKey: storageKey(for: pendingId))
    defaults.synchronize()
    return loadItem(pendingId: pendingId) == nil
  }

  private static func loadItem(pendingId: String) -> Item? {
    guard let defaults else {
      return nil
    }
    return decodeItem(defaults.object(forKey: storageKey(for: pendingId)))
  }

  private static func encodeItem(_ item: Item) -> String? {
    let data = try? JSONSerialization.data(withJSONObject: item.toDictionary())
    guard let data else {
      return nil
    }
    return String(data: data, encoding: .utf8)
  }

  private static func decodeItem(_ value: Any?) -> Item? {
    if let dictionary = value as? [String: Any] {
      return Item.fromDictionary(dictionary)
    }
    guard
      let json = value as? String,
      !json.isEmpty,
      let data = json.data(using: .utf8),
      let dictionary = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else {
      return nil
    }
    return Item.fromDictionary(dictionary)
  }

  /// One-time split of the old JSON array into per-id keys, then drop the blob.
  private static func migrateLegacyBlobIfNeeded() {
    guard let defaults else {
      return
    }
    guard
      let json = defaults.string(forKey: keyPendingJsonLegacy),
      !json.isEmpty,
      let data = json.data(using: .utf8),
      let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
    else {
      if defaults.object(forKey: keyPendingJsonLegacy) != nil {
        defaults.removeObject(forKey: keyPendingJsonLegacy)
        defaults.synchronize()
      }
      return
    }

    for dictionary in array {
      guard let item = Item.fromDictionary(dictionary), let encoded = encodeItem(item) else {
        continue
      }
      let key = storageKey(for: item.pendingId)
      if defaults.object(forKey: key) == nil {
        defaults.set(encoded, forKey: key)
      }
    }
    defaults.removeObject(forKey: keyPendingJsonLegacy)
    defaults.synchronize()
  }
}
