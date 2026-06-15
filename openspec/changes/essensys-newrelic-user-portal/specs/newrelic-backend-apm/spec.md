## ADDED Requirements

### Requirement: New Relic APM is optional via environment flag
The portal backend SHALL initialize the New Relic Go agent only when `NEW_RELIC_ENABLED` is set to `true`. When disabled or unset, the server SHALL start and serve all routes without contacting New Relic.

#### Scenario: Server starts with New Relic disabled
- **WHEN** the backend starts with `NEW_RELIC_ENABLED=false` or unset
- **THEN** `go test ./...` and a local HTTP server respond normally on all existing routes

#### Scenario: Server starts with New Relic enabled
- **WHEN** the backend starts with `NEW_RELIC_ENABLED=true`, valid `NEW_RELIC_LICENSE_KEY`, and `NEW_RELIC_APP_NAME`
- **THEN** the New Relic application initializes without preventing the HTTP server from listening

### Requirement: Chi routes are traced via nrchi middleware
When New Relic is enabled, the router SHALL register `nrchi` middleware so HTTP transactions appear in APM for `/api/portal/*` and `/api/gateway/*` routes.

#### Scenario: Portal API route creates a transaction
- **WHEN** New Relic is enabled and a authenticated request hits `GET /api/portal/gateway/status`
- **THEN** a named transaction is reported to New Relic APM for that route

### Requirement: Health check is excluded from APM noise
The route `GET /api/portal/health` SHALL NOT create New Relic transactions or SHALL be ignored by the agent so uptime probes do not inflate ingest volume.

#### Scenario: Health probe is not traced
- **WHEN** New Relic is enabled and `GET /api/portal/health` is called repeatedly
- **THEN** those requests do not dominate APM transaction counts

### Requirement: Sensitive data is not attached to transactions
The backend SHALL NOT add JWT values, `Authorization` headers, gateway tokens, user email, or domotic payload values (`k`/`v` bodies) as New Relic custom attributes.

#### Scenario: Inject request traced without payload values
- **WHEN** New Relic is enabled and `POST /api/portal/inject` succeeds
- **THEN** the transaction may record latency and aggregate metadata but SHALL NOT include raw domotic parameter values

### Requirement: Required environment variables are documented
The backend README or `.env` example SHALL document `NEW_RELIC_ENABLED`, `NEW_RELIC_LICENSE_KEY`, `NEW_RELIC_APP_NAME`, and `NEW_RELIC_DISTRIBUTED_TRACING_ENABLED`.

#### Scenario: Operator finds NR env documentation
- **WHEN** a developer reads the backend README
- **THEN** New Relic environment variables and the disabled-by-default behavior are described
