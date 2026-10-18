//
//  SpookyWidget.swift
//  SpookyWidget
//
//  Created by James Fehr on 17/10/26.
//

import SwiftUI
import WidgetKit

struct HauntEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct HauntProvider: TimelineProvider {
    func placeholder(in context: Context) -> HauntEntry {
        HauntEntry(date: Date(), snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (HauntEntry) -> Void) {
        let snapshot = context.isPreview ? WidgetSnapshot.placeholder : (WidgetSnapshot.load() ?? .empty)
        completion(HauntEntry(date: Date(), snapshot: snapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HauntEntry>) -> Void) {
        let snapshot = WidgetSnapshot.load() ?? .empty
        let now = Date()

        // Redraw at each upcoming due time so reminders turn overdue on time.
        // The app also asks for a redraw whenever reminders change.
        let dueTimes = snapshot.upcoming.compactMap(\.dueDate).filter { $0 > now }.sorted()
        let entries = ([now] + dueTimes.prefix(10)).map { HauntEntry(date: $0, snapshot: snapshot) }
        completion(Timeline(entries: entries, policy: .after(now.addingTimeInterval(60 * 60))))
    }
}

struct SpookyWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: HauntEntry

    private var snapshot: WidgetSnapshot {
        entry.snapshot
    }

    var body: some View {
        Group {
            if family == .systemSmall {
                pumpkinSummary
            } else {
                HStack(spacing: 14) {
                    pumpkinSummary
                        .frame(width: 104)
                    upcomingList
                }
            }
        }
        .widgetBackground(Color.midnight)
    }

    private var pumpkinSummary: some View {
        VStack(spacing: 6) {
            PumpkinView(rot: PumpkinView.rot(forOpenCount: snapshot.openCount), lit: snapshot.openCount == 0)
                .frame(width: 66, height: 66)
            Text(snapshot.openCount == 0 ? "All clear!" : "\(snapshot.openCount) left")
                .font(.headline)
                .foregroundColor(.pumpkin)
            if snapshot.todayCount > 0 {
                Text("\(snapshot.todayCount) due today")
                    .font(.caption2)
                    .foregroundColor(.boneWhite.opacity(0.7))
            }
        }
    }

    private var upcomingList: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Lurking next")
                .font(.caption.bold())
                .foregroundColor(.pumpkin)

            if snapshot.upcoming.isEmpty {
                Text("Nothing lurking 🎃")
                    .font(.caption)
                    .foregroundColor(.boneWhite.opacity(0.7))
            }

            ForEach(snapshot.upcoming.prefix(3), id: \.self) { item in
                row(item)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func row(_ item: WidgetSnapshot.Item) -> some View {
        let overdue = item.dueDate.map { $0 < entry.date } ?? false
        return VStack(alignment: .leading, spacing: 1) {
            Text((overdue ? "👻 " : "") + item.title)
                .font(.subheadline)
                .foregroundColor(.boneWhite)
                .lineLimit(1)
            Text(label(for: item, overdue: overdue))
                .font(.caption2)
                .foregroundColor(overdue ? Color.ember : Color.boneWhite.opacity(0.6))
                .lineLimit(1)
        }
    }

    /// "Today 5:00 PM · Halloween", or "Overdue · Halloween", like the app's reminder rows
    private func label(for item: WidgetSnapshot.Item, overdue: Bool) -> String {
        var parts: [String] = []
        if overdue {
            parts.append("Overdue")
        } else {
            var when: [String] = []
            if let date = item.date {
                let calendar = Calendar.current
                when.append(calendar.isDateInToday(date) ? "Today"
                            : calendar.isDateInTomorrow(date) ? "Tomorrow"
                            : date.formatted(date: .numeric, time: .omitted))
            }
            if let time = item.time {
                when.append(time.formatted(date: .omitted, time: .shortened))
            }
            if !when.isEmpty {
                parts.append(when.joined(separator: " "))
            }
        }
        if !item.listName.isEmpty {
            parts.append(item.listName)
        }
        return parts.joined(separator: " · ")
    }
}

private extension View {
    /// iOS 17 needs widgets to declare their background; iOS 16 just draws it
    @ViewBuilder
    func widgetBackground(_ color: Color) -> some View {
        if #available(iOS 17.0, *) {
            containerBackground(color, for: .widget)
        } else {
            padding().background(color)
        }
    }
}

@main
struct SpookyWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "SpookyWidget", provider: HauntProvider()) { entry in
            SpookyWidgetView(entry: entry)
        }
        .configurationDisplayName("Haunted Reminders")
        .description("See how rotten your pumpkin is and what's lurking next.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct SpookyWidget_Previews: PreviewProvider {
    static var previews: some View {
        SpookyWidgetView(entry: HauntEntry(date: Date(), snapshot: .placeholder))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
