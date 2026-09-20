import AppIntents

@available(iOS 16.0, *)
struct FriendEntity: AppEntity {
  static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Friend")
  static var defaultQuery = FriendEntityQuery()

  /// Caps parameterized App Shortcut phrase expansion under Apple's 1,000-phrase budget.
  static let suggestedEntityLimit = 80

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
    Array(
      FriendCatalogStore.load()
        .prefix(FriendEntity.suggestedEntityLimit)
        .map {
          FriendEntity(id: $0.contactIdentifier, displayName: $0.displayName)
        }
    )
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
    let rankedMatches = FriendCatalogStore.load().compactMap {
      entry -> (rank: Int, entity: FriendEntity)? in
      guard let rank = Self.matchRank(displayName: entry.displayName, query: loweredQuery)
      else {
        return nil
      }
      return (
        rank,
        FriendEntity(id: entry.contactIdentifier, displayName: entry.displayName)
      )
    }

    return rankedMatches
      .sorted { left, right in
        if left.rank != right.rank {
          return left.rank < right.rank
        }
        return left.entity.displayName.localizedCaseInsensitiveCompare(
          right.entity.displayName
        ) == .orderedAscending
      }
      .map(\.entity)
  }

  /// Lower rank is a better match: exact full name, exact token, token prefix, then contains.
  private static func matchRank(displayName: String, query: String) -> Int? {
    let loweredName = displayName.lowercased()
    if loweredName == query {
      return 0
    }

    let tokens = loweredName.split(whereSeparator: \.isWhitespace).map(String.init)
    if tokens.contains(query) {
      return 1
    }
    if tokens.contains(where: { $0.hasPrefix(query) }) {
      return 2
    }
    if loweredName.hasPrefix(query) {
      return 3
    }
    if loweredName.contains(query) || tokens.contains(where: { $0.contains(query) }) {
      return 4
    }
    return nil
  }
}
