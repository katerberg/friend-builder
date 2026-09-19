import Foundation

/// Reads the App Group snapshot written by Flutter `DueFriendSnapshotService`.
enum DueFriendSnapshotStore {
  static let appGroupId = "group.com.example.friendBuilder"

  static let keyFound = "due_friend_found"
  static let keyReason = "due_friend_reason"
  static let keyContactIdentifier = "due_friend_contact_identifier"
  static let keyDisplayName = "due_friend_display_name"
  static let keyUrgency = "due_friend_urgency"

  struct Snapshot {
    let found: Bool
    let reason: String
    let contactIdentifier: String
    let displayName: String
    let urgency: String

    var titleText: String {
      if found {
        return displayName.isEmpty ? "Friend" : displayName
      }
      if reason == "contacts_permission" {
        return "Contacts access required"
      }
      return "No one due"
    }

    var subtitleText: String {
      if found {
        return urgency.isEmpty ? "Due soon" : urgency
      }
      if reason == "contacts_permission" {
        return "Allow contacts in Friend Builder"
      }
      return "Add friends to contact in Friend Builder"
    }

    var spokenSummary: String {
      if found {
        let name = displayName.isEmpty ? "a friend" : displayName
        let urgencyText = urgency.isEmpty ? "is due soon" : urgency
        return "\(name) — \(urgencyText)"
      }
      if reason == "contacts_permission" {
        return "Contacts access is required in Friend Builder."
      }
      return "No one is due right now. Add friends to contact in Friend Builder."
    }

    static func fromPayload(_ payload: [String: Any]) -> Snapshot {
      Snapshot(
        found: payload["found"] as? Bool ?? false,
        reason: payload["reason"] as? String ?? "",
        contactIdentifier: payload["contactIdentifier"] as? String ?? "",
        displayName: payload["displayName"] as? String ?? "",
        urgency: payload["urgency"] as? String ?? ""
      )
    }
  }

  static func load() -> Snapshot {
    let defaults = UserDefaults(suiteName: appGroupId)
    return Snapshot(
      found: defaults?.bool(forKey: keyFound) ?? false,
      reason: defaults?.string(forKey: keyReason) ?? "",
      contactIdentifier: defaults?.string(forKey: keyContactIdentifier) ?? "",
      displayName: defaults?.string(forKey: keyDisplayName) ?? "",
      urgency: defaults?.string(forKey: keyUrgency) ?? ""
    )
  }
}
