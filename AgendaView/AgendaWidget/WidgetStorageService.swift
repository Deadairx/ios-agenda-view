//
//  WidgetStorageService.swift
//  AgendaWidget
//

import Foundation

class WidgetStorageService {
    private let appGroupId = "group.deadairx.AgendaView"

    private var containerUrl: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId)
    }

    private var eventsUrl: URL? {
        containerUrl?.appendingPathComponent("events.json")
    }

    func loadEvents() -> [WidgetCalendarEvent] {
        guard let url = eventsUrl else { return [] }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let events = try decoder.decode([WidgetCalendarEvent].self, from: data)
            return events.filter { $0.startDate >= Calendar.current.startOfDay(for: Date()) }
                .sorted { $0.startDate < $1.startDate }
        } catch {
            return []
        }
    }
}
