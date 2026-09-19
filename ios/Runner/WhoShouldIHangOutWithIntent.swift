import AppIntents

@available(iOS 16.0, *)
struct WhoShouldIHangOutWithIntent: AppIntent {
  static var title: LocalizedStringResource = "Who should I hang out with"
  static var description = IntentDescription(
    "Tells you which friend you are most overdue to see."
  )

  func perform() async throws -> some IntentResult & ProvidesDialog {
    let snapshot = DueFriendSnapshotStore.load()
    return .result(dialog: IntentDialog(stringLiteral: snapshot.spokenSummary))
  }
}

@available(iOS 16.0, *)
struct FriendBuilderAppShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: WhoShouldIHangOutWithIntent(),
      phrases: [
        "Who should I hang out with in \(.applicationName)",
        "Who am I overdue to see in \(.applicationName)",
        "Who is due in \(.applicationName)",
      ]
    )
    AppShortcut(
      intent: LogHangoutIntent(),
      phrases: [
        "I hung out with \(\.$friend) in \(.applicationName)",
        "Log a hangout with \(\.$friend) in \(.applicationName)",
        "Log a hangout in \(.applicationName)",
      ]
    )
  }
}
