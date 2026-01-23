//
//  AgendaWidget.swift
//  AgendaWidget
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    private let storageService = WidgetStorageService()

    func placeholder(in context: Context) -> AgendaEntry {
        AgendaEntry(date: Date(), events: Self.sampleEvents)
    }

    func getSnapshot(in context: Context, completion: @escaping (AgendaEntry) -> Void) {
        let events = storageService.loadEvents()
        let entry = AgendaEntry(date: Date(), events: events.isEmpty ? Self.sampleEvents : Array(events.prefix(6)))
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AgendaEntry>) -> Void) {
        let events = storageService.loadEvents()
        let upcomingEvents = events.filter { $0.startDate >= Date() || $0.isAllDay }
        let entry = AgendaEntry(date: Date(), events: Array(upcomingEvents.prefix(6)))

        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    static var sampleEvents: [WidgetCalendarEvent] {
        [
            WidgetCalendarEvent(id: "1", title: "Team Standup", startDate: Date(), isAllDay: false, colorHex: "#4285F4"),
            WidgetCalendarEvent(id: "2", title: "Lunch with Alex", startDate: Date().addingTimeInterval(3600 * 3), isAllDay: false, colorHex: "#33B679"),
            WidgetCalendarEvent(id: "3", title: "Project Review", startDate: Date().addingTimeInterval(3600 * 5), isAllDay: false, colorHex: "#E67C73")
        ]
    }
}

struct AgendaEntry: TimelineEntry {
    let date: Date
    let events: [WidgetCalendarEvent]
}

struct AgendaWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryRectangular:
            LockScreenWidgetView(events: entry.events)
        case .systemMedium:
            HomeScreenWidgetView(events: entry.events, size: .medium)
        case .systemLarge:
            HomeScreenWidgetView(events: entry.events, size: .large)
        default:
            HomeScreenWidgetView(events: entry.events, size: .medium)
        }
    }
}

struct LockScreenWidgetView: View {
    let events: [WidgetCalendarEvent]

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(displayItems.prefix(4), id: \.id) { item in
                switch item {
                case .event(let event):
                    HStack(spacing: 6) {
                        Text(event.formattedTime)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .frame(width: 50, alignment: .leading)
                        Text(event.title)
                            .font(.system(size: 12))
                            .lineLimit(1)
                    }
                case .separator(let text):
                    Text(text)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }

            if events.isEmpty {
                Text("No upcoming events")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var displayItems: [DisplayItem] {
        var items: [DisplayItem] = []
        var addedTomorrowSeparator = false

        for event in events.prefix(5) {
            if event.isTomorrow && !addedTomorrowSeparator {
                items.append(.separator("Tomorrow"))
                addedTomorrowSeparator = true
            }
            items.append(.event(event))
        }

        return items
    }
}

struct HomeScreenWidgetView: View {
    let events: [WidgetCalendarEvent]
    let size: WidgetSize

    enum WidgetSize {
        case medium, large
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Agenda")
                    .font(.headline)
                Spacer()
                Image(systemName: "calendar")
                    .foregroundStyle(.secondary)
            }

            if events.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "calendar.badge.checkmark")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No upcoming events")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                Spacer()
            } else {
                ForEach(displayItems.prefix(maxItems), id: \.id) { item in
                    switch item {
                    case .event(let event):
                        HomeEventRow(event: event)
                    case .separator(let text):
                        Text(text)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .padding()
    }

    private var maxItems: Int {
        size == .large ? 8 : 4
    }

    private var displayItems: [DisplayItem] {
        var items: [DisplayItem] = []
        var addedTomorrowSeparator = false

        for event in events {
            if event.isTomorrow && !addedTomorrowSeparator {
                items.append(.separator("Tomorrow"))
                addedTomorrowSeparator = true
            }
            items.append(.event(event))
        }

        return items
    }
}

struct HomeEventRow: View {
    let event: WidgetCalendarEvent

    var body: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 2)
                .fill(event.color)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.subheadline)
                    .lineLimit(1)
                Text(event.formattedTime)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 2)
    }
}

enum DisplayItem: Identifiable {
    case event(WidgetCalendarEvent)
    case separator(String)

    var id: String {
        switch self {
        case .event(let event): return event.id
        case .separator(let text): return "sep_\(text)"
        }
    }
}

@main
struct AgendaWidget: WidgetBundle {
    var body: some Widget {
        AgendaLockScreenWidget()
        AgendaHomeWidget()
    }
}

struct AgendaLockScreenWidget: Widget {
    let kind: String = "AgendaLockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            AgendaWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Agenda")
        .description("View your upcoming events at a glance.")
        .supportedFamilies([.accessoryRectangular])
    }
}

struct AgendaHomeWidget: Widget {
    let kind: String = "AgendaHomeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            AgendaWidgetEntryView(entry: entry)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("Agenda")
        .description("View your upcoming events with colors.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}
