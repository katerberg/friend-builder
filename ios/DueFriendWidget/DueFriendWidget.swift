import SwiftUI
import WidgetKit
import UIKit

private let widgetKind = "DueFriendWidget"

struct DueFriendEntry: TimelineEntry {
  let date: Date
  let snapshot: DueFriendSnapshotStore.Snapshot
}

struct DueFriendProvider: TimelineProvider {
  func placeholder(in context: Context) -> DueFriendEntry {
    DueFriendEntry(
      date: Date(),
      snapshot: DueFriendSnapshotStore.Snapshot(
        found: true,
        reason: "",
        contactIdentifier: "",
        displayName: "Alex",
        urgency: "2 days late"
      )
    )
  }

  func getSnapshot(in context: Context, completion: @escaping (DueFriendEntry) -> Void) {
    completion(DueFriendEntry(date: Date(), snapshot: DueFriendSnapshotStore.load()))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<DueFriendEntry>) -> Void) {
    let entry = DueFriendEntry(date: Date(), snapshot: DueFriendSnapshotStore.load())
    completion(Timeline(entries: [entry], policy: .atEnd))
  }
}

struct DueFriendWidgetView: View {
  var entry: DueFriendEntry

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("Friend Crafter")
        .font(.caption2)
        .foregroundColor(.secondary)
      Text(entry.snapshot.titleText)
        .font(.headline)
        .lineLimit(2)
      Text(entry.snapshot.subtitleText)
        .font(.subheadline)
        .foregroundColor(.secondary)
        .lineLimit(2)
      Spacer(minLength: 0)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .padding(.vertical, 4)
    .widgetURL(URL(string: "friendbuilder://due-friend"))
  }
}

@main
struct DueFriendWidget: Widget {
  let kind: String = widgetKind

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: DueFriendProvider()) { entry in
      if #available(iOSApplicationExtension 17.0, *) {
        DueFriendWidgetView(entry: entry)
          .containerBackground(.fill.tertiary, for: .widget)
      } else {
        DueFriendWidgetView(entry: entry)
          .padding()
          .background(Color(.systemBackground))
      }
    }
    .configurationDisplayName("Who is due")
    .description("Shows the friend you are most overdue to see.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}
