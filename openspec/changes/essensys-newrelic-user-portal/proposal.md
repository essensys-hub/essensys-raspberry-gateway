## Why

The **user portal** on OVH (`essensys-user-portal-backend` / `-frontend`, deployed via `essensys-ansible/support-site.yml`) has no production observability today: operators cannot see API latency, JS errors, or VPS health for `https://mon.essensys.fr/portal/`. Gateway sites already use **Prometheus on CM5**, but the **cloud hub** is blind. New Relic on the VPS closes this gap with APM, Browser, and Infrastructure monitoring without replacing edge Prometheus.

## What Changes

- **Go APM** in `essensys-user-portal-backend`: `newrelic-go` v3 + Chi middleware, feature flag `NEW_RELIC_ENABLED`, health route excluded from tracing.
- **Browser agent** in `essensys-user-portal-frontend`: `@newrelic/browser-agent`, SPA page views on `/portal/*`, API error reporting, build-time `VITE_NEW_RELIC_*` vars.
- **Infrastructure agent** on OVH VPS: new Ansible role `newrelic_infra` (`newrelic-infra`, optional `nri-nginx` / `nri-postgresql`).
- **Ansible extensions**: `portal_backend` `.env` NR vars from vault; `portal_frontend` build env; `support-site.yml` includes `newrelic_infra` when `newrelic_enabled`.
- **Security**: license keys in Ansible Vault only; no JWT/gateway tokens or domotic payloads in NR attributes.
- **Non-goals (MVP)**: New Relic on CM5 gateway, replace Prometheus edge, instrument `essensys-support-site` `:8080`, advanced business dashboards.

## Capabilities

### New Capabilities

- `newrelic-backend-apm`: Go agent initialization, Chi middleware, route exclusions, custom attributes, disabled-by-default local dev.
- `newrelic-browser-agent`: Browser agent init, SPA navigation tracking, API error notices, Vite build integration.
- `newrelic-infra-vps`: New Relic Infrastructure agent install and config on OVH VPS via Ansible.
- `newrelic-ansible-portal-deploy`: Vault-backed secrets, portal role extensions, playbook ordering, ops documentation.

### Modified Capabilities

*(none — observability is additive; portal behavior unchanged when `newrelic_enabled: false`)*

## Impact

- **Modified repos**: `essensys-user-portal-backend` (go.mod, main, router), `essensys-user-portal-frontend` (newrelic module, main, portalApi), `essensys-ansible` (new role + portal_* extensions, `support-site.yml`, docs).
- **Dependencies**: New Go/npm packages; APT repo for `newrelic-infra` on VPS.
- **Secrets**: `vault_newrelic_license_key` and browser IDs in Ansible Vault; `.env` mode `0600`.
- **Runtime**: Negligible overhead when disabled; distributed tracing optional between Browser and APM.
- **Risk**: NR ingest cost and PII leakage — mitigated by feature flags, attribute filtering, domain whitelist on Browser app.
