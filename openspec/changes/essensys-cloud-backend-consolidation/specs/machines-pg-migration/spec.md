## ADDED Requirements

### Requirement: Machines stored in PostgreSQL
Machine inventory SHALL be persisted in table `machines` replacing file-based `machines.json` MemoryStore.

#### Scenario: Machine record persisted
- **WHEN** a legacy machine authenticates via Basic Auth for the first time
- **THEN** a row exists in `machines` with `hashed_pkey` and `last_seen` updated

### Requirement: Telemetry table for mystatus
Latest telemetry per machine SHALL be stored in `machine_telemetry` keyed by `client_id`.

#### Scenario: MyStatus updates telemetry
- **WHEN** `POST /api/mystatus` receives `{ version, ek: [{k,v}] }`
- **THEN** `machine_telemetry` is upserted for the machine's client ID

### Requirement: Gateway push status table
Gateway monitoring payloads from `POST /api/infos` SHALL be stored in `gateway_push_status` keyed by hostname.

#### Scenario: Admin gateways list from PG
- **WHEN** admin requests `GET /api/admin/gateways`
- **THEN** data is read from PostgreSQL, not from a JSON file

### Requirement: Import path from machines.json
A one-time import command or migration script SHALL load existing `machines.json` into PostgreSQL without data loss.

#### Scenario: Import preserves hashed_pkey keys
- **WHEN** the import script runs against a production `machines.json` backup
- **THEN** all machine records appear in `machines` with matching primary keys
