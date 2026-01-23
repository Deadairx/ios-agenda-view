//
//  CalendarDataManager.swift
//  AgendaView
//

import Foundation

@MainActor
class CalendarDataManager: ObservableObject {
    @Published var calendars: [GoogleCalendar] = []
    @Published var events: [CalendarEvent] = []
    @Published var isLoading = false
    @Published var error: String?

    private let authService: GoogleAuthService
    private let calendarService: GoogleCalendarService
    private let storageService: StorageService

    init(authService: GoogleAuthService) {
        self.authService = authService
        self.calendarService = GoogleCalendarService(authService: authService)
        self.storageService = StorageService()
        loadCachedData()
    }

    private func loadCachedData() {
        calendars = storageService.loadCalendars()
        events = storageService.loadEvents()
    }

    func fetchCalendars() async {
        isLoading = true
        error = nil

        do {
            let fetchedCalendars = try await calendarService.fetchCalendars()

            let savedSelections = storageService.loadCalendarSelections()
            calendars = fetchedCalendars.map { calendar in
                var cal = calendar
                if let isSelected = savedSelections[calendar.id] {
                    cal.isSelected = isSelected
                }
                return cal
            }

            storageService.saveCalendars(calendars)
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func fetchEvents() async {
        isLoading = true
        error = nil

        let selectedCalendarIds = calendars.filter { $0.isSelected }.map { $0.id }

        guard !selectedCalendarIds.isEmpty else {
            events = []
            isLoading = false
            return
        }

        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .month, value: 1, to: startDate) ?? startDate

        do {
            events = try await calendarService.fetchEvents(
                calendarIds: selectedCalendarIds,
                from: startDate,
                to: endDate
            )
            storageService.saveEvents(events)
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func toggleCalendar(_ calendar: GoogleCalendar) {
        if let index = calendars.firstIndex(where: { $0.id == calendar.id }) {
            calendars[index].isSelected.toggle()
            storageService.saveCalendarSelections(calendars)
        }
    }

    func refresh() async {
        await fetchCalendars()
        await fetchEvents()
    }
}
