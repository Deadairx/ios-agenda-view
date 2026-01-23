//
//  SettingsView.swift
//  AgendaView
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var authService: GoogleAuthService
    @ObservedObject var dataManager: CalendarDataManager
    @State private var showingSignOutConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    if let email = authService.userEmail {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.blue)
                            Text(email)
                                .font(.body)
                        }
                    }

                    Button(role: .destructive) {
                        showingSignOutConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Sign Out")
                        }
                    }
                }

                Section("Calendars") {
                    if dataManager.calendars.isEmpty {
                        Text("No calendars found")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(dataManager.calendars) { calendar in
                            CalendarToggleRow(
                                calendar: calendar,
                                onToggle: {
                                    dataManager.toggleCalendar(calendar)
                                    Task {
                                        await dataManager.fetchEvents()
                                    }
                                }
                            )
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog(
                "Sign Out",
                isPresented: $showingSignOutConfirmation,
                titleVisibility: .visible
            ) {
                Button("Sign Out", role: .destructive) {
                    authService.signOut()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .task {
                if dataManager.calendars.isEmpty {
                    await dataManager.fetchCalendars()
                }
            }
        }
    }
}

struct CalendarToggleRow: View {
    let calendar: GoogleCalendar
    let onToggle: () -> Void

    var body: some View {
        Button {
            onToggle()
        } label: {
            HStack {
                Circle()
                    .fill(Color(hex: calendar.backgroundColor ?? "#4285F4") ?? .blue)
                    .frame(width: 12, height: 12)

                Text(calendar.summary)
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: calendar.isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(calendar.isSelected ? .blue : .secondary)
            }
        }
    }
}
