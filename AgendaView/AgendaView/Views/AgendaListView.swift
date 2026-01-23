//
//  AgendaListView.swift
//  AgendaView
//

import SwiftUI

struct AgendaListView: View {
    @ObservedObject var authService: GoogleAuthService
    @ObservedObject var dataManager: CalendarDataManager
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            Group {
                if dataManager.events.isEmpty && !dataManager.isLoading {
                    emptyState
                } else {
                    eventsList
                }
            }
            .navigationTitle("Agenda")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        openGoogleCalendarNewEvent()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .refreshable {
                await dataManager.refresh()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(authService: authService, dataManager: dataManager)
            }
            .task {
                if dataManager.calendars.isEmpty {
                    await dataManager.fetchCalendars()
                }
                await dataManager.fetchEvents()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("No Upcoming Events")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Your calendar is clear for the next month")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button("Refresh") {
                Task {
                    await dataManager.refresh()
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var eventsList: some View {
        List {
            ForEach(groupedEvents, id: \.0) { section in
                Section(header: Text(section.0)) {
                    ForEach(section.1) { event in
                        EventRow(event: event)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                openGoogleCalendarEvent(event)
                            }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .overlay {
            if dataManager.isLoading {
                ProgressView()
            }
        }
    }

    private var groupedEvents: [(String, [CalendarEvent])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"

        let grouped = Dictionary(grouping: dataManager.events) { event -> String in
            if event.isToday {
                return "Today"
            } else if event.isTomorrow {
                return "Tomorrow"
            } else {
                return formatter.string(from: event.startDate)
            }
        }

        return grouped.sorted { lhs, rhs in
            let lhsDate = lhs.value.first?.startDate ?? Date.distantFuture
            let rhsDate = rhs.value.first?.startDate ?? Date.distantFuture
            return lhsDate < rhsDate
        }
    }

    private func openGoogleCalendarEvent(_ event: CalendarEvent) {
        let urlString = "comgooglecalendar://eventbyid/\(event.id)"
        if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else if let webUrl = URL(string: "https://calendar.google.com/calendar/r/eventedit/\(event.id)") {
            UIApplication.shared.open(webUrl)
        }
    }

    private func openGoogleCalendarNewEvent() {
        let urlString = "comgooglecalendar://action/create"
        if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else if let webUrl = URL(string: "https://calendar.google.com/calendar/r/eventedit") {
            UIApplication.shared.open(webUrl)
        }
    }
}

struct EventRow: View {
    let event: CalendarEvent

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(event.color)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.body)
                    .lineLimit(1)

                Text(event.formattedTime)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}
