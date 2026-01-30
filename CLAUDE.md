# Claude Code Instructions

Use this when implementing changes in this repo.

## First Read

- `AGENTS.md`
- `docs/architecture.md`
- `docs/conventions.md`

## Guardrails

- Widgets must render from cached data only; no network calls from the widget extension.
- Never create/commit `Secrets.plist`. Use `Secrets.example.plist` as the template and document-only reference.
- Preserve the existing layering:
  - Views (SwiftUI) are thin.
  - Services handle network/auth/storage.
  - `CalendarDataManager` coordinates and owns app state.

## Where To Put Code

- UI: `AgendaView/AgendaView/Views/`
- App services: `AgendaView/AgendaView/Services/`
- Models: `AgendaView/AgendaView/Models/`
- Widget UI and models: `AgendaView/AgendaWidget/`

## Verification

After making changes, prefer at least a build of the impacted scheme(s):

- App build:
  - `xcodebuild -project "AgendaView/AgendaView.xcodeproj" -scheme AgendaView -destination 'platform=iOS Simulator,name=iPhone 15' build`
- Widget build (if widget code changed):
  - `xcodebuild -project "AgendaView/AgendaView.xcodeproj" -scheme AgendaWidgetExtension -destination 'platform=iOS Simulator,name=iPhone 15' build`
- Tests (when relevant):
  - `xcodebuild -project "AgendaView/AgendaView.xcodeproj" -scheme AgendaViewTests -destination 'platform=iOS Simulator,name=iPhone 15' test`

## Repo Gotchas

- The App Group id is hard-coded in both storage services: `group.deadairx.AgendaView`.
- The OAuth redirect scheme is hard-coded in `GoogleAuthService`. Changing bundle ids/Google OAuth settings may require updates.
- There is a duplicated `Color(hex:)` extension in both app and widget models; avoid introducing a third copy.
