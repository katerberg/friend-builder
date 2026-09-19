import AppIntents

@available(iOS 16.0, *)
struct LogHangoutIntent: AppIntent {
  static var title: LocalizedStringResource = "Log a hangout"
  static var description = IntentDescription(
    "Logs a hangout with a friend in Friend Builder."
  )

  @Parameter(title: "Friend")
  var friend: FriendEntity

  static var parameterSummary: some ParameterSummary {
    Summary("Log a hangout with \(\.$friend)")
  }

  func perform() async throws -> some IntentResult & ProvidesDialog {
    let catalog = FriendCatalogStore.load()
    if catalog.isEmpty {
      return .result(
        dialog: IntentDialog(
          stringLiteral: "No friends are available yet. Add friends to contact in Friend Builder first."
        )
      )
    }

    let displayName = friend.displayName.isEmpty ? "a friend" : friend.displayName
    let pendingId = UUID().uuidString

    PendingHangoutStore.enqueue(
      pendingId: pendingId,
      contactIdentifier: friend.id,
      displayName: friend.displayName
    )

    let savedImmediately = await HangoutChannelBridge.logHangout(
      pendingId: pendingId,
      contactIdentifier: friend.id,
      displayName: friend.displayName
    )
    if savedImmediately {
      PendingHangoutStore.remove(pendingId: pendingId)
    }

    return .result(
      dialog: IntentDialog(stringLiteral: "Logged a hangout with \(displayName).")
    )
  }
}
