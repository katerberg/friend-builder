import Intents

/// Minimal SiriKit messaging surface for CarPlay communication entitlement compliance.
/// Product messaging is not a CarPlay v1 feature — send hands off into Messages via continueInApp.
class IntentHandler: INExtension, INSendMessageIntentHandling, INSearchForMessagesIntentHandling,
  INSetMessageAttributeIntentHandling
{
  override func handler(for intent: INIntent) -> Any {
    return self
  }

  // MARK: - INSendMessageIntentHandling

  func resolveRecipients(
    for intent: INSendMessageIntent,
    with completion: @escaping ([INSendMessageRecipientResolutionResult]) -> Void
  ) {
    guard let recipients = intent.recipients, !recipients.isEmpty else {
      completion([INSendMessageRecipientResolutionResult.needsValue()])
      return
    }
    completion(recipients.map { INSendMessageRecipientResolutionResult.success(with: $0) })
  }

  func resolveContent(
    for intent: INSendMessageIntent,
    with completion: @escaping (INStringResolutionResult) -> Void
  ) {
    if let content = intent.content, !content.isEmpty {
      completion(INStringResolutionResult.success(with: content))
    } else {
      completion(INStringResolutionResult.needsValue())
    }
  }

  func confirm(
    intent: INSendMessageIntent,
    completion: @escaping (INSendMessageIntentResponse) -> Void
  ) {
    completion(INSendMessageIntentResponse(code: .ready, userActivity: nil))
  }

  func handle(
    intent: INSendMessageIntent,
    completion: @escaping (INSendMessageIntentResponse) -> Void
  ) {
    let userActivity = NSUserActivity(activityType: "com.example.friendBuilder.sendMessage")
    userActivity.title = "Send Message"
    userActivity.userInfo = [
      "recipients": (intent.recipients ?? []).compactMap { $0.displayName },
      "content": intent.content ?? "",
    ]
    // Hand off to the host app / Messages rather than claiming an in-app messenger.
    let response = INSendMessageIntentResponse(code: .continueInApp, userActivity: userActivity)
    completion(response)
  }

  // MARK: - INSearchForMessagesIntentHandling

  func handle(
    intent: INSearchForMessagesIntent,
    completion: @escaping (INSearchForMessagesIntentResponse) -> Void
  ) {
    let response = INSearchForMessagesIntentResponse(code: .success, userActivity: nil)
    response.messages = []
    completion(response)
  }

  // MARK: - INSetMessageAttributeIntentHandling

  func handle(
    intent: INSetMessageAttributeIntent,
    completion: @escaping (INSetMessageAttributeIntentResponse) -> Void
  ) {
    completion(INSetMessageAttributeIntentResponse(code: .success, userActivity: nil))
  }
}
