# Development

## Requirements

- Xcode installed (project: `AgendaView/AgendaView.xcodeproj`)
- A Google OAuth Client ID (iOS) configured with the redirect scheme used by the app

## Secrets

This repo expects a `Secrets.plist` in the repo root at runtime.

- `Secrets.plist` is intentionally untracked (see `.gitignore`).
- Use `Secrets.example.plist` as a template.

Keys:

- `GOOGLE_CLIENT_ID` - string (iOS OAuth client id)

## Build

List targets/schemes:

- `xcodebuild -list -project "AgendaView/AgendaView.xcodeproj"`

Build the app:

- `xcodebuild -project "AgendaView/AgendaView.xcodeproj" -scheme AgendaView -destination 'platform=iOS Simulator,name=iPhone 15' build`

Build the widget extension:

- `xcodebuild -project "AgendaView/AgendaView.xcodeproj" -scheme AgendaWidgetExtension -destination 'platform=iOS Simulator,name=iPhone 15' build`

## Test

- `xcodebuild -project "AgendaView/AgendaView.xcodeproj" -scheme AgendaViewTests -destination 'platform=iOS Simulator,name=iPhone 15' test`

## Widget Debug Notes

- Widgets read cached data from the App Group container, not from the network.
- Cache file name: `events.json`
- App Group id: `group.deadairx.AgendaView`

If the widget shows sample data, it usually means the cache file is missing/empty.
