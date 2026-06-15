## ADDED Requirements

### Requirement: Backend service on localhost 7070
The gateway SHALL run the Essensys backend API reachable at `127.0.0.1:7070` for Nginx `/api/` proxying.

#### Scenario: Backend listening locally
- **WHEN** backend module is enabled and system is active
- **THEN** `ss -tlnp` shows a listener on `127.0.0.1:7070` or `0.0.0.0:7070` restricted to localhost via firewall

### Requirement: Frontend static assets available to Nginx
The gateway SHALL provide built frontend static files at the path configured for `services.essensys.nginx.frontendRoot`.

#### Scenario: Frontend files present
- **WHEN** the frontend module is enabled
- **THEN** `index.html` exists under the configured frontend root in the Nix store or NVMe path

### Requirement: Traefik TLS for user HTTPS
Traefik (or equivalent) SHALL terminate HTTPS for user-facing frontend access when enabled.

#### Scenario: Traefik service active
- **WHEN** `services.essensys.traefik.enable = true`
- **THEN** Traefik systemd service is active and configured for TLS entrypoint

### Requirement: Redis and Mosquitto with NVMe-backed state
Redis and Mosquitto SHALL store persistent data under NVMe-backed directories when enabled.

#### Scenario: Redis data path on NVMe
- **WHEN** Redis is enabled
- **THEN** its data directory path is under the NVMe mount or configured `services.essensys.dataDir`

### Requirement: Module stubs for optional services
AdGuard, Prometheus, and MCP MAY ship as disabled stubs with documented enable options in v1 without full production tuning.

#### Scenario: Optional services default off
- **WHEN** default `gateway-cm5` configuration is built
- **THEN** optional monitoring/AdGuard modules are disabled unless explicitly enabled
