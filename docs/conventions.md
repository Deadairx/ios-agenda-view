# Conventions

## Swift / SwiftUI

- Keep Views thin; put IO/network/storage in Services.
- Use async/await for network and refresh flows.
- Keep UI mutations on the main actor; `CalendarDataManager` is `@MainActor`.

## Error Handling

- Prefer surfacing user-facing failures via published `error` strings.
- Avoid noisy logging; use `print` sparingly.

## Widget Constraints

- Do not introduce network calls in the widget extension.
- The widget should remain resilient: empty cache => show friendly empty state or sample events.

## Shared Utilities

- There is already a `Color(hex:)` helper in both app and widget code.
- If you need new shared helpers, prefer a single, clearly-owned implementation rather than additional duplicates.
