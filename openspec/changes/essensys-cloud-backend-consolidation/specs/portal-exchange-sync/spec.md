## ADDED Requirements

### Requirement: Portal exchange returns real data
`GET /api/portal/exchange?keys=` SHALL return exchange key-value pairs for the authenticated user's `linked_machine_id` from the OVH cache, not an empty stub.

#### Scenario: Exchange after inject
- **WHEN** a user with approved link injects a shutter command and the gateway pushes exchange within 60s
- **THEN** a subsequent `GET /api/portal/exchange?keys=605,606,...` includes updated values for those indices

#### Scenario: Exchange requires approved link
- **WHEN** an unlinked user requests `/api/portal/exchange`
- **THEN** the response status is 403

### Requirement: Stale cache metadata
When exchange cache is older than the configured TTL (default 120s), the response SHALL include metadata indicating staleness.

#### Scenario: Stale cache flagged
- **WHEN** gateway has not pushed exchange for more than 120 seconds
- **THEN** the exchange response includes `stale: true` and `updated_at` timestamp

#### Scenario: Gateway offline UI guidance
- **WHEN** exchange is stale or empty and gateway heartbeat is older than 2 minutes
- **THEN** the portal frontend displays an explicit offline or stale-state message (no fabricated values)

### Requirement: Fallback to machine telemetry
When exchange cache is empty, the backend MAY serve last known values from `machine_telemetry` (WAN mystatus) with `source: "mystatus"` and `stale: true`.

#### Scenario: Fallback when cache empty
- **WHEN** no gateway exchange cache exists but mystatus telemetry exists for the machine
- **THEN** exchange returns telemetry values with stale metadata
