import CarPlay
import Foundation
import UIKit

/// Native CarPlay UI: list root → contact detail → optional multi-number sheet → `tel:`.
final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
  private weak var interfaceController: CPInterfaceController?
  private weak var templateApplicationScene: CPTemplateApplicationScene?

  private var currentTopPerson: [String: Any]?
  private var isLoading = true

  override init() {
    super.init()
    CarPlayFlutterBridge.shared.onRefreshRequested = { [weak self] in
      self?.reloadTopPerson()
    }
  }

  func templateApplicationScene(
    _ templateApplicationScene: CPTemplateApplicationScene,
    didConnect interfaceController: CPInterfaceController
  ) {
    self.templateApplicationScene = templateApplicationScene
    self.interfaceController = interfaceController
    isLoading = true
    interfaceController.setRootTemplate(makeRootTemplate(), animated: false) { _, _ in }
    reloadTopPerson()
  }

  func templateApplicationScene(
    _ templateApplicationScene: CPTemplateApplicationScene,
    didDisconnect interfaceController: CPInterfaceController
  ) {
    if self.interfaceController === interfaceController {
      self.interfaceController = nil
    }
    if self.templateApplicationScene === templateApplicationScene {
      self.templateApplicationScene = nil
    }
  }

  private func reloadTopPerson() {
    isLoading = true
    updateRootTemplate()
    CarPlayFlutterBridge.shared.getTopPerson { [weak self] payload in
      DispatchQueue.main.async {
        guard let self = self else { return }
        self.isLoading = false
        self.currentTopPerson = payload
        self.updateRootTemplate()
      }
    }
  }

  private func updateRootTemplate() {
    guard let interfaceController = interfaceController else { return }
    interfaceController.setRootTemplate(makeRootTemplate(), animated: true) { _, _ in }
  }

  private func makeRootTemplate() -> CPListTemplate {
    if isLoading && currentTopPerson == nil {
      let loadingItem = CPListItem(text: "Loading…", detailText: nil)
      loadingItem.handler = { _, completion in
        completion()
      }
      let section = CPListSection(items: [loadingItem])
      return CPListTemplate(title: "Friend Crafter", sections: [section])
    }

    let found = currentTopPerson?["found"] as? Bool ?? false
    if !found {
      let reason = currentTopPerson?["reason"] as? String
      let emptyTemplate = CPListTemplate(title: "Friend Crafter", sections: [])
      if reason == "contacts_permission" {
        emptyTemplate.emptyViewTitleVariants = ["Contacts access required"]
        emptyTemplate.emptyViewSubtitleVariants = [
          "Allow contacts access in Friend Builder to see who is due"
        ]
      } else {
        emptyTemplate.emptyViewTitleVariants = ["No one due"]
        emptyTemplate.emptyViewSubtitleVariants = [
          "Add friends to contact in Friend Builder"
        ]
      }
      return emptyTemplate
    }

    let displayName = currentTopPerson?["displayName"] as? String ?? "Friend"
    let urgency = currentTopPerson?["urgency"] as? String
    let listItem = CPListItem(text: displayName, detailText: urgency)
    listItem.handler = { [weak self] _, completion in
      self?.pushContactDetail()
      completion()
    }
    let section = CPListSection(items: [listItem])
    return CPListTemplate(title: "Friend Crafter", sections: [section])
  }

  private func pushContactDetail() {
    guard let interfaceController = interfaceController,
          let person = currentTopPerson,
          person["found"] as? Bool == true else {
      return
    }

    let displayName = person["displayName"] as? String ?? "Friend"
    let urgency = person["urgency"] as? String ?? ""
    let hasPhone = person["hasPhone"] as? Bool ?? false

    let contact = CPContact(name: displayName, image: makeContactImage(from: person))
    if hasPhone {
      contact.subtitle = urgency
      let callButton = CPContactCallButton { [weak self] _ in
        self?.handleCallPressed(for: person)
      }
      contact.actions = [callButton]
    } else {
      contact.subtitle = urgency.isEmpty ? "Missing contact info" : "\(urgency) · Missing contact info"
      contact.actions = []
    }

    let detailTemplate = CPContactTemplate(contact: contact)
    interfaceController.pushTemplate(detailTemplate, animated: true) { _, _ in }
  }

  private func makeContactImage(from person: [String: Any]) -> UIImage {
    if let photoBase64 = person["photoBase64"] as? String,
       let data = Data(base64Encoded: photoBase64),
       let image = UIImage(data: data) {
      return image
    }
    let size = CGSize(width: 120, height: 120)
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { context in
      UIColor.systemGray3.setFill()
      context.fill(CGRect(origin: .zero, size: size))
    }
  }

  private func handleCallPressed(for person: [String: Any]) {
    let phones = person["phones"] as? [[String: Any]] ?? []
    let dialable: [(label: String, number: String)] = phones.compactMap { entry in
      guard let number = entry["number"] as? String, !number.isEmpty else {
        return nil
      }
      let label = entry["label"] as? String ?? number
      return (label, number)
    }

    guard !dialable.isEmpty else { return }

    if dialable.count == 1 {
      dial(number: dialable[0].number, contactIdentifier: person["contactIdentifier"] as? String)
      return
    }

    let actions = dialable.map { phone in
      CPAlertAction(title: "\(phone.label): \(phone.number)", style: .default) { [weak self] _ in
        self?.dial(
          number: phone.number,
          contactIdentifier: person["contactIdentifier"] as? String
        )
      }
    }
    let cancel = CPAlertAction(title: "Cancel", style: .cancel) { _ in }
    let sheet = CPActionSheetTemplate(
      title: "Call",
      message: person["displayName"] as? String,
      actions: actions + [cancel]
    )
    interfaceController?.presentTemplate(sheet, animated: true) { _, _ in }
  }

  private func dial(number: String, contactIdentifier: String?) {
    guard let scene = templateApplicationScene,
          let url = URL(string: "tel://\(number)") else {
      return
    }

    scene.open(url) { [weak self] success in
      guard success, let contactIdentifier = contactIdentifier, !contactIdentifier.isEmpty else {
        return
      }
      CarPlayFlutterBridge.shared.logHangout(contactIdentifier: contactIdentifier) { _ in
        DispatchQueue.main.async {
          self?.reloadTopPerson()
        }
      }
    }
  }
}
