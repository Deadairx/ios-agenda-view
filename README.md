# iOS Agenda Widget

A native iOS app providing fast-syncing widgets for Google Calendar.

## Vision

Widgets that sync with Google Calendar and display the next 3-5 upcoming events. The goal is quick synchronization—seeing newly added events as fast as iOS allows.

---

## MVP Requirements

### 1. Google Calendar Authentication
- OAuth 2.0 sign-in with Google
- Secure token storage in Keychain
- Automatic token refresh
- Sign out capability

### 2. Calendar Selection
- Fetch list of user's calendars after sign-in
- Settings screen to toggle calendars on/off
- Persist selection locally

### 3. Lock Screen Widget
- Double-wide accessory widget format
- Display 3-4 upcoming events
- Format: `12:30p  Event Name` or `All day  Event Name`
- Show "Tomorrow" separator when crossing days
- Refresh via iOS widget timeline (every 15 min background, faster when app active)

Example:
```
12:30p  Standup
8:30p   Games w/ Evan
Tomorrow
6:00a   Yoga
```

### 4. Home Screen Widget
- Medium and Large widget sizes
- Display 4-6 upcoming events
- Show event color from Google Calendar as background/accent
- Tap to open Google Calendar app

### 5. In-App Agenda View
- Scrollable list of upcoming events (1 month)
- Tap event → opens in Google Calendar app
- Pull-to-refresh for manual sync
- Add button → opens Google Calendar event creation
- Settings access for calendar selection

### 6. Data Sync
- Background app refresh enabled
- App Group for widget-app data sharing
- Local event cache for offline display
- Fetch events 1 month ahead

---

## Success Criteria

### Functional
- [ ] User can sign in with Google account
- [ ] User can select which calendars to display
- [ ] Lock screen widget displays next 3-4 events correctly
- [ ] Home screen widget displays next 4-6 events with colors
- [ ] All-day events show as "All day" in widgets
- [ ] Widgets refresh within 15 minutes (background)
- [ ] Tapping widget/event opens Google Calendar app
- [ ] In-app agenda shows upcoming month of events
- [ ] Pull-to-refresh syncs immediately

### Performance
- [ ] App launches in under 2 seconds
- [ ] Widget renders without persistent "loading" state
- [ ] Sync completes within 5 seconds on good connection

### Reliability
- [ ] App shows cached events when offline
- [ ] Auth tokens refresh automatically without user action
- [ ] No crashes during normal use

---

## Technical Notes

### Scope Decisions
- **Accounts:** Single Google account only (MVP)
- **Time range:** Fetch events for 1 month ahead
- **Calendars:** User selects which calendars to display
- **All-day events:** Show inline with "All day" as the time

### iOS Widget Constraints
- Lock screen widgets update via timeline; iOS controls refresh rate (~15 min background)
- App Group required for sharing data between main app and widget extension
- Widgets cannot make network requests directly; rely on cached data
