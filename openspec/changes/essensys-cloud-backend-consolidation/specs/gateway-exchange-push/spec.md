## ADDED Requirements

### Requirement: Gateway exchange push endpoint
The consolidated backend SHALL expose `POST /api/gateway/exchange` authenticated with the same gateway Bearer token and MAC headers as other `/api/gateway/*` routes.

#### Scenario: Valid gateway push accepted
- **WHEN** cloudsync posts `{ "keys": [{"k":605,"v":"1"}, ...] }` with valid gateway auth
- **THEN** `gateway_exchange_cache` is upserted for the gateway's `machine_id` and HTTP 200 is returned

#### Scenario: Invalid gateway auth rejected
- **WHEN** a request to `POST /api/gateway/exchange` lacks valid Bearer token or MAC triplet
- **THEN** the response status is 401

### Requirement: Cloudsync pushes on heartbeat interval
The edge `internal/cloudsync` module SHALL push exchange snapshot to OVH at least once per heartbeat interval (default 60s) when `cloud.enabled: true`.

#### Scenario: Periodic push from Redis
- **WHEN** cloudsync heartbeat runs and Redis contains exchange keys 605-622
- **THEN** cloudsync calls `POST /api/gateway/exchange` with current Redis values

### Requirement: Optional push on Redis change
Cloudsync MAY push exchange immediately on local Redis change with debounce (default 5s) to reduce UI latency after inject.

#### Scenario: Fast update after local apply
- **WHEN** a cloud action is applied locally and Redis exchange keys change
- **THEN** OVH cache is updated within 5 seconds without waiting for next heartbeat
