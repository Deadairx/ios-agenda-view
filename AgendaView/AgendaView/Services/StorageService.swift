//
//  StorageService.swift
//  AgendaView
//

import Foundation

class StorageService {
    private let appGroupId = "group.deadairx.AgendaView"

    private var containerUrl: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId)
    }

    private var documentsUrl: URL {
        containerUrl ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    private var calendarsUrl: URL {
        documentsUrl.appendingPathComponent("calendars.json")
    }

    private var eventsUrl: URL {
        documentsUrl.appendingPathComponent("events.json")
    }

    private var selectionsUrl: URL {
        documentsUrl.appendingPathComponent("selections.json")
    }

    func saveCalendars(_ calendars: [GoogleCalendar]) {
        save(calendars, to: calendarsUrl)
    }

    func loadCalendars() -> [GoogleCalendar] {
        load(from: calendarsUrl) ?? []
    }

    func saveEvents(_ events: [CalendarEvent]) {
        save(events, to: eventsUrl)
    }

    func loadEvents() -> [CalendarEvent] {
        load(from: eventsUrl) ?? []
    }

    func saveCalendarSelections(_ calendars: [GoogleCalendar]) {
        let selections = Dictionary(uniqueKeysWithValues: calendars.map { ($0.id, $0.isSelected) })
        save(selections, to: selectionsUrl)
    }

    func loadCalendarSelections() -> [String: Bool] {
        load(from: selectionsUrl) ?? [:]
    }

    private func save<T: Encodable>(_ value: T, to url: URL) {
        do {
            let data = try JSONEncoder().encode(value)
            try data.write(to: url)
        } catch {
            print("Failed to save to \(url): \(error)")
        }
    }

    private func load<T: Decodable>(from url: URL) -> T? {
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            return nil
        }
    }
}
