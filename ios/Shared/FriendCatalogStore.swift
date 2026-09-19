import Foundation

/// Reads the contactable-friend catalog written by Flutter for App Intents.
enum FriendCatalogStore {
  static let appGroupId = "group.com.example.friendBuilder"
  static let keyCatalogJson = "friend_catalog_json"

  struct Entry: Equatable {
    let contactIdentifier: String
    let displayName: String
  }

  static func load() -> [Entry] {
    guard
      let defaults = UserDefaults(suiteName: appGroupId),
      let json = defaults.string(forKey: keyCatalogJson),
      !json.isEmpty,
      let data = json.data(using: .utf8),
      let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
    else {
      return []
    }

    return array.compactMap { item in
      guard
        let contactIdentifier = item["contactIdentifier"] as? String,
        !contactIdentifier.isEmpty,
        let displayName = item["displayName"] as? String,
        !displayName.isEmpty
      else {
        return nil
      }
      return Entry(contactIdentifier: contactIdentifier, displayName: displayName)
    }
  }
}
