## ADDED Requirements

### Requirement: support-site.yml includes newrelic_infra role
The playbook `essensys-ansible/support-site.yml` SHALL include role `newrelic_infra` after `common` and before application roles, gated by `newrelic_enabled`.

#### Scenario: Playbook lists newrelic role
- **WHEN** `support-site.yml` is read
- **THEN** it references `newrelic_infra` in the role order

### Requirement: Portal backend receives New Relic environment variables
Role `portal_backend` SHALL deploy `/opt/essensys/portal-backend/.env` entries for `NEW_RELIC_ENABLED`, `NEW_RELIC_LICENSE_KEY`, `NEW_RELIC_APP_NAME`, and `NEW_RELIC_DISTRIBUTED_TRACING_ENABLED` sourced from Ansible variables and vault.

#### Scenario: Backend env contains NR settings after deploy
- **WHEN** the portal backend role completes with `newrelic_backend_enabled: true`
- **THEN** `/opt/essensys/portal-backend/.env` contains `NEW_RELIC_ENABLED=true` and a non-empty vaulted license key

#### Scenario: Backend env disables NR when flagged off
- **WHEN** the portal backend role completes with `newrelic_backend_enabled: false`
- **THEN** `/opt/essensys/portal-backend/.env` contains `NEW_RELIC_ENABLED=false`

### Requirement: Portal frontend build receives Vite New Relic variables
Role `portal_frontend` SHALL pass `VITE_NEW_RELIC_*` environment variables to `npm run build` when `newrelic_browser_enabled` is true.

#### Scenario: Frontend build embeds browser config
- **WHEN** `portal_frontend` runs with `newrelic_browser_enabled: true`
- **THEN** the npm build step receives `VITE_NEW_RELIC_ENABLED`, account ID, application ID, and related browser identifiers

### Requirement: Portal backend restarts after env changes
Role `portal_backend` SHALL restart `essensys-portal-backend` when New Relic-related `.env` values change.

#### Scenario: Service restarted on NR env update
- **WHEN** New Relic variables in `.env` are updated by Ansible
- **THEN** `essensys-portal-backend` is restarted via systemd handler or task

### Requirement: Operational documentation exists
The file `essensys-ansible/docs/newrelic.md` (or a section in `docs/playbooks.md`) SHALL document enable/disable steps, vault setup, validation checklist, and rollback via `newrelic_enabled: false`.

#### Scenario: Operator finds New Relic runbook
- **WHEN** an operator opens Ansible docs for the support site
- **THEN** New Relic deployment and verification steps are documented
