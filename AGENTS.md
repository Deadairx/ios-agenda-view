# Agent Notes (ios-agenda-widget)

This repo is a native iOS app + WidgetKit extension that shows upcoming Google Calendar events.

## Repo Map

- `AgendaView/AgendaView/` - iOS app (SwiftUI)
- `AgendaView/AgendaWidget/` - Widget extension (WidgetKit)

Key files:

- Auth: `AgendaView/AgendaView/Services/GoogleAuthService.swift`
- Google API: `AgendaView/AgendaView/Services/GoogleCalendarService.swift`
- Sync + state: `AgendaView/AgendaView/Services/CalendarDataManager.swift`
- App cache: `AgendaView/AgendaView/Services/StorageService.swift`
- Widget UI + timeline: `AgendaView/AgendaWidget/AgendaWidget.swift`
- Widget cache read: `AgendaView/AgendaWidget/WidgetStorageService.swift`

## Core Constraints (Repo-Specific)

- Widgets should not do network requests. They must render from cached data.
- Cached data is shared via an App Group container.
  - App Group id: `group.deadairx.AgendaView`
  - Cache file name: `events.json`
- OAuth client id is expected in `Secrets.plist` (untracked). Use `Secrets.example.plist` as a template.

## Data Flow (High Level)

- App signs in and stores tokens in Keychain (`GoogleAuthService`).
- App fetches calendars/events (`GoogleCalendarService`) and persists them (`StorageService`).
- Widget reads cached events from the App Group container (`WidgetStorageService`) and displays them.

## Build / Test

- List schemes: `xcodebuild -list -project "AgendaView/AgendaView.xcodeproj"`
- Build app: `xcodebuild -project "AgendaView/AgendaView.xcodeproj" -scheme AgendaView -destination 'platform=iOS Simulator,name=iPhone 15' build`
- Build widget extension: `xcodebuild -project "AgendaView/AgendaView.xcodeproj" -scheme AgendaWidgetExtension -destination 'platform=iOS Simulator,name=iPhone 15' build`
- Run tests: `xcodebuild -project "AgendaView/AgendaView.xcodeproj" -scheme AgendaViewTests -destination 'platform=iOS Simulator,name=iPhone 15' test`

## Safety / Hygiene

- Do not add or commit `Secrets.plist` or any token-bearing outputs.
- Avoid changing the App Group id unless you also update both storage services and entitlements.
- Prefer small, targeted changes that match existing SwiftUI patterns.

More detail:

- `docs/development.md`
- `docs/architecture.md`
- `docs/conventions.md`
