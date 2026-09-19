import AppIntents

@available(iOS 16.0, *)
struct LogHangoutIntent: AppIntent {
  static var title: LocalizedStringResource = "Log a hangout"
  static var description = IntentDescription(
    "Logs a hangout with a friend in Friend Builder."
  )

  /// Opens the app so Dart can drain the verified App Group queue soon.
  static var openAppWhenRun: Bool = true

  @Parameter(title: "Friend")
  var friend: FriendEntity

  static var parameterSummary: some ParameterSummary {
    Summary("Log a hangout with \(\.$friend)")
  }

  func perform() async throws -> some IntentResult & ProvidesDialog {
    let catalog = FriendCatalogStore.load()
    if catalog.isEmpty {
      let snapshot = DueFriendSnapshotStore.load()
      if snapshot.reason == "contacts_permission" {
        return .result(
          dialog: IntentDialog(
            stringLiteral: "Contacts access is required in Friend Builder before I can log hangouts with Siri."
          )
        )
      }
      return .result(
        dialog: IntentDialog(
          stringLiteral: "No friends are available yet. Add friends to contact in Friend Builder first."
        )
      )
    }

    let displayName = friend.displayName.isEmpty ? "a friend" : friend.displayName
    let pendingId = UUID().uuidString

    // Queue-only: Dart drain is the sole SQLite writer for Siri hangouts.
    let enqueued = PendingHangoutStore.enqueue(
      pendingId: pendingId,
      contactIdentifier: friend.id,
      displayName: friend.displayName
    )

    if enqueued {
      return .result(
        dialog: IntentDialog(
          stringLiteral: "I'll save this hangout with \(displayName) when Friend Builder opens."
        )
      )
    }

    return .result(
      dialog: IntentDialog(
        stringLiteral: "I couldn't log that hangout. Please open Friend Builder and try again."
      )
    )
  }
}
