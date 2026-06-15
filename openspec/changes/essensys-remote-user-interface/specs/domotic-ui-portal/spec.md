## ADDED Requirements

### Requirement: Portal serves domotic pages under /portal
The user-portal-frontend SHALL be a SPA mounted at **`/portal/`** with at minimum routes for dashboard, shutters (volets), and lights (éclairage).

#### Scenario: Dashboard route loads
- **WHEN** an approved user navigates to `/portal/dashboard`
- **THEN** the dashboard page renders without requiring manual backend DNS configuration

### Requirement: Shutter controls use normalized inject API
Shutter UI actions SHALL call `POST /api/portal/inject` with the correct index mapping derived from `essensys-server-frontend` legacy patterns (not direct Redis or partial MCP writes).

#### Scenario: Open shutter sends inject
- **WHEN** user taps open on a configured shutter control
- **THEN** the frontend posts to `/api/portal/inject` with the mapped `k` and `v` values

### Requirement: Unapproved users see gate screen only
The portal frontend SHALL redirect or render a gate screen for users without approved links, without loading domotic control components.

#### Scenario: Gate screen for pending user
- **WHEN** user without approved link opens any `/portal/*` domotic route
- **THEN** only the link-request or waiting UI is shown

### Requirement: Gateway offline indicator
When hub reports gateway offline (heartbeat stale), the UI SHALL display a visible offline badge and disable inject actions.

#### Scenario: Offline gateway disables controls
- **WHEN** last heartbeat exceeds configured timeout
- **THEN** domotic action buttons are disabled and an offline message is shown
