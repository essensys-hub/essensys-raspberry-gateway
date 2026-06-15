## ADDED Requirements

### Requirement: Portal inject expands to full scenario block
Before persisting a cloud action, the portal-backend SHALL expand partial inject input into a full parameter set including index **590** and all indices **605 through 622**, with unused indices set to **0**, matching `ActionService.AddAction()` semantics on the edge.

#### Scenario: Partial inject expanded
- **WHEN** user posts `{ "k": 613, "v": "64" }` to `/api/portal/inject`
- **THEN** the stored `cloud_actions.params` contains entries for 590 and 605..622 with correct values

### Requirement: Cloud actions use unique GUID idempotence
Each enqueued cloud action SHALL have a unique `guid`. Re-posting the same guid SHALL NOT create duplicate executable rows.

#### Scenario: Duplicate guid ignored
- **WHEN** the same `guid` is submitted twice
- **THEN** only one pending cloud action exists for that guid

### Requirement: Cloud action lifecycle states
Cloud actions SHALL transition through statuses: **`pending`**, **`delivered`** (picked by gateway), **`done`** (acked after local apply), **`failed`** (optional, with reason).

#### Scenario: Gateway poll marks delivered
- **WHEN** gateway agent fetches pending actions
- **THEN** returned actions are marked `delivered` until done ack or timeout retry policy applies
