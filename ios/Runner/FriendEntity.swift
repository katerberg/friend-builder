import AppIntents

@available(iOS 16.0, *)
struct FriendEntity: AppEntity {
  static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Friend")
  static var defaultQuery = FriendEntityQuery()

  var id: String
  var displayName: String

  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(title: "\(displayName)")
  }
}

@available(iOS 16.0, *)
struct FriendEntityQuery: EntityQuery {
  func entities(for identifiers: [FriendEntity.ID]) async throws -> [FriendEntity] {
    let catalog = FriendCatalogStore.load()
    return catalog
      .filter { identifiers.contains($0.contactIdentifier) }
      .map {
        FriendEntity(id: $0.contactIdentifier, displayName: $0.displayName)
      }
  }

  func suggestedEntities() async throws -> [FriendEntity] {
    FriendCatalogStore.load().map {
      FriendEntity(id: $0.contactIdentifier, displayName: $0.displayName)
    }
  }
}

@available(iOS 16.0, *)
extension FriendEntityQuery: EntityStringQuery {
  func entities(matching string: String) async throws -> [FriendEntity] {
    let query = string.trimmingCharacters(in: .whitespacesAndNewlines)
    if query.isEmpty {
      return try await suggestedEntities()
    }
    let loweredQuery = query.lowercased()
    return FriendCatalogStore.load()
      .filter { $0.displayName.lowercased().contains(loweredQuery) }
      .map {
        FriendEntity(id: $0.contactIdentifier, displayName: $0.displayName)
      }
  }
}
