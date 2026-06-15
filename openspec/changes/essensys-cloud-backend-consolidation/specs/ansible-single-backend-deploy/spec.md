## ADDED Requirements

### Requirement: Single systemd service on OVH
Ansible SHALL deploy one systemd unit (e.g. `essensys-cloud-backend.service`) listening on `:8080` when `cloud_backend_consolidated: true`.

#### Scenario: One active backend service
- **WHEN** consolidation deploy completes on OVH
- **THEN** `systemctl is-active essensys-cloud-backend` succeeds and `essensys-portal-backend` on `:8081` is disabled

### Requirement: Merged environment template
The Ansible role SHALL template a single `.env` file containing OAuth, JWT, DB, New Relic, portal, and gateway configuration variables.

#### Scenario: OAuth vars present after deploy
- **WHEN** consolidated backend starts on VPS
- **THEN** `GOOGLE_CLIENT_ID`, `JWT_SECRET`, and `NEW_RELIC_*` are loaded from the merged template

### Requirement: Nginx single upstream
Nginx configuration SHALL proxy all `/api/`, `/api/portal/`, and `/api/gateway/` locations to the consolidated backend port without a separate `:8081` upstream.

#### Scenario: Portal inject via Nginx
- **WHEN** browser posts to `https://mon.essensys.fr/api/portal/inject`
- **THEN** Nginx forwards to `:8080` consolidated backend

### Requirement: Rollback flag
Variable `cloud_backend_legacy_mode: true` SHALL restore dual-backend deploy (support-site `:8080` + portal `:8081`) for emergency rollback.

#### Scenario: Rollback restores dual services
- **WHEN** operator sets `cloud_backend_legacy_mode: true` and re-runs playbook
- **THEN** both legacy services are enabled and Nginx routes match pre-consolidation configuration
