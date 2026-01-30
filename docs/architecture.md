# Architecture

## Components

- App: `AgendaView/AgendaView/` (SwiftUI)
- Widget extension: `AgendaView/AgendaWidget/` (WidgetKit)

## Auth

- `AgendaView/AgendaView/Services/GoogleAuthService.swift`
  - OAuth via `ASWebAuthenticationSession`
  - Stores `access_token`, `refresh_token`, expiry, and `userEmail` in Keychain

## Data Fetch

- `AgendaView/AgendaView/Services/GoogleCalendarService.swift`
  - Fetch calendars from `calendarList`
  - Fetch events per calendar from `events` (singleEvents + orderBy=startTime)
  - Maps into `CalendarEvent` with an approximate color derived from `colorId`

## App State + Sync

- `AgendaView/AgendaView/Services/CalendarDataManager.swift`
  - Owns `calendars`, `events`, loading/error state
  - Loads cached data on init
  - Fetches calendars then events for selected calendars

## Storage

- App storage: `AgendaView/AgendaView/Services/StorageService.swift`
  - Uses App Group container when available, otherwise falls back to Documents
  - Files:
    - `calendars.json`
    - `events.json`
    - `selections.json`

- Widget storage: `AgendaView/AgendaWidget/WidgetStorageService.swift`
  - Reads `events.json` from the App Group container

## Widget Rendering

- `AgendaView/AgendaWidget/AgendaWidget.swift`
  - Loads cached events into a timeline entry
  - Schedules updates every ~15 minutes
  - Shows a "Tomorrow" separator when crossing days

## Invariants

- Widgets render from cached data only.
- App Group id must match across entitlements and both storage services: `group.deadairx.AgendaView`.
