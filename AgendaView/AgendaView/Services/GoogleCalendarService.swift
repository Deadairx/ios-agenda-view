//
//  GoogleCalendarService.swift
//  AgendaView
//

import Foundation

class GoogleCalendarService {
    private let authService: GoogleAuthService

    init(authService: GoogleAuthService) {
        self.authService = authService
    }

    func fetchCalendars() async throws -> [GoogleCalendar] {
        guard let accessToken = await authService.getValidAccessToken() else {
            throw CalendarError.notAuthenticated
        }

        let url = URL(string: "https://www.googleapis.com/calendar/v3/users/me/calendarList")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw CalendarError.requestFailed
        }

        let calendarListResponse = try JSONDecoder().decode(CalendarListResponse.self, from: data)

        return calendarListResponse.items.map { item in
            GoogleCalendar(
                id: item.id,
                summary: item.summary,
                colorId: item.colorId,
                backgroundColor: item.backgroundColor,
                isSelected: true
            )
        }
    }

    func fetchEvents(calendarIds: [String], from startDate: Date, to endDate: Date) async throws -> [CalendarEvent] {
        guard let accessToken = await authService.getValidAccessToken() else {
            throw CalendarError.notAuthenticated
        }

        var allEvents: [CalendarEvent] = []
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]

        for calendarId in calendarIds {
            let encodedCalendarId = calendarId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? calendarId

            var components = URLComponents(string: "https://www.googleapis.com/calendar/v3/calendars/\(encodedCalendarId)/events")!
            components.queryItems = [
                URLQueryItem(name: "timeMin", value: formatter.string(from: startDate)),
                URLQueryItem(name: "timeMax", value: formatter.string(from: endDate)),
                URLQueryItem(name: "singleEvents", value: "true"),
                URLQueryItem(name: "orderBy", value: "startTime"),
                URLQueryItem(name: "maxResults", value: "250")
            ]

            guard let url = components.url else { continue }

            var request = URLRequest(url: url)
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

            do {
                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    continue
                }

                let eventsResponse = try JSONDecoder().decode(EventsResponse.self, from: data)

                let events = eventsResponse.items.compactMap { item -> CalendarEvent? in
                    guard let title = item.summary else { return nil }

                    let isAllDay = item.start.date != nil
                    let startDate: Date
                    let endDate: Date

                    if isAllDay {
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd"
                        guard let start = item.start.date.flatMap({ dateFormatter.date(from: $0) }),
                              let end = item.end.date.flatMap({ dateFormatter.date(from: $0) }) else {
                            return nil
                        }
                        startDate = start
                        endDate = end
                    } else {
                        guard let startDateTime = item.start.dateTime,
                              let endDateTime = item.end.dateTime,
                              let start = formatter.date(from: startDateTime),
                              let end = formatter.date(from: endDateTime) else {
                            return nil
                        }
                        startDate = start
                        endDate = end
                    }

                    return CalendarEvent(
                        id: item.id,
                        title: title,
                        startDate: startDate,
                        endDate: endDate,
                        isAllDay: isAllDay,
                        calendarId: calendarId,
                        colorHex: item.colorId.flatMap { Self.colorFromId($0) } ?? "#4285F4"
                    )
                }

                allEvents.append(contentsOf: events)
            } catch {
                print("Error fetching events for calendar \(calendarId): \(error)")
            }
        }

        return allEvents.sorted { $0.startDate < $1.startDate }
    }

    private static func colorFromId(_ colorId: String) -> String {
        let colors: [String: String] = [
            "1": "#7986CB",
            "2": "#33B679",
            "3": "#8E24AA",
            "4": "#E67C73",
            "5": "#F6BF26",
            "6": "#F4511E",
            "7": "#039BE5",
            "8": "#616161",
            "9": "#3F51B5",
            "10": "#0B8043",
            "11": "#D50000"
        ]
        return colors[colorId] ?? "#4285F4"
    }
}

enum CalendarError: Error, LocalizedError {
    case notAuthenticated
    case requestFailed
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not authenticated with Google"
        case .requestFailed:
            return "Failed to fetch data from Google Calendar"
        case .decodingFailed:
            return "Failed to parse calendar data"
        }
    }
}

private struct CalendarListResponse: Codable {
    let items: [CalendarListItem]
}

private struct CalendarListItem: Codable {
    let id: String
    let summary: String
    let colorId: String?
    let backgroundColor: String?
}

private struct EventsResponse: Codable {
    let items: [EventItem]
}

private struct EventItem: Codable {
    let id: String
    let summary: String?
    let start: EventDateTime
    let end: EventDateTime
    let colorId: String?
}

private struct EventDateTime: Codable {
    let date: String?
    let dateTime: String?
}
